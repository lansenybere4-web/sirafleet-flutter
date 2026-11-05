import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerte_model.dart';
import '../../models/camion_details_model.dart';
import '../../models/camion_model.dart';
import '../../models/equipement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/camion_export_service.dart';
import '../../services/camion_service.dart';

class CamionDetailScreen extends StatefulWidget {
  final int camionId;
  final String? matricule;

  const CamionDetailScreen({
    super.key,
    required this.camionId,
    this.matricule,
  });

  @override
  State<CamionDetailScreen> createState() => _CamionDetailScreenState();
}

class _CamionDetailScreenState extends State<CamionDetailScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final CamionService _service = CamionService();

  CamionDetails? _details;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final details = await _service.getCamionDetails(
        widget.camionId,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> _exportExcel() async {
    final d = _details;
    if (d == null || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      await CamionExportService.exporterDetails(d);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export Excel généré avec succès.'),
          backgroundColor: accentColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: dangerColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _details?.camion.matricule ?? widget.matricule ?? 'Camion',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Exporter en Excel',
            onPressed: (_details == null || _isExporting) ? null : _exportExcel,
            icon: _isExporting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null || _details == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 55, color: dangerColor),
              const SizedBox(height: 12),
              Text(_error ?? 'Erreur inconnue.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _details!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  _headerCard(d),
                  const SizedBox(height: 14),
                  _activiteCard(d),
                  const SizedBox(height: 14),
                  _missionCard(d),
                  const SizedBox(height: 14),
                  _carburantCard(d),
                  const SizedBox(height: 14),
                  _equipementsCard(d),
                  const SizedBox(height: 14),
                  _alertesCard(d),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE GÉNÉRIQUE
  // ============================================================

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IDENTITÉ
  // ============================================================

  Widget _headerCard(CamionDetails d) {
    final c = d.camion;

    final (label, color) = d.enMission
        ? ('En mission', Colors.blue)
        : switch (c.statut) {
      'en_circulation' => ('En circulation', Colors.blue),
      'en_panne' => ('En panne', dangerColor),
      'maintenance' => ('Maintenance', Colors.orange),
      _ => ('Disponible', accentColor),
    };

    final marqueModele = [c.marque, c.modele]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' ');

    return _card(
      icon: Icons.local_shipping_rounded,
      title: 'Informations générales',
      trailing: _badge(label, color),
      child: Column(
        children: [
          _infoRow('Matricule', c.matricule),
          _infoRow('Marque / Modèle', marqueModele.isEmpty ? '-' : marqueModele),
          _infoRow('Année de fabrication', c.annee?.toString() ?? '-'),
          _infoRow('Année d’acquisition', c.anneeAcquisition?.toString() ?? '-'),
          _infoRow('Mise en service', formatDateFr(c.dateMiseEnService)),
          _infoRow(
            'Ancienneté',
            c.ancienneteAnnees == null ? '-' : '${c.ancienneteAnnees} an(s)',
          ),
          _infoRow('Kilométrage', '${c.kilometrage.toStringAsFixed(0)} km'),
          _infoRow('Équipements', '${d.equipements.length} installé(s)'),
          _infoRow('Alertes actives', '${d.alertesActives}'),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITÉ (missions + maintenances)
  // ============================================================

  Widget _activiteCard(CamionDetails d) {
    final c = d.camion;

    return _card(
      icon: Icons.insights_rounded,
      title: 'Activité du véhicule',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statTile('Missions (total)', '${c.missionsCount}', Colors.blue),
          _statTile(
            'Missions terminées',
            '${c.missionsTerminees}',
            accentColor,
          ),
          _statTile('Maintenances', '${c.maintenancesCount}', Colors.orange),
          _statTile('Alertes actives', '${d.alertesActives}', dangerColor),
        ],
      ),
    );
  }

  // ============================================================
  // MISSION
  // ============================================================

  Widget _missionCard(CamionDetails d) {
    final m = d.missionActive;

    if (m == null) {
      return _card(
        icon: Icons.route_rounded,
        title: 'Mission',
        trailing: _badge('Aucune mission en cours', Colors.grey),
        child: const Text(
          'Ce camion n’est actuellement affecté à aucune mission en cours.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      );
    }

    final chauffeur = m['chauffeur'];
    final user = chauffeur is Map ? chauffeur['user'] : null;
    final nomChauffeur = (user is Map ? user['name'] : null)?.toString() ?? '-';

    return _card(
      icon: Icons.route_rounded,
      title: 'Mission en cours',
      trailing: _badge('En cours', Colors.blue),
      child: Column(
        children: [
          _infoRow('Référence', m['reference']?.toString() ?? '-'),
          _infoRow(
            'Trajet',
            '${m['origine'] ?? '-'}  →  ${m['destination'] ?? '-'}',
          ),
          _infoRow('Chauffeur', nomChauffeur),
          _infoRow('Démarrée le', _formatIso(m['started_at']?.toString())),
        ],
      ),
    );
  }

  // ============================================================
  // CARBURANT
  // ============================================================

  Widget _carburantCard(CamionDetails d) {
    final mesure = d.derniereMesure;
    final pct = mesure?.niveauPourcentage;
    final ravito = d.dernierRavitaillement;

    final color = pct == null
        ? Colors.grey
        : pct <= 20
        ? dangerColor
        : pct <= 40
        ? Colors.orange
        : accentColor;

    return _card(
      icon: Icons.local_gas_station_rounded,
      title: 'Carburant',
      child: mesure == null
          ? const Text(
        'Aucune mesure de carburant enregistrée.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                pct != null ? '${pct.toStringAsFixed(1)} %' : '-',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              if (mesure.niveauLitres != null)
                Text(
                  '(${mesure.niveauLitres!.toStringAsFixed(1)} L)',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ((pct ?? 0) / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Dernière mesure', _formatDate(mesure.mesureAt)),
          _infoRow('Source', mesure.equipementNom ?? '-'),
          if (ravito != null) ...[
            const Divider(height: 22),
            _infoRow(
              'Dernier ravitaillement',
              '${ravito.quantiteLitres?.toStringAsFixed(1) ?? '-'} L '
                  '• ${_formatDate(ravito.ravitaillementAt)}',
            ),
            _infoRow('Station', ravito.station ?? '-'),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ÉQUIPEMENTS
  // ============================================================

  Widget _equipementsCard(CamionDetails d) {
    return _card(
      icon: Icons.memory_rounded,
      title: 'Équipements installés',
      trailing: Text(
        '${d.equipements.length}',
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      ),
      child: d.equipements.isEmpty
          ? const Text(
        'Aucun équipement associé à ce camion.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      )
          : Column(children: d.equipements.map(_equipementTile).toList()),
    );
  }

  Widget _equipementTile(EquipementModel e) {
    final color = switch (e.statut) {
      'actif' => accentColor,
      'en_panne' => dangerColor,
      'a_remplacer' => Colors.orange,
      _ => Colors.blue,
    };

    final label = switch (e.statut) {
      'actif' => 'Actif',
      'en_panne' => 'En panne',
      'a_remplacer' => 'À remplacer',
      'maintenance' => 'Maintenance',
      _ => e.statut,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.devices, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'N° série : ${e.numeroSerie}'
                      '${e.imei.isNotEmpty ? '  •  IMEI : ${e.imei}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          _badge(label, color),
        ],
      ),
    );
  }

  // ============================================================
  // ALERTES (avec mission)
  // ============================================================

  Widget _alertesCard(CamionDetails d) {
    return _card(
      icon: Icons.warning_amber_rounded,
      title: 'Alertes & signalements',
      trailing: Text(
        '${d.alertes.length}',
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      ),
      child: d.alertes.isEmpty
          ? const Text(
        'Aucune alerte pour ce camion.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      )
          : Column(children: d.alertes.map(_alerteTile).toList()),
    );
  }

  Widget _alerteTile(AlerteModel a) {
    final color = a.gravite == 'critique'
        ? dangerColor
        : a.gravite == 'importante'
        ? Colors.orange
        : primaryColor;

    final statutColor = switch (a.statut) {
      'Nouveau' => dangerColor,
      'En cours' => const Color(0xFFF4A261),
      _ => accentColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.type,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              _badge(a.statut, statutColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            a.message.isEmpty ? 'Aucune description.' : a.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 13,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                a.missionReference ?? 'Mission inconnue',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${a.date} ${a.heure}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final l = date.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(l.day)}/${p(l.month)}/${l.year} à ${p(l.hour)}:${p(l.minute)}';
  }

  String _formatIso(String? iso) {
    if (iso == null) return '-';
    return _formatDate(DateTime.tryParse(iso));
  }
}
