import 'api_client.dart';
import 'session.dart';

class SavingsService {
  static double parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> getGoals() async {
    final planId = await Session.getPlanId();
    final query = planId != null ? '?planId=$planId' : '';
    final data = await ApiClient.get('/savings/goals$query');

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createGoal({
    required String title,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final planId = await Session.getPlanId() ?? await AuthServiceFallback.ensurePlanId();
    final data = await ApiClient.post(
      '/savings/goals',
      body: {
        'planId': planId,
        'title': title,
        'targetAmount': targetAmount,
        if (targetDate != null) 'targetDate': targetDate.toUtc().toIso8601String(),
      },
    );
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addContribution({
    required String goalId,
    required double nominal,
    String? note,
    DateTime? contributedAt,
  }) async {
    final data = await ApiClient.post(
      '/savings/goals/$goalId/contributions',
      body: {
        'amount': nominal,
        'contributedAt': (contributedAt ?? DateTime.now()).toUtc().toIso8601String(),
        if (note != null && note.isNotEmpty) 'description': note,
      },
    );
    return data as Map<String, dynamic>;
  }
}

class AuthServiceFallback {
  static Future<String> ensurePlanId() async {
    final plans = await ApiClient.get('/plans');
    if (plans is List && plans.isNotEmpty) {
      final id = plans.first['id'].toString();
      await Session.savePlanId(id);
      return id;
    }
    throw ApiException('Wedding plan belum dibuat. Atur rencana terlebih dahulu.', 400);
  }
}