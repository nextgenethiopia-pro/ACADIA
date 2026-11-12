import 'dart:convert';

import 'package:acadia/src/core/config/secrets.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Forwards payment activity to the administrator's Telegram chat.
///
/// Sending is strictly one-way: messages are posted to the bot, no commands,
/// buttons or callbacks are registered, and nothing is written back to the
/// database from here.
class PaymentNotificationService {
  PaymentNotificationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _apiBase = 'https://api.telegram.org';
  static const Duration _timeout = Duration(seconds: 20);

  static const Map<String, String> _statusTitles = <String, String>{
    'pending': 'PENDING',
    'approved': 'APPROVED',
    'rejected': 'REJECTED',
    'failed': 'FAILED',
  };

  static const Map<String, String> _statusEmoji = <String, String>{
    'pending': '\u{1F553}',
    'approved': '\u2705',
    'rejected': '\u274C',
    'failed': '\u26A0\uFE0F',
  };

  /// Reports a newly submitted payment.
  ///
  /// The notification always states PENDING. Submitting payment information
  /// never marks a payment as successful.
  Future<void> notifyPaymentSubmitted({
    required String userId,
    required String paymentId,
    required num amount,
    required String method,
    required String reference,
    String currency = 'ETB',
    String? packageName,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? screenshotUrl,
    String? submittedAt,
  }) async {
    final problems = _validate(
      userId: userId,
      amount: amount,
      method: method,
      currency: currency,
      screenshotUrl: screenshotUrl,
    );
    if (problems.isNotEmpty) {
      _logInvalid('new payment', problems);
      return;
    }

    const status = 'pending';

    final caption = _format(
      heading: '\u{1F195} <b>New Payment Submitted</b>',
      status: status,
      rows: <List<String>>[
        <String>['Account ID', _code(userId)],
        <String>['Payment ID', _code(paymentId)],
        <String>['Student', _text(userName)],
        <String>['Email', _text(userEmail)],
        <String>['Phone', _text(userPhone)],
        <String>['Package', _text(packageName)],
        <String>['Amount', '${_plain(amount)} $currency'],
        <String>['Method', method],
        <String>['Reference ID', _code(reference)],
        <String>['Submitted', _formatTime(submittedAt)],
      ],
      extraLines: const <String>[
        '\u2139\uFE0F Awaiting admin review \u2014 this payment is not approved.',
      ],
    );

    await _deliver(caption: caption, screenshotUrl: screenshotUrl);
  }

