import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/constants.dart';
import '../../models/message_signalement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chauffeur_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/signalement_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AlertesScreen extends StatefulWidget {
  final Map<String, dynamic>? mission;

  const AlertesScreen({super.key, this.mission});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  // ================================================================
  // PALETTE
  // ================================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color primaryDark = Color(0xFF14263F);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF4F6F9);

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
  // CONTROLLERS / SERVICES
  // ================================================================

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker imagePicker = ImagePicker();
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  final SignalementService _signalementService = SignalementService();

  // ================================================================
  // ÉTAT VOCAL
  // ================================================================

  bool isRecording = false;
  Timer? recordingTimer;
  int recordingSeconds = 0;

  // ================================================================
  // ÉTAT AUDIO PLAYBACK
  // ================================================================

  String? playingAudioUrl;
  bool isPlayingAudio = false;

  // ================================================================
  // ÉTAT SIGNALEMENT / MESSAGES
  // ================================================================

  int? signalementId;
  List<MessageSignalementModel> messages = [];
  bool isLoading = false;
  bool isSending = false;
  Timer? refreshTimer;

  // ================================================================
  // CONTEXTE CHAUFFEUR / MISSION / CAMION (auto-récupéré)
  // ================================================================

  final ChauffeurService _chauffeurService = ChauffeurService();

  bool isLoadingContext = true;
  String? contextError;

  int? missionId;
  int? chauffeurId;
  int? camionId;
  String truck = 'Camion';
  String missionStatus = '';

