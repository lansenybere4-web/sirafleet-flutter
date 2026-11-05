import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chauffeur_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';
import '../../services/user_export_service.dart';
import '../../widgets/chauffeur_pro_sections.dart';
import '../../widgets/profile_widgets.dart';

class ProfilUtilisateurScreen extends StatefulWidget {
  final UserModel utilisateur;

  /// Sidebar affichée sur desktop (ex : const SidebarAdmin(selectedIndex: 1)).
  final Widget? sidebar;

  const ProfilUtilisateurScreen({
    super.key,
    required this.utilisateur,
    this.sidebar,
  });

  @override
  State<ProfilUtilisateurScreen> createState() =>
      _ProfilUtilisateurScreenState();
}

class _ProfilUtilisateurScreenState extends State<ProfilUtilisateurScreen> {
  final ChauffeurService _chauffeurService = ChauffeurService();

  Chauffeur? _chauffeur;
  bool _loading = false;
  String? _chauffeurError;

  UserModel get u => widget.utilisateur;

  String get _nomComplet => u.fullName.isEmpty ? 'Utilisateur' : u.fullName;

  bool get _estChauffeur => u.role.toLowerCase().trim().contains('chauffeur');

  bool get _estActif => u.statut.toLowerCase().trim() == 'actif';

  bool get _aFicheChauffeur => u.chauffeurId != null;

  @override
  void initState() {
    super.initState();
    if (_estChauffeur && _aFicheChauffeur) {
      _loadChauffeur();
    }
  }

  // ============================================================
  // CHARGEMENT DE LA FICHE CHAUFFEUR
  // ============================================================

