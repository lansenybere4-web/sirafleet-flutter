import '../core/constants.dart';

class MessageSignalementModel {
  final int id;
  final int signalementId;
  final int userId;

  /// texte, vocal, image
  final String type;

  final String? message;
  final String? audioUrl;
  final int? audioDuration;
  final String? imageUrl;
  final bool lu;
  final DateTime createdAt;
  final String userName;

  MessageSignalementModel({
    required this.id,
    required this.signalementId,
    required this.userId,
    required this.type,
    required this.message,
    required this.audioUrl,
    required this.audioDuration,
    required this.imageUrl,
    required this.lu,
    required this.createdAt,
    required this.userName,
  });

  factory MessageSignalementModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    String userName = 'Utilisateur';

    if (user is Map<String, dynamic>) {
      final nom = user['nom']?.toString() ?? '';
      final prenom = user['prenom']?.toString() ?? '';
      userName = '$prenom $nom'.trim();

      if (userName.isEmpty) {
        userName = user['name']?.toString() ?? 'Utilisateur';
      }
    }

    return MessageSignalementModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      signalementId:
      int.tryParse(json['signalement_id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'texte',
      message: json['message']?.toString(),
      // On reconstruit l'URL nous-mêmes à partir du chemin relatif
      // (audio_path / image_path) + AppConstants.mediaBaseUrl, plutôt
      // que de faire confiance à l'URL absolue renvoyée par Laravel
      // (audio_url / image_url), qui dépend de APP_URL côté serveur
      // et peut être injoignable depuis un appareil mobile
      // (localhost/127.0.0.1 au lieu de 10.0.2.2, par exemple).
      audioUrl: _buildMediaUrl(json['audio_path']?.toString()) ??
          json['audio_url']?.toString(),
      audioDuration: int.tryParse(
        json['audio_duration']?.toString() ?? '',
      ),
      imageUrl: _buildMediaUrl(json['image_path']?.toString()) ??
          json['image_url']?.toString(),
      lu: json['lu'] == true,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ) ??
          DateTime.now(),
      userName: userName,
    );
  }

  /*static String? _buildMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;

    final base = AppConstants.mediaBaseUrl;
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;

    return '$base/storage/$cleanPath';
  }*/

  static String? _buildMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;

    final base = AppConstants.mediaBaseUrl;
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;

    return '$base/api/media/$cleanPath'; // passe par MediaController (CORS + bon Content-Type)
  }

  bool isFromMe(int currentUserId) => userId == currentUserId;

  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
