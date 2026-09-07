import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_responsable.dart';
import 'profil_chauffeur_screen.dart';

class ChauffeursScreen extends StatefulWidget {
  const ChauffeursScreen({super.key});

  @override
  State<ChauffeursScreen> createState() => _ChauffeursScreenState();
}

class _ChauffeursScreenState extends State<ChauffeursScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  // ============================================================
  // DONNÉES
  // ============================================================

  List<Map<String, dynamic>> chauffeurs = [];

  bool isLoading = true;
  bool isRefreshing = false;

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // On attend le premier frame pour pouvoir lire l'AuthProvider
    // via context.read() en toute sécurité.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChauffeurs();
    });
  }

  // ============================================================
  // CHARGEMENT API
  // ============================================================

  Future<void> _loadChauffeurs({
    bool refresh = false,
  }) async {
    if (refresh) {
      if (mounted) {
        setState(() {
          isRefreshing = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }
    }

    try {
      // --------------------------------------------------------
      // TOKEN
      // --------------------------------------------------------

      final token = context.read<AuthProvider>().token;

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/chauffeurs',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'GET /chauffeurs -> ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data = [];

        // Laravel peut retourner :
        //
        // [
        //   {...},
        //   {...}
        // ]
        //
        // ou :
        //
        // {
        //   "data": [...]
        // }
        //
        // ou :
        //
        // {
        //   "chauffeurs": [...]
        // }

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['chauffeurs'] is List) {
            data = decoded['chauffeurs'];
          }
        }

        final List<Map<String, dynamic>> loadedChauffeurs = [];

        for (final item in data) {
          if (item is Map) {
            loadedChauffeurs.add(
              Map<String, dynamic>.from(item),
            );
          }
        }

        if (!mounted) return;

        setState(() {
          chauffeurs = loadedChauffeurs;
          errorMessage = null;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        String message =
            'Erreur serveur : ${response.statusCode}';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {
          // corps de réponse non JSON, on garde le message par défaut
        }

        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Erreur chargement chauffeurs : $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  List<Map<String, dynamic>> get filteredChauffeurs {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return chauffeurs;
    }

    return chauffeurs.where((chauffeur) {
      final nom = _getNomComplet(chauffeur).toLowerCase();

      final id = _getString(
        chauffeur,
        [
          'id',
          'matricule',
          'numero_matricule',
        ],
      ).toLowerCase();

      final telephone = _getString(
        chauffeur,
        [
          'telephone',
          'phone',
          'tel',
        ],
      ).toLowerCase();

      final camion = _getCamion(chauffeur).toLowerCase();

      final statut = _getStatut(chauffeur).toLowerCase();

      final email = _getString(
        chauffeur,
        ['email'],
      ).toLowerCase();

      return nom.contains(query) ||
          id.contains(query) ||
          telephone.contains(query) ||
          camion.contains(query) ||
          statut.contains(query) ||
          email.contains(query);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const ResponsableSidebar(
            current: ResponsableMenuItem.chauffeurs,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU PRINCIPAL
  // ============================================================

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadChauffeurs(
        refresh: true,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chauffeurs',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Gestion et suivi des chauffeurs',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ACTUALISER
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Actualiser',
              onPressed: isRefreshing
                  ? null
                  : () {
                _loadChauffeurs(
                  refresh: true,
                );
              },
              icon: isRefreshing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              )
                  : const Icon(
                Icons.refresh,
                color: primaryColor,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // NOTIFICATIONS
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: dangerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          // PROFIL RESPONSABLE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                SizedBox(width: 9),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responsable',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestionnaire flotte',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildContent() {
    final liste = filteredChauffeurs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liste des chauffeurs',
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Consultez les informations, affectations et performances des chauffeurs.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 25),

        _buildStatistics(),

        const SizedBox(height: 25),

        _buildSearch(),

        const SizedBox(height: 20),

        Row(
          children: [
            const Text(
              'Chauffeurs',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${liste.length}',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        if (errorMessage != null)
          _buildErrorState()
        else if (liste.isEmpty)
          _buildEmptyState()
        else
          ...liste.map(
                (chauffeur) => _buildChauffeurCard(
              chauffeur,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics() {
    final total = chauffeurs.length;

    final actifs = chauffeurs.where((e) {
      final statut = _getStatut(e);

      return statut == 'En service' ||
          statut == 'En mission';
    }).length;

    final disponibles = chauffeurs.where((e) {
      return _getStatut(e) == 'Disponible';
    }).length;

    final repos = chauffeurs.where((e) {
      return _getStatut(e) == 'Repos';
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              SizedBox(
                width: _responsiveStatWidth(
                  constraints.maxWidth,
                ),
                child: _buildStatCard(
                  icon: Icons.people_alt_outlined,
                  value: '$total',
                  label: 'Total chauffeurs',
                  color: primaryColor,
                ),
              ),
              SizedBox(
                width: _responsiveStatWidth(
                  constraints.maxWidth,
                ),
                child: _buildStatCard(
                  icon: Icons.local_shipping_outlined,
                  value: '$actifs',
                  label: 'Actifs',
                  color: accentColor,
                ),
              ),
              SizedBox(
                width: _responsiveStatWidth(
                  constraints.maxWidth,
                ),
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  value: '$disponibles',
                  label: 'Disponibles',
                  color: warningColor,
                ),
              ),
              SizedBox(
                width: _responsiveStatWidth(
                  constraints.maxWidth,
                ),
                child: _buildStatCard(
                  icon: Icons.airline_seat_flat_outlined,
                  value: '$repos',
                  label: 'En repos',
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_alt_outlined,
                value: '$total',
                label: 'Total chauffeurs',
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_shipping_outlined,
                value: '$actifs',
                label: 'Actifs',
                color: accentColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                value: '$disponibles',
                label: 'Disponibles',
                color: warningColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                icon: Icons.airline_seat_flat_outlined,
                value: '$repos',
                label: 'En repos',
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }

  double _responsiveStatWidth(double width) {
    if (width < 550) {
      return width;
    }

    return (width - 15) / 2;
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
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
  // RECHERCHE
  // ============================================================

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText:
          'Rechercher par nom, matricule, camion, téléphone ou statut...',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: primaryColor,
            size: 21,
          ),
          suffixIcon:
          searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();
            },
            icon: const Icon(
              Icons.clear,
              size: 19,
            ),
          )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // CARTE CHAUFFEUR
  // ============================================================

  Widget _buildChauffeurCard(
      Map<String, dynamic> chauffeur,
      ) {
    final statut = _getStatut(chauffeur);

    final statusColor = _getStatusColor(
      statut,
    );

    final missions = _getInt(
      chauffeur,
      [
        'missions',
        'missions_count',
        'nombre_missions',
      ],
    );

    final missionsTerminees = _getInt(
      chauffeur,
      [
        'missionsTerminees',
        'missions_terminees',
        'missions_completed',
        'missions_terminees_count',
      ],
    );

    final signalements = _getInt(
      chauffeur,
      [
        'signalements',
        'signalements_count',
        'nombre_signalements',
      ],
    );

    final progression = missions == 0
        ? 0.0
        : (missionsTerminees / missions)
        .clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openProfile(chauffeur);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return _buildCompactDriverCard(
                  chauffeur,
                  statut,
                  statusColor,
                  missions,
                  missionsTerminees,
                  signalements,
                  progression,
                );
              }

              return _buildDesktopDriverCard(
                chauffeur,
                statut,
                statusColor,
                missions,
                missionsTerminees,
                signalements,
                progression,
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARTE DESKTOP
  // ============================================================

  Widget _buildDesktopDriverCard(
      Map<String, dynamic> chauffeur,
      String statut,
      Color statusColor,
      int missions,
      int missionsTerminees,
      int signalements,
      double progression,
      ) {
    return Row(
      children: [
        _buildDriverAvatar(chauffeur),

        const SizedBox(width: 15),

        Expanded(
          flex: 3,
          child: _buildDriverInfo(
            chauffeur,
          ),
        ),

        Expanded(
          flex: 2,
          child: _buildMissionInfo(
            missions,
            missionsTerminees,
            progression,
          ),
        ),

        Expanded(
          flex: 2,
          child: _buildSignalementInfo(
            signalements,
          ),
        ),

        SizedBox(
          width: 120,
          child: _buildStatusInfo(
            statut,
            statusColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARTE COMPACTE
  // ============================================================

  Widget _buildCompactDriverCard(
      Map<String, dynamic> chauffeur,
      String statut,
      Color statusColor,
      int missions,
      int missionsTerminees,
      int signalements,
      double progression,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDriverAvatar(chauffeur),

            const SizedBox(width: 15),

            Expanded(
              child: _buildDriverInfo(
                chauffeur,
              ),
            ),

            const SizedBox(width: 10),

            _buildStatusInfo(
              statut,
              statusColor,
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _buildMissionInfo(
                missions,
                missionsTerminees,
                progression,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: _buildSignalementInfo(
                signalements,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // INFORMATIONS CHAUFFEUR
  // ============================================================

  Widget _buildDriverInfo(
      Map<String, dynamic> chauffeur,
      ) {
    final nom = _getNomComplet(chauffeur);

    final id = _getString(
      chauffeur,
      [
        'matricule',
        'numero_matricule',
        'id',
      ],
      fallback: '—',
    );

    final camion = _getCamion(chauffeur);

    final telephone = _getString(
      chauffeur,
      [
        'telephone',
        'phone',
        'tel',
      ],
      fallback: '—',
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          nom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '$id • $camion',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 7),

        Row(
          children: [
            Icon(
              Icons.phone_outlined,
              size: 13,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                telephone,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MISSIONS
  // ============================================================

  Widget _buildMissionInfo(
      int missions,
      int missionsTerminees,
      double progression,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'MISSIONS',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '$missions',
          style: const TextStyle(
            color: primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          '$missionsTerminees terminées',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 9,
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: progression,
            minHeight: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor:
            const AlwaysStoppedAnimation<Color>(
              accentColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SIGNALEMENTS
  // ============================================================

  Widget _buildSignalementInfo(
      int signalements,
      ) {
    final color = signalements > 0
        ? dangerColor
        : accentColor;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'SIGNALEMENTS',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: color,
              size: 18,
            ),

            const SizedBox(width: 6),

            Text(
              '$signalements',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STATUT
  // ============================================================

  Widget _buildStatusInfo(
      String statut,
      Color statusColor,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: Text(
            statut,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profil',
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios,
              color: primaryColor,
              size: 12,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildDriverAvatar(
      Map<String, dynamic> chauffeur,
      ) {
    final photo = _getString(
      chauffeur,
      [
        'photo',
        'photo_url',
        'avatar',
        'image',
      ],
    );

    if (photo.isNotEmpty) {
      return CircleAvatar(
        radius: 29,
        backgroundColor:
        primaryColor.withValues(
          alpha: 0.10,
        ),
        backgroundImage: NetworkImage(photo),
      );
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: 0.10,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: primaryColor,
        size: 31,
      ),
    );
  }

  // ============================================================
// OUVERTURE PROFIL
// ============================================================

  void _openProfile(
      Map<String, dynamic> chauffeur,
      ) {
    final dynamic rawId = chauffeur['id'];

    final int? chauffeurId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    if (chauffeurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\u2019ouvrir ce profil : identifiant manquant.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilChauffeurScreen(
          chauffeurId: chauffeurId,
        ),
      ),
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: dangerColor.withValues(
              alpha: 0.7,
            ),
            size: 55,
          ),

          const SizedBox(height: 15),

          const Text(
            'Impossible de charger les chauffeurs',
            style: TextStyle(
              color: primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 7),

          Text(
            errorMessage ??
                'Une erreur est survenue.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              _loadChauffeurs();
            },
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text(
              'Réessayer',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    final recherche =
    searchController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            recherche.isNotEmpty
                ? Icons.person_search_outlined
                : Icons.people_outline,
            color: Colors.grey.shade400,
            size: 60,
          ),

          const SizedBox(height: 15),

          Text(
            recherche.isNotEmpty
                ? 'Aucun chauffeur trouvé'
                : 'Aucun chauffeur enregistré',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            recherche.isNotEmpty
                ? 'Essayez une autre recherche.'
                : 'Les chauffeurs enregistrés apparaîtront ici.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITAIRE STRING
  // ============================================================

  String _getString(
      Map<String, dynamic> data,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // UTILITAIRE INT
  // ============================================================

  int _getInt(
      Map<String, dynamic> data,
      List<String> keys, {
        int fallback = 0,
      }) {
    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      if (value != null) {
        final parsed =
        int.tryParse(value.toString());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return fallback;
  }

  // ============================================================
  // NOM COMPLET
  // ============================================================

  String _getNomComplet(
      Map<String, dynamic> chauffeur,
      ) {
    // Cas :
    // "nomComplet": "Mamadou Traoré"

    final nomComplet = _getString(
      chauffeur,
      [
        'nomComplet',
        'nom_complet',
      ],
    );

    if (nomComplet.isNotEmpty) {
      return nomComplet;
    }

    // Cas :
    // "nom": "Traoré",
    // "prenom": "Mamadou"

    final nom = _getString(
      chauffeur,
      [
        'nom',
        'last_name',
        'lastname',
      ],
    );

    final prenom = _getString(
      chauffeur,
      [
        'prenom',
        'first_name',
        'firstname',
      ],
    );

    final resultat =
    '$prenom $nom'.trim();

    if (resultat.isNotEmpty) {
      return resultat;
    }

    // Cas :
    // "user": {...}

    final user = chauffeur['user'];

    if (user is Map) {
      final userMap =
      Map<String, dynamic>.from(user);

      final userNomComplet =
      _getString(
        userMap,
        [
          'nomComplet',
          'nom_complet',
          'name',
        ],
      );

      if (userNomComplet.isNotEmpty) {
        return userNomComplet;
      }

      final userNom = _getString(
        userMap,
        [
          'nom',
          'last_name',
          'lastname',
        ],
      );

      final userPrenom = _getString(
        userMap,
        [
          'prenom',
          'first_name',
          'firstname',
        ],
      );

      final userResultat =
      '$userPrenom $userNom'.trim();

      if (userResultat.isNotEmpty) {
        return userResultat;
      }
    }

    return 'Chauffeur';
  }

  // ============================================================
  // CAMION
  // ============================================================

  String _getCamion(
      Map<String, dynamic> chauffeur,
      ) {
    final camionDirect = _getString(
      chauffeur,
      [
        'camion_matricule',
        'camion_id',
        'vehicule',
        'vehicle',
      ],
    );

    if (camionDirect.isNotEmpty) {
      return camionDirect;
    }

    final camion = chauffeur['camion'];

    if (camion is Map) {
      final camionMap =
      Map<String, dynamic>.from(camion);

      final matricule = _getString(
        camionMap,
        [
          'matricule',
          'immatriculation',
          'numero',
          'id',
        ],
      );

      if (matricule.isNotEmpty) {
        return matricule;
      }
    }

    return 'Aucun camion';
  }

  // ============================================================
  // STATUT
  // ============================================================

  String _getStatut(
      Map<String, dynamic> chauffeur,
      ) {
    final statut = _getString(
      chauffeur,
      [
        'statut',
        'status',
        'etat',
        'state',
      ],
    );

    if (statut.isEmpty) {
      return 'Disponible';
    }

    switch (statut.toLowerCase().trim()) {
      case 'active':
      case 'actif':
      case 'en service':
        return 'En service';

      case 'mission':
      case 'en mission':
        return 'En mission';

      case 'available':
      case 'disponible':
        return 'Disponible';

      case 'rest':
      case 'repos':
        return 'Repos';

      default:
        return statut;
    }
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color _getStatusColor(
      String statut,
      ) {
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}