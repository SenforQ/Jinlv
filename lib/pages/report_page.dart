import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 举报页面
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.figure});

  final Figure figure;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedReason = '';
  bool _isSubmitting = false;

  static const List<Map<String, String>> _reasons = [
    {'value': 'spam', 'label': '垃圾广告'},
    {'value': 'harassment', 'label': '骚扰或人身攻击'},
    {'value': 'fake', 'label': '虚假信息'},
    {'value': 'inappropriate', 'label': '不当内容'},
    {'value': 'other', 'label': '其他'},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择举报原因')),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('举报已提交，我们会尽快处理')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: const Text(
          '举报',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 被举报对象
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        widget.figure.avatar,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.white12,
                          child: const Icon(Icons.person, color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.figure.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '举报该用户的内容',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 举报原因
              Text(
                '举报原因',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ..._reasons.map((r) => _buildReasonTile(r['value']!, r['label']!)),
              const SizedBox(height: 24),
              // 补充说明
              Text(
                '补充说明（选填）',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '请描述您举报的详细原因...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryYellow, width: 1.5),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              // 提交按钮
              FilledButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('提交举报'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTile(String value, String label) {
    final isSelected = _selectedReason == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedReason = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryYellow.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryYellow : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? _primaryYellow : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
