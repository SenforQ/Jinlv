import 'package:flutter/material.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/models/journey_node.dart';
import 'package:jinlv/services/journey_node_storage.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);
const List<String> _nodeTypes = ['景点', '美食', '住宿', '交通', '购物', '其他'];

/// 编辑行程页面 - 新增/编辑行程节点
class EditJourneyNodePage extends StatefulWidget {
  const EditJourneyNodePage({
    super.key,
    required this.journey,
    this.node,
    this.initialDate,
  });

  final Journey journey;
  final JourneyNode? node;
  final DateTime? initialDate;

  @override
  State<EditJourneyNodePage> createState() => _EditJourneyNodePageState();
}

class _EditJourneyNodePageState extends State<EditJourneyNodePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _footprintController = TextEditingController();
  final _budgetController = TextEditingController();

  String _type = '景点';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isSaving = false;
  bool get _isEdit => widget.node != null;

  @override
  void initState() {
    super.initState();
    if (widget.node != null) {
      final n = widget.node!;
      _titleController.text = n.title;
      _subtitleController.text = n.subtitle ?? '';
      _footprintController.text = n.footprint;
      _budgetController.text = n.budget != null ? n.budget!.toStringAsFixed(0) : '0';
      _type = n.type;
      _startTime = n.startTime;
      _endTime = n.endTime;
    } else {
      final base = widget.initialDate ?? widget.journey.startDate;
      _startTime = DateTime(base.year, base.month, base.day, 13, 0);
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _footprintController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String get _durationText {
    final minutes = _endTime.difference(_startTime).inMinutes;
    if (minutes < 60) return '$minutes分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h小时';
    return '$h小时$m分钟';
  }

  String _formatDate(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日';
  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间必须晚于开始时间')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final budgetVal = double.tryParse(_budgetController.text.trim()) ?? 0;
      final node = _isEdit
          ? widget.node!.copyWith(
              title: title,
              subtitle: _subtitleController.text.trim().isEmpty
                  ? null
                  : _subtitleController.text.trim(),
              type: _type,
              startTime: _startTime,
              endTime: _endTime,
              budget: budgetVal,
              footprint: _footprintController.text.trim(),
            )
          : JourneyNode(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              journeyId: widget.journey.id,
              title: title,
              subtitle: _subtitleController.text.trim().isEmpty
                  ? null
                  : _subtitleController.text.trim(),
              type: _type,
              startTime: _startTime,
              endTime: _endTime,
              budget: budgetVal,
              footprint: _footprintController.text.trim(),
            );

      if (_isEdit) {
        await JourneyNodeStorage.updateNode(node);
      } else {
        await JourneyNodeStorage.addNode(node);
      }

      if (mounted) {
        Navigator.of(context).pop(node);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(color: Colors.white)),
        ),
        title: Text(
          _isEdit ? '编辑行程' : '添加行程',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('行程信息', [
              _buildTextField(_titleController, '标题 (必填)', required: true),
              const SizedBox(height: 12),
              _buildTextField(_subtitleController, '副标题/备注 (可选)'),
              const SizedBox(height: 12),
              _buildTypeField(),
            ]),
            const SizedBox(height: 16),
            _buildSection('时间安排', [
              _buildTimeRow('开始', _startTime, true),
              const SizedBox(height: 12),
              _buildTimeRow('结束', _endTime, false),
              const SizedBox(height: 12),
              _buildDurationRow(),
            ]),
            const SizedBox(height: 16),
            _buildSection('预算', [
              _buildBudgetField(),
            ]),
            const SizedBox(height: 16),
            _buildSection('足迹记录', [
              _buildFootprintField(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '必填' : null
          : null,
    );
  }

  Widget _buildTypeField() {
    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.grey[900],
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _nodeTypes
                  .map((t) => ListTile(
                        title: Text(t, style: const TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(ctx, t),
                      ))
                  .toList(),
            ),
          ),
        );
        if (result != null) setState(() => _type = result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: _primaryYellow, size: 20),
            const SizedBox(width: 12),
            Text(_type, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime value, bool isStart) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: widget.journey.startDate,
          lastDate: widget.journey.endDate,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _primaryYellow,
                onPrimary: Colors.black,
                surface: Colors.grey,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _primaryYellow,
                onPrimary: Colors.black,
                surface: Colors.grey,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (time == null || !mounted) return;
        final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          if (isStart) {
            _startTime = newDt;
            if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDt;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: Colors.white70)),
            const Spacer(),
            Text(_formatDate(value), style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            Text(_formatTime(value), style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('持续时间', style: TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(_durationText, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBudgetField() {
    return TextFormField(
      controller: _budgetController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixText: '¥ ',
        prefixStyle: const TextStyle(color: Colors.white),
        hintText: '0',
        hintStyle: TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFootprintField() {
    return Stack(
      children: [
        TextFormField(
          controller: _footprintController,
          maxLines: 5,
          maxLength: 200,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '记录你的足迹...',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (_) => setState(() {}),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              // TODO: 添加图片
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryYellow.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: _primaryYellow, size: 24),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 12,
          child: Text(
            '${_footprintController.text.length}/200',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
