import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jinlv/pages/home_page.dart';
import 'package:jinlv/pages/explore_page.dart';
import 'package:jinlv/pages/records_page.dart';
import 'package:jinlv/pages/message_page.dart';
import 'package:jinlv/pages/profile_page.dart';

// 近旅 - 主题色：黑色 + 黄色 #FFEB3B
const Color _primaryYellow = Color(0xFFFFEB3B);

/// 胶囊形状，所有按钮统一使用（圆角矩形模拟胶囊）
const OutlinedBorder _capsuleShape = StadiumBorder();

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '近旅',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _primaryYellow,
          onPrimary: Colors.black,
          surface: Colors.black,
          onSurface: _primaryYellow,
          secondary: _primaryYellow,
          onSecondary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: _primaryYellow,
          elevation: 0,
        ),
        // 所有胶囊按钮优先使用黄色 #FFEB3B
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryYellow,
            foregroundColor: Colors.black,
            shape: _capsuleShape,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primaryYellow,
            foregroundColor: Colors.black,
            shape: _capsuleShape,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryYellow,
            side: const BorderSide(color: _primaryYellow),
            shape: _capsuleShape,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryYellow,
            shape: _capsuleShape,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primaryYellow,
          foregroundColor: Colors.black,
        ),
      ),
      home: const MainPage(),
    );
  }
}

/// 主页面 - 带玻璃质感底部导航栏
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const ExplorePage(),
          const RecordsPage(),
          MessagePage(currentTabIndex: _currentIndex),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, '首页'),
                      _buildNavItem(1, Icons.explore_outlined, Icons.explore, '探索'),
                      _buildNavItem(2, Icons.directions_walk_outlined, Icons.directions_walk, '记录'),
                      _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, '消息'),
                      _buildNavItem(4, Icons.person_outline, Icons.person, '我的'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: _primaryYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? _primaryYellow : Colors.white70,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _primaryYellow : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
