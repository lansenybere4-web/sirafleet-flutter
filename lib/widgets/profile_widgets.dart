import 'package:flutter/material.dart';

class ProfileColors {
  static const primary = Color(0xFF1D3557);
  static const accent = Color(0xFF2A9D8F);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFF4A261);
  static const background = Color(0xFFF5F7FA);
  static const text = Color(0xFF243247);
  static const muted = Color(0xFF718096);
  static const border = Color(0xFFE5EAF0);
}

BoxDecoration profileCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: ProfileColors.border),
  boxShadow: [
    BoxShadow(
      color: ProfileColors.primary.withValues(alpha: 0.025),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ],
);

// ───────────────────────── Données ─────────────────────────

class ProfileBadge {
  final IconData icon;
  final String label;
  final Color color;
  const ProfileBadge(this.icon, this.label, this.color);
}

class ProfileDetail {
  final IconData icon;
  final String value;
  const ProfileDetail(this.icon, this.value);
}

class ProfileStat {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const ProfileStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ───────────────────────── Shell (sidebar + barre + corps) ─────────────────────────

class ProfileShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? sidebar;
  final bool loading;
  final String? error;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOptions;
  final Widget Function(bool isDesktop) builder;

  const ProfileShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.sidebar,
    this.loading = false,
    this.error,
    this.onRefresh,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;
          final content = Column(
            children: [
              _topBar(context, isDesktop),
              Expanded(child: _body(isDesktop)),
            ],
          );

          if (isDesktop && sidebar != null) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [sidebar!, Expanded(child: content)],
            );
          }
          return content;
        },
      ),
    );
  }

  Widget _topBar(BuildContext context, bool isDesktop) {
    final showBack = !isDesktop || sidebar == null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 30 : 16,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ProfileColors.border)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded),
              color: ProfileColors.primary,
              tooltip: 'Retour',
            ),
            const SizedBox(width: 8),
          ],
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: ProfileColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: ProfileColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ProfileColors.primary,
                    fontSize: isDesktop ? 21 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ProfileColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Actualiser',
              onPressed: () => onRefresh!(),
              icon: const Icon(Icons.refresh_rounded),
              color: ProfileColors.primary,
            ),
          if (onOptions != null)
            IconButton(
              tooltip: 'Options',
              onPressed: onOptions,
              icon: const Icon(Icons.more_vert_rounded),
              color: ProfileColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _body(bool isDesktop) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: ProfileColors.accent),
      );
    }

    if (error != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: profileCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 54, color: ProfileColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger le profil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ProfileColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ProfileColors.muted, height: 1.5),
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => onRefresh!(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1450),
          child: builder(isDesktop),
        ),
      ),
    );

    if (onRefresh == null) return scroll;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: ProfileColors.accent,
      child: scroll,
    );
  }
}

// ───────────────────────── En-tête ─────────────────────────

class ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? photoUrl;
  final List<ProfileBadge> badges;
  final List<ProfileDetail> details;
  final VoidCallback? onMore;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.badges = const [],
    this.details = const [],
    this.onMore,
  });

  ImageProvider? get _photo {
    final p = photoUrl?.trim();
    if (p == null || p.isEmpty) return null;
    final uri = Uri.tryParse(p);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(p);
    }
    return null; // chemin relatif : nécessite l'URL publique du stockage
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D3557), Color(0xFF294A70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ProfileColors.primary.withValues(alpha: 0.12),
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
            child: _circle(180, 0.045),
          ),
          Positioned(
            right: 70,
            bottom: -70,
            child: _circle(150, 0.035),
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
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 4,
                        ),
                        image: photo == null
                            ? null
                            : DecorationImage(image: photo, fit: BoxFit.cover),
                      ),
                      child: photo == null
                          ? const Icon(Icons.person_rounded,
                          size: 48, color: ProfileColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFFDCE6F2),
                              fontSize: 14,
                            ),
                          ),
                          if (badges.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: badges.map(_badge).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onMore != null)
                      IconButton(
                        onPressed: onMore,
                        tooltip: 'Plus d’options',
                        icon: const Icon(Icons.more_horiz_rounded,
                            color: Colors.white, size: 28),
                      ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(top: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18)),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (int i = 0; i < details.length; i++) ...[
                          if (i > 0) const SizedBox(width: 18),
                          Expanded(child: _detail(details[i])),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );

  Widget _badge(ProfileBadge b) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: b.color.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(b.icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          b.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _detail(ProfileDetail d) => Row(
    children: [
      Icon(d.icon, size: 17, color: const Color(0xFFB8C9DC)),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          d.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );
}

// ───────────────────────── Sections ─────────────────────────

class ProfileSectionTitle extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const ProfileSectionTitle(this.title, this.subtitle, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: ProfileColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ProfileColors.accent, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ProfileColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                    color: ProfileColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte avec titre + lignes d'infos séparées automatiquement par des dividers.
class ProfileSection extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 1, color: ProfileColors.border));
      }
      rows.add(children[i]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title, subtitle, icon),
          const SizedBox(height: 20),
          ...rows,
        ],
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? 'Non renseigné' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ProfileColors.muted, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style:
              const TextStyle(color: ProfileColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? ProfileColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deux sections côte à côte sur desktop, empilées sur mobile.
class ProfileTwoColumns extends StatelessWidget {
  final bool isDesktop;
  final Widget left, right;
  const ProfileTwoColumns({
    super.key,
    required this.isDesktop,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 22),
          Expanded(child: right),
        ],
      );
    }
    return Column(children: [left, const SizedBox(height: 18), right]);
  }
}

// ───────────────────────── Statistiques ─────────────────────────

class ProfileStatsGrid extends StatelessWidget {
  final List<ProfileStat> stats;
  const ProfileStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final count = isNarrow ? 1 : (stats.length >= 3 ? 3 : stats.length);

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isNarrow ? 3.0 : 1.65,
          children: stats.map(_card).toList(),
        );
      },
    );
  }

  Widget _card(ProfileStat s) => Container(
    padding: const EdgeInsets.all(19),
    decoration: profileCardDecoration(),
    child: Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: s.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(s.icon, color: s.color, size: 27),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.value,
                style: const TextStyle(
                  color: ProfileColors.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ProfileColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: ProfileColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── Statut ─────────────────────────

String displayStatus(String? status) {
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
      return status == null || status.trim().isEmpty ? 'Non défini' : status;
  }
}

Color statusColor(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'actif':
    case 'active':
    case 'en service':
    case 'disponible':
      return ProfileColors.accent;
    case 'suspendu':
    case 'suspended':
      return ProfileColors.danger;
    case 'inactif':
    case 'inactive':
      return ProfileColors.warning;
    default:
      return ProfileColors.muted;
  }
}