import 'package:flutter/material.dart';

const navy = Color(0xFF06356F);
const blue = Color(0xFF0868F7);
const ink = Color(0xFF10264D);
const muted = Color(0xFF6F7F99);
const line = Color(0xFFDDE5F0);
const page = Color(0xFFF7F9FC);
const green = Color(0xFF0A9B58);
const red = Color(0xFFE51F2B);

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({super.key, required this.title, this.back, this.actions});
  final String title;
  final VoidCallback? back;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(54);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: navy,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(
      icon: Icon(back == null ? Icons.menu_rounded : Icons.arrow_back_rounded),
      onPressed: back ?? () {},
    ),
    titleSpacing: 0,
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    actions: actions,
  );
}

class AdminBottomBar extends StatelessWidget {
  const AdminBottomBar({
    super.key,
    required this.selected,
    required this.onTap,
  });
  final int selected;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 64,
    elevation: 4,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFE7F0FF),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    selectedIndex: selected,
    onDestinationSelected: onTap,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Users',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      NavigationDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: 'Reports',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.color = blue,
    this.outlined = false,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final bool outlined;
  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              minimumSize: const Size.fromHeight(48),
              shape: shape,
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: shape,
            ),
            child: child,
          );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox(this.hint, {super.key, this.trailing});
  final String hint;
  final IconData? trailing;
  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: muted),
      prefixIcon: const Icon(Icons.search, size: 19),
      suffixIcon: trailing == null ? null : Icon(trailing, size: 19),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      isDense: true,
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class LabeledValue extends StatelessWidget {
  const LabeledValue(
    this.label,
    this.value, {
    super.key,
    this.valueColor = ink,
  });
  final String label;
  final String value;
  final Color valueColor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );
}

void showNotice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
