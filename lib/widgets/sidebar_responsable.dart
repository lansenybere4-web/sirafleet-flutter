import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

import '../screens/responsable/dashboard_screen.dart';
import '../screens/responsable/camions_screen.dart';
import '../screens/responsable/chauffeurs_screen.dart';
import '../screens/responsable/missions_screen.dart';
import '../screens/responsable/maintenance_screen.dart';
import '../screens/responsable/carburant_screen.dart';
import '../screens/responsable/suivi_gps_screen.dart';
import '../screens/responsable/alertes_screen.dart';
import '../screens/responsable/rapports_screen.dart';

enum ResponsableMenuItem {
  dashboard,
  camions,
  chauffeurs,
  missions,
  maintenance,
  carburant,
  suiviGps,
  alertes,
  rapports,
}

class ResponsableSidebar extends StatelessWidget {
  final ResponsableMenuItem current;

  const ResponsableSidebar({
    super.key,
    required this.current,
  });

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: primaryColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            _buildLogo(),

            const SizedBox(height: 35),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _item(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Tableau de bord',
                      item: ResponsableMenuItem.dashboard,
                      builder: (_) =>
                      const ResponsableDashboardScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Camions',
                      item: ResponsableMenuItem.camions,
                      builder: (_) => const CamionsScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.people_outline,
                      title: 'Chauffeurs',
                      item: ResponsableMenuItem.chauffeurs,
                      builder: (_) => const ChauffeursScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'Missions',
                      item: ResponsableMenuItem.missions,
                      builder: (_) => const MissionsScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.build_outlined,
                      title: 'Maintenance',
                      item: ResponsableMenuItem.maintenance,
                      builder: (_) => const MaintenanceScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.local_gas_station_outlined,
                      title: 'Carburant',
                      item: ResponsableMenuItem.carburant,
                      builder: (_) => const CarburantScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.map_outlined,
                      title: 'Suivi GPS',
                      item: ResponsableMenuItem.suiviGps,
                      builder: (_) => const SuiviGpsScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.warning_amber_rounded,
                      title: 'Alertes',
                      item: ResponsableMenuItem.alertes,
                      builder: (_) => const AlertesScreen(),
                    ),

                    _item(
                      context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Rapports',
                      item: ResponsableMenuItem.rapports,
                      builder: (_) => const RapportsScreen(),
                    ),

                    const SizedBox(height: 20),

                    Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),

                    const SizedBox(height: 10),

                    _logoutItem(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_shipping,
            color: primaryColor,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        const Text(
          'SiraFleet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _item(
      BuildContext context, {
        required IconData icon,
        required String title,
        required ResponsableMenuItem item,
        required WidgetBuilder builder,
      }) {
    final selected = item == current;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,

        selected: selected,

        onTap: () {
          if (selected) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: builder,
            ),
          );
        },

        leading: Icon(
          icon,
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.70),
          size: 21,
        ),

        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.70),
            fontSize: 13,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // DECONNEXION
  // ============================================================

  Widget _logoutItem(BuildContext context) {
    return ListTile(
      dense: true,

      onTap: () => _showLogoutDialog(context),

      leading: Icon(
        Icons.logout,
        color: Colors.white.withValues(alpha: 0.70),
        size: 21,
      ),

      title: Text(
        'Déconnexion',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.70),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ============================================================
  // DIALOGUE DECONNEXION
  // ============================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: const Text(
            'Déconnexion',
          ),

          content: const Text(
            'Voulez-vous vraiment vous déconnecter ?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Annuler',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final auth = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                await auth.logout();

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
              ),

              child: const Text(
                'Déconnexion',
              ),
            ),
          ],
        );
      },
    );
  }
}