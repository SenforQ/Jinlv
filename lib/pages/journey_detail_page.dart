import 'package:flutter/material.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/models/journey_node.dart';
import 'package:jinlv/pages/edit_journey_node_page.dart';
import 'package:jinlv/pages/journey_node_detail_page.dart';
import 'package:jinlv/services/journey_node_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);
const String _appStoreId = '6759796245';
const String _appStoreUrl = 'https://apps.apple.com/app/id$_appStoreId';

/// 旅程详情页 - 按参考图布局
class JourneyDetailPage extends StatefulWidget {
  const JourneyDetailPage({super.key, required this.journey});

  final Journey journey;

  @override
  State<JourneyDetailPage> createState() => _JourneyDetailPageState();
}

class _JourneyDetailPageState extends State<JourneyDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _calendarExpanded = true;
  List<JourneyNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.journey.startDate;
    _selectedDay = widget.journey.startDate;
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    final list = await JourneyNodeStorage.getNodes(widget.journey.id);
    if (mounted) setState(() => _nodes = list);
  }

  List<JourneyNode> get _nodesForSelectedDay {
    if (_selectedDay == null) return [];
    return _nodes.where((n) {
      final d = n.startTime;
      return d.year == _selectedDay!.year &&
          d.month == _selectedDay!.month &&
          d.day == _selectedDay!.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _formatShortDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 24),
                    _buildTimeline(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              // 分享 App
              _buildHeaderButton(Icons.share_outlined, () => _shareApp(context)),
            ],
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            widget.journey.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 副标题：日期 | 时长
          Row(
            children: [
              Text(
                '${_formatShortDate(widget.journey.startDate)} - ${_formatShortDate(widget.journey.endDate)}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('|', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
              Icon(Icons.schedule_outlined, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                widget.journey.durationText,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
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

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TableCalendar<dynamic>(
            firstDay: DateTime(widget.journey.startDate.year, widget.journey.startDate.month, 1),
            lastDay: DateTime(widget.journey.endDate.year, widget.journey.endDate.month + 1, 0)
                .add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarFormat: _calendarExpanded ? CalendarFormat.month : CalendarFormat.week,
            onFormatChanged: (_) => setState(() => _calendarExpanded = !_calendarExpanded),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: Colors.white54),
              outsideTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              selectedDecoration: const BoxDecoration(
                color: _primaryYellow,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.black),
              todayDecoration: BoxDecoration(
                color: _primaryYellow.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.white),
              rangeStartDecoration: const BoxDecoration(
                color: _primaryYellow,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: _primaryYellow,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: _primaryYellow.withValues(alpha: 0.2),
              withinRangeTextStyle: const TextStyle(color: Colors.white70),
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) => Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              todayBuilder: (context, date, _) => Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryYellow.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            locale: 'zh_CN',
            availableGestures: AvailableGestures.all,
          ),
          GestureDetector(
            onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                _calendarExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                color: Colors.white54,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddNode() async {
    final result = await Navigator.of(context).push<JourneyNode>(
      MaterialPageRoute(
        builder: (_) => EditJourneyNodePage(
          journey: widget.journey,
          node: null,
          initialDate: _selectedDay ?? widget.journey.startDate,
        ),
      ),
    );
    if (result != null) _loadNodes();
  }

  Future<void> _openNodeDetail(JourneyNode node) async {
    final result = await Navigator.of(context).push<JourneyNode>(
      MaterialPageRoute(
        builder: (_) => JourneyNodeDetailPage(
          journey: widget.journey,
          node: node,
        ),
      ),
    );
    if (result != null) _loadNodes();
  }

  Future<void> _openEditNode(JourneyNode node) async {
    final result = await Navigator.of(context).push<JourneyNode>(
      MaterialPageRoute(
        builder: (_) => EditJourneyNodePage(
          journey: widget.journey,
          node: node,
        ),
      ),
    );
    if (result != null) _loadNodes();
  }

  Widget _buildTimeline() {
    final dayNodes = _nodesForSelectedDay;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间轴
        SizedBox(
          width: 56,
          child: dayNodes.isEmpty
              ? Column(
                  children: ['00:00', '06:00', '12:00', '18:00', '24:00']
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Row(
                              children: [
                                Text(
                                  t,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: dayNodes
                      .map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Text(
                                  '${n.startTime.hour.toString().padLeft(2, '0')}:${n.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),
        // 时间轴竖线（参考图 teal 色）
        Container(
          width: 2,
          margin: const EdgeInsets.only(left: 4, top: 8),
          constraints: BoxConstraints(
            minHeight: dayNodes.isEmpty ? 200 : (dayNodes.length * 100).toDouble(),
          ),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 24),
        // 主内容区
        Expanded(
          child: dayNodes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 80,
                        color: _primaryYellow.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '空空如也',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '精彩的旅程从规划开始',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '点击下方添加按钮,添加第一个行程节点',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '双击行程节点可编辑,左滑可删除',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: dayNodes.map((node) => _buildNodeCard(node)).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNodeCard(JourneyNode node) {
    return Dismissible(
      key: Key(node.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除行程'),
            content: Text('确定删除「${node.title}」？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (ok == true) {
          await JourneyNodeStorage.deleteNode(widget.journey.id, node.id);
          _loadNodes();
          return true;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => _openNodeDetail(node),
        onDoubleTap: () => _openEditNode(node),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧圆形相机图标（参考图样式）
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryYellow.withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: _primaryYellow, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            node.subtitle != null && node.subtitle!.isNotEmpty
                                ? node.subtitle!
                                : '被自己',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_outlined, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  node.timeRangeText,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 预算 - 右下角
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '¥${node.budget?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openAddNode(),
      backgroundColor: _primaryYellow,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('添加'),
    );
  }
}
