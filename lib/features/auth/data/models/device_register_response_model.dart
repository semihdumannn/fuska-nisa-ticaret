import 'api_user_model.dart';

class DeviceRegisterResponseModel {
  final String token;
  final ApiUserModel user;
  final String totpSecret;
  final bool isNewUser;

  const DeviceRegisterResponseModel({
    required this.token,
    required this.user,
    required this.totpSecret,
    required this.isNewUser,
  });

  factory DeviceRegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return DeviceRegisterResponseModel(
      token: json['token'] as String,
      user: ApiUserModel.fromJson(json['user'] as Map<String, dynamic>),
      totpSecret: json['totp_secret'] as String,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }
}
