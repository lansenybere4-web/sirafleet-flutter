import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/rapport_mission_service.dart';

class RapportMissionScreen extends StatefulWidget {
  final Map<String, dynamic> mission;

  const RapportMissionScreen({
    super.key,
    required this.mission,
  });

  @override
  State<RapportMissionScreen> createState() => _RapportMissionScreenState();
}

class _RapportMissionScreenState extends State<RapportMissionScreen> {
  // ============================================================
  // COULEURS
  // ============================================================

  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFF4A261);
  static const Color backgroundColor = Color(0xFFEDF1F5);
  static const Color paperColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFD8DFE7);
  static const Color inkColor = Color(0xFF1F2937);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _incidentController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // ETAT
  // ============================================================

  double niveauCarburant = 50;
  String etatCamion = 'RAS';
  bool incidentSignale = false;
  bool certifieExact = false;
  bool envoiEnCours = false;

  final List<XFile> _photos = [];
  final Map<String, Uint8List> _photoBytesCache = {};

  Map<String, dynamic>? rapportEnvoye;

  @override
  void initState() {
    super.initState();

    final distance = widget.mission['distance'];
    if (distance != null) {
      final match = RegExp(r'[\d.]+').firstMatch(distance.toString());
      if (match != null) _distanceController.text = match.group(0)!;
    }

    final carburant = widget.mission['niveauCarburant'];
    if (carburant != null) {
      final valeur = double.tryParse(carburant.toString());
      if (valeur != null) niveauCarburant = valeur.clamp(0, 100);
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _incidentController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  String get _numeroRapport {
    final id = widget.mission['id']?.toString() ?? '0';
    final date = DateFormat('yyMMdd').format(DateTime.now());
    return 'RM-$date-${id.padLeft(4, '0')}';
  }

  // ============================================================
  // PHOTOS — sélection
  // ============================================================

  Future<void> _ajouterPhoto(ImageSource source) async {
    if (_photos.length >= 6) {
      _showMessage('Maximum 6 photos par rapport.', warningColor);
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      _photos.add(image);
      _photoBytesCache[image.path] = bytes;
    });
  }

  void _retirerPhoto(XFile photo) {
    setState(() {
      _photos.remove(photo);
      _photoBytesCache.remove(photo.path);
    });
  }

  void _choisirSourcePhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 6),
                child: Text('Ajouter une photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: primaryColor),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ajouterPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: primaryColor),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ajouterPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final estValide = rapportEnvoye != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Rapport de fin de mission',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (estValide)
            IconButton(
              tooltip: 'Imprimer / Exporter en PDF',
              icon: const Icon(Icons.print_outlined),
              onPressed: _imprimerRapport,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _fichePaper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ficheHeader(),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'RAPPORT DE FIN DE MISSION',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                              color: inkColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _numberedSection('1', 'IDENTIFICATION DE LA MISSION'),
                        _missionInfoBlock(),
                        const SizedBox(height: 20),
                        _numberedSection('2', 'DONNÉES KILOMÉTRIQUES ET CARBURANT'),
                        const SizedBox(height: 10),
                        _distanceField(),
                        const SizedBox(height: 16),
                        _fuelField(),
                        const SizedBox(height: 20),
                        _numberedSection('3', 'ÉTAT DU VÉHICULE À L\'ARRIVÉE'),
                        const SizedBox(height: 10),
                        _truckStateChecklist(),
                        const SizedBox(height: 20),
                        _numberedSection('4', 'DÉCLARATION D\'INCIDENT'),
                        const SizedBox(height: 10),
                        _incidentBlock(),
                        const SizedBox(height: 20),
                        _numberedSection('5', 'PIÈCES JOINTES (PHOTOS)'),
                        const SizedBox(height: 10),
                        _photosBlock(),
                        const SizedBox(height: 20),
                        _numberedSection('6', 'OBSERVATIONS DU CHAUFFEUR'),
                        const SizedBox(height: 10),
                        _commentField(),
                        const SizedBox(height: 22),
                        _numberedSection('7', 'CERTIFICATION ET VALIDATION'),
                        const SizedBox(height: 10),
                        _certificationBlock(),
                        const SizedBox(height: 18),
                        _signatureBlock(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (!estValide) _submitButton(),
                  if (estValide) _validatedBanner(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // "PAPIER" DE LA FICHE
  // ============================================================

  Widget _fichePaper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // EN-TÊTE STYLE FICHE OFFICIELLE (façon entête d'entreprise)
  // ============================================================

  Widget _ficheHeader() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIRAFLEET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Gestion intelligente de flotte de transport',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('N° FICHE',
                      style: TextStyle(fontSize: 8.5, color: Colors.grey.shade600)),
                  Text(
                    _numeroRapport,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now()),
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: borderColor, thickness: 1.2),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _numberedSection(String number, String label) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            number,
            style: const TextStyle(
                color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: inkColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: borderColor, thickness: 1)),
      ],
    );
  }

  // ============================================================
  // BLOC INFOS MISSION (lecture seule, style tableau administratif)
  // ============================================================

  Widget _missionInfoBlock() {
    final id = widget.mission['id'] ?? '---';
    final origine = widget.mission['origine'] ?? widget.mission['depart'] ?? 'Départ';
    final destination =
        widget.mission['destination'] ?? widget.mission['arrivee'] ?? 'Destination';
    final camion =
        widget.mission['camion'] ?? widget.mission['camionMatricule'] ?? 'Non renseigné';
    final date = widget.mission['date']?.toString() ?? '—';

    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final nomChauffeur =
    currentUser != null ? '${currentUser.prenom} ${currentUser.nom}'.trim() : 'Chauffeur';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoCell('N° MISSION', '#$id', isFirst: true),
              ),
              Expanded(
                child: _infoCell('DATE', date),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _infoCell('CHAUFFEUR', nomChauffeur),
              ),
              Expanded(
                child: _infoCell('CAMION AFFECTÉ', camion.toString()),
              ),
            ],
          ),
          _infoCell('TRAJET', '$origine   →   $destination', isLast: true, fullWidth: true),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value,
      {bool isFirst = false, bool isLast = false, bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : const BorderSide(color: borderColor),
          left: BorderSide.none,
        ),
        color: const Color(0xFFFAFBFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: inkColor)),
        ],
      ),
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  Widget _distanceField() {
    return TextFormField(
      controller: _distanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      decoration: _inputDecoration(
        label: 'Distance réelle parcourue',
        hint: 'Exemple : 125.5',
        icon: Icons.speed_outlined,
        suffix: 'km',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Indique la distance parcourue';
        final distance = double.tryParse(value.trim().replaceAll(',', '.'));
        if (distance == null || distance < 0) return 'Distance invalide';
        return null;
      },
    );
  }

  // ============================================================
  // CARBURANT
  // ============================================================

  Widget _fuelField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_gas_station, color: accentColor, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Niveau de carburant après la mission',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text('${niveauCarburant.round()}%',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          Slider(
            value: niveauCarburant,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: accentColor,
            label: '${niveauCarburant.round()}%',
            onChanged: (value) => setState(() => niveauCarburant = value),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ETAT CAMION — style checklist officielle
  // ============================================================

  Widget _truckStateChecklist() {
    return Column(
      children: [
        _checklistOption('RAS', 'Aucun problème constaté', Icons.check_circle_outline, accentColor),
        const SizedBox(height: 8),
        _checklistOption('À vérifier', 'Contrôle recommandé au dépôt', Icons.warning_amber_rounded, warningColor),
        const SizedBox(height: 8),
        _checklistOption('Problème signalé', 'Intervention nécessaire', Icons.error_outline, dangerColor),
      ],
    );
  }

  Widget _checklistOption(String value, String description, IconData icon, Color color) {
    final selected = etatCamion == value;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          etatCamion = value;
          if (value == 'Problème signalé') incidentSignale = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : borderColor, width: selected ? 1.4 : 1),
          borderRadius: BorderRadius.circular(8),
          color: selected ? color.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: selected ? color : Colors.grey.shade400, width: 1.6),
                color: selected ? color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: selected ? color : inkColor)),
                  Text(description, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INCIDENT
  // ============================================================

  Widget _incidentBlock() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: incidentSignale ? dangerColor.withValues(alpha: 0.06) : const Color(0xFFFAFBFC),
            border: Border.all(color: incidentSignale ? dangerColor.withValues(alpha: 0.3) : borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(incidentSignale ? Icons.warning : Icons.check_circle_outline,
                  color: incidentSignale ? dangerColor : accentColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Un incident est survenu durant la mission ?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Switch(
                value: incidentSignale,
                activeColor: dangerColor,
                onChanged: (value) {
                  setState(() {
                    incidentSignale = value;
                    if (!value) _incidentController.clear();
                  });
                },
              ),
            ],
          ),
        ),
        if (incidentSignale) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _incidentController,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Description de l\'incident',
              hint: 'Exemple : crevaison, problème moteur...',
              icon: Icons.edit_note,
            ),
            validator: (value) {
              if (incidentSignale && (value == null || value.trim().isEmpty)) {
                return 'Décris l\'incident';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  // ============================================================
  // PHOTOS JOINTES
  // ============================================================

  Widget _photosBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Joins une photo de l\'état du camion, d\'un incident ou d\'une preuve de livraison. '
              'Ces photos seront visibles par le responsable dans son rapport. (6 max)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photos.map((photo) => _photoThumbnail(photo)),
            if (_photos.length < 6) _addPhotoTile(),
          ],
        ),
      ],
    );
  }

  Widget _photoThumbnail(XFile photo) {
    final bytes = _photoBytesCache[photo.path];

    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: () => _retirerPhoto(photo),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: dangerColor, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTile() {
    return InkWell(
      onTap: _choisirSourcePhoto,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, style: BorderStyle.solid),
          color: const Color(0xFFFAFBFC),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: primaryColor, size: 22),
            SizedBox(height: 4),
            Text('Ajouter', style: TextStyle(fontSize: 10, color: primaryColor)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMENTAIRE
  // ============================================================

  Widget _commentField() {
    return TextFormField(
      controller: _commentaireController,
      maxLines: 3,
      decoration: _inputDecoration(
        label: 'Remarque facultative',
        hint: 'Une information importante à signaler ?',
        icon: Icons.comment_outlined,
      ),
    );
  }

  // ============================================================
  // CERTIFICATION
  // ============================================================

  Widget _certificationBlock() {
    return InkWell(
      onTap: () => setState(() => certifieExact = !certifieExact),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: certifieExact ? primaryColor : borderColor),
          borderRadius: BorderRadius.circular(8),
          color: certifieExact ? primaryColor.withValues(alpha: 0.04) : Colors.transparent,
        ),
        child: Row(
          children: [
            Checkbox(
              value: certifieExact,
              activeColor: primaryColor,
              onChanged: (value) => setState(() => certifieExact = value ?? false),
            ),
            const Expanded(
              child: Text(
                'Je certifie que les informations renseignées ci-dessus sont exactes et complètes.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BLOC SIGNATURE (style fiche papier)
  // ============================================================

  Widget _signatureBlock() {
    final estValide = rapportEnvoye != null;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final nomChauffeur =
    currentUser != null ? '${currentUser.prenom} ${currentUser.nom}'.trim() : 'Chauffeur';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rapport établi et signé électroniquement par',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                const SizedBox(height: 3),
                Text(nomChauffeur,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Icon(estValide ? Icons.verified : Icons.pending_outlined,
              color: estValide ? accentColor : Colors.grey),
          const SizedBox(width: 6),
          Text(
            estValide ? 'Transmis au responsable' : 'En attente de transmission',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: estValide ? accentColor : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _validatedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: accentColor),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Rapport transmis avec succès au responsable. Tu peux l\'imprimer.',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: _imprimerRapport,
            icon: const Icon(Icons.print_outlined, color: primaryColor),
            label: const Text('Imprimer',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTON D'ENVOI
  // ============================================================

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: envoiEnCours ? null : _submitReport,
        icon: envoiEnCours
            ? const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send),
        label: Text(
          envoiEnCours ? 'TRANSMISSION EN COURS...' : 'TRANSMETTRE LE RAPPORT',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ============================================================
  // ENVOI
  // ============================================================

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (!certifieExact) {
      _showMessage('Coche la case de certification avant d\'envoyer.', warningColor);
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Terminer la mission ?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Le rapport sera envoyé au responsable et la mission passera '
                'automatiquement à l\'état terminée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: const Text('CONFIRMER'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      _showMessage('Session expirée. Veuillez vous reconnecter.', dangerColor);
      return;
    }

    final missionId = int.tryParse(widget.mission['id'].toString());
    if (missionId == null) {
      _showMessage('Identifiant de mission invalide.', dangerColor);
      return;
    }

    final distance = double.tryParse(_distanceController.text.trim().replaceAll(',', '.'));
    if (distance == null || distance < 0) {
      _showMessage('Distance parcourue invalide.', dangerColor);
      return;
    }

    setState(() => envoiEnCours = true);

    try {
      final service = RapportMissionService(token: token);

      final resultat = await service.envoyerRapport(
        missionId: missionId,
        distanceReelle: distance,
        niveauCarburant: niveauCarburant.round(),
        etatCamion: etatCamion,
        incidentSignale: incidentSignale,
        incidentDescription: incidentSignale ? _incidentController.text.trim() : null,
        commentaire: _commentaireController.text.trim().isEmpty
            ? null
            : _commentaireController.text.trim(),
        photos: _photos,
      );

      if (!mounted) return;

      setState(() {
        rapportEnvoye = {
          'distance_reelle': distance,
          'niveau_carburant': niveauCarburant.round(),
          'etat_camion': etatCamion,
          'incident_signale': incidentSignale,
          'incident_description': _incidentController.text.trim(),
          'commentaire': _commentaireController.text.trim(),
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultat['message']?.toString() ?? 'Rapport envoyé avec succès.'),
          backgroundColor: accentColor,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'rapport': resultat['data'],
            'mission_id': missionId,
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      _showMessage(message, dangerColor);
    } finally {
      if (mounted) setState(() => envoiEnCours = false);
    }
  }

  // ============================================================
  // IMPRESSION / EXPORT PDF DE LA FICHE (avec photos jointes)
  // ============================================================

  Future<void> _imprimerRapport() async {
    final doc = pw.Document();

    final id = widget.mission['id'] ?? '---';
    final origine = widget.mission['origine'] ?? widget.mission['depart'] ?? 'Départ';
    final destination = widget.mission['destination'] ?? widget.mission['arrivee'] ?? 'Destination';
    final camion = widget.mission['camion'] ?? widget.mission['camionMatricule'] ?? 'Non renseigné';
    final date = widget.mission['date']?.toString() ?? '—';

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    final nomChauffeur =
    currentUser != null ? '${currentUser.prenom} ${currentUser.nom}'.trim() : 'Chauffeur';

    final r = rapportEnvoye ??
        {
          'distance_reelle':
          double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0,
          'niveau_carburant': niveauCarburant.round(),
          'etat_camion': etatCamion,
          'incident_signale': incidentSignale,
          'incident_description': _incidentController.text.trim(),
          'commentaire': _commentaireController.text.trim(),
        };

    final pdfPrimary = PdfColor.fromInt(0xFF1D3557);
    final pdfGrey = PdfColor.fromInt(0xFF6B7280);
    final pdfBorder = PdfColor.fromInt(0xFFD8DFE7);

    // Les photos gardées en mémoire (cache local) sont intégrées telles
    // quelles dans le PDF — pas besoin de retélécharger depuis le serveur.
    final photoImages = <pw.MemoryImage>[];
    for (final photo in _photos) {
      final bytes = _photoBytesCache[photo.path];
      if (bytes != null) photoImages.add(pw.MemoryImage(bytes));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SIRAFLEET', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
                    pw.Text('RAPPORT DE FIN DE MISSION', style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_numeroRapport, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimary)),
                    pw.Text(DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now()), style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdfBorder),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          _pdfSectionTitle('1. Identification de la mission', pdfPrimary),
          pw.SizedBox(height: 6),
          _pdfInfoTable([
            ['N° Mission', '#$id'],
            ['Chauffeur', nomChauffeur],
            ['Trajet', '$origine  ->  $destination'],
            ['Camion affecté', camion.toString()],
            ['Date de mission', date],
          ], pdfBorder, pdfGrey),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('2. Données kilométriques et carburant', pdfPrimary),
          pw.SizedBox(height: 6),
          _pdfInfoTable([
            ['Distance parcourue', '${r['distance_reelle']} km'],
            ['Carburant restant', '${r['niveau_carburant']}%'],
          ], pdfBorder, pdfGrey),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('3. État du véhicule', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(r['etat_camion'].toString(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('4. Incident', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(
            (r['incident_signale'] == true)
                ? (r['incident_description']?.toString().isNotEmpty == true
                ? r['incident_description'].toString()
                : 'Incident signalé, aucune description fournie.')
                : 'Aucun incident signalé.',
            style: pw.TextStyle(fontSize: 10, color: pdfGrey),
          ),
          if (photoImages.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionTitle('5. Pièces jointes (${photoImages.length} photo(s))', pdfPrimary),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photoImages
                  .map((img) => pw.Container(
                width: 130,
                height: 130,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: pdfBorder)),
                child: pw.Image(img, fit: pw.BoxFit.cover),
              ))
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 14),
          _pdfSectionTitle('6. Observations du chauffeur', pdfPrimary),
          pw.SizedBox(height: 6),
          pw.Text(
            (r['commentaire']?.toString().isNotEmpty == true) ? r['commentaire'].toString() : 'Aucune remarque.',
            style: pw.TextStyle(fontSize: 10, color: pdfGrey),
          ),
          pw.SizedBox(height: 26),
          pw.Divider(color: pdfBorder),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport établi par', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
                  pw.Text(nomChauffeur, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text('Signature : ____________________', style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
    );
  }

  pw.Widget _pdfInfoTable(List<List<String>> rows, PdfColor border, PdfColor grey) {
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.5),
      columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5)},
      children: rows
          .map((row) => pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(row[0], style: pw.TextStyle(fontSize: 9, color: grey)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(row[1], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
      ]))
          .toList(),
    );
  }

  // ============================================================
  // WIDGETS UTILITAIRES
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.3)),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 4)),
    );
  }
}
