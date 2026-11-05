import 'package:flutter/material.dart';

// ============================================================
// COULEURS
// ============================================================

const Color kPrimary = Color(0xFF1D3557);
const Color kAccent = Color(0xFF2A9D8F);
const Color kDanger = Color(0xFFE63946);
const Color kWarning = Color(0xFFF4A261);
const Color kBg = Color(0xFFF5F7FA);

// ============================================================
// FORMATAGE
// ============================================================

/// Texte propre : renvoie [fallback] si null / vide / "null".
String txt(dynamic v, [String fallback = '—']) {
  if (v == null) return fallback;
  final t = v.toString().trim();
  if (t.isEmpty || t.toLowerCase() == 'null') return fallback;
  return t;
}

String _two(int n) => n.toString().padLeft(2, '0');

String fmtDate(dynamic v) {
  final d = DateTime.tryParse(txt(v, ''));
  if (d == null) return txt(v);
  final l = d.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year}';
}

String fmtDateTime(dynamic v) {
  final d = DateTime.tryParse(txt(v, ''));
  if (d == null) return txt(v);
  final l = d.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
}

String withUnit(dynamic v, String unit) {
  final t = txt(v, '');
  return t.isEmpty ? '—' : '$t $unit';
}

String fmtDuration(Duration d) {
  if (d.inMinutes < 1) return '< 1 min';
  return '${d.inHours} h ${_two(d.inMinutes % 60)} min';
}

String fullName(Map? u) {
  if (u == null) return 'Utilisateur';
  final name = '${txt(u['prenom'], '')} ${txt(u['nom'], '')}'.trim();
  return name.isEmpty ? txt(u['name'], 'Utilisateur') : name;
}

String humanizeKey(String key) {
  final t = key.replaceAll('_', ' ').trim();
  if (t.isEmpty) return key;
  return t[0].toUpperCase() + t.substring(1);
}

// ============================================================
// STATUTS / TYPES
// ============================================================

String missionStatutLabel(dynamic raw) {
  switch (txt(raw, '').toLowerCase()) {
    case 'a_venir':
    case 'planifiée':
    case 'planifiee':
      return 'Planifiée';
    case 'en_cours':
    case 'en cours':
      return 'En cours';
    case 'terminee':
    case 'terminée':
      return 'Terminée';
    case 'annulee':
    case 'annulée':
      return 'Annulée';
    default:
      return txt(raw, 'Planifiée');
  }
}

Color missionStatutColor(String label) {
  switch (label) {
    case 'En cours':
      return const Color(0xFF2563EB);
    case 'Terminée':
      return const Color(0xFF059669);
    case 'Annulée':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFFD97706);
  }
}

Color prioriteColor(String p) {
  final l = p.toLowerCase();
  if (l.contains('haut') || l.contains('urgent') || l.contains('critique')) return kDanger;
  if (l.contains('moy') || l.contains('normal')) return kWarning;
  return kAccent;
}

Color signalementStatutColor(String statut) {
  switch (statut) {
    case 'Nouveau':
      return kDanger;
    case 'En cours':
      return kWarning;
    default:
      return kAccent;
  }
}

IconData signalementIcon(String type) {
  switch (type) {
    case 'Accident':
      return Icons.car_crash;
    case 'Problème camion':
      return Icons.local_shipping;
    case 'Problème route':
      return Icons.warning_amber;
    case 'Panne':
      return Icons.build;
    case 'SOS':
      return Icons.sos;
    default:
      return Icons.report_problem;
  }
}

Color signalementColor(String type) {
  switch (type) {
    case 'Accident':
    case 'SOS':
      return kDanger;
    case 'Problème camion':
      return Colors.orange;
    case 'Problème route':
      return Colors.deepOrange;
    case 'Panne':
      return Colors.blueGrey;
    default:
      return kPrimary;
  }
}

// ============================================================
// SIGNALEMENT BRUT (API) -> MAP ATTENDU PAR SignalementDetailScreen
// ------------------------------------------------------------
// Corrige au passage les clés réelles : le camion a "matricule"
// (pas "immatriculation"/"numero") et l'utilisateur a "nom"/"prenom"
// (pas "name"). On ajoute aussi mission_id / chauffeur_id / user_id
// pour pouvoir naviguer vers la mission et le compte.
// ============================================================

Map<String, dynamic> signalementToMap(Map raw, {Map? fallbackMission}) {
  final chauffeur = raw['chauffeur'] is Map ? raw['chauffeur'] as Map : null;
  final user = chauffeur != null && chauffeur['user'] is Map
      ? chauffeur['user'] as Map
      : null;
  final camion = raw['camion'] is Map ? raw['camion'] as Map : null;
  final mission = raw['mission'] is Map ? raw['mission'] as Map : fallbackMission;

  final dt = DateTime.tryParse(
    txt(raw['date_signalement'] ?? raw['created_at'], ''),
  )?.toLocal();

  final type = txt(raw['type'], 'Autre');

  return {
    'id': raw['id'],
    'type': type,
    'statut': txt(raw['statut'], 'Nouveau'),
    'message': txt(raw['description'], 'Aucune description.'),
    'latitude': raw['latitude'],
    'longitude': raw['longitude'],
    'messages_count': raw['messages_count'],

    // Qui / quoi
    'chauffeur': user != null ? fullName(user) : 'Chauffeur inconnu',
    'chauffeur_id': raw['chauffeur_id'] ?? chauffeur?['id'],
    'user_id': user?['id'] ?? chauffeur?['user_id'],
    'camion': txt(camion?['matricule'] ?? camion?['immatriculation'], 'Camion inconnu'),
    'mission': txt(mission?['reference'] ?? raw['mission_id'], 'N/A'),
    'mission_id': raw['mission_id'] ?? mission?['id'],

    // Date
    'heure': dt != null ? '${_two(dt.hour)}:${_two(dt.minute)}' : '--:--',
    'date': dt != null ? '${_two(dt.day)}/${_two(dt.month)}/${dt.year}' : 'Date inconnue',
    'dateTime': dt,
    'icon': signalementIcon(type),
  };
}

// ============================================================
// WIDGETS
// ============================================================

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? badge;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(icon, color: kPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontSize: 12.5,
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
}

class StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatBox({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Ligne cliquable (mission, alerte, message, personne...).
class LinkTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const LinkTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kDanger, size: 44),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
