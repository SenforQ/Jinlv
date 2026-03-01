import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';
import 'package:jinlv/pages/figure_chat_page.dart';
import 'package:jinlv/pages/report_page.dart';
import 'package:jinlv/services/block_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 角色/达人详情页 - 查看完整信息和图片
class FigureDetailPage extends StatefulWidget {
  const FigureDetailPage({
    super.key,
    required this.figure,
    this.initialFollowed = false,
  });

  final Figure figure;
  final bool initialFollowed;

  @override
  State<FigureDetailPage> createState() => _FigureDetailPageState();
}

class _FigureDetailPageState extends State<FigureDetailPage> {
  late bool _isFollowed;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.initialFollowed;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _displayCount => _isFollowed ? widget.figure.followCount + 1 : widget.figure.followCount;

  void _showActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择操作'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportPage(figure: widget.figure),
                ),
              );
            },
            child: const Text('举报'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await BlockService.blockFigure(widget.figure.id);
              if (mounted) Navigator.of(context).pop(true);
            },
            child: const Text('拉黑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await BlockService.muteFigure(widget.figure.id);
              if (mounted) Navigator.of(context).pop(true);
            },
            child: const Text('屏蔽'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = [widget.figure.avatar, ...widget.figure.travelImages];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        title: Text(
          widget.figure.nickname,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showActionSheet(),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 图片轮播
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemCount: images.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white12,
                        child: const Icon(Icons.image, color: Colors.white38, size: 64),
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(images.length, (i) {
                        final isActive = i == _currentImageIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 8 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? _primaryYellow : Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 基本信息
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.figure.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 18, color: _primaryYellow),
                        const SizedBox(width: 6),
                        Text(
                          '$_displayCount 人关注',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.figure.category,
                            style: const TextStyle(color: _primaryYellow, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isFollowed = !_isFollowed),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isFollowed ? _primaryYellow.withValues(alpha: 0.3) : _primaryYellow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _isFollowed ? '已关注' : '关注',
                    style: TextStyle(
                      color: _isFollowed ? _primaryYellow : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 旅行攻略
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '旅行攻略',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.figure.travelGuide ?? '暂无攻略',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FigureChatPage(figure: widget.figure),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('攻略咨询'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
