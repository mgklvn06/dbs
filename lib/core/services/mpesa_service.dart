import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:dbs/core/constants/mpesa_backend.dart';

class MpesaService {
  final Dio _http;
  final String _configuredBaseUrl;
  String? _activeBaseUrl;

  MpesaService({Dio? http, String? baseUrl})
    : _http =
          http ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ),
      _configuredBaseUrl = (baseUrl ?? kMpesaBackendBaseUrl).trim();

  bool get isConfigured => _configuredBaseUrl.isNotEmpty || kDebugMode;

  List<String> _candidateBaseUrls() {
    final candidates = <String>[];
    if (_configuredBaseUrl.isNotEmpty) {
      candidates.add(_configuredBaseUrl);
    }

    if (!kDebugMode) return candidates;

    if (kIsWeb) {
      candidates.addAll(<String>[
        'http://localhost:3000',
        'http://localhost:3001',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:3001',
      ]);
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          candidates.addAll(<String>[
            'http://10.0.2.2:3000',
            'http://10.0.2.2:3001',
            'http://localhost:3000',
            'http://localhost:3001',
          ]);
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          candidates.addAll(<String>[
            'http://localhost:3000',
            'http://localhost:3001',
            'http://127.0.0.1:3000',
            'http://127.0.0.1:3001',
          ]);
          break;
      }
    }

    final unique = <String>[];
    for (final base in candidates) {
      final normalized = base.trim();
      if (normalized.isEmpty || unique.contains(normalized)) continue;
      unique.add(normalized);
    }
    return unique;
  }

  Future<bool> _isHealthy(String baseUrl) async {
    try {
      final response = await _http.get(
        _joinBaseAndPath(baseUrl, '/health'),
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveActiveBaseUrl() async {
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      return _activeBaseUrl!;
    }

    final candidates = _candidateBaseUrls();
    if (candidates.isEmpty) {
      throw StateError(
        'M-Pesa backend URL is missing. Set MPESA_BACKEND_BASE_URL or run in debug with local backend.',
      );
    }

    for (final base in candidates) {
      final healthy = await _isHealthy(base);
      if (!healthy) continue;
      _activeBaseUrl = base;
      return base;
    }

    throw StateError(
      'Unable to reach M-Pesa backend. Tried: ${candidates.join(', ')}. Ensure backend is running and reachable.',
    );
  }

  Future<String> _resolveEndpoint(String path) async {
    final base = await _resolveActiveBaseUrl();
    return _joinBaseAndPath(base, path);
  }

  String _joinBaseAndPath(String baseUrl, String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  Future<MpesaStkPushResult> initiateStkPush({
    required String phone,
    required num amount,
    required String userId,
    required String doctorId,
    String? slotId,
  }) async {
    try {
      final endpoint = await _resolveEndpoint(kMpesaStkPushEndpointPath);
      final response = await _http.post(
        endpoint,
        data: <String, dynamic>{
          'phone': phone,
          'amount': amount,
          'userId': userId,
          'doctorId': doctorId,
          if (slotId != null && slotId.isNotEmpty) 'slotId': slotId,
        },
      );

      final body = _readMap(response.data);
      final tx = _readMap(body['transaction']);

      final checkoutRequestId = _readString(tx['checkoutRequestId']).isNotEmpty
          ? _readString(tx['checkoutRequestId'])
          : _readString(body['CheckoutRequestID']);
      final merchantRequestId = _readString(tx['merchantRequestId']).isNotEmpty
          ? _readString(tx['merchantRequestId'])
          : _readString(body['MerchantRequestID']);

      if (checkoutRequestId.isEmpty) {
        throw Exception('Missing CheckoutRequestID from backend response.');
      }

      return MpesaStkPushResult(
        checkoutRequestId: checkoutRequestId,
        merchantRequestId: merchantRequestId,
        customerMessage: _readString(tx['customerMessage']).isNotEmpty
            ? _readString(tx['customerMessage'])
            : _readString(body['CustomerMessage']),
        responseDescription: _readString(tx['responseDescription']).isNotEmpty
            ? _readString(tx['responseDescription'])
            : _readString(body['ResponseDescription']),
      );
    } on DioException catch (e) {
      final data = _readMap(e.response?.data);
      final errorText = _readString(data['error']);
      final detailsText = _readString(data['details']);
      final message = errorText.isNotEmpty
          ? (detailsText.isNotEmpty ? '$errorText: $detailsText' : errorText)
          : e.message ?? 'Failed to initiate M-Pesa STK push.';
      throw Exception(message);
    }
  }

  Future<MpesaTransactionStatus> getTransactionStatus(
    String checkoutRequestId,
  ) async {
    final normalizedId = checkoutRequestId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('checkoutRequestId is required.');
    }

    try {
      final endpoint = await _resolveEndpoint(
        '$kMpesaTransactionEndpointPath/$normalizedId',
      );
      final response = await _http.get(endpoint);

      final body = _readMap(response.data);
      final tx = _readMap(body['transaction']);

      return MpesaTransactionStatus(
        checkoutRequestId: _readString(tx['checkoutRequestId']).isNotEmpty
            ? _readString(tx['checkoutRequestId'])
            : normalizedId,
        merchantRequestId: _readString(tx['merchantRequestId']),
        status: _readString(tx['status']).isNotEmpty
            ? _readString(tx['status']).toLowerCase()
            : 'pending',
        resultCode: _readInt(tx['resultCode']),
        resultDesc: _readString(tx['resultDesc']),
        amount: _readNum(tx['amount']) ?? _readNum(tx['callbackAmount']),
        phone: _readString(tx['phone']).isNotEmpty
            ? _readString(tx['phone'])
            : _readString(tx['callbackPhone']),
        mpesaReceiptNumber: _readString(tx['mpesaReceiptNumber']),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return MpesaTransactionStatus(
          checkoutRequestId: normalizedId,
          merchantRequestId: '',
          status: 'pending',
          resultCode: null,
          resultDesc: 'Transaction not found yet.',
          amount: null,
          phone: '',
          mpesaReceiptNumber: '',
        );
      }
      final data = _readMap(e.response?.data);
      final message = _readString(data['error']).isNotEmpty
          ? _readString(data['error'])
          : e.message ?? 'Failed to fetch M-Pesa transaction.';
      throw Exception(message);
    }
  }

  static String? normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('254') && digits.length == 12) return digits;
    if (digits.startsWith('0') && digits.length == 10) {
      return '254${digits.substring(1)}';
    }
    if (digits.startsWith('7') && digits.length == 9) return '254$digits';
    return null;
  }

  static Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static String _readString(dynamic raw) {
    if (raw is String) return raw.trim();
    if (raw == null) return '';
    return '$raw'.trim();
  }

  static int? _readInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static num? _readNum(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }
}

class MpesaStkPushResult {
  final String checkoutRequestId;
  final String merchantRequestId;
  final String customerMessage;
  final String responseDescription;

  const MpesaStkPushResult({
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.customerMessage,
    required this.responseDescription,
  });
}

class MpesaTransactionStatus {
  final String checkoutRequestId;
  final String merchantRequestId;
  final String status;
  final int? resultCode;
  final String resultDesc;
  final num? amount;
  final String phone;
  final String mpesaReceiptNumber;

  const MpesaTransactionStatus({
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.status,
    required this.resultCode,
    required this.resultDesc,
    required this.amount,
    required this.phone,
    required this.mpesaReceiptNumber,
  });

  bool get isSuccess => status == 'success';
  bool get isTerminal =>
      status == 'success' ||
      status == 'failed' ||
      status == 'cancelled' ||
      status == 'timeout';
}
