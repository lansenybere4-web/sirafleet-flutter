import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chauffeur_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color dangerColor = Color(0xFFE63946);

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ChauffeurService _chauffeurService = ChauffeurService();
  final UserService _userService = UserService();

  Chauffeur? _chauffeurProfile;
  bool _loadingChauffeur = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChauffeurProfileIfNeeded();
    });
  }

  // ================================================================
  // CHARGEMENT DU PROFIL CHAUFFEUR (camion affecté réel)
  // ================================================================

  Future<void> _loadChauffeurProfileIfNeeded() async {
    final authProvider =
    Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isChauffeur) {
      return;
    }

    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _loadingChauffeur = true;
    });

    try {
      final chauffeur =
      await _chauffeurService.getMyChauffeurProfile(token);

      if (!mounted) return;

      setState(() {
        _chauffeurProfile = chauffeur;
        _loadingChauffeur = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingChauffeur = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // ============================================================
    // COMPTE CONNECTÉ
    // ============================================================

    final String nomComplet = user == null
        ? 'Utilisateur'
        : '${user.prenom} ${user.nom}'.trim();

    final String email = user?.email ?? 'Non renseigné';
    final String telephone =
    user?.numTel.isNotEmpty == true ? user!.numTel : 'Non renseigné';

    final String adresse =
    user?.address.isNotEmpty == true ? user!.address : 'Non renseignée';

    final String role = _formatRole(user?.role);

    final String statut = _formatStatut(user?.statut);

    return Scaffold(
      backgroundColor: ProfilScreen.backgroundColor,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: ProfilScreen.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Mon profil',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null
                ? null
                : () => _showEditProfileDialog(context, authProvider),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.refreshUser();
          await _loadChauffeurProfileIfNeeded();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),
          child: Column(
            children: [
              // ======================================================
              // IDENTITÉ
              // ======================================================

              _buildProfileHeader(
                nom: nomComplet,
                role: role,
              ),

              const SizedBox(height: 18),

              // ======================================================
              // INFORMATIONS PERSONNELLES
              // ======================================================

              _buildSection(
                title: 'Informations personnelles',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    title: 'Nom complet',
                    value: nomComplet,
                  ),

                  _buildDivider(),

                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: email,
                  ),

                  _buildDivider(),

                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    title: 'Téléphone',
                    value: telephone,
                  ),

                  _buildDivider(),

                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    title: 'Adresse',
                    value: adresse,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ======================================================
              // INFORMATIONS COMPTE
              // ======================================================

              _buildSection(
                title: 'Informations du compte',
                icon: Icons.manage_accounts_outlined,
                children: [
                  _buildInfoRow(
                    icon: Icons.work_outline,
                    title: 'Rôle',
                    value: role,
                  ),

                  _buildDivider(),

                  _buildInfoRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Statut',
                    value: statut,
                    valueColor: _getStatusColor(user?.statut),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ======================================================
              // ESPACE CHAUFFEUR
              // ======================================================

              if (authProvider.isChauffeur)
                _buildSection(
                  title: 'Espace chauffeur',
                  icon: Icons.local_shipping_outlined,
                  children: [
                    _buildDriverInfo(),
                  ],
                ),

              if (authProvider.isChauffeur)
                const SizedBox(height: 15),

              // ======================================================
              // PARAMÈTRES
              // ======================================================

              _buildSection(
                title: 'Paramètres',
                icon: Icons.settings_outlined,
                children: [
                  _buildActionRow(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    subtitle: 'Gérer les notifications',
                    onTap: () {
                      _showComingSoon(
                        context,
                        'Paramètres des notifications',
                      );
                    },
                  ),

                  _buildDivider(),

                  _buildActionRow(
                    icon: Icons.lock_outline,
                    title: 'Sécurité',
                    subtitle: 'Modifier votre mot de passe',
                    onTap: () {
                      _showComingSoon(
                        context,
                        'Paramètres de sécurité',
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ======================================================
              // DÉCONNEXION
              // ======================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _confirmLogout(
                      context,
                      authProvider,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Se déconnecter',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProfilScreen.dangerColor,
                    side: const BorderSide(
                      color: ProfilScreen.dangerColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HEADER PROFIL
  // ================================================================

  Widget _buildProfileHeader({
    required String nom,
    required String role,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfilScreen.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: ProfilScreen.primaryColor,
              size: 48,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            nom,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            role,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'COMPTE CONNECTÉ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION
  // ================================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: ProfilScreen.primaryColor,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  title,
                  style: const TextStyle(
                    color: ProfilScreen.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...children,
          ],
        ),
      ),
    );
  }

  // ================================================================
  // INFORMATION
  // ================================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ProfilScreen.backgroundColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade700,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFORMATIONS CHAUFFEUR (camion affecté réel)
  // ================================================================

  Widget _buildDriverInfo() {
    if (_loadingChauffeur) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final camion = _chauffeurProfile?.camionActuel;
    final camionType = _chauffeurProfile?.camionActuelType;

    final bool aUnCamion = camion != null && camion.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfilScreen.backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ProfilScreen.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              aUnCamion
                  ? Icons.local_shipping
                  : Icons.local_shipping_outlined,
              color: ProfilScreen.primaryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Affectation du camion',
                  style: TextStyle(
                    color: ProfilScreen.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                if (aUnCamion) ...[
                  Text(
                    camion,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (camionType != null && camionType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        camionType,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ] else
                  const Text(
                    'Aucun camion affecté actuellement.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTION
  // ================================================================

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ProfilScreen.backgroundColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: ProfilScreen.primaryColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DIVIDER
  // ================================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  // ================================================================
  // FORMATAGE DU RÔLE
  // ================================================================

  String _formatRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'chauffeur':
        return 'Chauffeur';

      case 'responsable_flotte':
        return 'Responsable de flotte';

      case 'directeur':
        return 'Directeur';

      case 'admin':
      case 'administrateur':
        return 'Administrateur';

      default:
        return 'Utilisateur';
    }
  }

  // ================================================================
  // FORMATAGE DU STATUT
  // ================================================================

  String _formatStatut(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'actif':
        return 'Actif';

      case 'inactif':
        return 'Inactif';

      case 'suspendu':
        return 'Suspendu';

      default:
        return 'Non défini';
    }
  }

  // ================================================================
  // COULEUR DU STATUT
  // ================================================================

  Color _getStatusColor(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'actif':
        return ProfilScreen.accentColor;

      case 'inactif':
        return Colors.orange;

      case 'suspendu':
        return ProfilScreen.dangerColor;

      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // DIALOGUE D'ÉDITION DU PROFIL
  // ================================================================

  Future<void> _showEditProfileDialog(
      BuildContext context,
      AuthProvider authProvider,
      ) async {
    final user = authProvider.user;

    if (user == null) return;

    final nomController = TextEditingController(text: user.nom);
    final prenomController = TextEditingController(text: user.prenom);
    final emailController = TextEditingController(text: user.email);
    final telController = TextEditingController(text: user.numTel);
    final adresseController = TextEditingController(text: user.address);

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Modifier mon profil',
                style: TextStyle(
                  color: ProfilScreen.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nomController,
                        decoration:
                        const InputDecoration(labelText: 'Nom'),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: prenomController,
                        decoration:
                        const InputDecoration(labelText: 'Prénom'),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        decoration:
                        const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email invalide'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: telController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: adresseController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    setStateDialog(() => isSaving = true);

                    try {
                      // ------------------------------------------------
                      // ⚠️ ASSOMPTION : le UserModel expose `roleId`.
                      // Si ton champ s'appelle autrement (ex: role_id,
                      // ou si seul `role` — le libellé — existe),
                      // remplace la ligne ci-dessous en conséquence.
                      // ------------------------------------------------
                      final String roleId = user.roleId.toString();

                      await _userService.updateUser(
                        token: authProvider.token!,
                        id: user.id.toString(),
                        nom: nomController.text.trim(),
                        prenom: prenomController.text.trim(),
                        email: emailController.text.trim(),
                        numTel: telController.text.trim(),
                        roleId: roleId,
                        address: adresseController.text.trim(),
                        statut: user.statut ?? 'actif',
                      );

                      await authProvider.refreshUser();

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      setStateDialog(() => isSaving = false);

                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfilScreen.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================================================
  // DIALOGUE DÉCONNEXION
  // ================================================================

  void _confirmLogout(
      BuildContext context,
      AuthProvider authProvider,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Déconnexion',
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
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

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfilScreen.dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'DÉCONNECTER',
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BIENTÔT DISPONIBLE
  // ================================================================

  void _showComingSoon(
      BuildContext context,
      String title,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  color: ProfilScreen.primaryColor,
                  size: 45,
                ),

                const SizedBox(height: 12),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ProfilScreen.primaryColor,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Cette fonctionnalité sera configurée prochainement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfilScreen.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
