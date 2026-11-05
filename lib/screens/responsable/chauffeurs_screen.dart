import 'dart:convert';

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
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE8EDF3);
  static const Color secondaryText = Color(0xFF718096);

  final TextEditingController searchController =
  TextEditingController();

  List<Map<String, dynamic>> chauffeurs = [];

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;
  String selectedStatus = 'Tous';

  static const List<String> statusFilters = [
    'Tous',
    'Disponible',
    'En mission',
    'En service',
    'Repos',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChauffeurs();
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  // ============================================================
  // API LARAVEL
  // ============================================================

  Future<void> _loadChauffeurs({bool refresh = false}) async {
    if (refresh) {
      setState(() => isRefreshing = true);
    } else {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final token = context.read<AuthProvider>().token;

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Session expirée. Veuillez vous reconnecter.',
        );
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/chauffeurs'),
        headers: {
          'Accept': 'application/json',
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

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Erreur serveur : ${response.statusCode}';

        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> data = [];

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map) {
        if (decoded['data'] is List) {
          data = decoded['data'];
        } else if (decoded['chauffeurs'] is List) {
          data = decoded['chauffeurs'];
        }
      }

      final loaded = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      setState(() {
        chauffeurs = loaded;
        errorMessage = null;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement chauffeurs : $e');

      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  // ============================================================
  // FILTRAGE ET RECHERCHE
  // ============================================================

  List<Map<String, dynamic>> get filteredChauffeurs {
    final query = searchController.text.trim().toLowerCase();

    return chauffeurs.where((chauffeur) {
      final status = _getStatut(chauffeur);

      final matchesStatus = selectedStatus == 'Tous' ||
          status == selectedStatus;

      final searchable = [
        _getNomComplet(chauffeur),
        _getMatricule(chauffeur),
        _getTelephone(chauffeur),
        _getCamion(chauffeur),
        _getEmail(chauffeur),
        status,
      ].join(' ').toLowerCase();

      return matchesStatus && searchable.contains(query);
    }).toList();
  }

  int _countStatus(String status) {
    return chauffeurs
        .where((chauffeur) => _getStatut(chauffeur) == status)
        .length;
  }

  // ============================================================
  // PAGE PRINCIPALE
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
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_rounded,
            color: primaryColor,
            size: 25,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des chauffeurs',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestionnaire de flotte · SiraFleet',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _iconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualiser la liste',
            onTap: isRefreshing
                ? null
                : () => _loadChauffeurs(refresh: true),
            loading: isRefreshing,
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Responsable',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gestionnaire flotte',
                      style: TextStyle(
                        color: secondaryText,
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

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
          ),
        )
            : Icon(
          icon,
          color: primaryColor,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (errorMessage != null && chauffeurs.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadChauffeurs(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeading(),
                const SizedBox(height: 24),
                _buildStatistics(),
                const SizedBox(height: 28),
                _buildListHeader(),
                const SizedBox(height: 16),
                _buildSearchAndFilters(compact),
                const SizedBox(height: 18),
                if (errorMessage != null) ...[
                  _buildInlineError(),
                  const SizedBox(height: 14),
                ],
                _buildDriverList(compact),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TITRE
  // ============================================================

  Widget _buildPageHeading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chauffeurs',
              style: TextStyle(
                color: primaryColor,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Consultez les chauffeurs et leurs affectations.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        );

        final total = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${chauffeurs.length} chauffeur${chauffeurs.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 15),
              total,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: heading),
            total,
          ],
        );
      },
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1050
            ? 4
            : width >= 540
            ? 2
            : 1;

        const gap = 14.0;
        final cardWidth =
            (width - (gap * (columns - 1))) / columns;

        final stats = [
          _StatData(
            'Total chauffeurs',
            chauffeurs.length,
            Icons.groups_outlined,
            primaryColor,
          ),
          _StatData(
            'Disponibles',
            _countStatus('Disponible'),
            Icons.check_circle_outline_rounded,
            accentColor,
          ),
          _StatData(
            'En mission',
            _countStatus('En mission'),
            Icons.local_shipping_outlined,
            warningColor,
          ),
          _StatData(
            'En repos',
            _countStatus('Repos'),
            Icons.hotel_outlined,
            secondaryText,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: _buildStatCard(stat),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stat.value}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.label,
                  style: const TextStyle(
                    color: secondaryText,
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

  // ============================================================
  // EN-TÊTE DE LISTE
  // ============================================================

  Widget _buildListHeader() {
    final count = filteredChauffeurs.length;

    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Répertoire des chauffeurs',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Identité, coordonnées et statut opérationnel',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1F8),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$count résultat${count > 1 ? 's' : ''}',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECHERCHE ET FILTRES
  // ============================================================

  Widget _buildSearchAndFilters(bool compact) {
    final search = Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Nom, matricule, téléphone ou camion...',
          hintStyle: const TextStyle(
            color: Color(0xFF9AA5B4),
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: secondaryText,
            size: 21,
          ),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
            tooltip: 'Effacer',
            onPressed: searchController.clear,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
      ),
    );

    final filters = DropdownButtonFormField<String>(
      value: selectedStatus,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Statut',
        labelStyle: const TextStyle(
          color: secondaryText,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
      ),
      items: statusFilters.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: primaryColor,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => selectedStatus = value);
        }
      },
    );

    if (compact) {
      return Column(
        children: [
          search,
          const SizedBox(height: 12),
          filters,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 14),
        SizedBox(width: 200, child: filters),
      ],
    );
  }

  // ============================================================
  // LISTE : TABLEAU SUR GRAND ÉCRAN
  // ============================================================

  Widget _buildDriverList(bool compact) {
    final list = filteredChauffeurs;

    if (list.isEmpty) {
      return _buildEmptyState();
    }

    if (compact) {
      return Column(
        children: list.map((chauffeur) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileDriverCard(chauffeur),
          );
        }).toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1050,
          child: Column(
            children: [
              _buildTableHeader(),
              ...List.generate(list.length, (index) {
                final chauffeur = list[index];

                return _buildTableRow(
                  chauffeur,
                  index,
                  index == list.length - 1,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 52,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: _TableHeading('CHAUFFEUR'),
          ),
          Expanded(
            flex: 2,
            child: _TableHeading('MATRICULE'),
          ),
          Expanded(
            flex: 2,
            child: _TableHeading('TÉLÉPHONE'),
          ),
          Expanded(
            flex: 2,
            child: _TableHeading('CAMION'),
          ),
          SizedBox(
            width: 130,
            child: _TableHeading('STATUT'),
          ),
          SizedBox(
            width: 75,
            child: _TableHeading('ACTION'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      Map<String, dynamic> chauffeur,
      int index,
      bool last,
      ) {
    final status = _getStatut(chauffeur);
    final color = _getStatusColor(status);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openProfile(chauffeur),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _buildAvatar(chauffeur, radius: 21),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNomComplet(chauffeur),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _getEmail(chauffeur).isEmpty
                                ? 'Chauffeur SiraFleet'
                                : _getEmail(chauffeur),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _getMatricule(chauffeur),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _getTelephone(chauffeur).isEmpty
                      ? 'Non renseigné'
                      : _getTelephone(chauffeur),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: secondaryText,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _getCamion(chauffeur),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(status, color),
                ),
              ),
              SizedBox(
                width: 75,
                child: IconButton(
                  tooltip: 'Voir le profil',
                  onPressed: () => _openProfile(chauffeur),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: primaryColor,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARTE POUR PETITS ÉCRANS
  // ============================================================

  Widget _buildMobileDriverCard(
      Map<String, dynamic> chauffeur,
      ) {
    final status = _getStatut(chauffeur);
    final color = _getStatusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openProfile(chauffeur),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(chauffeur, radius: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNomComplet(chauffeur),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _getMatricule(chauffeur),
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildStatusBadge(status, color),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, color: borderColor),
              ),
              _buildMobileInfo(
                Icons.phone_outlined,
                'Téléphone',
                _getTelephone(chauffeur).isEmpty
                    ? 'Non renseigné'
                    : _getTelephone(chauffeur),
              ),
              const SizedBox(height: 12),
              _buildMobileInfo(
                Icons.local_shipping_outlined,
                'Camion affecté',
                _getCamion(chauffeur),
              ),
              if (_getEmail(chauffeur).isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMobileInfo(
                  Icons.email_outlined,
                  'E-mail',
                  _getEmail(chauffeur),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openProfile(chauffeur),
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    size: 17,
                  ),
                  label: const Text('Voir le profil'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInfo(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: secondaryText, size: 17),
        const SizedBox(width: 9),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVATAR ET BADGE
  // ============================================================

  Widget _buildAvatar(
      Map<String, dynamic> chauffeur, {
        double radius = 22,
      }) {
    String photo = _getString(
      chauffeur,
      ['photo_url', 'photo', 'avatar', 'image'],
    );

    if (photo.isEmpty && chauffeur['user'] is Map) {
      photo = _getString(
        Map<String, dynamic>.from(chauffeur['user'] as Map),
        ['photo_url'],
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEAF1F8),
      child: Icon(
        Icons.person_rounded,
        color: primaryColor,
        size: radius * 1.15,
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERREURS ET LISTE VIDE
  // ============================================================

  Widget _buildInlineError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: dangerColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage ?? 'Erreur de chargement',
              style: const TextStyle(
                color: dangerColor,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadChauffeurs(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: dangerColor,
              size: 54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les chauffeurs',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadChauffeurs(),
              icon: const Icon(Icons.refresh_rounded),
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

  Widget _buildEmptyState() {
    final searching = searchController.text.trim().isNotEmpty ||
        selectedStatus != 'Tous';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            searching
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            color: const Color(0xFFB0BAC7),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            searching
                ? 'Aucun résultat trouvé'
                : 'Aucun chauffeur enregistré',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            searching
                ? 'Modifiez votre recherche ou choisissez un autre statut.'
                : 'Les chauffeurs enregistrés apparaîtront ici.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),
          if (searching) ...[
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                searchController.clear();
                setState(() => selectedStatus = 'Tous');
              },
              child: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OUVERTURE DU PROFIL
  // ============================================================

  void _openProfile(Map<String, dynamic> chauffeur) {
    final rawId = chauffeur['id'];
    final chauffeurId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    if (chauffeurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’ouvrir le profil : identifiant manquant.',
          ),
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
  // EXTRACTION DES DONNÉES
  // ============================================================

  String _getString(
      Map<String, dynamic> data,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  String _getNomComplet(Map<String, dynamic> chauffeur) {
    final direct = _getString(
      chauffeur,
      ['nomComplet', 'nom_complet'],
    );

    if (direct.isNotEmpty) return direct;

    final directName = _getString(chauffeur, ['name']);
    if (directName.isNotEmpty) return directName;

    final prenom = _getString(
      chauffeur,
      ['prenom', 'first_name', 'firstname'],
    );
    final nom = _getString(
      chauffeur,
      ['nom', 'last_name', 'lastname'],
    );

    final result = '$prenom $nom'.trim();
    if (result.isNotEmpty) return result;

    final user = chauffeur['user'];

    if (user is Map) {
      final userMap = Map<String, dynamic>.from(user);

      final userName = _getString(
        userMap,
        ['nomComplet', 'nom_complet', 'name'],
      );

      if (userName.isNotEmpty) return userName;

      final userPrenom = _getString(
        userMap,
        ['prenom', 'first_name', 'firstname'],
      );
      final userNom = _getString(
        userMap,
        ['nom', 'last_name', 'lastname'],
      );

      final userResult = '$userPrenom $userNom'.trim();
      if (userResult.isNotEmpty) return userResult;
    }

    return 'Chauffeur';
  }

  String _getMatricule(Map<String, dynamic> chauffeur) {
    return _getString(
      chauffeur,
      ['matricule', 'numero_matricule', 'id'],
      fallback: '—',
    );
  }

  String _getTelephone(Map<String, dynamic> chauffeur) {
    final direct = _getString(
      chauffeur,
      ['telephone','num_tel', 'phone', 'tel'],
    );

    if (direct.isNotEmpty) return direct;

    final user = chauffeur['user'];
    if (user is Map) {
      return _getString(
        Map<String, dynamic>.from(user),
        ['num_tel', 'telephone', 'phone', 'tel'],
      );
    }

    return '';
  }

  String _getEmail(Map<String, dynamic> chauffeur) {
    final direct = _getString(chauffeur, ['email']);
    if (direct.isNotEmpty) return direct;

    final user = chauffeur['user'];
    if (user is Map) {
      return _getString(
        Map<String, dynamic>.from(user),
        ['email'],
      );
    }

    return '';
  }

  String _getCamion(Map<String, dynamic> chauffeur) {
    final direct = _getString(
      chauffeur,
      ['camion_matricule', 'vehicule', 'vehicle'],
    );

    if (direct.isNotEmpty) return direct;

    final camion = chauffeur['camion'];

    if (camion is Map) {
      final matricule = _getString(
        Map<String, dynamic>.from(camion),
        ['matricule', 'immatriculation', 'numero'],
      );

      if (matricule.isNotEmpty) return matricule;
    }

    return 'Aucun camion';
  }

  String _getStatut(Map<String, dynamic> chauffeur) {
    final raw = _getString(
      chauffeur,
      ['statut', 'status', 'etat', 'state'],
    ).toLowerCase().trim();

    switch (raw) {
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
        return raw.isEmpty ? 'Non défini' : raw;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En mission':
        return warningColor;
      case 'En service':
        return accentColor;
      case 'Disponible':
        return primaryColor;
      case 'Repos':
        return secondaryText;
      default:
        return dangerColor;
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}

// ============================================================
// COMPOSANTS SIMPLES
// ============================================================

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData(
      this.label,
      this.value,
      this.icon,
      this.color,
      );
}

class _TableHeading extends StatelessWidget {
  final String label;

  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8491A3),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