// ================================================================
// INIT
// ================================================================
  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.clearBadge();

    // 1. Écoute des changements d'état du lecteur
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlayingAudio = state == PlayerState.playing);
    });

    // 2. Configuration explicite du routage vers le HAUT-PARLEUR EXTERNE
    audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true, // Forcer le haut-parleur externe
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback, // Contourne le mode silencieux/vibreur
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContext();
    });
  }



  // ================================================================
  // CHARGER LE CONTEXTE (chauffeur / mission / camion)
  // ================================================================

  Future<void> _loadContext() async {
    // Si une mission a été explicitement passée (ancien usage), on
    // l'utilise directement — sinon on va la chercher nous-mêmes,
    // comme le fait ChauffeurHomeScreen.
    if (widget.mission != null) {
      final mission = widget.mission!;
      final chauffeur = mission['chauffeur'];
      final camion = mission['camion'];

      setState(() {
        missionId = int.tryParse(mission['id']?.toString() ?? '');
        chauffeurId = chauffeur is Map
            ? int.tryParse(chauffeur['id']?.toString() ?? '')
            : int.tryParse(mission['chauffeur_id']?.toString() ?? '');
        camionId = camion is Map
            ? int.tryParse(camion['id']?.toString() ?? '')
            : int.tryParse(mission['camion_id']?.toString() ?? '');
        truck = mission['camion']?.toString() ?? 'Camion';
        missionStatus = mission['statut']?.toString() ?? '';
        isLoadingContext = false;
      });

      await _loadExistingSignalement();
      return;
    }

    setState(() {
      isLoadingContext = true;
      contextError = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      if (token == null || token.isEmpty) {
        throw Exception('Session utilisateur introuvable.');
      }

      final response = await _chauffeurService.getMyChauffeur(token);

      final rawData = response['data'];
      final data = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

      final rawChauffeur = data['chauffeur'];
      final rawMission = data['mission'];
      final rawCamion = data['camion'];

      final chauffeur = rawChauffeur is Map ? Map<String, dynamic>.from(rawChauffeur) : null;
      final mission = rawMission is Map ? Map<String, dynamic>.from(rawMission) : null;
      final camion = rawCamion is Map ? Map<String, dynamic>.from(rawCamion) : null;

      if (!mounted) return;

      setState(() {
        chauffeurId = int.tryParse(chauffeur?['id']?.toString() ?? '');
        missionId = int.tryParse(mission?['id']?.toString() ?? '');
        camionId = int.tryParse(camion?['id']?.toString() ?? '');
        truck = camion?['immatriculation']?.toString() ??
            camion?['matricule']?.toString() ??
            mission?['camion']?.toString() ??
            'Camion';
        missionStatus = mission?['statut']?.toString() ?? '';
        isLoadingContext = false;
      });

      await _loadExistingSignalement();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingContext = false;
        contextError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ================================================================
  // RETROUVER UN SIGNALEMENT DÉJÀ EXISTANT POUR CETTE MISSION
  // (pour ne pas perdre la conversation en quittant l'écran)
  // ================================================================

  Future<void> _loadExistingSignalement() async {
    if (missionId == null) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null || token.isEmpty) return;

      final all = await _signalementService.getSignalements(token);

      // La liste est déjà triée du plus récent au plus ancien côté
      // API (orderBy date_signalement desc) : on prend le premier
      // signalement qui correspond à la mission en cours.
      Map<String, dynamic>? match;

      for (final item in all) {
        final itemMissionId = int.tryParse(
          (item['mission_id'] ?? item['mission']?['id'])?.toString() ?? '',
        );

        if (itemMissionId != null && itemMissionId == missionId) {
          match = item;
          break;
        }
      }

      if (match == null) return;

      final id = int.tryParse(match['id']?.toString() ?? '');
      if (id == null) return;

      if (!mounted) return;

      setState(() => signalementId = id);

      await _loadMessages(silent: true);
      _startAutoRefresh();
    } catch (e) {
      // Silencieux : si ça échoue, l'utilisateur peut toujours créer
      // un nouveau signalement via les boutons de signalement rapide.
      debugPrint('Impossible de retrouver un signalement existant : $e');
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildAppBar(),
          if (isLoadingContext)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            )
          else if (contextError != null)
            _buildContextError()
          else if (missionId == null)
              _buildNoActiveMission()
            else ...[
                _buildMissionCard(),
                _buildQuickReports(),
              ],
          if (!isLoadingContext && contextError == null && missionId != null)
            Expanded(
              child: signalementId == null ? _buildNoThreadYet() : _buildMessagesList(),
            )
          else
            const Spacer(),
          if (!isLoadingContext && contextError == null && missionId != null)
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildContextError() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(color: dangerColor.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 36, color: dangerColor),
              ),
              const SizedBox(height: 16),
              const Text('Connexion impossible', style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                contextError ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadContext,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveMission() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.assignment_late_outlined, size: 38, color: primaryColor),
              ),
              const SizedBox(height: 16),
              const Text('Aucune mission active', style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Vous devez avoir une mission en cours pour signaler un problème au responsable.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: appBarGradient,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 3))],
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responsable de flotte',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: Colors.greenAccent),
                        SizedBox(width: 5),
                        Text('Disponible', style: TextStyle(color: Colors.greenAccent, fontSize: 10.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CARTE MISSION
  // ================================================================

  Widget _buildMissionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Camion $truck', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(missionStatus, style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SIGNALEMENTS RAPIDES
  // ================================================================

  Widget _buildQuickReports() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Un problème ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 3),
          const Text('Appuyez sur le problème à signaler.', style: TextStyle(fontSize: 11, color: Color(0xFF8B95A5))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReportButton(icon: Icons.car_crash_rounded, title: 'Accident', type: 'Accident', color: dangerColor),
                _buildReportButton(icon: Icons.local_shipping_rounded, title: 'Camion', type: 'Problème camion', color: Colors.orange),
                _buildReportButton(icon: Icons.warning_amber_rounded, title: 'Route', type: 'Problème route', color: Colors.deepOrange),
                _buildReportButton(icon: Icons.build_rounded, title: 'Panne', type: 'Panne', color: Colors.blueGrey),
                _buildReportButton(icon: Icons.more_horiz_rounded, title: 'Autre', type: 'Autre', color: primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton({
    required IconData icon,
    required String title,
    required String type,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showReportConfirmation(title, type, color),
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.85), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportConfirmation(String title, String type, Color color) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.report_problem_rounded, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Signaler : $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ],
          ),
          content: Text('Voulez-vous signaler un problème de type "$title" au responsable ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Non')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _createSignalementAndReport(type);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Oui, signaler'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // CRÉER LE SIGNALEMENT PUIS ENVOYER LE 1ER MESSAGE
  // ================================================================

  Future<void> _createSignalementAndReport(String type) async {
    if (missionId == null || chauffeurId == null || camionId == null) {
      _showError('Informations de mission incomplètes pour créer un signalement.');
      return;
    }

    setState(() => isSending = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      final quickMessage = _getQuickReportMessage(type);

      final data = await _signalementService.createSignalement(
        token,
        missionId: missionId!,
        chauffeurId: chauffeurId!,
        camionId: camionId!,
        type: type,
        description: quickMessage,
      );

      final newId = int.tryParse(data['id']?.toString() ?? '');
      if (newId == null) throw Exception('Réponse invalide du serveur.');

      // NOUVEAU : on envoie aussi la description comme premier message du fil
      final firstMessage = await _signalementService.sendMessage(
        token,
        newId,
        quickMessage,
      );

      setState(() {
        signalementId = newId;
        messages = [firstMessage];
        isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type signalé au responsable.'),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _startAutoRefresh();
      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      _showError('Impossible d\u2019envoyer le signalement.');
    }
  }

  String _getQuickReportMessage(String type) {
    switch (type) {
      case 'Accident':
        return '🚨 Je signale un accident pendant la mission.';
      case 'Problème camion':
        return '🚛 J’ai un problème avec le camion.';
      case 'Problème route':
        return '🛣️ Il y a un problème sur la route.';
      case 'Panne':
        return '🔧 Le camion est en panne.';
      default:
        return '⚠️ Je veux signaler un problème.';
    }
  }

  // ================================================================
  // ÉTATS (aucune conversation / chargement / vide)
  // ================================================================

  Widget _buildNoThreadYet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.forum_outlined, size: 38, color: primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune conversation',
              style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Signalez un problème ci-dessus ou écrivez directement un message pour contacter le responsable.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (signalementId == null) return;

    if (!silent) setState(() => isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      final data = await _signalementService.getMessages(token, signalementId!);

      if (!mounted) return;

      setState(() {
        messages = data;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _startAutoRefresh() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadMessages(silent: true);
    });
  }

  // ================================================================
  // LISTE DES MESSAGES
  // ================================================================

  Widget _buildMessagesList() {
    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (messages.isEmpty) {
      return _buildNoThreadYet();
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        int.tryParse(authProvider.user?.id?.toString() ?? '') ?? 0;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadMessages(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final fromMe = message.isFromMe(currentUserId);
          final showDateSeparator = index == 0 || !_isSameDay(messages[index - 1].createdAt, message.createdAt);

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF8B95A5), fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.message ?? '',
                style: TextStyle(color: fromMe ? Colors.white : const Color(0xFF1F2937), fontSize: 13.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(message.formattedTime, style: TextStyle(color: fromMe ? Colors.white70 : Colors.grey, fontSize: 9)),
          ],
        ),
      ),
    );
  }

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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
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
                  errorBuilder: (context, error, stack) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(message.formattedTime, style: TextStyle(color: fromMe ? Colors.white70 : Colors.grey, fontSize: 9)),
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
          decoration: BoxDecoration(color: color.withValues(alpha: animated ? 0.9 : 0.45), borderRadius: BorderRadius.circular(2)),
        ),
      )
          .toList(),
    );
  }

 /* Future<void> _toggleAudio(String? url) async {
    if (url == null) return;

    try {
      if (isPlayingAudio && playingAudioUrl == url) {
        await audioPlayer.pause();
        return;
      }
      playingAudioUrl = url;
      await audioPlayer.play(UrlSource(url));
    } catch (e) {
      _showError('Impossible de lire le message vocal.');
    }
  }*/

 /* Future<void> _toggleAudio(String? url) async {
    if (url == null) return;

    try {
      if (isPlayingAudio && playingAudioUrl == url) {
        await audioPlayer.pause();
        return;
      }
      playingAudioUrl = url;

      await audioPlayer.setVolume(1.0); // AJOUTÉ — au cas où le volume interne serait à 0
      await audioPlayer.play(UrlSource(url));
      //await audioPlayer.play(UrlSource('https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav'));

      // AJOUTÉ — pour vérifier que le lecteur détecte bien un fichier valide
      audioPlayer.onDurationChanged.listen((d) {
        debugPrint('DURÉE DÉTECTÉE PAR LE PLAYER : $d');
      });
    } catch (e) {
      debugPrint('ERREUR LECTURE AUDIO : $e');
      _showError('Impossible de lire le message vocal.');
    }
  }*/

  /*Future<void> _toggleAudio(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      // Si l'audio est déjà en cours de lecture -> Mise en pause
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

      // Lecture d'un nouvel audio
      await audioPlayer.stop();
      playingAudioUrl = url;

      // Forcer le volume max et le mode de lecture média
      await audioPlayer.setVolume(1.0);
      await audioPlayer.play(
        UrlSource(url),
        mode: PlayerMode.mediaPlayer,
      );

      setState(() => isPlayingAudio = true);
    } catch (e) {
      debugPrint('ERREUR LECTURE AUDIO : $e');
      setState(() => isPlayingAudio = false);
      _showError('Impossible de lire le message vocal.');
    }
  }*/

  Future<void> _toggleAudio(String? url) async {
    if (url == null || url.isEmpty) {
      debugPrint('AUDIO ❌ URL vide');
      return;
    }

    try {
      // ------------------------------------------------------------
      // 1. Construire une URL accessible depuis le téléphone
      // ------------------------------------------------------------
      String audioUrl = url.trim();

      debugPrint('AUDIO URL REÇUE : $audioUrl');

      // Si Laravel renvoie seulement :
      // /storage/...
      // on ajoute l'adresse du serveur.
      if (audioUrl.startsWith('/')) {
        audioUrl = '${AppConstants.mediaBaseUrl}$audioUrl';
      }

      // Si Laravel renvoie localhost ou 127.0.0.1,
      // on remplace par l'adresse IP du PC.
      if (audioUrl.contains('localhost:8000')) {
        audioUrl = audioUrl.replaceFirst(
          'http://localhost:8000',
          AppConstants.mediaBaseUrl,
        );
      }

      if (audioUrl.contains('127.0.0.1:8000')) {
        audioUrl = audioUrl.replaceFirst(
          'http://127.0.0.1:8000',
          AppConstants.mediaBaseUrl,
        );
      }

      debugPrint('AUDIO URL FINALE : $audioUrl');

      // ------------------------------------------------------------
      // 2. Pause si le même vocal est en cours
      // ------------------------------------------------------------
      if (isPlayingAudio && playingAudioUrl == audioUrl) {
        await audioPlayer.pause();

        if (mounted) {
          setState(() => isPlayingAudio = false);
        }

        return;
      }

      // ------------------------------------------------------------
      // 3. Reprendre si le même vocal est en pause
      // ------------------------------------------------------------
      if (!isPlayingAudio &&
          playingAudioUrl == audioUrl &&
          audioPlayer.state == PlayerState.paused) {
        await audioPlayer.resume();

        if (mounted) {
          setState(() => isPlayingAudio = true);
        }

        return;
      }

      // ------------------------------------------------------------
      // 4. Arrêter l'ancien vocal
      // ------------------------------------------------------------
      await audioPlayer.stop();

      playingAudioUrl = audioUrl;

      // ------------------------------------------------------------
      // 5. Volume
      // ------------------------------------------------------------
      await audioPlayer.setVolume(1.0);

      // ------------------------------------------------------------
      // 6. Lecture
      // ------------------------------------------------------------
      debugPrint('AUDIO ▶️ LECTURE : $audioUrl');

      await audioPlayer.play(
        UrlSource(audioUrl),
        mode: PlayerMode.mediaPlayer,
      );

      if (mounted) {
        setState(() => isPlayingAudio = true);
      }
    } catch (e, stackTrace) {
      debugPrint('AUDIO ❌ ERREUR : $e');
      debugPrint('AUDIO ❌ STACK : $stackTrace');

      if (mounted) {
        setState(() => isPlayingAudio = false);

        _showError(
          'Impossible de lire le message vocal.',
        );
      }
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
              IconButton(onPressed: _cancelRecording, icon: const Icon(Icons.delete_outline_rounded, color: dangerColor)),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: dangerColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: dangerColor, shape: BoxShape.circle)),
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
              icon: const Icon(Icons.camera_alt_outlined, color: primaryColor),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(22)),
                child: TextField(
                  controller: messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Écrire ici...',
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
              icon: const Icon(Icons.mic_none_rounded, color: primaryColor),
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

  // ================================================================
  // ENSURE SIGNALEMENT (auto-créé, type "Autre")
  // ================================================================

  Future<bool> _ensureSignalement() async {
    if (signalementId != null) return true;

    if (missionId == null || chauffeurId == null || camionId == null) {
      _showError('Informations de mission incomplètes.');
      return false;
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      final data = await _signalementService.createSignalement(
        token,
        missionId: missionId!,
        chauffeurId: chauffeurId!,
        camionId: camionId!,
        type: 'Autre',
      );

      final newId = int.tryParse(data['id']?.toString() ?? '');
      if (newId == null) throw Exception('Réponse invalide du serveur.');

      setState(() => signalementId = newId);
      _startAutoRefresh();
      return true;
    } catch (e) {
      _showError('Impossible de démarrer la conversation.');
      return false;
    }
  }

  // ================================================================
  // ENVOI — TEXTE
  // ================================================================

  Future<void> _sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    final ok = await _ensureSignalement();
    if (!ok) {
      setState(() => isSending = false);
      return;
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Utilisateur non authentifié.');

      final message = await _signalementService.sendMessage(token, signalementId!, text);

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
    final source = await _chooseImageSource();
    if (source == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final XFile? image = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) return;

      setState(() => isSending = true);

      final ok = await _ensureSignalement();
      if (!ok) {
        setState(() => isSending = false);
        return;
      }

      if (token == null) throw Exception('Utilisateur non authentifié.');

      final message = await _signalementService.sendImageMessage(token, signalementId!, image);

      setState(() {
        messages.add(message);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      // Erreur détaillée pour identifier la vraie cause (route
      // manquante côté Laravel, taille de fichier refusée, etc.)
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajouter une photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: primaryColor),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: primaryColor),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // ENREGISTREMENT VOCAL
  // ================================================================

  /*Future<void> _startRecording() async {
    if (isRecording) return;

    try {
      final hasPermission = await audioRecorder.hasPermission();
      if (!hasPermission) {
        _showError(
          'Permission microphone refusée. Vérifie les autorisations de l\'app dans les paramètres du téléphone.',
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/sirafleet_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
      _showError(
        'Impossible de démarrer l’enregistrement : ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }*/


  Future<void> _startRecording() async {
    if (isRecording) return;

    try {
      final hasPermission = await audioRecorder.hasPermission();
      if (!hasPermission) {
        _showError(
          'Permission microphone refusée. Vérifie les autorisations de l\'app dans les paramètres du téléphone.',
        );
        return;
      }

      // Web : pas de système de fichiers, le package record renvoie une URL blob.
      // Mobile : fichier temporaire en .m4a (AAC).
      String path = '';
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        path = '${directory.path}/sirafleet_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await audioRecorder.start(
        RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
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
      _showError(
        'Impossible de démarrer l’enregistrement : ${e.toString().replaceFirst('Exception: ', '')}',
      );
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

      final ok = await _ensureSignalement();
      if (!ok) {
        setState(() => isSending = false);
        return;
      }

      if (token == null) throw Exception('Utilisateur non authentifié.');

      //final message = await _signalementService.sendVocalMessage(token, signalementId!, path, duration);

      final message = await _signalementService.sendVocalMessage(
        token,
        signalementId!,
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
      // Erreur détaillée pour identifier la vraie cause (route
      // manquante côté Laravel, permission refusée, etc.)
      _showError(e.toString().replaceFirst('Exception: ', ''));
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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return "Aujourd'hui";
    if (target == today.subtract(const Duration(days: 1))) return 'Hier';

    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
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