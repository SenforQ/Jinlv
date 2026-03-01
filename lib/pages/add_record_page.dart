import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/services/journey_storage.dart';
import 'package:jinlv/services/user_storage.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 新增/编辑旅程页面
class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key, this.journey});

  final Journey? journey;

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _coverPath;
  String? _coverFullPath;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;
  bool get _isEdit => widget.journey != null;

  @override
  void initState() {
    super.initState();
    if (widget.journey != null) {
      final j = widget.journey!;
      _nameController.text = j.name;
      _destinationController.text = j.destination;
      _budgetController.text = j.budget ?? '';
      _startDate = j.startDate;
      _endDate = j.endDate;
      _coverPath = j.coverPath;
      if (j.coverPath != null) {
        UserStorage.getFullPath(j.coverPath!).then((path) {
          if (mounted) setState(() => _coverFullPath = path);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String get _durationText {
    final days = _endDate.difference(_startDate).inDays;
    if (days == 0) return '1天';
    if (days == 1) return '2天1晚';
    return '${days + 1}天${days}晚';
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    try {
      final dir = await UserStorage.getDocumentsDirectory();
      final journeyDir = Directory('${dir.path}/journey_covers');
      if (!await journeyDir.exists()) {
        await journeyDir.create(recursive: true);
      }

      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.png';
      final destPath = '${journeyDir.path}/$fileName';
      final destFile = File(destPath);
      await File(picked.path).copy(destFile.path);

      final relativePath = 'journey_covers/$fileName';

      if (mounted) {
        setState(() {
          _coverPath = relativePath;
          _coverFullPath = destPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置封面失败: $e')),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final budget = _budgetController.text.trim();
      final journey = Journey(
        id: _isEdit ? widget.journey!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        destination: _destinationController.text.trim(),
        coverPath: _coverPath,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: _isEdit ? widget.journey!.createdAt : DateTime.now(),
        budget: budget.isEmpty ? null : budget,
      );

      if (_isEdit) {
        await JourneyStorage.updateJourney(journey);
      } else {
        await JourneyStorage.addJourney(journey);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑旅程' : '新增旅程'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        leadingWidth: 64,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _onSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryYellow),
                      ),
                    )
                  : const Text('保存'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 旅程封面
            _buildSection(
              '旅程封面',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: _coverFullPath != null && File(_coverFullPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_coverFullPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48, color: Colors.white54),
                                const SizedBox(height: 8),
                                Text(
                                  '设置封面图',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAlbumButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // 可扩展为最近照片
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 基本信息
            _buildSection(
              '基本信息',
              Column(
                children: [
                  _buildInputRow(
                    Icons.flag_outlined,
                    '旅程名称(必填)',
                    _nameController,
                    (v) => v?.trim().isEmpty ?? true ? '请输入旅程名称' : null,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildInputRow(
                    Icons.place_outlined,
                    '目的地(必填)',
                    _destinationController,
                    (v) => v?.trim().isEmpty ?? true ? '请输入目的地' : null,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildInputRow(
                    Icons.account_balance_wallet_outlined,
                    '预算(选填)',
                    _budgetController,
                    null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 时间安排
            _buildSection(
              '时间安排',
              Column(
                children: [
                  _buildDateRow('开始日期', _formatDate(_startDate), _pickStartDate),
                  const Divider(height: 1, color: Colors.white24),
                  _buildDateRow('结束日期', _formatDate(_endDate), _pickEndDate),
                  const Divider(height: 1, color: Colors.white24),
                  _buildDateRow('行程时长', _durationText, null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAlbumButton() {
    return GestureDetector(
      onTap: _pickCover,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.photo_library_outlined, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text('相册', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    IconData icon,
    String hint,
    TextEditingController controller,
    String? Function(String?)? validator,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _primaryYellow),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: _inputDecoration(hint),
              style: const TextStyle(color: Colors.white),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              label == '行程时长' ? Icons.schedule_outlined : Icons.calendar_today_outlined,
              size: 20,
              color: _primaryYellow,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (onTap != null) const SizedBox(width: 8),
            if (onTap != null) Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日';
}
