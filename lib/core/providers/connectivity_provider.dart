import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline, unknown }

class ConnectivityNotifier extends Notifier<NetworkStatus> {
  @override
  NetworkStatus build() {
    // Connectivity stream'i dinle
    final subscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        final hasConnection = results.any(
          (r) => r != ConnectivityResult.none,
        );
        state = hasConnection ? NetworkStatus.online : NetworkStatus.offline;
      },
    );

    // Cleanup
    ref.onDispose(subscription.cancel);

    // Baslangic durumu
    _checkInitial();
    return NetworkStatus.unknown;
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    state = hasConnection ? NetworkStatus.online : NetworkStatus.offline;
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, NetworkStatus>(
  ConnectivityNotifier.new,
);

final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityProvider);
  return status != NetworkStatus.offline;
});
