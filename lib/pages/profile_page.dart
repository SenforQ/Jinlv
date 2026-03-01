import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jinlv/pages/editor_page.dart';
import 'package:jinlv/pages/feedback_page.dart';
import 'package:jinlv/pages/privacy_policy_page.dart';
import 'package:jinlv/pages/about_me_page.dart';
import 'package:jinlv/pages/forever_vip_page.dart';
import 'package:jinlv/pages/coins_page.dart';
import 'package:jinlv/pages/user_agreement_page.dart';
import 'package:jinlv/services/user_storage.dart';
import 'package:share_plus/share_plus.dart';

// 近旅 - 项目名，默认昵称
const String _appName = '近旅';

// App Store ID
const String _appStoreId = '6759796245';
const String _appStoreUrl = 'https://apps.apple.com/app/id$_appStoreId';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
  String? _nickname;
  String? _signature;
  int _coinBalance = 0;
  bool _isVipActivated = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final avatarPath = await UserStorage.getAvatarPath();
    final nickname = await UserStorage.getNickname();
    final signature = await UserStorage.getSignature();
    final coinBalance = await UserStorage.getCoinBalance();
    final isVipActivated = await UserStorage.isPermanentVipActivated();
    if (mounted) {
      setState(() {
        _avatarPath = avatarPath;
        _nickname = nickname;
        _signature = signature;
        _coinBalance = coinBalance;
        _isVipActivated = isVipActivated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 用户信息区域：头像 + 昵称
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nickname ?? _appName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _signature ?? '个人主页',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white54,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 区域一：编辑资料、旅行记录、金币充值
            _buildSection(
              context,
              title: '个人资料',
              items: [
                _MenuItem(
                  icon: Icons.edit_outlined,
                  label: '编辑资料',
                  onTap: _onEditInformation,
                ),
                _MenuItem(
                  icon: Icons.route,
                  label: '旅行记录',
                  onTap: _onTravelRecords,
                ),
                _MenuItem(
                  icon: Icons.monetization_on_outlined,
                  label: '金币充值',
                  trailing: '$_coinBalance',
                  onTap: _onCoinRecharge,
                ),
                _MenuItem(
                  icon: Icons.workspace_premium_outlined,
                  label: '永久VIP',
                  trailing: _isVipActivated ? '已激活' : '未激活',
                  onTap: _onPermanentVip,
                ),
              ],
            ),
            // 区域二：评价应用、分享应用
            _buildSection(
              context,
              title: '应用支持',
              items: [
                _MenuItem(
                  icon: Icons.star_outline,
                  label: '给个好评',
                  onTap: _onRateApp,
                ),
                _MenuItem(
                  icon: Icons.share_outlined,
                  label: '分享APP',
                  onTap: _onShareApp,
                ),
                _MenuItem(
                  icon: Icons.feedback_outlined,
                  label: '意见反馈',
                  onTap: _onFeedback,
                ),
              ],
            ),
            // 区域三：隐私政策、用户协议、关于我们
            _buildSection(
              context,
              title: '法律与关于',
              items: [
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: '隐私政策',
                  onTap: _onPrivacyPolicy,
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: '用户协议',
                  onTap: _onUserAgreement,
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: '关于我们',
                  onTap: _onAboutMe,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _buildMenuItem(context, items[i]),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                        indent: 56,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: Builder(
        builder: (itemContext) {
          return InkWell(
            onTap: () => item.onTap(itemContext),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 左图
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 右文
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  // 右侧内容（如金币余额）
                  if (item.trailing != null) ...[
                    Text(
                      item.trailing!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 右箭头
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTravelRecords(BuildContext context) {
    // TODO: 跳转旅行记录页
  }

  Future<void> _onCoinRecharge(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoinsPage()),
    );
    if (mounted) _loadUserData();
  }

  Future<void> _onPermanentVip(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ForeverVipPage()),
    );
    if (result == true && mounted) _loadUserData();
  }

  Future<void> _onEditInformation(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditorPage()),
    );
    if (result == true && mounted) {
      _loadUserData();
    }
  }

  Widget _buildAvatar() {
    if (_avatarPath != null) {
      return FutureBuilder<String>(
        future: UserStorage.getFullPath(_avatarPath!),
        builder: (context, snapshot) {
          if (snapshot.hasData && File(snapshot.data!).existsSync()) {
            return ClipOval(
              child: Image.file(
                File(snapshot.data!),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            );
          }
          return _defaultAvatar();
        },
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return ClipOval(
      child: Image.asset(
        'assets/user_default.png',
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: Colors.grey[800],
          child: const Icon(Icons.person, size: 36, color: Colors.white54),
        ),
      ),
    );
  }

  Future<void> _onRateApp(BuildContext context) async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // 模拟器等环境：跳转 App Store 评分页
      await inAppReview.openStoreListing(appStoreId: _appStoreId);
    }
  }

  Future<void> _onShareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    Rect sharePositionOrigin;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      sharePositionOrigin = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } else {
      sharePositionOrigin = const Rect.fromLTWH(0, 0, 1, 1);
    }
    await Share.share(
      '推荐你使用近旅 App，一起探索身边的旅行！$_appStoreUrl',
      subject: '近旅',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  void _onFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FeedbackPage()),
    );
  }

  void _onPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _onUserAgreement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserAgreementPage()),
    );
  }

  void _onAboutMe(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutMePage()),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final void Function(BuildContext context) onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
