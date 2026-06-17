import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';

enum PaymentResult { success, pending, error, cancelled }

/// Midtrans Snap dalam WebView.
/// Setelah pembayaran selesai, Midtrans redirect ke catatrapat.app/payment/*
/// yang kita intercept sebelum browser mencoba memuatnya.
class PaymentWebviewScreen extends ConsumerStatefulWidget {
  const PaymentWebviewScreen({
    super.key,
    required this.snapToken,
    required this.plan,
  });

  final String snapToken;
  final UserPlan plan;

  @override
  ConsumerState<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handling = false; // mencegah double-pop

  static const _snapBase = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/';
  static const _callbackHost = 'catatrapat.app';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (_) => setState(() => _loading = false),
        onNavigationRequest: _handleNavigation,
      ))
      ..loadRequest(Uri.parse('$_snapBase${widget.snapToken}'));
  }

  NavigationDecision _handleNavigation(NavigationRequest req) {
    final uri = Uri.tryParse(req.url);
    if (uri == null || uri.host != _callbackHost) {
      return NavigationDecision.navigate;
    }

    // Intercept catatrapat.app/payment/{finish|pending|error}
    final path = uri.path;
    if (path.contains('/finish')) {
      _settle(PaymentResult.success);
    } else if (path.contains('/pending')) {
      _settle(PaymentResult.pending);
    } else if (path.contains('/error')) {
      _settle(PaymentResult.error);
    }
    return NavigationDecision.prevent;
  }

  Future<void> _settle(PaymentResult result) async {
    if (_handling) return;
    _handling = true;

    if (result == PaymentResult.success) {
      await ref.read(authProvider.notifier).upgradePlan(widget.plan);
    }

    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(PaymentResult.cancelled),
        ),
        title: Text('Pembayaran', style: AppTextStyles.bodyMd(w: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
