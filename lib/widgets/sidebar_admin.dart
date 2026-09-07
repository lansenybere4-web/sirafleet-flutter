import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

// ==========================
// ADMIN SCREENS
// ==========================

import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/utilisateurs_screen.dart';
import '../screens/admin/camions_admin_screen.dart';
//import '../screens/admin/roles_screen.dart';
import '../screens/admin/equipements_screen.dart';
import '../screens/admin/alertes_systeme_screen.dart';
import '../screens/admin/rapports_screen.dart';
import '../screens/admin/parametres_screen.dart';

class SidebarAdmin extends StatelessWidget {
  final int selectedIndex;

  const SidebarAdmin({
    super.key,
    this.selectedIndex = 0,
  });

  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final String nom = user?.nom ?? 'Administrateur';
    final String email = user?.email ?? 'admin@sirafleet.com';

    return Container(
      width: 250,
      color: primaryColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            // ======================================================
            // LOGO
            // ======================================================

            _buildLogo(),

            const SizedBox(height: 25),

            // ======================================================
            // PROFIL ADMIN
            // ======================================================

            _buildProfile(
              nom: nom,
              email: email,
            ),

            const SizedBox(height: 20),

            // ======================================================
            // MENU
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    // ==================================================
                    // ADMINISTRATION
                    // ==================================================

                    _buildSectionTitle('ADMINISTRATION'),

                    const SizedBox(height: 8),

                    // TABLEAU DE BORD
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      title: 'Tableau de bord',
                      index: 0,
                      builder: (_) =>
                      const AdminDashboardScreen(),
                    ),

                    // UTILISATEURS
                    _buildMenuItem(
                      context,
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      title: 'Utilisateurs',
                      index: 1,
                      builder: (_) =>
                      const UtilisateursScreen(),
                    ),

                    // VÉHICULES
                    _buildMenuItem(
                      context,
                      icon: Icons.local_shipping_outlined,
                      activeIcon: Icons.local_shipping,
                      title: 'Véhicules',
                      index: 2,
                      builder: (_) =>
                      const CamionsAdminScreen(),
                    ),

                    // RÔLES & PERMISSIONS
                    /*_buildMenuItem(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      activeIcon: Icons.admin_panel_settings,
                      title: 'Rôles & permissions',
                      index: 3,
                      builder: (_) =>
                      const RolesScreen(),
                    ),*/

                    const SizedBox(height: 18),

                    // ==================================================
                    // SUPERVISION
                    // ==================================================

                    _buildSectionTitle('SUPERVISION'),

                    const SizedBox(height: 8),

                    // ÉQUIPEMENTS
                    _buildMenuItem(
                      context,
                      icon: Icons.memory_outlined,
                      activeIcon: Icons.memory,
                      title: 'Équipements',
                      index: 4,
                      builder: (_) =>
                      const EquipementsScreen(),
                    ),

                    // ALERTES
                    _buildMenuItem(
                      context,
                      icon: Icons.warning_amber_outlined,
                      activeIcon: Icons.warning_amber,
                      title: 'Alertes système',
                      index: 5,
                      builder: (_) =>
                      const AlertesSystemeScreen(),
                    ),

                    // RAPPORTS
                    _buildMenuItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      title: 'Rapports',
                      index: 6,
                      builder: (_) =>
                      const RapportsScreen(),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // CONFIGURATION
                    // ==================================================

                    _buildSectionTitle('CONFIGURATION'),

                    const SizedBox(height: 8),

                    // PARAMÈTRES
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      title: 'Paramètres',
                      index: 7,
                      builder: (_) =>
                      const ParametresScreen(),
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // SÉPARATEUR
            // ========================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            const SizedBox(height: 5),

            // ========================================================
            // DÉCONNEXION
            // ========================================================

            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 15,
              ),
              child: _buildLogoutItem(
                context,
                authProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // LOGO
  // ==============================================================

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

  // ==============================================================
  // PROFIL ADMINISTRATEUR
  // ==============================================================

  Widget _buildProfile({
    required String nom,
    required String email,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: primaryColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NOM
                Text(
                  nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                // EMAIL
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 4),

                // RÔLE
                const Text(
                  'ADMINISTRATEUR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TITRE DE SECTION
  // ==============================================================

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 3,
          bottom: 3,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ITEM MENU
  // ==============================================================

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required IconData activeIcon,
        required String title,
        required int index,
        required WidgetBuilder builder,
      }) {
    final bool selected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),

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
          selected ? activeIcon : icon,
          color: selected
              ? Colors.white
              : Colors.white70,
          size: 21,
        ),

        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white70,
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

  // ==============================================================
  // DÉCONNEXION
  // ==============================================================

  Widget _buildLogoutItem(
      BuildContext context,
      AuthProvider authProvider,
      ) {
    return ListTile(
      dense: true,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      onTap: () => _showLogoutDialog(
        context,
        authProvider,
      ),

      leading: const Icon(
        Icons.logout,
        color: Colors.white70,
        size: 21,
      ),

      title: const Text(
        'Déconnexion',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ==============================================================
  // DIALOGUE DE DÉCONNEXION
  // ==============================================================

  void _showLogoutDialog(
      BuildContext context,
      AuthProvider authProvider,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: const Text(
            'Déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
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

                await authProvider.logout();

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
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