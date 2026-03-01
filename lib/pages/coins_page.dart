import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jinlv/services/user_storage.dart';

// 近旅主题色
const Color _primaryYellow = Color(0xFFFFEB3B);

/// 产品信息类（本地或真实）
class ProductInfo {
  final String id;
  final String price;
  final int coins;
  final bool isRealProduct;

  ProductInfo({
    required this.id,
    required this.price,
    required this.coins,
    this.isRealProduct = false,
  });
}

/// 金币充值页面 - iOS内购充值金币
class CoinsPage extends StatefulWidget {
  const CoinsPage({super.key});

  @override
  State<CoinsPage> createState() => _CoinsPageState();
}

class _CoinsPageState extends State<CoinsPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  int _userCoins = 0;

  // 产品ID配置（需在 App Store Connect 中配置对应商品）
  static const Set<String> _productIds = {
    'iOS_JINLV_29_9',
    'iOS_JINLV_49_9',
    'iOS_JINLV_99_9',
  };

  static const Map<String, int> _productCoins = {
    'iOS_JINLV_29_9': 150,
    'iOS_JINLV_49_9': 300,
    'iOS_JINLV_99_9': 600,
  };

  static const Map<String, String> _localProductPrices = {
    'iOS_JINLV_29_9': '¥29.9',
    'iOS_JINLV_49_9': '¥49.9',
    'iOS_JINLV_99_9': '¥99.9',
  };

  Map<String, ProductInfo> _productInfoMap = {};

  @override
  void initState() {
    super.initState();
    _loadUserCoins();
    _initializeStore();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _loadUserCoins() async {
    final coins = await UserStorage.getCoinBalance();
    if (mounted) {
      setState(() => _userCoins = coins);
    }
  }

  Future<void> _initializeStore() async {
    _initializeLocalProducts();

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isAvailable = true);

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('购买流错误: $error'),
    );

    await _loadProducts();
  }

  void _initializeLocalProducts() {
    _productInfoMap.clear();
    for (final productId in _productIds) {
      _productInfoMap[productId] = ProductInfo(
        id: productId,
        price: _localProductPrices[productId] ?? '¥0',
        coins: _productCoins[productId] ?? 0,
        isRealProduct: false,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);

      for (final product in response.productDetails) {
        if (_productInfoMap.containsKey(product.id)) {
          _productInfoMap[product.id] = ProductInfo(
            id: product.id,
            price: product.price,
            coins: _productCoins[product.id] ?? 0,
            isRealProduct: true,
          );
        }
      }

      if (mounted) {
        setState(() {
          _products = response.productDetails;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('加载产品失败: $e');
      if (mounted) setState(() => _loading = false);
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
          await _handlePurchaseSuccess(purchaseDetails.productID);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        if (mounted) setState(() => _purchasePending = false);
      }
    }
  }

  Future<void> _handlePurchaseSuccess(String productId) async {
    final coinsToAdd = _productCoins[productId] ?? 0;
    if (coinsToAdd > 0) {
      final newCoins = await UserStorage.addCoins(coinsToAdd);
      await _loadUserCoins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买成功！获得 $coinsToAdd 金币，当前余额: $newCoins 金币'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
    );
  }

  void _showCoinsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: _primaryYellow),
            const SizedBox(width: 8),
            Text('金币说明', style: TextStyle(color: Colors.grey[100])),
          ],
        ),
        content: Text(
          '金币用于旅行文案AI优化等扣费，以及探索旅行、记录足迹和享受更多精彩内容',
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了', style: TextStyle(color: _primaryYellow)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String productId) {
    final productInfo = _productInfoMap[productId];
    if (productInfo == null) return const SizedBox.shrink();

    final coins = productInfo.coins;

    ProductDetails? realProduct;
    if (productInfo.isRealProduct) {
      try {
        realProduct = _products.firstWhere((p) => p.id == productId);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _primaryYellow.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.monetization_on,
            color: _primaryYellow,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Text(
              '$coins',
              style: const TextStyle(
                color: _primaryYellow,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '金币',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            productInfo.price,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        trailing: _purchasePending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryYellow),
                ),
              )
            : FilledButton(
                onPressed: realProduct != null
                    ? () => _buyProduct(realProduct!)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('正在加载产品信息，请稍后再试')),
                        );
                      },
                child: const Text('购买'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('金币充值'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '说明',
            onPressed: _showCoinsInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前余额
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryYellow, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '当前余额',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: _primaryYellow, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          '$_userCoins',
                          style: const TextStyle(
                            color: _primaryYellow,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '金币',
                          style: TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '选择充值套餐',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryYellow),
                    ),
                  ),
                )
              else
                ..._productIds.map((productId) => _buildProductCard(productId)),
            ],
          ),
        ),
      ),
    );
  }
}
