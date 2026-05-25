import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/profile_data_providers.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/delete_address_usecase.dart';
import '../../domain/usecases/get_addresses_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

export '../../data/providers/profile_data_providers.dart'
    show profileRemoteDatasourceProvider, apiProfileRepositoryProvider;

// ---------------------------------------------------------------------------
// Profile state
// ---------------------------------------------------------------------------

@immutable
class ProfileState {
  final ProfileEntity? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileEntity? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile notifier (Riverpod 3.x — Notifier<T>)
// ---------------------------------------------------------------------------

class ApiProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(loadProfile);
    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await GetProfileUsecase(ref.read(apiProfileRepositoryProvider))();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (profile) =>
          state = state.copyWith(profile: profile, isLoading: false),
    );
  }

  Future<bool> updateProfile(UpdateProfileInput input) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await UpdateProfileUsecase(
      ref.read(apiProfileRepositoryProvider),
    )(input);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (profile) {
        state = state.copyWith(profile: profile, isLoading: false);
        return true;
      },
    );
  }

  Future<bool> updateAvatar(String imagePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result =
        await ref.read(apiProfileRepositoryProvider).updateAvatar(imagePath);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (avatarUrl) {
        if (state.profile != null) {
          state = state.copyWith(
            profile: state.profile!.copyWith(avatarUrl: avatarUrl),
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ---------------------------------------------------------------------------
// Addresses state
// ---------------------------------------------------------------------------

@immutable
class AddressesState {
  final List<AddressEntity> addresses;
  final bool isLoading;
  final String? error;

  const AddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  AddressesState copyWith({
    List<AddressEntity>? addresses,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Addresses notifier (Riverpod 3.x — Notifier<T>)
// ---------------------------------------------------------------------------

class ApiAddressesNotifier extends Notifier<AddressesState> {
  @override
  AddressesState build() {
    Future.microtask(loadAddresses);
    return const AddressesState(isLoading: true);
  }

  IProfileRepository get _repo => ref.read(apiProfileRepositoryProvider);

  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await GetAddressesUsecase(_repo)();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (addresses) =>
          state = state.copyWith(addresses: addresses, isLoading: false),
    );
  }

  Future<bool> addAddress(AddressEntity address) async {
    final result = await AddAddressUsecase(_repo)(address);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (newAddress) {
        state = state.copyWith(
          addresses: [...state.addresses, newAddress],
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> updateAddress(AddressEntity address) async {
    final result = await UpdateAddressUsecase(_repo)(address);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updated) {
        final updatedList = state.addresses.map((a) {
          return a.id == updated.id ? updated : a;
        }).toList();
        state = state.copyWith(addresses: updatedList, clearError: true);
        return true;
      },
    );
  }

  Future<bool> deleteAddress(int id) async {
    final result = await DeleteAddressUsecase(_repo)(id);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        final updatedList = state.addresses.where((a) => a.id != id).toList();
        state = state.copyWith(addresses: updatedList, clearError: true);
        return true;
      },
    );
  }

  Future<bool> setDefault(int id) async {
    final result = await _repo.setDefaultAddress(id);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        final updatedList = state.addresses.map((a) {
          return a.copyWith(isDefault: a.id == id);
        }).toList();
        state = state.copyWith(addresses: updatedList, clearError: true);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final apiProfileNotifierProvider =
    NotifierProvider<ApiProfileNotifier, ProfileState>(
  ApiProfileNotifier.new,
);

final apiAddressesNotifierProvider =
    NotifierProvider<ApiAddressesNotifier, AddressesState>(
  ApiAddressesNotifier.new,
);
