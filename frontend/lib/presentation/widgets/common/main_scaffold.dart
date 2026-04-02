import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      RouteNames.home,
      Icons.home_rounded,
      Icons.home_outlined,
      'nav_home',
    ),
    _NavItem(
      RouteNames.catalog,
      Icons.menu_book_rounded,
      Icons.menu_book_outlined,
      'nav_catalog',
    ),
    _NavItem(
      RouteNames.upload,
      Icons.add_circle_rounded,
      Icons.add_circle_outline_rounded,
      'nav_upload',
    ),
    _NavItem(
      RouteNames.bookshelf,
      Icons.bookmarks_rounded,
      Icons.bookmarks_outlined,
      'nav_bookshelf',
    ),
    _NavItem(
      '/profile/me',
      Icons.person_rounded,
      Icons.person_outlined,
      'nav_profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            context.go(_items[index].route);
          },
          items: _items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.outlinedIcon),
                  activeIcon: Icon(item.filledIcon, color: AppColors.primary),
                  label: item.labelKey.tr(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String labelKey;

  const _NavItem(this.route, this.filledIcon, this.outlinedIcon, this.labelKey);
}
