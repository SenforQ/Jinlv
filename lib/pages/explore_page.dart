import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';
import 'package:jinlv/pages/ai_chat_page.dart';
import 'package:jinlv/pages/figure_detail_page.dart';
import 'package:jinlv/pages/report_page.dart';
import 'package:jinlv/services/block_service.dart';
import 'package:jinlv/services/figure_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<String> _categories = [];
  List<Figure> _figures = [];
  Set<String> _blockedIds = {};
  Set<String> _mutedIds = {};
  bool _loading = true;
  String _selectedCategory = '全部';
  final Set<String> _followedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await FigureService.load();
    final blocked = await BlockService.getBlockedIds();
    final muted = await BlockService.getMutedIds();
    if (mounted) {
      setState(() {
        _categories = FigureService.categories;
        _figures = FigureService.figures;
        _blockedIds = blocked;
        _mutedIds = muted;
        _loading = false;
      });
    }
  }

  List<Figure> get _filteredFigures {
    var list = _selectedCategory == '全部'
        ? _figures
        : FigureService.getFiguresByCategory(_selectedCategory);
    list = list.where((f) => !_blockedIds.contains(f.id) && !_mutedIds.contains(f.id)).toList();
    return list;
  }

  void _showActionSheet(Figure figure) {
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
                  builder: (_) => ReportPage(figure: figure),
                ),
              );
            },
            child: const Text('举报'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await BlockService.blockFigure(figure.id);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                _loadData();
              }
            },
            child: const Text('拉黑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await BlockService.muteFigure(figure.id);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                _loadData();
              }
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
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: _primaryYellow),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '探索',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部引导图 - 点击跳转 AI 聊天
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/top_guide.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ),
          // 顶部分类选项
          _buildCategoryBar(),
          // 内容列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: _filteredFigures.map((f) => _buildFigureCard(f, _followedIds.contains(f.id))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    final options = ['全部', ..._categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: options.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryYellow : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openFigureDetail(Figure figure) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FigureDetailPage(
          figure: figure,
          initialFollowed: _followedIds.contains(figure.id),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) _loadData();
    });
  }

  Widget _buildFigureCard(Figure figure, bool isFollowed) {
    final displayCount = isFollowed ? figure.followCount + 1 : figure.followCount;

    return GestureDetector(
      onTap: () => _openFigureDetail(figure),
      child: Container(
      height: 270,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左图 - 支持左右切换 + 指示器
            SizedBox(
              width: 140,
              child: _FigureImageCarousel(figure: figure),
            ),
            // 右文 - 不滑动，超出显示省略号
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            figure.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_followedIds.contains(figure.id)) {
                              _followedIds.remove(figure.id);
                            } else {
                              _followedIds.add(figure.id);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFollowed ? _primaryYellow.withValues(alpha: 0.3) : _primaryYellow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isFollowed ? '已关注' : '关注',
                              style: TextStyle(
                                color: isFollowed ? _primaryYellow : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 16, color: _primaryYellow),
                        const SizedBox(width: 4),
                        Text(
                          '$displayCount 人关注',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '分类：${figure.category}',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        figure.travelGuide ?? _getDescription(figure),
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
            ),
            // 右下角红色三角形感叹号
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () => _showActionSheet(figure),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  String _getDescription(Figure figure) {
    const descs = {
      '生活': '记录旅途中的点滴生活，分享日常美好瞬间。每一段旅程都是生活的延伸，用心感受，用镜头定格。'
          '在路上的每一天都值得被铭记，无论是清晨的第一缕阳光，还是傍晚的落日余晖。'
          '生活不止眼前的苟且，还有诗和远方。',
      '景点': '探索各地特色景点，发现隐藏的风景。从山川湖海到古镇小巷，带你领略不一样的旅行视角。'
          '每一处风景都有它独特的故事，每一次探索都是与自然的对话。'
          '用脚步丈量世界，用心灵感受美好。',
      '特色': '挖掘当地特色美食与文化，体验最地道的风土人情。旅行不止于风景，更在于深度体验。'
          '品味当地美食，了解民俗文化，让每一次出行都充满意义。'
          '世界那么大，一起去看看。',
    };
    return descs[figure.category] ?? '分享旅行故事，记录美好时光。';
  }
}

/// 角色图片轮播 - 支持左右滑动，带指示器
class _FigureImageCarousel extends StatefulWidget {
  const _FigureImageCarousel({required this.figure});

  final Figure figure;

  @override
  State<_FigureImageCarousel> createState() => _FigureImageCarouselState();
}

class _FigureImageCarouselState extends State<_FigureImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = [widget.figure.avatar, ...widget.figure.travelImages];
    final count = images.length;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: count,
          itemBuilder: (_, i) => Image.asset(
            images[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white12,
              child: const Icon(Icons.image, color: Colors.white38, size: 48),
            ),
          ),
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(count, (i) {
                final isActive = i == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
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
    );
  }
}
