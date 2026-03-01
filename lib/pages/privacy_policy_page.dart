import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 隐私政策页面 - 内嵌浏览器
/// 访问：近旅-隐私政策
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  static const String _url =
      'https://docs.google.com/document/d/1-dYzWBEHn5h0yR7T1D5t57TQh4CViFLXVLsfom-kPrw/edit?usp=sharing';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    final browserHeight =
        MediaQuery.of(context).size.height - statusBarHeight - appBarHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: SizedBox(
          width: screenWidth,
          height: browserHeight,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
