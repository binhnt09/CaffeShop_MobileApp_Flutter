import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';

typedef StompUnsubscribe = void Function();

class StompService {
  static final StompService instance = StompService._internal();
  StompService._internal();

  StompClient? _client;
  bool _isConnected = false;
  final List<VoidCallback> _onConnectCallbacks = [];

  bool get isConnected => _isConnected;

  void connect({required String token, VoidCallback? onConnected}) {
    if (onConnected != null) {
      _onConnectCallbacks.add(onConnected);
    }

    if (_isConnected) {
      onConnected?.call();
      return;
    }

    if (_client != null && _client!.isActive) {
      return;
    }

    final wsUri = '${ApiConstants.baseUrl}/ws';

    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsUri,
        onConnect: (frame) {
          _isConnected = true;
          debugPrint('STOMP Connected successfully to $wsUri');
          for (var callback in List.from(_onConnectCallbacks)) {
            try {
              callback();
            } catch (e) {
              debugPrint('Error executing STOMP connect callback: $e');
            }
          }
          _onConnectCallbacks.clear();
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onDisconnect: (_) {
          _isConnected = false;
          debugPrint('STOMP Disconnected');
        },
        onStompError: (frame) {
          debugPrint('STOMP Error: ${frame.body}');
        },
        onWebSocketError: (error) {
          debugPrint('WebSocket Error: $error');
        },
      ),
    );

    _client!.activate();
  }

  StompUnsubscribe? subscribe(String destination, Function(dynamic data) onData) {
    if (_client == null || !_client!.isActive) {
      debugPrint('Cannot subscribe: STOMP client is not active');
      return null;
    }

    final unsubscribeFn = _client!.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final parsed = jsonDecode(frame.body!);
            onData(parsed);
          } catch (_) {
            onData(frame.body);
          }
        }
      },
    );

    return unsubscribeFn;
  }

  // Subscribe order status update for Customer (Order Tracking)
  StompUnsubscribe? subscribeOrderStatus(String orderId, Function(Map<String, dynamic> data) onUpdate) {
    return subscribe('/topic/order/$orderId', (data) {
      if (data is Map<String, dynamic>) {
        onUpdate(data);
      }
    });
  }

  // Subscribe branch new orders for Staff (KDS / POS)
  StompUnsubscribe? subscribeBranchOrders(String branchId, Function(Map<String, dynamic> data) onNewOrder) {
    return subscribe('/topic/branch/$branchId/new-order', (data) {
      if (data is Map<String, dynamic>) {
        onNewOrder(data);
      }
    });
  }

  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
    _onConnectCallbacks.clear();
  }
}
