import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/network/api_service.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, phone, password];
}

class OtpSubmitted extends AuthEvent {
  final String otp;
  const OtpSubmitted(this.otp);

  @override
  List<Object?> get props => [otp];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String newPassword;
  const ResetPasswordRequested(this.newPassword);

  @override
  List<Object?> get props => [newPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class LogoutRequested extends AuthEvent {}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final MockUser user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  final String demoOtp;
  const AuthOtpSent(this.email, this.demoOtp);

  @override
  List<Object?> get props => [email, demoOtp];
}

class AuthOtpSuccess extends AuthState {}

class AuthPasswordResetSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Global instance for simple access from screens or GoRouter redirects if needed
  static MockUser? currentUser;

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    // 1. Cố gắng đăng nhập qua API thật của backend
    try {
      final token = await ApiService.instance.login(event.email, event.password);
      if (token != null) {
        final realUser = await ApiService.instance.fetchUserInfo(event.email, token);
        if (realUser != null) {
          currentUser = realUser;
          emit(AuthAuthenticated(realUser));
          return;
        }
      }
    } catch (e) {
      print('Real API Login failed: $e. Falling back to local mock login...');
    }

    // 2. Fallback sang dữ liệu Mock cục bộ nếu Backend offline hoặc không có tài khoản
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final user = MockData.users.firstWhere(
        (u) => u.email.toLowerCase() == event.email.toLowerCase(),
      );
      
      final expectedPassword = '${user.role.toLowerCase()}123';
      if (event.password == expectedPassword || event.password == '123456' || event.password == 'password') {
        currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Mật khẩu không chính xác. Gợi ý: dùng \'123456\' hoặc \'{vai_trò}123\''));
      }
    } catch (e) {
      emit(const AuthError('Tài khoản không tồn tại trên hệ thống.'));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1500));

    if (event.fullName.isEmpty || event.email.isEmpty || event.phone.isEmpty || event.password.isEmpty) {
      emit(const AuthError('Vui lòng nhập đầy đủ thông tin đăng ký.'));
      return;
    }

    // In mock mode, we trigger OTP verification
    emit(AuthOtpSent(event.email, '123456'));
  }

  Future<void> _onOtpSubmitted(OtpSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.otp == '123456') {
      // Mock register user
      final newUser = MockUser(
        id: 'usr_new_${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Khách hàng Mới',
        email: 'newcustomer@coffee.com',
        phone: '0900000000',
        role: 'CUSTOMER',
      );
      // Add to mock database list
      MockData.users.add(newUser);
      currentUser = newUser;
      
      emit(AuthOtpSuccess());
      emit(AuthAuthenticated(newUser));
    } else {
      emit(const AuthError('Mã OTP không chính xác. Vui lòng nhập 123456'));
    }
  }

  Future<void> _onForgotPasswordRequested(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.email.isEmpty || !event.email.contains('@')) {
      emit(const AuthError('Email không hợp lệ.'));
      return;
    }

    emit(AuthOtpSent(event.email, '123456'));
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    emit(AuthPasswordResetSuccess());
  }

  Future<void> _onChangePasswordRequested(ChangePasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.oldPassword.isEmpty || event.newPassword.isEmpty) {
      emit(const AuthError('Vui lòng điền đầy đủ các trường mật khẩu.'));
      return;
    }
    
    emit(AuthInitial()); // Reset status
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    currentUser = null;
    emit(AuthUnauthenticated());
  }
}