  Future<void> _loadChauffeur() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _chauffeurError = null;
    });

    try {
      final token = context.read<AuthProvider>().token;

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      final chauffeur = await _chauffeurService.getChauffeurById(
        u.chauffeurId!,
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
        _chauffeurError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> _exporter() async {
    try {
      await UserExportService.exporter(
        [u],
        fileName: 'profil_${u.nom}_${u.prenom}'.replaceAll(' ', '_'),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export Excel généré.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      title: 'Profil utilisateur',
      subtitle: 'Informations personnelles et compte',
      icon: Icons.account_circle_outlined,
      sidebar: widget.sidebar,
      // Le profil de base s'affiche toujours, même si la fiche chauffeur
      // est en cours de chargement ou en erreur.
      loading: false,
      error: null,
      onRefresh: (_estChauffeur && _aFicheChauffeur) ? _loadChauffeur : null,
      builder: _buildContent,
    );
  }

  Widget _buildContent(bool isDesktop) {
    final c = _chauffeur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // EN-TÊTE
        // ------------------------------------------------------
        ProfileHeader(
          name: _nomComplet,
          subtitle: _estChauffeur
              ? 'Chauffeur professionnel'
              : (u.role.isEmpty ? 'Utilisateur' : u.role),
          photoUrl: u.photoProfil,
          badges: [
            ProfileBadge(
              Icons.verified_user_outlined,
              _estActif ? 'Compte actif' : 'Compte inactif',
              _estActif ? ProfileColors.accent : ProfileColors.danger,
            ),
            if (u.role.isNotEmpty)
              ProfileBadge(
                Icons.admin_panel_settings_outlined,
                u.role,
                Colors.white.withValues(alpha: 0.16),
              ),
          ],
          details: [
            ProfileDetail(
              Icons.phone_outlined,
              u.numTel.isEmpty ? 'Téléphone non renseigné' : u.numTel,
            ),
            ProfileDetail(
              Icons.mail_outline_rounded,
              u.email.isEmpty ? 'Email non renseigné' : u.email,
            ),
            if (u.siteAffectation.isNotEmpty)
              ProfileDetail(
                Icons.business_outlined,
                u.siteAffectation,
              ),
          ],
        ),

        const SizedBox(height: 24),

        // ------------------------------------------------------
        // INFORMATIONS PERSONNELLES + COMPTE
        // ------------------------------------------------------
        ProfileTwoColumns(
          isDesktop: isDesktop,
          left: ProfileSection(
            title: 'Informations personnelles',
            subtitle: 'Identité et coordonnées',
            icon: Icons.contact_page_outlined,
            children: [
              ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'Prénom',
                value: u.prenom,
              ),
              ProfileInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Nom',
                value: u.nom,
              ),
              ProfileInfoRow(
                icon: Icons.email_outlined,
                label: 'Adresse e-mail',
                value: u.email,
              ),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: u.numTel,
              ),
              ProfileInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: u.address,
              ),
            ],
          ),
          right: ProfileSection(
            title: 'Informations du compte',
            subtitle: 'Rôle et statut',
            icon: Icons.manage_accounts_outlined,
            children: [
              ProfileInfoRow(
                icon: Icons.fingerprint,
                label: 'Identifiant',
                value: u.id,
              ),
              ProfileInfoRow(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Rôle',
                value: u.role,
              ),
              ProfileInfoRow(
                icon: Icons.key_outlined,
                label: 'Identifiant du rôle',
                value: u.roleId,
              ),
              ProfileInfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Statut du compte',
                value: u.statut,
                valueColor:
                _estActif ? ProfileColors.accent : ProfileColors.danger,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ------------------------------------------------------
        // AFFECTATION + ACTIVITÉ
        // ------------------------------------------------------
        ProfileTwoColumns(
          isDesktop: isDesktop,
          left: ProfileSection(
            title: 'Affectation',
            subtitle: 'Lieu de travail et ancienneté',
            icon: Icons.business_outlined,
            children: [
              ProfileInfoRow(
                icon: Icons.apartment_outlined,
                label: 'Site d’affectation',
                value: u.siteAffectation.isEmpty
                    ? 'Non renseigné'
                    : u.siteAffectation,
              ),
              ProfileInfoRow(
                icon: Icons.event_outlined,
                label: 'Compte créé le',
                value: (u.createdAt == null || u.createdAt!.isEmpty)
                    ? '—'
                    : u.createdAt!,
              ),
            ],
          ),
          right: ProfileSection(
            title: 'Activité',
            subtitle: 'Missions et incidents',
            icon: Icons.insights_outlined,
            children: [
              ProfileInfoRow(
                icon: Icons.local_shipping_outlined,
                label: 'Missions (total)',
                value: '${u.nbMissions}',
              ),
              ProfileInfoRow(
                icon: Icons.check_circle_outline,
                label: 'Missions terminées',
                value: '${u.nbMissionsTerminees}',
              ),
              ProfileInfoRow(
                icon: Icons.timelapse_outlined,
                label: 'Missions en cours',
                value: '${u.nbMissionsEnCours}',
              ),
              ProfileInfoRow(
                icon: Icons.warning_amber_rounded,
                label: 'Accidents déclarés',
                value: '${u.nbAccidents}',
                valueColor: u.nbAccidents > 0
                    ? ProfileColors.danger
                    : ProfileColors.accent,
              ),
            ],
          ),
        ),

        // ------------------------------------------------------
        // BLOC CHAUFFEUR (un chauffeur est aussi un utilisateur)
        // ------------------------------------------------------
        if (_estChauffeur) ...[
          const SizedBox(height: 22),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: ProfileColors.accent),
              ),
            )
          else if (c != null)
            ChauffeurProSections(chauffeur: c, isDesktop: isDesktop)
          else
            _buildChauffeurUnavailable(),
        ],

        const SizedBox(height: 26),

        // ------------------------------------------------------
        // EXPORT EXCEL
        // ------------------------------------------------------
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exporter,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exporter en Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // RETOUR
        // ------------------------------------------------------
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour à la liste'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProfileColors.primary,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              side: const BorderSide(color: ProfileColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // FICHE CHAUFFEUR INDISPONIBLE
  // ============================================================

  Widget _buildChauffeurUnavailable() {
    final message = !_aFicheChauffeur
        ? 'Aucune fiche chauffeur n’est associée à ce compte.'
        : (_chauffeurError ?? 'Informations chauffeur indisponibles.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: profileCardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: ProfileColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ProfileColors.muted,
                height: 1.5,
              ),
            ),
          ),
          if (_aFicheChauffeur)
            TextButton(
              onPressed: _loadChauffeur,
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}