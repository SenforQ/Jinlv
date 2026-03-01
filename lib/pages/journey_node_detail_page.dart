import 'package:flutter/material.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/models/journey_node.dart';
import 'package:jinlv/pages/edit_journey_node_page.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 行程节点详情页 - 查看记录详情
class JourneyNodeDetailPage extends StatelessWidget {
  const JourneyNodeDetailPage({super.key, required this.journey, required this.node});

  final Journey journey;
  final JourneyNode node;

  String _formatDate(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日';
  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
          node.title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<JourneyNode>(
                MaterialPageRoute(
                  builder: (_) => EditJourneyNodePage(
                    journey: journey,
                    node: node,
                  ),
                ),
              );
              if (result != null && context.mounted) {
                Navigator.of(context).pop(result);
              }
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('行程信息', [
            _buildInfoRow('标题', node.title),
            if (node.subtitle != null && node.subtitle!.isNotEmpty)
              _buildInfoRow('副标题/备注', node.subtitle!),
            _buildInfoRow('类型', node.type),
          ]),
          const SizedBox(height: 16),
          _buildSection('时间安排', [
            _buildInfoRow('开始', '${_formatDate(node.startTime)} ${_formatTime(node.startTime)}'),
            _buildInfoRow('结束', '${_formatDate(node.endTime)} ${_formatTime(node.endTime)}'),
            _buildInfoRow('持续时间', node.durationText),
          ]),
          const SizedBox(height: 16),
          _buildSection('预算', [
            _buildInfoRow('金额', '¥${node.budget?.toStringAsFixed(0) ?? '0'}'),
          ]),
          if (node.footprint.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('足迹记录', [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  node.footprint,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
