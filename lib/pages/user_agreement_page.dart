import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 用户协议页面 - 内嵌浏览器
/// 访问：近旅-用户条款
class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({super.key});

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  static const String _url =
      'https://docs.google.com/document/d/1DQEYp41V-cGxTsfQr5gjivs1GqRui4gU37ZnWAJb1T4/edit?usp=sharing';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final browserHeight = screenHeight - statusBarHeight - appBarHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
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
