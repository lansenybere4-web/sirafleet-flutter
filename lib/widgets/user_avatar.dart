// lib/widgets/user_avatar.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Avatar réutilisable : affiche la photo réseau, ou une icône par défaut
/// si l'URL est vide ou si le chargement échoue.
/// Contrairement à CircleAvatar.backgroundImage, l'erreur est affichée
/// dans la console (debugPrint) au lieu d'être avalée silencieusement.
class UserAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final Color color;

  const UserAvatar({
    super.key,
    required this.url,
    this.radius = 23,
    this.color = const Color(0xFF1D3557),
  });

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.10),
      child: Icon(Icons.person_outline, size: radius, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _fallback();

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          u,
          fit: BoxFit.cover,
          errorBuilder: (_, error, __) {
            debugPrint('UserAvatar : impossible de charger $u -> $error');
            return _fallback();
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: color.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}
