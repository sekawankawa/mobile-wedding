// lib/services/wedding_feature_service.dart
import 'api_client.dart';
import 'session.dart';

class WeddingFeatureService {
  // 1. RencanaPage & AturTanggalPage -> /plans
  static Future<Map<String, dynamic>?> getCurrentPlan() async {
    final plans = await ApiClient.get('/plans');
    if (plans is List && plans.isNotEmpty) {
      final plan = plans.first as Map<String, dynamic>;
      await Session.savePlanId(plan['id'].toString());
      return plan;
    }
    return null;
  }

  static Future<Map<String, dynamic>> saveOrUpdatePlan({
    required String title,
    required DateTime weddingDate,
    required double totalBudget,
    String? city,
    int? guestCount,
  }) async {
    final existingPlanId = await Session.getPlanId();
    final payload = {
      'title': title,
      'weddingDate': weddingDate.toIso8601String().split('T').first,
      'totalBudget': totalBudget,
      if (city != null) 'city': city,
      if (guestCount != null) 'guestCount': guestCount,
    };

    final data = existingPlanId != null
        ? await ApiClient.patch('/plans/$existingPlanId', body: payload)
        : await ApiClient.post('/plans', body: payload);

    final plan = data as Map<String, dynamic>;
    await Session.savePlanId(plan['id'].toString());
    return plan;
  }

  // 2. UserPage -> /users/me
  static Future<Map<String, dynamic>> getMyProfile() async {
    final data = await ApiClient.get('/users/me');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMyProfile({
    String? name,
    String? phone,
  }) async {
    final data = await ApiClient.patch(
      '/users/me',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      },
    );
    return data as Map<String, dynamic>;
  }

  // 3. AsistenPage -> /chatbot/messages
  static Future<String> askAssistant(String message) async {
    final planId = await Session.getPlanId();
    final sessionId = await Session.getChatbotSessionId();
    final data = await ApiClient.post(
      '/chatbot/messages',
      body: {
        'message': message,
        if (planId != null) 'planId': planId,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );
    if (data is Map<String, dynamic>) {
      final returnedSessionId = data['sessionId']?.toString();
      if (returnedSessionId != null && returnedSessionId.isNotEmpty) {
        await Session.saveChatbotSessionId(returnedSessionId);
      }
      return (data['reply'] ?? '').toString();
    }
    return data.toString();
  }
}
