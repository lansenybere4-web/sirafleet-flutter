// lib/widgets/camion_statut_badge.dart
import 'package:flutter/material.dart';

import '../models/camion_model.dart';

/// Badge du statut réel d'un camion (disponible / en mission /
/// en maintenance / en panne) + rappel de la prochaine maintenance
/// programmée. Utilisé côté admin ET côté responsable de flotte.
class CamionStatutBadge extends StatelessWidget {
  final Camion camion;

  const CamionStatutBadge({super.key, required this.camion});

  static (String, Color) info(String statutAffiche) {
    switch (statutAffiche) {
      case 'en_mission':
        return ('En mission', Colors.blue);
      case 'en_panne':
        return ('En panne', const Color(0xFFE63946));
      case 'maintenance':
        return ('En maintenance', Colors.orange);
      default:
        return ('Disponible', const Color(0xFF2A9D8F));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = info(camion.statutAffiche);
    final prevue = camion.prochaineMaintenanceDate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pill(label, color),
        if (prevue != null && !camion.enMaintenance) ...[
          const SizedBox(height: 4),
          _pill(
            'Maintenance prévue le ${formatDateFr(prevue)}',
            Colors.orange,
            icon: Icons.build_outlined,
          ),
        ],
      ],
    );
  }

  Widget _pill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
