import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/draggable_add_button.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    // final isVisible = ref.watch(bottomNavBarVisibleProvider); // Removed auto-hide
    final index = _calculateSelectedIndex(context);
    
    // Only show FAB on Home (0) and Timeline (1)
    final showFab = index == 0 || index == 1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 1. If not on Home, go to Home
        if (index != 0) {
          _onItemTapped(0, context);
          return;
        }

        // 2. Removed auto-hide restore logic

        // 3. Double back logic
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '再按一次退出应用',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              backgroundColor: Colors.black54,
              behavior: SnackBarBehavior.floating,
              width: 160,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // 4. Exit App
        await SystemNavigator.pop();
      },
      child: Stack( 
        children: [
          Scaffold(
            body: widget.child,
            resizeToAvoidBottomInset: false, // Prevent FAB moving with keyboard
            bottomNavigationBar: NavigationBar(
               selectedIndex: index,
               onDestinationSelected: (int idx) => _onItemTapped(idx, context),
               destinations: const [
                 NavigationDestination(icon: Icon(Icons.devices), label: '资产'),
                 NavigationDestination(
                   icon: Icon(Icons.history),
                   label: '物历',
                 ),
                 NavigationDestination(
                   icon: Icon(Icons.person_outline),
                   selectedIcon: Icon(Icons.person),
                   label: '我的',
                 ),
               ],
            ),
          ),
          if (showFab) const DraggableAddButton(),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/')) {
      if (location == '/') return 0;
      if (location.startsWith('/timeline')) return 1;
      if (location.startsWith('/profile')) return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/timeline');
        break;
      case 2:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
