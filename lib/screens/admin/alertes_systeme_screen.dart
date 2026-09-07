import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerte_model.dart';
import '../../services/signalement_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_admin.dart';

class AlertesSystemeScreen extends StatefulWidget {
  const AlertesSystemeScreen({
    super.key,
  });

  @override
  State<AlertesSystemeScreen> createState() =>
      _AlertesSystemeScreenState();
}

class _AlertesSystemeScreenState
    extends State<AlertesSystemeScreen> {
  static const Color primaryColor =
  Color(0xFF1D3557);

  static const Color accentColor =
  Color(0xFF2A9D8F);

  static const Color dangerColor =
  Color(0xFFE63946);

  static const Color backgroundColor =
  Color(0xFFF5F7FA);

  final SignalementService _service =
  SignalementService();

  List<AlerteModel> alertes = [];

  bool isLoading = true;

  String? errorMessage;

  String filtreGravite = 'Toutes';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _chargerAlertes();
      },
    );
  }

  Future<void> _chargerAlertes() async {
    try {
      final authProvider =
      context.read<AuthProvider>();

      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage =
          'Session utilisateur introuvable.';
        });

        return;
      }

      final data =
      await _service.getSignalements(token);

      final result = data
          .map(
            (json) => AlerteModel.fromJson(json),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        alertes = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _marquerTraitee(
      AlerteModel alerte,
      ) async {
    try {
      final authProvider =
      context.read<AuthProvider>();

      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        _showMessage(
          'Session utilisateur introuvable.',
        );

        return;
      }

      await _service.updateStatut(
        token,
        alerte.id,
        'Résolu',
      );

      await _chargerAlertes();

      if (!mounted) return;

      _showMessage(
        'Signalement marqué comme traité.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
      );
    }
  }

  Color _colorForGravite(String gravite) {
    switch (gravite) {
      case 'critique':
        return dangerColor;

      case 'importante':
        return Colors.orange;

      case 'info':
        return accentColor;

      default:
        return Colors.grey;
    }
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Icons.car_crash_outlined;

      case 'problème camion':
        return Icons.local_shipping_outlined;

      case 'problème route':
        return Icons.warning_amber_outlined;

      case 'panne':
        return Icons.build_outlined;

      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filtreGravite == 'Toutes'
        ? alertes
        : alertes
        .where(
          (a) =>
      a.gravite == filtreGravite,
    )
        .toList();

    final nouvelles = alertes
        .where(
          (a) => a.statut == 'nouvelle',
    )
        .length;

    final critiques = alertes
        .where(
          (a) => a.gravite == 'critique',
    )
        .length;

    final importantes = alertes
        .where(
          (a) => a.gravite == 'importante',
    )
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(
            selectedIndex: 5,
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _buildContent(
                    filtered,
                    nouvelles,
                    critiques,
                    importantes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      List<AlerteModel> filtered,
      int nouvelles,
      int critiques,
      int importantes,
      ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: dangerColor,
                size: 50,
              ),
              const SizedBox(height: 15),
              const Text(
                'Impossible de charger les alertes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _chargerAlertes,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Réessayer',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertes système',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Supervisez les signalements, incidents et problèmes de la flotte.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.notifications_active_outlined,
                  'Nouvelles',
                  '$nouvelles',
                  primaryColor,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _buildStatCard(
                  Icons.warning_amber_rounded,
                  'Critiques',
                  '$critiques',
                  dangerColor,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _buildStatCard(
                  Icons.info_outline,
                  'Importantes',
                  '$importantes',
                  Colors.orange,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _buildStatCard(
                  Icons.list_alt_outlined,
                  'Total',
                  '${alertes.length}',
                  accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
            ),
            padding:
            const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Liste des alertes',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${filtered.length} résultat(s)',
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(width: 10),

                    IconButton(
                      onPressed: _chargerAlertes,
                      tooltip: 'Actualiser',
                      icon: const Icon(
                        Icons.refresh,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildFilters(),

                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  ...filtered.map(
                        (a) => _buildAlerteItem(a),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: const Row(
        children: [
          Text(
            'Alertes système',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      'Toutes',
      'critique',
      'importante',
      'info',
    ];

    const labels = {
      'Toutes': 'Toutes',
      'critique': 'Critique',
      'importante': 'Importante',
      'info': 'Info',
    };

    return Wrap(
      spacing: 8,
      children: filters.map((f) {
        final selected =
            filtreGravite == f;

        return ChoiceChip(
          label: Text(
            labels[f]!,
          ),
          selected: selected,
          onSelected: (_) {
            setState(() {
              filtreGravite = f;
            });
          },
          selectedColor: primaryColor,
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlerteItem(
      AlerteModel a,
      ) {
    final color =
    _colorForGravite(a.gravite);

    final estTraitee =
        a.statut == 'traitee';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              _iconForType(a.type),
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.type,
                        style:
                        const TextStyle(
                          color:
                          primaryColor,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        color.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          10,
                        ),
                      ),
                      child: Text(
                        a.gravite
                            .toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    if (!estTraitee) ...[
                      const SizedBox(
                        width: 8,
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration:
                        const BoxDecoration(
                          color:
                          dangerColor,
                          shape:
                          BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  a.message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Source : ${a.source}',
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                a.heure,
                style:
                const TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              Text(
                a.date,
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize: 9,
                ),
              ),

              const SizedBox(height: 6),

              if (estTraitee)
                const Text(
                  'Traitée',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.bold,
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () =>
                      _marquerTraitee(a),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    primaryColor,
                    side:
                    const BorderSide(
                      color: primaryColor,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize:
                    Size.zero,
                  ),
                  child: const Text(
                    'Marquer traitée',
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding:
      const EdgeInsets.all(35),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color:
            Colors.grey.shade400,
            size: 50,
          ),

          const SizedBox(height: 10),

          const Text(
            'Aucune alerte',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Aucun signalement ne correspond au filtre sélectionné.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}