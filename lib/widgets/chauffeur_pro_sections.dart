import 'package:flutter/material.dart';

import '../../models/chauffeur_model.dart';
import 'profile_widgets.dart';

class ChauffeurProSections extends StatelessWidget {
  final Chauffeur chauffeur;
  final bool isDesktop;

  /// Si false, n'affiche pas la section « Informations professionnelles »
  /// (utile si elle est déjà placée dans une colonne à côté de l'identité).
  final bool showProfessionalInfo;

  const ChauffeurProSections({
    super.key,
    required this.chauffeur,
    required this.isDesktop,
    this.showProfessionalInfo = true,
  });

  static String _value(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Non renseigné' : v.trim();

  static String _date(String? d) {
    if (d == null || d.trim().isEmpty) return 'Non renseignée';
    return d.length >= 10 ? d.substring(0, 10) : d;
  }

  /// Section « Informations professionnelles » (exposée pour l'écran chauffeur)
  static Widget professionalInfo(Chauffeur c) {
    return ProfileSection(
      title: 'Informations professionnelles',
      subtitle: 'Permis et situation professionnelle',
      icon: Icons.work_outline_rounded,
      children: [
        ProfileInfoRow(
          icon: Icons.badge_outlined,
          label: 'Matricule',
          value: _value(c.matricule),
        ),
        ProfileInfoRow(
          icon: Icons.credit_card_outlined,
          label: 'Numéro de permis',
          value: _value(c.permis),
        ),
        ProfileInfoRow(
          icon: Icons.directions_car_outlined,
          label: 'Type de permis',
          value: _value(c.typePermis),
        ),
        ProfileInfoRow(
          icon: Icons.calendar_month_outlined,
          label: 'Date d’embauche',
          value: _date(c.dateEmbauche),
        ),
        ProfileInfoRow(
          icon: Icons.verified_outlined,
          label: 'Statut professionnel',
          value: displayStatus(c.statut),
          valueColor: statusColor(c.statut),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showProfessionalInfo) ...[
          professionalInfo(chauffeur),
          const SizedBox(height: 22),
        ],
        _truckCard(),
        const SizedBox(height: 26),
        const ProfileSectionTitle(
          'Activité du chauffeur',
          'Résumé des activités enregistrées',
          Icons.insights_rounded,
        ),
        const SizedBox(height: 16),
        ProfileStatsGrid(
          stats: [
            ProfileStat(
              title: 'Missions effectuées',
              value: '${chauffeur.missionsCount}',
              subtitle: 'Total des missions',
              icon: Icons.route_rounded,
              color: const Color(0xFF3977D5),
            ),
            ProfileStat(
              title: 'Missions terminées',
              value: '${chauffeur.missionsTermineesCount}',
              subtitle: 'Missions achevées',
              icon: Icons.task_alt_rounded,
              color: ProfileColors.accent,
            ),
            ProfileStat(
              title: 'Signalements',
              value: '${chauffeur.signalementsCount}',
              subtitle: 'Signalements enregistrés',
              icon: Icons.report_gmailerrorred_outlined,
              color: ProfileColors.danger,
            ),
          ],
        ),
      ],
    );
  }

  Widget _truckCard() {
    final truckName = _value(chauffeur.camionActuel);
    final truckType = _value(chauffeur.camionActuelType);
    final hasTruck =
        truckName != 'Non renseigné' && truckName != 'Aucun camion affecté';
    final badgeColor = hasTruck ? ProfileColors.accent : ProfileColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSectionTitle(
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
              border: Border.all(color: ProfileColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: ProfileColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: ProfileColors.primary, size: 34),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTruck ? truckName : 'Aucun camion affecté',
                        style: const TextStyle(
                          color: ProfileColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasTruck ? truckType : 'Affectation non disponible',
                        style: const TextStyle(
                            color: ProfileColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    hasTruck ? 'Affecté' : 'Non affecté',
                    style: TextStyle(
                      color: badgeColor,
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
}