import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';
import '../../features/customer/cart_checkout/bloc/cart_bloc.dart';

class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  StompClient? _client;
  final StreamController<Map<String, dynamic>> _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;

  void connect(String? token) {
    if (_client != null && _client!.connected) {
      return;
    }

    final baseUrlWithoutHttp = ApiConstants.baseUrl.replaceAll('http://', '').replaceAll('https://', '');
    final wsUrl = 'ws://$baseUrlWithoutHttp/ws';

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          print('WebSocket Connected successfully');
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
        },
        onDisconnect: (StompFrame frame) {
          print('WebSocket disconnected');
        },
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );

    _client?.activate();
  }

  void subscribeToOrder(String orderId) {
    if (_client == null || !_client!.connected) {
      print('WebSocket is not connected. Cannot subscribe.');
      return;
    }

    _client?.subscribe(
      destination: '/topic/order/$orderId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(frame.body!);
            _orderStatusController.add(data);
          } catch (e) {
            print('Error parsing WebSocket frame: $e');
          }
        }
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }
}