  /// Reports a payment whose status an administrator has just persisted.
  ///
  /// [payment] is the stored payment record, so the notification always
  /// reflects what was saved. [status] must be one of `pending`, `approved`,
  /// `rejected` or `failed`.
  Future<void> notifyPaymentStatusChanged({
    required Map<String, dynamic> payment,
    required String status,
    String? reason,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();
    if (!_statusTitles.containsKey(normalizedStatus)) {
      debugPrint(
        '[PaymentNotificationService] unknown payment status "$status" \u2014 '
        'notification skipped.',
      );
      return;
    }

    final paymentId = _text(payment['id']);
    final userId = _text(payment['user_id']);
    final amount = _toAmount(payment['amount']);
    final currency = _text(payment['currency']).isEmpty
        ? 'ETB'
        : _text(payment['currency']);
    final method = _text(payment['payment_method']).isNotEmpty
        ? _text(payment['payment_method'])
        : _text(payment['method']);
    final reference = _text(payment['transaction_ref']).isNotEmpty
        ? _text(payment['transaction_ref'])
        : _text(payment['transaction_reference']);
    final packageName = _text(payment['package_name']).isNotEmpty
        ? _text(payment['package_name'])
        : _text(payment['package']);
    final screenshotUrl = _text(payment['receipt_url']).isNotEmpty
        ? _text(payment['receipt_url'])
        : _text(payment['screenshot_url']);

    final problems = _validate(
      userId: userId,
      amount: amount,
      method: method,
      currency: currency,
      screenshotUrl: screenshotUrl,
    );
    if (problems.isNotEmpty) {
      _logInvalid('payment status change', problems);
      return;
    }

    final extraLines = <String>[];
    switch (normalizedStatus) {
      case 'approved':
        extraLines.add('\u2714\uFE0F Package unlocked for the student.');
        break;
      case 'rejected':
        final trimmedReason = reason?.trim() ?? '';
        extraLines.add(
          '<b>Rejection reason:</b> ${_escape(trimmedReason.isEmpty ? 'Not specified' : trimmedReason)}',
        );
        break;
      case 'pending':
        extraLines.add('\u{1F553} Still awaiting review.');
        break;
      case 'failed':
        extraLines.add(
          '\u26A0\uFE0F Payment did not complete. No access has been granted.',
        );
        break;
    }

    final caption = _format(
      heading: '\u{1F514} <b>Payment Status Update</b>',
      status: normalizedStatus,
      rows: <List<String>>[
        <String>['Account ID', _code(userId)],
        <String>['Payment ID', _code(paymentId)],
        <String>['Student', _text(payment['user_name'])],
        <String>['Email', _text(payment['user_email'])],
        <String>['Phone', _text(payment['user_phone'])],
        <String>['Package', packageName],
        <String>['Amount', '${_plain(amount)} $currency'],
        <String>['Method', method],
        <String>['Reference ID', _code(reference)],
        <String>[
          'Submitted',
          _formatTime(_text(payment['submission_date'])),
        ],
      ],
      extraLines: extraLines,
    );

    await _deliver(caption: caption, screenshotUrl: screenshotUrl);
  }

  // -------------------------------------------------------------------------
  // Message building
  // -------------------------------------------------------------------------

  String _format({
    required String heading,
    required String status,
    required List<List<String>> rows,
    List<String> extraLines = const <String>[],
  }) {
    final lines = <String>[heading, ''];

    for (final row in rows) {
      final value = row[1].trim();
      if (value.isEmpty) continue;
      lines.add('<b>${row[0]}:</b> $value');
    }

    lines.add(
      '<b>Status:</b> ${_statusEmoji[status]} <b>${_statusTitles[status]}</b>',
    );

    if (extraLines.isNotEmpty) {
      lines.add('');
      lines.addAll(extraLines);
    }

    return lines.join('\n');
  }

  /// Sends the notification, attaching the payment screenshot when a usable
  /// image link is available, otherwise falling back to a text message.
  Future<void> _deliver({
    required String caption,
    String? screenshotUrl,
  }) async {
    final url = screenshotUrl?.trim() ?? '';

    if (url.isNotEmpty) {
      final sentAsPhoto = await _post('sendPhoto', <String, dynamic>{
        'chat_id': Secrets.telegramChatId,
        'photo': url,
        'caption': caption,
        'parse_mode': 'HTML',
      });
      if (sentAsPhoto) return;

      await _post('sendMessage', <String, dynamic>{
        'chat_id': Secrets.telegramChatId,
        'text': '$caption\n\n<b>Screenshot:</b> ${_escape(url)}',
        'parse_mode': 'HTML',
      });
      return;
    }

    await _post('sendMessage', <String, dynamic>{
      'chat_id': Secrets.telegramChatId,
      'text': caption,
      'parse_mode': 'HTML',
    });
  }

  /// Posts to the Telegram bot API. Failures are logged, never thrown, so a
  /// notification problem can never break a payment.
  Future<bool> _post(String method, Map<String, dynamic> payload) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '$_apiBase/bot${Secrets.telegramBotToken}/$method',
            ),
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return true;

      debugPrint(
        '[PaymentNotificationService] Telegram $method failed '
        '(${response.statusCode}): ${response.body}',
      );
      return false;
    } catch (error) {
      debugPrint('[PaymentNotificationService] Telegram $method error: $error');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Validation & formatting helpers
  // -------------------------------------------------------------------------

  List<String> _validate({
    required String userId,
    required num amount,
    required String method,
    required String currency,
    String? screenshotUrl,
  }) {
    final problems = <String>[];

    if (userId.trim().isEmpty) problems.add('user account id is missing');
    if (amount <= 0) problems.add('amount must be greater than zero');
    if (method.trim().isEmpty) problems.add('payment method is missing');
    if (currency.trim().isEmpty) problems.add('currency is missing');

    final url = screenshotUrl?.trim() ?? '';
    if (url.isNotEmpty && !url.startsWith('http')) {
      problems.add('screenshot url is not a valid link');
    }

    return problems;
  }

  void _logInvalid(String context, List<String> problems) {
    debugPrint(
      '[PaymentNotificationService] payment data validation failed for '
      '$context: ${problems.join('; ')}. Notification skipped.',
    );
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  num _toAmount(dynamic value) {
    if (value is num) return value;
    return num.tryParse(_text(value)) ?? 0;
  }

  /// Renders a value as a monospace field, escaping it first.
  String _code(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    return '<code>${_escape(text)}</code>';
  }

  String _plain(num value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  String _formatTime(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return _formatTime(DateTime.now().toIso8601String());
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _escape(raw);

    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
