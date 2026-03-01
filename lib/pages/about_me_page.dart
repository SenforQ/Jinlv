import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 关于我们页面
class AboutMePage extends StatefulWidget {
  const AboutMePage({super.key});

  @override
  State<AboutMePage> createState() => _AboutMePageState();
}

class _AboutMePageState extends State<AboutMePage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/applogo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, size: 48, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App 昵称
            Text(
              '近旅',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            // App 版本
            Text(
              _version.isEmpty ? '加载中...' : '版本 $_version',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
