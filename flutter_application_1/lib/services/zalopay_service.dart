import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Result of creating an order on the ZaloPay sandbox gateway.
class ZaloPayOrder {
  final String appTransId;
  final String zpTransToken;
  final String orderUrl;
  final int amountVnd;

  ZaloPayOrder({
    required this.appTransId,
    required this.zpTransToken,
    required this.orderUrl,
    required this.amountVnd,
  });
}

enum ZaloPayStatus { paid, pending, failed }

/// Result of querying an order's payment status.
class ZaloPayQueryResult {
  final ZaloPayStatus status;
  final int zpTransId;
  final int amount;
  final String message;

  ZaloPayQueryResult({
    required this.status,
    required this.zpTransId,
    required this.amount,
    required this.message,
  });
}

/// ZaloPay SANDBOX payment service.
///
/// Uses the public sandbox test app credentials published by ZaloPay at
/// https://github.com/zalopay-samples/test-apps — no real money is involved.
/// API reference: https://docs.zalopay.vn (Payment Gateway v2).
class ZaloPayService {
  // Sandbox-only credentials. In production these must live on a server,
  // never inside the app.
  static const String appId = '2554';
  static const String _key1 = 'sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn';

  static const String _createEndpoint = 'https://sb-openapi.zalopay.vn/v2/create';
  static const String _queryEndpoint = 'https://sb-openapi.zalopay.vn/v2/query';

  /// Product prices are already in VND. ZaloPay requires the amount as an
  /// integer number of VND (min 1,000).
  static int toVndAmount(double amount) {
    return max(amount.round(), 1000);
  }

  String _hmacSha256(String key, String data) {
    return Hmac(sha256, utf8.encode(key)).convert(utf8.encode(data)).toString();
  }

  /// app_trans_id must be unique and prefixed with the current date in
  /// GMT+7 (yyMMdd), per the ZaloPay API spec.
  String _newAppTransId() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final suffix =
        '${now.millisecondsSinceEpoch % 1000000}${Random().nextInt(9000) + 1000}';
    return '$yy$mm${dd}_$suffix';
  }

  /// Creates a payment order on the ZaloPay sandbox and returns the gateway
  /// URL the buyer uses to pay.
  Future<ZaloPayOrder> createOrder({
    required int amountVnd,
    required String description,
    required List<Map<String, dynamic>> items,
    String appUser = 'demo_user',
  }) async {
    final appTransId = _newAppTransId();
    final appTime = DateTime.now().millisecondsSinceEpoch.toString();
    final embedData = '{}';
    final item = jsonEncode(items);

    // mac = HMAC_SHA256(key1, app_id|app_trans_id|app_user|amount|app_time|embed_data|item)
    final macData =
        '$appId|$appTransId|$appUser|$amountVnd|$appTime|$embedData|$item';
    final mac = _hmacSha256(_key1, macData);

    final response = await http.post(
      Uri.parse(_createEndpoint),
      body: {
        'app_id': appId,
        'app_user': appUser,
        'app_time': appTime,
        'amount': amountVnd.toString(),
        'app_trans_id': appTransId,
        'embed_data': embedData,
        'item': item,
        'description': description,
        'mac': mac,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ZaloPay create order failed (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['return_code'] != 1) {
      throw Exception(
        'ZaloPay error: ${data['return_message']} (${data['sub_return_message'] ?? ''})',
      );
    }

    return ZaloPayOrder(
      appTransId: appTransId,
      zpTransToken: data['zp_trans_token'] ?? '',
      orderUrl: data['order_url'] ?? '',
      amountVnd: amountVnd,
    );
  }

  /// Queries the sandbox for the payment status of [appTransId].
  ///
  /// return_code: 1 = paid, 2 = failed, 3 = pending/processing.
  Future<ZaloPayQueryResult> queryOrder(String appTransId) async {
    // mac = HMAC_SHA256(key1, app_id|app_trans_id|key1)
    final mac = _hmacSha256(_key1, '$appId|$appTransId|$_key1');

    final response = await http.post(
      Uri.parse(_queryEndpoint),
      body: {
        'app_id': appId,
        'app_trans_id': appTransId,
        'mac': mac,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ZaloPay query failed (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final returnCode = data['return_code'];

    final ZaloPayStatus status;
    if (returnCode == 1) {
      status = ZaloPayStatus.paid;
    } else if (returnCode == 2) {
      status = ZaloPayStatus.failed;
    } else {
      status = ZaloPayStatus.pending;
    }

    return ZaloPayQueryResult(
      status: status,
      zpTransId: (data['zp_trans_id'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      message: data['return_message'] ?? '',
    );
  }
}
