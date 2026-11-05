import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../models/message_signalement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/push_notification_service.dart';
import '../../services/signalement_service.dart';

class SignalementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> signalement;

  const SignalementDetailScreen({
    super.key,
    required this.signalement,
  });

  @override
  State<SignalementDetailScreen> createState() =>
      _SignalementDetailScreenState();
}

class _SignalementDetailScreenState extends State<SignalementDetailScreen> {
  // ================================================================
  // PALETTE
  // ================================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color primaryDark = Color(0xFF14263F);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color bubbleReceived = Colors.white;

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sendButtonGradient = LinearGradient(
    colors: [accentColor, Color(0xFF238477)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================================================================
  // CONTROLLERS
  // ================================================================

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // ================================================================
  // SERVICES
  // ================================================================

  final SignalementService _signalementService = SignalementService();
  final ImagePicker imagePicker = ImagePicker();

  // ================================================================
  // STATUT
  // ================================================================

  late String statut;
  late int signalementId;

  // ================================================================
  // MESSAGES
  // ================================================================

  List<MessageSignalementModel> messages = [];
  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;
  Timer? refreshTimer;

  // ================================================================
  // ENREGISTREMENT VOCAL
  // ================================================================

  final AudioRecorder audioRecorder = AudioRecorder();
  bool isRecording = false;
  Timer? recordingTimer;
  int recordingSeconds = 0;

  // ================================================================
  // LECTEUR AUDIO
  // ================================================================

  final AudioPlayer audioPlayer = AudioPlayer();
  String? playingAudioUrl;
  bool isPlayingAudio = false;

  // ================================================================
  // INIT
  // ================================================================

 @override
  void initState() {
    super.initState();
    PushNotificationService.instance.clearBadge();

    statut = widget.signalement['statut']?.toString() ?? 'Nouveau';
    signalementId =
        int.tryParse(widget.signalement['id']?.toString() ?? '') ?? 0;

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlayingAudio = state == PlayerState.playing);
    });

    _loadMessages();

    refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadMessages(silent: true);
    });

    audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlayingAudio = state == PlayerState.playing);
    });
  }

  // ================================================================
  // CHARGER LES MESSAGES
  // ================================================================

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non authentifié.');
      }

      final data =
      await _signalementService.getMessages(token, signalementId);

      if (!mounted) return;

      setState(() {
        messages = data;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (!silent) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final signalement = widget.signalement;
    final chauffeur = signalement['chauffeur']?.toString() ?? 'Chauffeur';
    final camion = signalement['camion']?.toString() ?? 'Camion';
    final mission = signalement['mission']?.toString() ?? 'Non définie';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildAppBar(chauffeur, camion, mission),
          _buildSignalementHeader(),
          Expanded(child: _buildMessagesList()),
          _buildActions(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ================================================================
  // APP BAR CUSTOM (DÉGRADÉ)
  // ================================================================

  Widget _buildAppBar(String chauffeur, String camion, String mission) {
    return Container(
      decoration: const BoxDecoration(
        gradient: appBarGradient,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              _buildAvatar(chauffeur, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chauffeur,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$camion • Mission $mission',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => _loadMessages(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {double size = 40}) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.36,
        ),
      ),
    );
  }

  // ================================================================
  // EN-TÊTE SIGNALEMENT
  // ================================================================

  Widget _buildSignalementHeader() {
    final signalement = widget.signalement;
    final type = signalement['type']?.toString() ?? 'Signalement';
    final color = _getTypeColor(type);
    final id = 'SIG-${signalement['id']?.toString() ?? ''}';
    final mission = signalement['mission']?.toString() ?? 'Non renseignée';
    final heure = signalement['heure']?.toString() ?? '--:--';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(
              signalement['icon'] is IconData ? signalement['icon'] : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$id  •  Mission $mission  •  $heure',
                  style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final Color color;
    switch (statut) {
      case 'Nouveau':
        color = dangerColor;
        break;
      case 'En cours':
        color = warningColor;
        break;
      case 'Résolu':
        color = accentColor;
        break;
      default:
        color = primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(statut, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================================================================
  // LISTE DES MESSAGES
  // ================================================================

  Widget _buildMessagesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (errorMessage != null) {
      return _buildStateMessage(
        icon: Icons.wifi_off_rounded,
        color: dangerColor,
        title: 'Connexion impossible',
        subtitle: errorMessage!,
        actionLabel: 'Réessayer',
        onAction: () => _loadMessages(),
      );
    }

    if (messages.isEmpty) {
      return _buildStateMessage(
        icon: Icons.chat_bubble_outline_rounded,
        color: Colors.grey.shade400,
        title: 'Aucun message',
        subtitle: 'La conversation avec ce chauffeur apparaîtra ici.',
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        int.tryParse(authProvider.user?.id?.toString() ?? '') ?? 0;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadMessages(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final fromMe = message.isFromMe(currentUserId);
          final showDateSeparator = index == 0 ||
              !_isSameDay(messages[index - 1].createdAt, message.createdAt);

          Widget bubble;
          switch (message.type) {
            case 'vocal':
              bubble = _buildAudioMessage(message, fromMe);
              break;
            case 'image':
              bubble = _buildImageMessage(message, fromMe);
              break;
            default:
              bubble = _buildTextMessage(message, fromMe);
          }

          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),
              bubble,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final label = _formatDateLabel(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8B95A5), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MESSAGE TEXTE
  // ================================================================

  Widget _buildTextMessage(MessageSignalementModel message, bool fromMe) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: fromMe
              ? const LinearGradient(colors: [primaryColor, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: fromMe ? null : bubbleReceived,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromMe ? 16 : 4),
            bottomRight: Radius.circular(fromMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: (fromMe ? primaryColor : Colors.black).withValues(alpha: fromMe ? 0.20 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.userName,
                  style: const TextStyle(color: primaryColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.message ?? '',
                style: TextStyle(
                  color: fromMe ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.formattedTime,
              style: TextStyle(color: fromMe ? Colors.white70 : Colors.grey, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MESSAGE IMAGE
  // ================================================================

  Widget _buildImageMessage(MessageSignalementModel message, bool fromMe) {
    if (message.imageUrl == null || message.imageUrl!.isEmpty) return const SizedBox();

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: fromMe ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => _openImagePreview(message.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network(
                  message.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      color: Colors.grey.shade100,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                message.formattedTime,
                style: TextStyle(color: fromMe ? Colors.white70 : Colors.grey, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InteractiveViewer(child: Image.network(url)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MESSAGE VOCAL
  // ================================================================

  Widget _buildAudioMessage(MessageSignalementModel message, bool fromMe) {
    final isThisPlaying = isPlayingAudio && playingAudioUrl == message.audioUrl;

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: fromMe
              ? const LinearGradient(colors: [primaryColor, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: fromMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromMe ? 16 : 4),
            bottomRight: Radius.circular(fromMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: (fromMe ? primaryColor : Colors.black).withValues(alpha: fromMe ? 0.20 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleAudio(message.audioUrl),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fromMe ? Colors.white.withValues(alpha: 0.18) : accentColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: fromMe ? Colors.white : accentColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWaveformDots(fromMe, isThisPlaying),
                  const SizedBox(height: 5),
                  Text(
                    message.audioDuration != null ? _formatDuration(message.audioDuration!) : '--:--',
                    style: TextStyle(color: fromMe ? Colors.white70 : Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformDots(bool fromMe, bool animated) {
    final color = fromMe ? Colors.white : primaryColor;
    final heights = [6.0, 12.0, 8.0, 16.0, 10.0, 14.0, 7.0, 11.0, 9.0, 13.0];

    return Row(
      children: heights
          .map(
            (h) => Container(
          width: 2.4,
          height: h,
          margin: const EdgeInsets.only(right: 2.6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: animated ? 0.9 : 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )
          .toList(),
    );
  }

 Future<void> _toggleAudio(String? url) async {
    if (url == null) return;

    try {
      if (isPlayingAudio && playingAudioUrl == url) {
        await audioPlayer.pause();
        return;
      }
      playingAudioUrl = url;
      await audioPlayer.play(UrlSource(url));
    } catch (e) {
      _showError('Impossible de lire ce message vocal : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

 /* Future<void> _toggleAudio(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      // Si l'audio est déjà en cours de lecture -> Pause
      if (isPlayingAudio && playingAudioUrl == url) {
        await audioPlayer.pause();
        setState(() => isPlayingAudio = false);
        return;
      }

      // Si le même audio est en pause -> Reprise
      if (!isPlayingAudio && playingAudioUrl == url && audioPlayer.state == PlayerState.paused) {
        await audioPlayer.resume();
        setState(() => isPlayingAudio = true);
        return;
      }

      // Nouvelle lecture
      await audioPlayer.stop();
      playingAudioUrl = url;

      // S'assurer que le volume est au maximum et jouer en mode mediaPlayer
      await audioPlayer.setVolume(1.0);
      await audioPlayer.play(
        UrlSource(url),
        mode: PlayerMode.mediaPlayer,
      );

      setState(() => isPlayingAudio = true);
    } catch (e) {
      debugPrint('Erreur lecture audio : $e');
      setState(() => isPlayingAudio = false);
      _showError('Impossible de lire ce message vocal : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }*/

  // ================================================================
  // ACTIONS RESPONSABLE
  // ================================================================

  Widget _buildActions() {
    if (statut == 'Résolu') {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
            SizedBox(width: 7),
            Text('Signalement résolu', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          if (statut == 'Nouveau')
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takeInCharge,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Prendre en charge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor, width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (statut == 'Nouveau') const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: sendButtonGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _resolveSignalement,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Marquer résolu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeInCharge() async {
    await _changeStatut('En cours', 'Signalement pris en charge.');
  }

  Future<void> _resolveSignalement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Résoudre le signalement'),
        content: const Text('Voulez-vous vraiment marquer ce signalement comme résolu ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _changeStatut('Résolu', 'Signalement résolu.');
    }
  }

  Future<void> _changeStatut(String newStatut, String successMessage) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      await _signalementService.updateStatut(token, signalementId, newStatut);

      if (!mounted) return;

      setState(() {
        statut = newStatut;
        widget.signalement['statut'] = newStatut;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      _showError('Impossible de modifier le statut.');
    }
  }

  // ================================================================
  // CHAMP DE SAISIE
  // ================================================================

  Widget _buildMessageInput() {
    if (isRecording) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline_rounded, color: dangerColor),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: dangerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _buildPulsingDot(),
                      const SizedBox(width: 9),
                      const Text('Enregistrement...', style: TextStyle(color: dangerColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text(_formatDuration(recordingSeconds), style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _stopRecordingAndSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: dangerColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: dangerColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: isSending ? null : _pickAndSendImage,
              icon: const Icon(Icons.image_outlined, color: primaryColor),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Répondre au chauffeur...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: isSending ? null : _startRecording,
              icon: Icon(Icons.mic_none_rounded, color: primaryColor),
            ),
            GestureDetector(
              onTap: isSending ? null : _sendTextMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: sendButtonGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: isSending
                    ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: dangerColor, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  // ================================================================
  // ENVOI — TEXTE
  // ================================================================

  Future<void> _sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      final message = await _signalementService.sendMessage(token, signalementId, text);

      messageController.clear();

      setState(() {
        messages.add(message);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      _showError('Impossible d’envoyer le message.');
    }
  }

  // ================================================================
  // ENVOI — IMAGE
  // ================================================================

  Future<void> _pickAndSendImage() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) return;

      setState(() => isSending = true);

      if (token == null) throw Exception('Utilisateur non authentifié.');

      final message = await _signalementService.sendImageMessage(token, signalementId, image);

      setState(() {
        messages.add(message);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      _showError('Impossible d’envoyer l’image : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ================================================================
  // ENREGISTREMENT VOCAL
  // ================================================================

  /*Future<void> _startRecording() async {
    if (isRecording) return;

    try {
      final hasPermission = await audioRecorder.hasPermission();
      if (!hasPermission) {
        _showError('L’autorisation du microphone est nécessaire.');
        return;
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/signalement_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );

      setState(() {
        isRecording = true;
        recordingSeconds = 0;
      });

      recordingTimer?.cancel();
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => recordingSeconds++);
      });
    } catch (e) {
      _showError('Impossible de démarrer l’enregistrement.');
    }
  }*/

  Future<void> _startRecording() async {
    if (isRecording) return;

    try {
      final hasPermission = await audioRecorder.hasPermission();
      if (!hasPermission) {
        _showError('L\u2019autorisation du microphone est nécessaire.');
        return;
      }

      final config = kIsWeb
          ? const RecordConfig(encoder: AudioEncoder.opus, bitRate: 128000, sampleRate: 44100)
          : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);

      String path;
      if (kIsWeb) {
        // Ignoré en interne par le package sur le web, mais un argument reste requis.
        path = 'signalement_${DateTime.now().millisecondsSinceEpoch}.webm';
      } else {
        final directory = await getTemporaryDirectory();
        path = '${directory.path}/signalement_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await audioRecorder.start(config, path: path);

      setState(() {
        isRecording = true;
        recordingSeconds = 0;
      });

      recordingTimer?.cancel();
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => recordingSeconds++);
      });
    } catch (e) {
      _showError('Impossible de démarrer l\u2019enregistrement : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!isRecording) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      recordingTimer?.cancel();
      final path = await audioRecorder.stop();

      if (!mounted) return;

      final duration = recordingSeconds;
      setState(() => isRecording = false);

      if (path == null || path.isEmpty || duration < 1) {
        _showError('Le message vocal est trop court.');
        return;
      }

      setState(() => isSending = true);

      if (token == null) throw Exception('Utilisateur non authentifié.');

      final message = await _signalementService.sendVocalMessage(
        token,
        signalementId,
        path,
        duration,
        fileExtension: kIsWeb ? 'webm' : 'm4a',
      );

      setState(() {
        messages.add(message);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        isRecording = false;
        isSending = false;
      });
      _showError('Impossible d’envoyer le message vocal : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      recordingTimer?.cancel();
      await audioRecorder.stop();

      if (!mounted) return;

      setState(() {
        isRecording = false;
        recordingSeconds = 0;
      });
    } catch (e) {
      debugPrint('Erreur annulation audio : $e');
    }
  }

  // ================================================================
  // UTILITAIRES
  // ================================================================

 /* Color _getTypeColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;
      case 'Problème camion':
        return Colors.orange;
      case 'Problème route':
        return Colors.deepOrange;
      case 'Panne':
        return Colors.blueGrey;
      default:
        return primaryColor;
    }
  }*/

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Accident':
        return dangerColor;
      case 'Problème camion':
        return Colors.orange;
      case 'Problème route':
        return Colors.deepOrange;
      case 'Panne':
        return Colors.blueGrey;
      case 'SOS':
        return dangerColor;
      default:
        return primaryColor;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return "Aujourd'hui";
    if (target == today.subtract(const Duration(days: 1))) return 'Hier';

    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];

    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: dangerColor, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    recordingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    audioRecorder.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}