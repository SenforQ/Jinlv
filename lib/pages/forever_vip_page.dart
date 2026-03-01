import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jinlv/services/user_storage.dart';

/// 永久VIP页面 - iOS内购
class ForeverVipPage extends StatefulWidget {
  const ForeverVipPage({super.key});

  @override
  State<ForeverVipPage> createState() => _ForeverVipPageState();
}

class _ForeverVipPageState extends State<ForeverVipPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _product;
  String _price = '¥29.9';
  bool _purchasePending = false;
  bool _loading = true;

  // 使用与 coins_page 相同的产品 ID，确保 App Store Connect 中已配置
  static const Set<String> _productIds = {'iOS_JINLV_29'};
  static const String _localPrice = '¥29.9';

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('购买流错误: $error'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.first;
        if (mounted) {
          setState(() {
            _product = product;
            _price = product.price;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _price = _localPrice; _loading = false; });
      }
    } catch (e) {
      debugPrint('加载产品失败: $e');
      if (mounted) setState(() { _price = _localPrice; _loading = false; });
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _purchasePending = true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('购买失败: ${purchaseDetails.error?.message ?? "未知错误"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handlePurchaseSuccess();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        if (mounted) setState(() => _purchasePending = false);
      }
    }
  }

  Future<void> _handlePurchaseSuccess() async {
    await UserStorage.setPermanentVipActivated(true);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('恭喜！永久VIP已激活'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在恢复购买...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复购买失败: $e')),
        );
      }
    }
  }

  Future<void> _onConfirm() async {
    if (_product != null) {
      // 使用 buyConsumable 与 coins_page 一致，该产品在 App Store Connect 中为消耗型
      await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在加载产品信息，请稍后再试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _restorePurchases,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('恢复购买', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/vip_content_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
          // 半透明遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          // 内容
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  )
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 皇冠图标
                  Icon(Icons.workspace_premium, size: 56, color: Color(0xFFFFD700)),
                  const SizedBox(height: 16),
                  // 标题
                  Text(
                    '会员专属',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 权益列表
                  _buildBenefit('无限头像更换', Icons.check_circle),
                  _buildBenefit('去除应用内广告', Icons.check_circle),
                  _buildBenefit('尊享专属旅行内容', Icons.check_circle),
                  const SizedBox(height: 32),
                  // 购买档位（默认显示）
                  _buildPurchaseCard(),
                  const SizedBox(height: 32),
                  // 确认按钮
                  GestureDetector(
                    onTap: _purchasePending ? null : _onConfirm,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          colors: _purchasePending
                              ? [Colors.grey, Colors.grey[700]!]
                              : [Color(0xFF5B7FFF), Color(0xFF9B59B6)],
                        ),
                      ),
                      child: Center(
                        child: _purchasePending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('确认', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF9B59B6), size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF9B59B6), width: 2),
      ),
      child: Column(
        children: [
          Text(
            _price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '永久VIP',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Text(
              '永久尊享',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
