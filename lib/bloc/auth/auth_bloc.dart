import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    _checkSession();
  }

  Future<http.Response> _login(String email, String password) {
    final url = adminEndpoint('admin_login');
    return http.post(
      Uri.parse(url),
      headers: buildApiHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
  }

  Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('uid', user['admin_id'] as int);
    await prefs.setString('adminType', user['admin_type'] as String);
    await prefs.setString('firstName', user['first_name'] as String);
    await prefs.setString('middleName', user['middle_name'] as String);
    await prefs.setString('lastName', user['last_name'] as String);
    await prefs.setString('email', user['email_address'] as String);
    await prefs.setString('department', user['department'] as String);
    await prefs.setInt('departmentId', user['department_id'] as int);
    await prefs.setString('status', user['status'] as String);
  }

  AuthSuccess _toAuthSuccess(Map<String, dynamic> user) {
    return AuthSuccess(
      uid: user['admin_id'] as int,
      adminType: user['admin_type'] as String,
      firstName: user['first_name'] as String,
      middleName: user['middle_name'] as String,
      lastName: user['last_name'] as String,
      email: user['email_address'] as String,
      department: user['department'] as String,
      departmentId: user['department_id'] as int,
      status: user['status'] as String,
    );
  }

  void _checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid');
      final adminType = prefs.getString('adminType');
      final departmentId = prefs.getInt('departmentId');
      final firstName = prefs.getString('firstName');
      final middleName = prefs.getString('middleName');
      final lastName = prefs.getString('lastName');
      final email = prefs.getString('email');
      final department = prefs.getString('department');
      final status = prefs.getString('status');

      if (uid != null &&
          adminType != null &&
          departmentId != null &&
          firstName != null &&
          middleName != null &&
          lastName != null &&
          email != null &&
          email != department) {
        emit(AuthSuccess(
            uid: uid,
            adminType: adminType,
            departmentId: departmentId,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: email,
            department: department!,
            status: status!));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure('Failed to check session: $e'));
    }
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    print('AuthBloc - $change');
  }

  void _onAuthLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final email = event.email;
      final password = event.password;
      // Email validation using regex
      if (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
          .hasMatch(email)) {
        emit(AuthFailure(
            'Incorrect email or password, or account inactive. Please try again or contact support.'));
        return;
      }
      if (password.length < 6) {
        emit(AuthFailure('Password cannot be less than 6 characters'));
        return;
      }

      if (appEnv == 'local' && enableLocalAuthMock) {
        final isValidLocalCredential =
            email.toLowerCase() == localTestAdminEmail.toLowerCase() &&
                password == localTestAdminPassword;
        if (!isValidLocalCredential) {
          emit(AuthFailure('Invalid local test credentials.'));
          return;
        }

        final localUser = <String, dynamic>{
          'admin_id': 999001,
          'admin_type': 'admin',
          'first_name': 'Local',
          'middle_name': 'Test',
          'last_name': 'Admin',
          'email_address': localTestAdminEmail,
          'department': 'Engineering',
          'department_id': localTestAdminDepartmentId,
          'status': 'active',
        };
        await _saveSession(localUser);
        emit(_toAuthSuccess(localUser));
        return;
      }

      final response = await _login(email, password);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == "Login successful") {
          final user = data['user'];

          await _saveSession(user);
          print("ADMINTYPE: ${user['admin_type']}");
          emit(_toAuthSuccess(user));
        } else {
          emit(AuthFailure('Login failed'));
        }
      } else if (response.statusCode == 401) {
        // If the API returns 401 Unauthorized, extract and show the error message
        final data = jsonDecode(response.body);
        emit(AuthFailure(data['error'] ?? 'Unknown error occurred'));
      } else {
        // Handle other errors (e.g., 500, 404, etc.)
        emit(AuthFailure('Server error. Please try again later.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onAuthLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
