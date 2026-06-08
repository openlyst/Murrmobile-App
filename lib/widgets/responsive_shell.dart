import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/upload_page.dart';
import '../pages/notifications_page.dart';
import '../pages/settings_page.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

class ResponsiveShell extends StatefulWidget {
  final int initialIndex;
  const ResponsiveShell({super.key, this.initialIndex = 0});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  late int _selectedIndex;
  bool _wasLoggedIn = false;

  List<NavItem> get _items {
    final base = <NavItem>[
      const NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        page: HomePage(),
      ),
      const NavItem(
        label: 'Search',
        icon: Icons.search_outlined,
        activeIcon: Icons.search_rounded,
        page: SearchPage(),
      ),
    ];
    if (MurrtubeApi.hasCookies) {
      base.addAll(const [
        NavItem(
          label: 'Upload',
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle_rounded,
          page: UploadPage(),
        ),
        NavItem(
          label: 'Activity',
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications_rounded,
          page: NotificationsPage(),
        ),
      ]);
    }
    base.add(const NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      page: SettingsPage(),
    ));
    return base;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _wasLoggedIn = MurrtubeApi.hasCookies;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nowLoggedIn = MurrtubeApi.hasCookies;
    if (nowLoggedIn != _wasLoggedIn) {
      _wasLoggedIn = nowLoggedIn;
      if (_selectedIndex >= _items.length) {
        _selectedIndex = 0;
      }
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _DesktopLayout(
        items: _items,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Scaffold(
      body: _items[_selectedIndex].page,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = index == _selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  )
                                : null,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? colorScheme.primary
                                  : mutedColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? colorScheme.primary
                                  : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _DesktopLayout({
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Murrmobile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => onItemTapped(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? item.activeIcon
                                        : item.icon,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : mutedColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : mutedColor,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const Spacer(),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Container(width: 1, color: theme.dividerColor),
          Expanded(
            child: items[selectedIndex].page,
          ),
        ],
      ),
    );
  }
}
