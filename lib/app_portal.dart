import 'package:flutter/material.dart';

import 'frontend/screens/admin/admin_app.dart';
import 'frontend/screens/admin/video_splash_screen.dart';
import 'frontend/screens/user/user_app.dart';

/// The single application entry point. It keeps the Admin and Staff
/// presentation layers separate while both continue to use the same API.
class SupermarketBillingPortal extends StatelessWidget {
  const SupermarketBillingPortal({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BBT Billing',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF075FEA)),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    ),
    home: const VideoSplashScreen(destination: _AccessPortal()),
  );
}

class _AccessPortal extends StatelessWidget {
  const _AccessPortal();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF05275D),
      foregroundColor: Colors.white,
      title: const Text('Supermarket Billing'),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: Color(0xFF05275D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose your workspace',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your account role is verified again when you sign in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 28),
                _WorkspaceCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin',
                  subtitle: 'Users, products, inventory, reports and settings',
                  onTap: () => _open(
                    context,
                    SupermarketAdminApp(
                      onLogout: () {
                        // Logout is initiated inside the workspace's inherited
                        // widget tree. Remove the route on the next frame so
                        // Flutter can finish rebuilding that tree first.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) Navigator.of(context).pop();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _WorkspaceCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Staff / User',
                  subtitle: 'Billing, stock review, payments and profile',
                  onTap: () => _open(context, const SupermarketUserApp()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _open(BuildContext context, Widget application) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => application));
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE8F0FE),
              child: Icon(icon, color: const Color(0xFF075FEA), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
