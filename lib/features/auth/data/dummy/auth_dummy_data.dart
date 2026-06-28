/// Dummy Data for Authentication
/// In a real app, this would be replaced with API calls
class AuthDummyData {
  AuthDummyData._();

  /// Simulate login - returns success for any valid email/password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Basic validation
    if (email.isEmpty || !email.contains('@')) {
      return {
        'success': false,
        'message': 'Email tidak valid',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password minimal 6 karakter',
      };
    }

    // Simulate successful login
    return {
      'success': true,
      'message': 'Login berhasil',
      'user': {
        'id': '1',
        'name': email.split('@').first,
        'email': email,
        'isLoggedIn': true,
      },
    };
  }

  /// Simulate registration
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Basic validation
    if (name.isEmpty) {
      return {
        'success': false,
        'message': 'Nama tidak boleh kosong',
      };
    }

    if (email.isEmpty || !email.contains('@')) {
      return {
        'success': false,
        'message': 'Email tidak valid',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password minimal 6 karakter',
      };
    }

    // Simulate successful registration
    return {
      'success': true,
      'message': 'Registrasi berhasil',
      'user': {
        'id': '1',
        'name': name,
        'email': email,
        'isLoggedIn': true,
      },
    };
  }
}
