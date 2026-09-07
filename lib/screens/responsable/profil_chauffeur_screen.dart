/*import 'package:flutter/material.dart';

class ProfilChauffeurScreen extends StatelessWidget {
  final Map<String, dynamic> chauffeur;

  const ProfilChauffeurScreen({
    super.key,
    required this.chauffeur,
  });

  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final statut =
        chauffeur['statut']?.toString() ?? 'Disponible';

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil chauffeur',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Options',
            onPressed: () {
              _showOptions(context);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          30,
        ),
        child: Column(
          children: [
            _buildProfileHeader(statut),

            const SizedBox(height: 15),

            // ==================================================
            // IDENTITÉ
            // ==================================================

            _buildSection(
              title: 'Identité du chauffeur',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(
                  Icons.badge_outlined,
                  'Matricule',
                  chauffeur['id'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.person_outline,
                  'Nom',
                  chauffeur['nom'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.person_outline,
                  'Prénom',
                  chauffeur['prenom'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  chauffeur['telephone'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.email_outlined,
                  'Adresse email',
                  chauffeur['email'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.home_outlined,
                  'Adresse',
                  chauffeur['adresse'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.cake_outlined,
                  'Date de naissance',
                  chauffeur['dateNaissance'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.location_city_outlined,
                  'Lieu de naissance',
                  chauffeur['lieuNaissance'],
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // INFORMATIONS PROFESSIONNELLES
            // ==================================================

            _buildSection(
              title: 'Informations professionnelles',
              icon: Icons.work_outline,
              children: [
                _buildInfoRow(
                  Icons.badge_outlined,
                  'Matricule professionnel',
                  chauffeur['id'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.credit_card_outlined,
                  'Permis de conduire',
                  chauffeur['permis'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  'Catégorie du permis',
                  chauffeur['categoriePermis'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.calendar_month_outlined,
                  'Date d’embauche',
                  chauffeur['dateEmbauche'],
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.work_history_outlined,
                  'Statut professionnel',
                  statut,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CAMION
            // ==================================================

            _buildSection(
              title: 'Véhicule affecté',
              icon: Icons.local_shipping_outlined,
              children: [
                _buildTruckCard(),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATISTIQUES
            // ==================================================

            _buildSection(
              title: 'Statistiques',
              icon: Icons.analytics_outlined,
              children: [
                _buildStatistics(),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // MISSIONS
            // ==================================================

            _buildSection(
              title: 'Activité des missions',
              icon: Icons.assignment_outlined,
              children: [
                _buildMissionSummary(context),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // SIGNALEMENTS
            // ==================================================

            _buildSection(
              title: 'Signalements',
              icon: Icons.warning_amber_outlined,
              children: [
                _buildSignalementSummary(context),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ACTIONS
            // ==================================================

            _buildActions(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER PROFIL
  // ============================================================

  Widget _buildProfileHeader(String statut) {
    final statusColor = _getStatusColor(statut);

    final photo =
        chauffeur['photo']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primaryColor,
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
          // PHOTO
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: photo.isNotEmpty
                  ? Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 55,
                  );
                },
              )
                  : const Icon(
                Icons.person,
                color: primaryColor,
                size: 55,
              ),
            ),
          ),

          const SizedBox(height: 13),

          Text(
            chauffeur['nomComplet'] ??
                'Chauffeur',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Chauffeur professionnel',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderBadge(
                chauffeur['id'] ?? '—',
              ),
              _buildHeaderBadge(
                statut,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(
      String text, {
        Color? color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.25) ??
            Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      dynamic value,
      ) {
    final displayValue =
    value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'Non renseigné';

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
              BorderRadius.circular(9),
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(
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

  // ============================================================
  // CAMION
  // ============================================================

  Widget _buildTruckCard() {
    final camion =
        chauffeur['camion'] ?? 'Aucun camion';

    final type =
        chauffeur['typeCamion'] ??
            'Type non renseigné';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              primaryColor.withValues(alpha: 0.10),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  camion.toString(),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.check_circle,
                color: accentColor,
                size: 18,
              ),
              SizedBox(height: 3),
              Text(
                'Affecté',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics() {
    final total =
    (chauffeur['missions'] ?? 0) as int;

    final terminees =
    (chauffeur['missionsTerminees'] ?? 0)
    as int;

    final signalements =
    (chauffeur['signalements'] ?? 0) as int;

    return Row(
      children: [
        Expanded(
          child: _buildStatistic(
            Icons.assignment_outlined,
            '$total',
            'Missions',
            primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatistic(
            Icons.check_circle_outline,
            '$terminees',
            'Terminées',
            accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatistic(
            Icons.warning_amber_outlined,
            '$signalements',
            'Signalements',
            signalements > 0
                ? dangerColor
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistic(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MISSIONS
  // ============================================================

  Widget _buildMissionSummary(
      BuildContext context,
      ) {
    final total =
    (chauffeur['missions'] ?? 0) as int;

    final terminees =
    (chauffeur['missionsTerminees'] ?? 0)
    as int;

    final enCours =
    (total - terminees).clamp(0, total);

    return Column(
      children: [
        _buildProgressRow(
          title: 'Missions terminées',
          value: terminees,
          total: total,
          color: accentColor,
        ),

        const SizedBox(height: 12),

        _buildProgressRow(
          title: 'Missions restantes',
          value: enCours,
          total: total,
          color: warningColor,
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Historique des missions du chauffeur',
              );
            },
            icon: const Icon(
              Icons.history,
              size: 18,
            ),
            label: const Text(
              'Voir l’historique des missions',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              padding:
              const EdgeInsets.symmetric(
                vertical: 11,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String title,
    required int value,
    required int total,
    required Color color,
  }) {
    final progress = total == 0
        ? 0.0
        : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value / $total',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius:
          BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor:
            Colors.grey.shade200,
            valueColor:
            AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SIGNALEMENTS
  // ============================================================

  Widget _buildSignalementSummary(
      BuildContext context,
      ) {
    final total =
    (chauffeur['signalements'] ?? 0) as int;

    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color:
          accentColor.withValues(alpha: 0.08),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: accentColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucun signalement enregistré.',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSignalementRow(
          Icons.warning_amber_outlined,
          'Signalements enregistrés',
          '$total',
          dangerColor,
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Historique des signalements',
              );
            },
            icon: const Icon(
              Icons.visibility_outlined,
              size: 18,
            ),
            label: const Text(
              'Voir les signalements',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: dangerColor,
              side: const BorderSide(
                color: dangerColor,
              ),
              padding:
              const EdgeInsets.symmetric(
                vertical: 11,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalementRow(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius:
        BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS RESPONSABLE
  // ============================================================

  Widget _buildActions(
      BuildContext context,
      ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Ouverture du suivi GPS du chauffeur',
              );
            },
            icon: const Icon(
              Icons.location_on_outlined,
              size: 18,
            ),
            label: const Text('Suivi GPS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              padding:
              const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(11),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showContactDialog(context);
            },
            icon: const Icon(
              Icons.phone_outlined,
              size: 18,
            ),
            label: const Text('Contacter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPTIONS
  // ============================================================

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: primaryColor,
                ),
                title: const Text(
                  'Voir la position GPS',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage(
                    context,
                    'Suivi GPS du chauffeur',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: primaryColor,
                ),
                title: const Text(
                  'Voir l’historique',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage(
                    context,
                    'Historique du chauffeur',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
                title: const Text('Fermer'),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTACT
  // ============================================================

  void _showContactDialog(
      BuildContext context,
      ) {
    final telephone =
        chauffeur['telephone'] ?? 'Non renseigné';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Contacter le chauffeur',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                chauffeur['nomComplet'] ??
                    'Chauffeur',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    telephone.toString(),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showMessage(
                  context,
                  'Appel vers $telephone',
                );
              },
              icon: const Icon(
                Icons.phone,
                size: 17,
              ),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration:
          const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'En mission':
        return warningColor;

      case 'En service':
        return accentColor;

      case 'Disponible':
        return primaryColor;

      case 'Repos':
        return Colors.grey;

      default:
        return primaryColor;
    }
  }
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chauffeur_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';

class ProfilChauffeurScreen extends StatefulWidget {
  final int chauffeurId;

  const ProfilChauffeurScreen({
    super.key,
    required this.chauffeurId,
  });

  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  State<ProfilChauffeurScreen> createState() =>
      _ProfilChauffeurScreenState();
}

class _ProfilChauffeurScreenState extends State<ProfilChauffeurScreen> {
  final ChauffeurService _chauffeurService = ChauffeurService();

  Chauffeur? _chauffeur;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ================================================================
  // CHARGEMENT
  // ================================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token;

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée, veuillez vous reconnecter.');
      }

      final chauffeur = await _chauffeurService.getChauffeurById(
        widget.chauffeurId,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _chauffeur = chauffeur;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilChauffeurScreen.backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: ProfilChauffeurScreen.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil chauffeur',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_chauffeur != null)
            IconButton(
              tooltip: 'Options',
              onPressed: () {
                _showOptions(context);
              },
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: ProfilChauffeurScreen.dangerColor,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfilChauffeurScreen.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final chauffeur = _chauffeur!;
    final statut = chauffeur.statut.isNotEmpty ? chauffeur.statut : 'Disponible';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        child: Column(
          children: [
            _buildProfileHeader(chauffeur, statut),

            const SizedBox(height: 15),

            // ==================================================
            // IDENTITÉ
            // ==================================================

            _buildSection(
              title: 'Identité du chauffeur',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(
                  Icons.badge_outlined,
                  'Matricule',
                  chauffeur.matricule,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.person_outline,
                  'Nom',
                  chauffeur.nom,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.person_outline,
                  'Prénom',
                  chauffeur.prenom,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  chauffeur.telephone,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.email_outlined,
                  'Adresse email',
                  chauffeur.email,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // INFORMATIONS PROFESSIONNELLES
            // ==================================================

            _buildSection(
              title: 'Informations professionnelles',
              icon: Icons.work_outline,
              children: [
                _buildInfoRow(
                  Icons.badge_outlined,
                  'Matricule professionnel',
                  chauffeur.matricule,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.credit_card_outlined,
                  'Permis de conduire',
                  chauffeur.permis,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  'Catégorie du permis',
                  chauffeur.typePermis,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.calendar_month_outlined,
                  'Date d\u2019embauche',
                  chauffeur.dateEmbauche,
                ),
                _buildDivider(),
                _buildInfoRow(
                  Icons.work_history_outlined,
                  'Statut professionnel',
                  statut,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CAMION
            // ==================================================

            _buildSection(
              title: 'Véhicule affecté',
              icon: Icons.local_shipping_outlined,
              children: [
                _buildTruckCard(chauffeur),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATISTIQUES
            // ==================================================

            _buildSection(
              title: 'Statistiques',
              icon: Icons.analytics_outlined,
              children: [
                _buildStatistics(chauffeur),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // MISSIONS
            // ==================================================

            _buildSection(
              title: 'Activité des missions',
              icon: Icons.assignment_outlined,
              children: [
                _buildMissionSummary(context, chauffeur),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // SIGNALEMENTS
            // ==================================================

            _buildSection(
              title: 'Signalements',
              icon: Icons.warning_amber_outlined,
              children: [
                _buildSignalementSummary(context, chauffeur),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ACTIONS
            // ==================================================

            _buildActions(context, chauffeur),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER PROFIL
  // ============================================================

  Widget _buildProfileHeader(Chauffeur chauffeur, String statut) {
    final statusColor = _getStatusColor(statut);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ProfilChauffeurScreen.primaryColor,
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
          Container(
            width: 95,
            height: 95,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.person,
              color: ProfilChauffeurScreen.primaryColor,
              size: 55,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            chauffeur.nomComplet.isNotEmpty
                ? chauffeur.nomComplet
                : 'Chauffeur',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Chauffeur professionnel',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderBadge(
                chauffeur.matricule.isNotEmpty ? chauffeur.matricule : '—',
              ),
              _buildHeaderBadge(
                statut,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(
      String text, {
        Color? color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.25) ??
            Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: ProfilChauffeurScreen.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: ProfilChauffeurScreen.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String? value,
      ) {
    final displayValue =
    value != null && value.trim().isNotEmpty ? value : 'Non renseigné';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: ProfilChauffeurScreen.backgroundColor,
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
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(
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

  // ============================================================
  // CAMION
  // ============================================================

  Widget _buildTruckCard(Chauffeur chauffeur) {
    final bool aUnCamion = chauffeur.camionActuel != null &&
        chauffeur.camionActuel!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ProfilChauffeurScreen.backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ProfilChauffeurScreen.primaryColor
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: ProfilChauffeurScreen.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aUnCamion ? chauffeur.camionActuel! : 'Aucun camion',
                  style: const TextStyle(
                    color: ProfilChauffeurScreen.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aUnCamion
                      ? (chauffeur.camionActuelType ?? 'Type non renseigné')
                      : 'Aucune mission active en ce moment',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                aUnCamion ? Icons.check_circle : Icons.remove_circle_outline,
                color: aUnCamion
                    ? ProfilChauffeurScreen.accentColor
                    : Colors.grey,
                size: 18,
              ),
              const SizedBox(height: 3),
              Text(
                aUnCamion ? 'Affecté' : 'Non affecté',
                style: TextStyle(
                  color: aUnCamion
                      ? ProfilChauffeurScreen.accentColor
                      : Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics(Chauffeur chauffeur) {
    final total = chauffeur.missionsCount;
    final terminees = chauffeur.missionsTermineesCount;
    final signalements = chauffeur.signalementsCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatistic(
            Icons.assignment_outlined,
            '$total',
            'Missions',
            ProfilChauffeurScreen.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatistic(
            Icons.check_circle_outline,
            '$terminees',
            'Terminées',
            ProfilChauffeurScreen.accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatistic(
            Icons.warning_amber_outlined,
            '$signalements',
            'Signalements',
            signalements > 0
                ? ProfilChauffeurScreen.dangerColor
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistic(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MISSIONS
  // ============================================================

  Widget _buildMissionSummary(BuildContext context, Chauffeur chauffeur) {
    final total = chauffeur.missionsCount;
    final terminees = chauffeur.missionsTermineesCount;
    final enCours = (total - terminees).clamp(0, total);

    return Column(
      children: [
        _buildProgressRow(
          title: 'Missions terminées',
          value: terminees,
          total: total,
          color: ProfilChauffeurScreen.accentColor,
        ),

        const SizedBox(height: 12),

        _buildProgressRow(
          title: 'Missions restantes',
          value: enCours,
          total: total,
          color: ProfilChauffeurScreen.warningColor,
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Historique des missions du chauffeur',
              );
            },
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Voir l\u2019historique des missions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProfilChauffeurScreen.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String title,
    required int value,
    required int total,
    required Color color,
  }) {
    final progress = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value / $total',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SIGNALEMENTS
  // ============================================================

  Widget _buildSignalementSummary(BuildContext context, Chauffeur chauffeur) {
    final total = chauffeur.signalementsCount;

    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ProfilChauffeurScreen.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: ProfilChauffeurScreen.accentColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucun signalement enregistré.',
                style: TextStyle(
                  color: ProfilChauffeurScreen.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSignalementRow(
          Icons.warning_amber_outlined,
          'Signalements enregistrés',
          '$total',
          ProfilChauffeurScreen.dangerColor,
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Historique des signalements',
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Voir les signalements'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProfilChauffeurScreen.dangerColor,
              side: const BorderSide(
                color: ProfilChauffeurScreen.dangerColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalementRow(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS RESPONSABLE
  // ============================================================

  Widget _buildActions(BuildContext context, Chauffeur chauffeur) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                context,
                'Ouverture du suivi GPS du chauffeur',
              );
            },
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('Suivi GPS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProfilChauffeurScreen.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showContactDialog(context, chauffeur);
            },
            icon: const Icon(Icons.phone_outlined, size: 18),
            label: const Text('Contacter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfilChauffeurScreen.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPTIONS
  // ============================================================

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: ProfilChauffeurScreen.primaryColor,
                ),
                title: const Text('Modifier les infos professionnelles'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: ProfilChauffeurScreen.primaryColor,
                ),
                title: const Text('Voir la position GPS'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(context, 'Suivi GPS du chauffeur');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: ProfilChauffeurScreen.primaryColor,
                ),
                title: const Text('Voir l\u2019historique'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(context, 'Historique du chauffeur');
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Fermer'),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ÉDITION DES INFOS PROFESSIONNELLES
  // ============================================================

  Future<void> _showEditDialog(BuildContext context) async {
    final chauffeur = _chauffeur;
    if (chauffeur == null) return;

    final matriculeController = TextEditingController(text: chauffeur.matricule);
    final permisController = TextEditingController(text: chauffeur.permis);
    final typePermisController = TextEditingController(text: chauffeur.typePermis);
    final dateEmbaucheController =
    TextEditingController(text: chauffeur.dateEmbauche ?? '');

    String statut = chauffeur.statut.isNotEmpty ? chauffeur.statut : 'actif';
    const statutsPossibles = ['actif', 'inactif', 'suspendu'];
    if (!statutsPossibles.contains(statut)) {
      statut = 'actif';
    }

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
                'Modifier le chauffeur',
                style: TextStyle(
                  color: ProfilChauffeurScreen.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: matriculeController,
                      decoration: const InputDecoration(labelText: 'Matricule'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: permisController,
                      decoration: const InputDecoration(
                        labelText: 'N° permis de conduire',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: typePermisController,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie du permis',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateEmbaucheController,
                      decoration: const InputDecoration(
                        labelText: 'Date d\u2019embauche (AAAA-MM-JJ)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: statut,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: statutsPossibles
                          .map(
                            (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s[0].toUpperCase() + s.substring(1)),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => statut = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    setStateDialog(() => isSaving = true);

                    try {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token;

                      if (token == null || token.isEmpty) {
                        throw Exception('Session expirée.');
                      }

                      final updated = await _chauffeurService.updateChauffeur(
                        id: chauffeur.id ?? widget.chauffeurId,
                        token: token,
                        matricule: matriculeController.text.trim(),
                        permis: permisController.text.trim(),
                        typePermis: typePermisController.text.trim(),
                        dateEmbauche: dateEmbaucheController.text.trim().isEmpty
                            ? null
                            : dateEmbaucheController.text.trim(),
                        statut: statut,
                      );

                      if (!mounted) return;

                      setState(() => _chauffeur = updated);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      setStateDialog(() => isSaving = false);

                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfilChauffeurScreen.primaryColor,
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

  // ============================================================
  // CONTACT
  // ============================================================

  void _showContactDialog(BuildContext context, Chauffeur chauffeur) {
    final telephone =
    chauffeur.telephone.isNotEmpty ? chauffeur.telephone : 'Non renseigné';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Contacter le chauffeur',
            style: TextStyle(
              color: ProfilChauffeurScreen.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chauffeur.nomComplet.isNotEmpty
                    ? chauffeur.nomComplet
                    : 'Chauffeur',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: ProfilChauffeurScreen.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(telephone),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showMessage(context, 'Appel vers $telephone');
              },
              icon: const Icon(Icons.phone, size: 17),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfilChauffeurScreen.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'En mission':
        return ProfilChauffeurScreen.warningColor;

      case 'En service':
        return ProfilChauffeurScreen.accentColor;

      case 'Disponible':
      case 'actif':
        return ProfilChauffeurScreen.primaryColor;

      case 'Repos':
      case 'inactif':
        return Colors.grey;

      case 'suspendu':
        return ProfilChauffeurScreen.dangerColor;

      default:
        return ProfilChauffeurScreen.primaryColor;
    }
  }
}
