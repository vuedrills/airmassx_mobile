abstract class AuthEvent {}

class AuthLoadUser extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin({required this.email, required this.password});
}

class AuthRegister extends AuthEvent {
  final String name;
  final String email;
  final String password;

  AuthRegister(
      {required this.name, required this.email, required this.password});
}

class AuthLogout extends AuthEvent {}

class AuthGoogleLogin extends AuthEvent {}
class AuthAppleLogin extends AuthEvent {}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  AuthForgotPasswordRequested(this.email);
}

class AuthResetPasswordSubmitted extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;

  AuthResetPasswordSubmitted({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}
