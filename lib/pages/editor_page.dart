import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jinlv/services/user_storage.dart';

const String _defaultNickname = '近旅';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _signatureController = TextEditingController();

  String? _avatarRelativePath;
  String? _avatarFullPath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final avatarPath = await UserStorage.getAvatarPath();
    final nickname = await UserStorage.getNickname();
    final signature = await UserStorage.getSignature();

    String? fullPath;
    if (avatarPath != null) {
      fullPath = await UserStorage.getFullPath(avatarPath);
    }

    if (mounted) {
      setState(() {
        _avatarRelativePath = avatarPath;
        _avatarFullPath = fullPath;
        _nicknameController.text = nickname ?? _defaultNickname;
        _signatureController.text = signature ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    try {
      final dir = await UserStorage.getDocumentsDirectory();
      final avatarDir = Directory('${dir.path}/avatar');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final destPath = '${avatarDir.path}/$fileName';
      final destFile = File(destPath);
      await File(picked.path).copy(destFile.path);

      // 相对路径：avatar/avatar_xxx.png
      final relativePath = 'avatar/$fileName';

      if (mounted) {
        setState(() {
          _avatarRelativePath = relativePath;
          _avatarFullPath = destPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存头像失败: $e')),
        );
      }
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await UserStorage.setNickname(_nicknameController.text.trim());
      await UserStorage.setSignature(_signatureController.text.trim());
      if (_avatarRelativePath != null) {
        await UserStorage.setAvatarPath(_avatarRelativePath!);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(const SnackBar(content: Text('保存成功')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _avatarFullPath != null && File(_avatarFullPath!).existsSync()
              ? ClipOval(
                  child: Image.file(
                    File(_avatarFullPath!),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
              : ClipOval(
                  child: Image.asset(
                    'assets/user_default.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, size: 48, color: Colors.white54),
                    ),
                  ),
                ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: Color(0xFFFFEB3B), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑资料')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 用户头像
              Center(
                child: Column(
                  children: [
                    Text(
                      '用户头像',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildAvatar(),
                    const SizedBox(height: 8),
                    Text(
                      '点击选择头像',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 用户昵称
              Text(
                '用户昵称',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                decoration: _inputDecoration('请输入昵称'),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入昵称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // 用户签名
              Text(
                '用户签名',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _signatureController,
                maxLines: 4,
                decoration: _inputDecoration('请输入签名'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              // 保存按钮
              FilledButton(
                onPressed: _isSaving ? null : _onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
