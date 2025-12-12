import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../theme/theme.dart';
import 'home_screen.dart';
import 'data_screen.dart';
import 'staking_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DataScreen(),
    StakingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Shared animated background (only show in dark mode)
          if (isDark) const AnimatedBackground(),
          
          // Light mode background
          if (!isDark)
            Container(
              decoration: const BoxDecoration(
                gradient: CyberColorsLight.backgroundGradient,
              ),
            ),
          
          // Current screen
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CyberTheme.navBar(context),
          boxShadow: CyberTheme.navBarShadow(context),
          border: isDark ? null : Border(
            top: BorderSide(color: CyberColorsLight.borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(context, 1, Icons.storage_outlined, Icons.storage, 'Data'),
                _buildNavItem(context, 2, Icons.toll_outlined, Icons.toll, 'Stake'),
                _buildNavItem(context, 3, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = CyberTheme.primary(context);
    final inactiveColor = CyberTheme.textSecondary(context);
    final color = isSelected ? primaryColor : inactiveColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ScaleOnTap(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey<bool>(isSelected),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
