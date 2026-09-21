import 'package:flutter/material.dart';

void main() {
  runApp(const MaintenanceGoApp());
}

// ---- Color tokens ----
// Kept in one place so the palette is easy to tweak later.
class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1C1C1E);
  static const border = Color(0xFF2C2C2E);
  static const textPrimary = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFF9A9A9E);
  static const accent = Color(0xFFE8A33D); // dashboard warning-light amber
}

class MaintenanceGoApp extends StatelessWidget {
  const MaintenanceGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaintenanceGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.accent,
        ),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Placeholder bottom nav: highlights "Home" and does nothing on tap yet.
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined,
                color: AppColors.textSecondary),
            selectedIcon:
                Icon(Icons.directions_car, color: AppColors.accent),
            label: 'My Vehicle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppColors.accent),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.settings, color: AppColors.accent),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Top 40%: My Vehicle ----
            SizedBox(
              height: screenHeight * 0.4,
              child: const _MyVehicleSection(),
            ),

            // ---- Remaining space: navigation ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _NavCard(
                      title: 'Maintenance logs',
                      subtitle: 'Every service, receipt, and repair',
                      icon: Icons.receipt_long_outlined,
                    ),
                    SizedBox(height: 16),
                    _NavCard(
                      title: 'Maintenance calendar',
                      subtitle: 'What\'s due, and when',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyVehicleSection extends StatelessWidget {
  const _MyVehicleSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My vehicle',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '2026 Toyota Tacoma SR5',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          // Vehicle image sits under the name and takes the remaining space.
          // The photo has a near-black background, so it blends into the
          // dark theme.
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/tacoma.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                '42,180 miles',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Last service 3 months ago',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}