import 'api_user_model.dart';

class LoginResponseModel {
  final String token;
  final ApiUserModel user;

  const LoginResponseModel({
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] as String,
      user: ApiUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
