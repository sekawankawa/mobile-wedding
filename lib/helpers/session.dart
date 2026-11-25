// Menyimpan status login sementara selama aplikasi berjalan.
class Session {
  static bool isLoggedIn = false;

  static String? get userName => null;

  // Status navigasi sementara; token dan profil persisten disimpan di services/session.dart.
  static String? token;
}