import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyPlanId = 'active_plan_id';
  static const _keyChatbotSessionId = 'chatbot_session_id';

  static Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previousUserId = prefs.getString(_keyUserId);
    if (previousUserId != null && previousUserId != userId) {
      await prefs.remove(_keyPlanId);
      await prefs.remove(_keyChatbotSessionId);
    }
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<void> savePlanId(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlanId, planId);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getPlanId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlanId);
  }

  static Future<void> saveChatbotSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChatbotSessionId, sessionId);
  }

  static Future<String?> getChatbotSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyChatbotSessionId);
  }

  static Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyUserName),
      'email': prefs.getString(_keyUserEmail),
    };
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyPlanId);
    await prefs.remove(_keyChatbotSessionId);
  }
}