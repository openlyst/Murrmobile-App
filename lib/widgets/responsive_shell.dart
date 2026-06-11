import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/upload_page.dart';
import '../pages/notifications_page.dart';
import '../pages/settings_page.dart';
import '../pages/profile_page.dart';
import '../utils/app_preferences.dart';

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
  bool _useSidebar = true;
  bool _isSidebarCollapsed = false;

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
    if (MurrtubeApi.isAuthenticated) {
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
    _wasLoggedIn = MurrtubeApi.isAuthenticated;
    _loadSidebarPreference();
  }

  Future<void> _loadSidebarPreference() async {
    final useSidebar = await AppPreferences.getUseSidebar();
    if (mounted) {
      setState(() => _useSidebar = useSidebar);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nowLoggedIn = MurrtubeApi.isAuthenticated;
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
    if (_useSidebar) {
      return _DesktopLayout(
        items: _items,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        isCollapsed: _isSidebarCollapsed,
        onToggleCollapse: () {
          setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
        },
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Scaffold(
      body: SafeArea(
        child: _items[_selectedIndex].page,
      ),
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
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _DesktopLayout({
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final sidebarWidth = isCollapsed ? 72.0 : 240.0;
    
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            color: colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 20),
                  child: Row(
                    mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                      if (!isCollapsed) ...[
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
                              padding: EdgeInsets.symmetric(
                                horizontal: isCollapsed ? 12 : 16,
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
                                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                                  if (!isCollapsed) ...[
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
                                  ],
                                  if (isSelected && !isCollapsed) ...[
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onToggleCollapse,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 8 : 16,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Icon(
                              isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                              color: mutedColor,
                              size: 22,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 14),
                              Text(
                                'Collapse',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (MurrtubeApi.isAuthenticated && !isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          final slug = MurrtubeApi.currentUserSlug;
                          if (slug != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(slug: slug),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: mutedColor,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: items[selectedIndex].page,
          ),
        ],
      ),
    );
  }
}
