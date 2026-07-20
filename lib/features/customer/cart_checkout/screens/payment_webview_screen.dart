import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String successScheme;
  final String cancelScheme;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    this.successScheme = 'caffeshop://payment/success',
    this.cancelScheme = 'caffeshop://payment/cancel',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkUrlScheme(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkUrlScheme(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlScheme(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _checkUrlScheme(String url) {
    if (url.startsWith(widget.successScheme) || url.contains('status=PAID') || url.contains('/success')) {
      Navigator.of(context).pop('success');
      return true;
    }
    if (url.startsWith(widget.cancelScheme) || url.contains('status=CANCELLED') || url.contains('/cancel')) {
      Navigator.of(context).pop('cancel');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Qua PayOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop('cancel'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}
