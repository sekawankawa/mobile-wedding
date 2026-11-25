import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import 'session.dart';

class AuthService {
  static Future<void>? _googleInitFuture;

  static Future<void> _ensureGoogleInitialized() {
    final clientId = const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (clientId.isEmpty) {
      throw ApiException(
        'Google Sign-In belum dikonfigurasi. Isi GOOGLE_SERVER_CLIENT_ID saat build.',
        500,
      );
    }
    return _googleInitFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: clientId,
    );
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      '/auth/login',
      withAuth: false,
      body: {'email': email, 'password': password},
    );
    await _persistAuthResponse(data);
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    final data = await ApiClient.post(
      '/auth/register',
      withAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'acceptTerms': acceptTerms,
      },
    );
    if (data is Map<String, dynamic> && data.containsKey('accessToken')) {
      await _persistAuthResponse(data);
    }
  }

  static Future<void> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    late final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw ApiException('Login Google dibatalkan', 400);
      }
      throw ApiException(e.description ?? 'Gagal login dengan Google', 400);
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw ApiException('Gagal mendapatkan ID Token Google', 400);
    }

    final data = await ApiClient.post(
      '/auth/google',
      withAuth: false,
      body: {'idToken': idToken},
    );
    await _persistAuthResponse(data);
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout');
    } catch (_) {
      // Tetap bersihkan sesi lokal meskipun jaringan gagal
    } finally {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Abaikan jika user tidak login menggunakan Google
      }
      await Session.clear();
    }
  }

  static Future<void> _persistAuthResponse(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>;
    await Session.saveAuth(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      userId: user['id'].toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
    );
    // Autentikasi tidak boleh tampak gagal hanya karena sinkronisasi plan gagal.
    try {
      await syncActivePlan();
    } catch (_) {
      // Plan akan dimuat ulang saat halaman fitur dibuka.
    }
  }

  static Future<String?> syncActivePlan() async {
    final plans = await ApiClient.get('/plans');
    if (plans is List && plans.isNotEmpty) {
      final planId = plans.first['id'].toString();
      await Session.savePlanId(planId);
      return planId;
    }
    return null;
  }
}