import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/chauffeur_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';
import '../../widgets/chauffeur_pro_sections.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sidebar_responsable.dart';

class ProfilChauffeurScreen extends StatefulWidget {
  final int chauffeurId;

  const ProfilChauffeurScreen({
    super.key,
    required this.chauffeurId,
  });

  @override
  State<ProfilChauffeurScreen> createState() =>
      _ProfilChauffeurScreenState();
}

class _ProfilChauffeurScreenState extends State<ProfilChauffeurScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF243247);
  static const Color mutedColor = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE5EAF0);

  final ChauffeurService _chauffeurService = ChauffeurService();

  Chauffeur? _chauffeur;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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
    final c = _chauffeur;

    return ProfileShell(
      title: 'Profil chauffeur',
      subtitle: 'Informations et détails professionnels',
      icon: Icons.badge_outlined,
      sidebar: const ResponsableSidebar(current: ResponsableMenuItem.chauffeurs),
      loading: _loading,
      error: _error,
      onRefresh: _load,
      onOptions: _showOptions,
      builder: (isDesktop) {
        if (c == null) {
          return const Center(child: Text('Aucune information disponible.'));
        }
        return _buildContent(c, isDesktop);
      },
    );
  }

  String _v(String? s) => (s == null || s.trim().isEmpty) ? '' : s.trim();

  Widget _buildContent(Chauffeur c, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(
          name: _fullName(c),
          subtitle: 'Chauffeur professionnel',
          photoUrl: c.photoProfil,
          onMore: _showOptions,
          badges: [
            ProfileBadge(Icons.verified_user_outlined,
                displayStatus(c.statut), statusColor(c.statut)),
            ProfileBadge(
              Icons.badge_outlined,
              c.matricule?.isNotEmpty == true
                  ? c.matricule!
                  : 'Matricule non défini',
              Colors.white.withValues(alpha: 0.16),
            ),
          ],
          details: [
            ProfileDetail(Icons.phone_outlined,
            c.telephone.isEmpty ? 'Téléphone non renseigné' : c.telephone),
            ProfileDetail(Icons.mail_outline_rounded,
            c.email.isEmpty ? 'Email non renseigné' : c.email),
            if (c.siteAffectation.isNotEmpty)
            ProfileDetail(Icons.business_outlined, c.siteAffectation),

          ],

        ),
        const SizedBox(height: 24),
        ProfileTwoColumns(
          isDesktop: isDesktop,
          left: ProfileSection(
            title: 'Informations personnelles',
            subtitle: 'Identité et coordonnées',
            icon: Icons.contact_page_outlined,
            children: [
              ProfileInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nom complet',
                  value: _fullName(c)),
              ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: _v(c.telephone)),
              ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Adresse e-mail',
                  value: _v(c.email)),
              ProfileInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse',
                  value: _v(c.address)),
            ],
          ),
          right: ChauffeurProSections.professionalInfo(c),
        ),
        const SizedBox(height: 22),
        ChauffeurProSections(
          chauffeur: c,
          isDesktop: isDesktop,
          showProfessionalInfo: false, // déjà affichée dans la colonne de droite
        ),
        const SizedBox(height: 26),
        _buildActions(), // inchangé
        const SizedBox(height: 20),
        const SizedBox(height: 22),
        ProfileSection(
          title: 'Affectation',
          subtitle: 'Lieu de travail',
          icon: Icons.business_outlined,
          children: [
            ProfileInfoRow(
              icon: Icons.apartment_outlined,
              label: 'Site d’affectation',
              value: c.siteAffectation.isEmpty
                  ? 'Non renseigné'
                  : c.siteAffectation,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BARRE SUPERIEURE
  // ============================================================

  Widget _buildTopBar({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 30 : 16,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
              color: primaryColor,
              tooltip: 'Retour',
            ),
            const SizedBox(width: 8),
          ],
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil chauffeur',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: isDesktop ? 21 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Informations et détails professionnels',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            color: primaryColor,
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: _showOptions,
            icon: const Icon(Icons.more_vert_rounded),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CORPS PRINCIPAL
  // ============================================================

  Widget _buildBody(bool isDesktop) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 54,
                color: dangerColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger le profil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mutedColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chauffeur == null) {
      return const Center(
        child: Text('Aucune information disponible.'),
      );
    }

    final chauffeur = _chauffeur!;

    return RefreshIndicator(
      onRefresh: _load,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(chauffeur),
                const SizedBox(height: 24),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildIdentitySection(chauffeur),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _buildProfessionalSection(chauffeur),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildIdentitySection(chauffeur),
                      const SizedBox(height: 18),
                      _buildProfessionalSection(chauffeur),
                    ],
                  ),

                const SizedBox(height: 22),
                _buildTruckCard(chauffeur),
                const SizedBox(height: 26),
                _buildSectionTitle(
                  'Activité du chauffeur',
                  'Résumé des activités enregistrées',
                  Icons.insights_rounded,
                ),
                const SizedBox(height: 16),
                _buildStatistics(chauffeur),
                const SizedBox(height: 26),
                _buildActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EN-TETE DU PROFIL
  // ============================================================

  Widget _buildProfileHeader(Chauffeur chauffeur) {
    final fullName = _fullName(chauffeur);
    final status = _displayStatus(chauffeur.statut);
    final statusColor = _getStatusColor(chauffeur.statut);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D3557),
            Color(0xFF294A70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
          ),
          Positioned(
            right: 70,
            bottom: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 86,
                      width: 86,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Chauffeur professionnel',
                            style: TextStyle(
                              color: Color(0xFFDCE6F2),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _headerBadge(
                                icon: Icons.verified_user_outlined,
                                label: status,
                                color: statusColor,
                              ),
                              _headerBadge(
                                icon: Icons.badge_outlined,
                                label: chauffeur.matricule?.isNotEmpty == true
                                    ? chauffeur.matricule!
                                    : 'Matricule non défini',
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showOptions,
                      tooltip: 'Plus d’options',
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _headerDetail(
                          Icons.phone_outlined,
                          chauffeur.telephone ?? 'Téléphone non renseigné',
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _headerDetail(
                          Icons.mail_outline_rounded,
                          chauffeur.email ?? 'Email non renseigné',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFFB8C9DC),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IDENTITE
  // ============================================================

  Widget _buildIdentitySection(Chauffeur chauffeur) {
    return _buildSection(
      title: 'Informations personnelles',
      subtitle: 'Identité et coordonnées',
      icon: Icons.contact_page_outlined,
      children: [
        _buildInfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Nom complet',
          value: _fullName(chauffeur),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.badge_outlined,
          label: 'Matricule',
          value: _value(chauffeur.matricule),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: _value(chauffeur.telephone),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'Adresse e-mail',
          value: _value(chauffeur.email),
        ),
      ],
    );
  }

  // ============================================================
  // INFORMATIONS PROFESSIONNELLES
  // ============================================================

  Widget _buildProfessionalSection(Chauffeur chauffeur) {
    return _buildSection(
      title: 'Informations professionnelles',
      subtitle: 'Permis et situation professionnelle',
      icon: Icons.work_outline_rounded,
      children: [
        _buildInfoRow(
          icon: Icons.credit_card_outlined,
          label: 'Numéro de permis',
          value: _value(chauffeur.permis),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.directions_car_outlined,
          label: 'Type de permis',
          value: _value(chauffeur.typePermis),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.calendar_month_outlined,
          label: 'Date d’embauche',
          value: _formatDate(chauffeur.dateEmbauche),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.verified_outlined,
          label: 'Statut',
          value: _displayStatus(chauffeur.statut),
          valueColor: _getStatusColor(chauffeur.statut),
        ),
      ],
    );
  }

  // ============================================================
  // CAMION AFFECTE
  // ============================================================

  Widget _buildTruckCard(Chauffeur chauffeur) {
    final truckName = _value(chauffeur.camionActuel);
    final truckType = _value(chauffeur.camionActuelType);
    final hasTruck = truckName != 'Non renseigné' &&
        truckName != 'Aucun camion affecté';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Camion affecté',
            'Véhicule associé à ce chauffeur',
            Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: primaryColor,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTruck ? truckName : 'Aucun camion affecté',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasTruck ? truckType : 'Affectation non disponible',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (hasTruck ? accentColor : warningColor)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    hasTruck ? 'Affecté' : 'Non affecté',
                    style: TextStyle(
                      color: hasTruck ? accentColor : warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics(Chauffeur chauffeur) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final count = isNarrow ? 1 : 3;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isNarrow ? 3.0 : 1.65,
          children: [
            _buildStatistic(
              title: 'Missions effectuées',
              value: '${chauffeur.missionsCount}',
              subtitle: 'Total des missions',
              icon: Icons.route_rounded,
              color: const Color(0xFF3977D5),
            ),
            _buildStatistic(
              title: 'Missions terminées',
              value: '${chauffeur.missionsTermineesCount}',
              subtitle: 'Missions achevées',
              icon: Icons.task_alt_rounded,
              color: accentColor,
            ),
            _buildStatistic(
              title: 'Signalements',
              value: '${chauffeur.signalementsCount}',
              subtitle: 'Signalements enregistrés',
              icon: Icons.report_gmailerrorred_outlined,
              color: dangerColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatistic({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 10,
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
  // SECTIONS ET LIGNES D'INFORMATION
  // ============================================================

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, subtitle, icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mutedColor, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: borderColor,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1D3557).withOpacity(0.025),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: _showEditDialog,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Modifier le profil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showContactDialog,
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: const Text('Contacter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: const BorderSide(color: accentColor),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _showMessage(
              'Le suivi GPS sera disponible lorsque cet écran sera connecté.',
            );
          },
          icon: const Icon(Icons.location_on_outlined, size: 18),
          label: const Text('Suivi GPS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENU D'OPTIONS
  // ============================================================

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Options du profil',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: primaryColor,
                  ),
                  title: const Text('Modifier les informations'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: accentColor,
                  ),
                  title: const Text('Contacter le chauffeur'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showContactDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: mutedColor,
                  ),
                  title: const Text('Historique des activités'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'L’historique sera disponible lorsque cette fonctionnalité sera connectée.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MODIFICATION DU PROFIL
  // ============================================================

  Future<void> _showEditDialog() async {
    final chauffeur = _chauffeur;
    if (chauffeur == null) return;

    final matriculeController =
    TextEditingController(text: chauffeur.matricule ?? '');
    final permisController =
    TextEditingController(text: chauffeur.permis ?? '');
    final typePermisController =
    TextEditingController(text: chauffeur.typePermis ?? '');
    final dateController =
    TextEditingController(text: chauffeur.dateEmbauche ?? '');

    String selectedStatus = _normaliseStatusForApi(chauffeur.statut);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: const Text(
                  'Modifier le profil',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: SizedBox(
                  width: 460,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _editField(
                          controller: matriculeController,
                          label: 'Matricule',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),
                        _editField(
                          controller: permisController,
                          label: 'Numéro de permis',
                          icon: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 14),
                        _editField(
                          controller: typePermisController,
                          label: 'Type de permis',
                          icon: Icons.directions_car_outlined,
                        ),
                        const SizedBox(height: 14),
                        _editField(
                          controller: dateController,
                          label: 'Date d’embauche (AAAA-MM-JJ)',
                          icon: Icons.calendar_month_outlined,
                          hint: '2026-01-15',
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: _editDecoration(
                            'Statut',
                            Icons.verified_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'actif',
                              child: Text('Actif'),
                            ),
                            DropdownMenuItem(
                              value: 'inactif',
                              child: Text('Inactif'),
                            ),
                            DropdownMenuItem(
                              value: 'suspendu',
                              child: Text('Suspendu'),
                            ),
                          ],
                          onChanged: saving
                              ? null
                              : (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: mutedColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                      setDialogState(() => saving = true);

                      try {
                        final token =
                            this.context.read<AuthProvider>().token;

                        if (token == null || token.isEmpty) {
                          throw Exception(
                            'Session expirée. Veuillez vous reconnecter.',
                          );
                        }

                        final int? chauffeurId = chauffeur.id;

                        if (chauffeurId == null) {
                          if (!dialogContext.mounted) return;

                          setDialogState(() => saving = false);

                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Identifiant du chauffeur introuvable.'),
                            ),
                          );
                          return;
                        }

                        await _chauffeurService.updateChauffeur(
                          id: chauffeurId,
                          token: token,
                          matricule: matriculeController.text.trim(),
                          permis: permisController.text.trim(),
                          typePermis:
                          typePermisController.text.trim(),
                          dateEmbauche: dateController.text.trim(),
                          statut: selectedStatus,
                        );

                        if (!mounted) return;

                        Navigator.pop(dialogContext);
                        await _load();

                        if (!mounted) return;

                        _showMessage(
                          'Profil chauffeur mis à jour avec succès.',
                          success: true,
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;

                        setDialogState(() => saving = false);

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                            ),
                            backgroundColor: dangerColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
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
    } finally {
      matriculeController.dispose();
      permisController.dispose();
      typePermisController.dispose();
      dateController.dispose();
    }
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: _editDecoration(label, icon, hint: hint),
    );
  }

  InputDecoration _editDecoration(
      String label,
      IconData icon, {
        String? hint,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: accentColor, size: 21),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 1.5),
      ),
    );
  }

  // ============================================================
  // CONTACT
  // ============================================================

  void _showContactDialog() {
    final chauffeur = _chauffeur;
    if (chauffeur == null) return;

    final phone = chauffeur.telephone?.trim() ?? '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Contacter le chauffeur',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName(chauffeur),
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        phone.isEmpty ? 'Numéro non renseigné' : phone,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Fermer',
                style: TextStyle(color: mutedColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: phone.isEmpty
                  ? null
                  : () async {
                await Clipboard.setData(
                  ClipboardData(text: phone),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                _showMessage(
                  'Numéro copié dans le presse-papiers.',
                  success: true,
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text('Copier le numéro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _fullName(Chauffeur chauffeur) {
    final fullName = chauffeur.nomComplet.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final combined = '${chauffeur.prenom.trim()} ${chauffeur.nom.trim()}'
        .trim();

    return combined.isEmpty ? 'Chauffeur sans nom' : combined;
  }

  String _value(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non renseigné';
    }

    return value.trim();
  }

  String _formatDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Non renseignée';
    }

    // Présente la date sans heure lorsqu'elle provient d'un datetime.
    return date.length >= 10 ? date.substring(0, 10) : date;
  }

  String _normaliseStatusForApi(String? status) {
    final value = status?.trim().toLowerCase() ?? '';

    if (value == 'inactif' || value == 'inactive') return 'inactif';
    if (value == 'suspendu' || value == 'suspended') return 'suspendu';

    return 'actif';
  }

  String _displayStatus(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'actif':
      case 'active':
      case 'en service':
      case 'disponible':
        return 'Actif';

      case 'inactif':
      case 'inactive':
        return 'Inactif';

      case 'suspendu':
      case 'suspended':
        return 'Suspendu';

      default:
        return status == null || status.trim().isEmpty
            ? 'Non défini'
            : status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'actif':
      case 'active':
      case 'en service':
      case 'disponible':
        return accentColor;

      case 'suspendu':
      case 'suspended':
        return dangerColor;

      case 'inactif':
      case 'inactive':
        return warningColor;

      default:
        return mutedColor;
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? accentColor : primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
