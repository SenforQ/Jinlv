import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/pages/add_record_page.dart';
import 'package:jinlv/pages/journey_detail_page.dart';
import 'package:jinlv/services/journey_storage.dart';
import 'package:jinlv/services/user_storage.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 旅行手记首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Journey> _journeys = [];
  String _searchKeyword = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    final list = await JourneyStorage.getJourneys();
    if (mounted) {
      setState(() {
        _journeys = list;
        _loading = false;
      });
    }
  }

  void _openJourneyDetail(Journey journey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JourneyDetailPage(journey: journey),
      ),
    );
  }

  Future<void> _openEditRecord(Journey journey) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecordPage(journey: journey),
      ),
    );
    if (result == true && mounted) _loadJourneys();
  }

  Future<void> _openAddRecord() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRecordPage()),
    );
    if (result == true && mounted) _loadJourneys();
  }

  List<Journey> get _filteredJourneys {
    if (_searchKeyword.isEmpty) return _journeys;
    final k = _searchKeyword.toLowerCase();
    return _journeys
        .where((j) =>
            j.name.toLowerCase().contains(k) ||
            j.destination.toLowerCase().contains(k))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '近旅-近期旅行',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '每一段的行程都是将来美好的回忆',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: _primaryYellow,
                    iconSize: 28,
                    onPressed: _openAddRecord,
                    tooltip: '新增',
                  )
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (v) => setState(() => _searchKeyword = v),
                decoration: InputDecoration(
                  hintText: '搜索行程',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // 内容区
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _primaryYellow))
                  : _filteredJourneys.isEmpty
                      ? _buildEmptyState()
                      : _buildJourneyList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryYellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight_takeoff,
                size: 56,
                color: _primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '点击下方按钮，开始规划您的第一段旅程',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              '长按可编辑或删除旅程',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _openAddRecord,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('开启新旅程'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          '旅行中',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._filteredJourneys.map((j) => _buildJourneyCard(j)),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: _openAddRecord,
            icon: const Icon(Icons.add),
            label: const Text('开启新旅程'),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyCard(Journey journey) {
    return FutureBuilder<String?>(
      future: journey.coverPath != null
          ? UserStorage.getFullPath(journey.coverPath!)
          : null,
      builder: (context, snapshot) {
        final hasCover = journey.coverPath != null &&
            snapshot.hasData &&
            File(snapshot.data!).existsSync();

        return GestureDetector(
          onTap: () => _openJourneyDetail(journey),
          onLongPress: () => _showJourneyOptions(journey),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryYellow, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: hasCover
                  ? Stack(
                    children: [
                      // 封面图全屏
                      SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 底部渐变黑色蒙版 alpha 0 -> alpha 1
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0x00000000),
                                const Color(0xFF000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 底部内容
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _primaryYellow.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      journey.durationText,
                                      style: const TextStyle(
                                        color: _primaryYellow,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    journey.id.substring(journey.id.length - 3),
                                    style: TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_formatShortDate(journey.startDate)} - ${_formatShortDate(journey.endDate)}',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.place_outlined, size: 16, color: _primaryYellow),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      journey.destination,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  if (journey.budget != null && journey.budget!.isNotEmpty)
                                    Text(
                                      '预算 ${journey.budget}',
                                      style: TextStyle(color: _primaryYellow, fontSize: 12),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primaryYellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                journey.durationText,
                                style: const TextStyle(color: _primaryYellow, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              journey.id.substring(journey.id.length - 3),
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              '${_formatShortDate(journey.startDate)} - ${_formatShortDate(journey.endDate)}',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 16, color: _primaryYellow),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                journey.destination,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (journey.budget != null && journey.budget!.isNotEmpty)
                              Text(
                                '预算 ${journey.budget}',
                                style: TextStyle(color: _primaryYellow, fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }

  String _formatShortDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  void _showJourneyOptions(Journey journey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: _primaryYellow),
              title: const Text('编辑', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转编辑页
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await JourneyStorage.deleteJourney(journey.id);
                if (mounted) _loadJourneys();
              },
            ),
          ],
        ),
      ),
    );
  }
}
