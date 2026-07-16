/// Payment Methods Configuration
///
/// Based on ACADIA V1.0.0 specification:
/// 5 payment methods with account details
class PaymentMethods {
  static const List<Map<String, String>> allMethods = [
    {
      'id': 'telebirr',
      'name': 'Telebirr',
      'account': '0967870090',
      'holder': 'FIRAOL TADESA',
      'icon': 'phone',
    },
    {
      'id': 'mpesa',
      'name': 'M-PESA',
      'account': '0705578277',
      'holder': 'BONA BAYU',
      'icon': 'phone_android',
    },
    {
      'id': 'cbe',
      'name': 'CBE',
      'account': '1000720789985',
      'holder': 'FIRAOL TADESA',
      'icon': 'account_balance',
    },
    {
      'id': 'cbo',
      'name': 'CBO',
      'account': '1016100072577',
      'holder': 'FIRAOL TADESA',
      'icon': 'account_balance',
    },
    {
      'id': 'awash',
      'name': 'AWASH BANK',
      'account': '01320500140900',
      'holder': 'FIRAOL TADESA',
      'icon': 'account_balance',
    },
  ];

  /// Get payment method by ID
  static Map<String, String>? getMethodById(String id) {
    try {
      return allMethods.firstWhere((m) => m['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Get method name by ID
  static String getMethodName(String id) {
    final method = getMethodById(id);
    return method?['name'] ?? 'Unknown';
  }

  /// Get method account by ID
  static String getMethodAccount(String id) {
    final method = getMethodById(id);
    return method?['account'] ?? '';
  }

  /// Get method holder by ID
  static String getMethodHolder(String id) {
    final method = getMethodById(id);
    return method?['holder'] ?? '';
  }

  /// Get display text for payment method
  static String getDisplayText(String id) {
    final method = getMethodById(id);
    if (method == null) return 'Unknown';

    return '${method['name']}\n${method['account']}\n${method['holder']}';
  }

  /// Get all method names
  static List<String> getAllMethodNames() {
    return allMethods.map((m) => m['name'] ?? '').toList();
  }
}
