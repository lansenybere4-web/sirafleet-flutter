import 'package:flutter/material.dart';

import '../../widgets/sidebar_admin.dart';
import '../../models/parametre.dart';
import '../../services/parametre_service.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final ParametreService _service = ParametreService();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  final nomAppCtrl = TextEditingController();
  final entrepriseCtrl = TextEditingController();
  final versionCtrl = TextEditingController();
  final apiUrlCtrl = TextEditingController();

  double vitesseMax = 90;
  double carburantMin = 15;

  bool notifSOS = true;
  bool notifPanne = true;
  bool notifMaintenance = false;
  bool notifCarburant = true;
  bool notifVitesse = true;
  bool notifConnexion = true;

  int sessionTimeout = 30;
  bool doubleAuth = false;
  bool journalisation = true;

  int frequenceGPS = 30;
  bool gpsActif = true;
  bool historiqueGPS = true;

  bool apiActive = true;

  @override
  void initState() {
    super.initState();
    _loadParametres();
  }

  Future<void> _loadParametres() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final p = await _service.getParametres();
      _applyParametre(p);
    } catch (e) {
      setState(() {
        errorMessage = 'Impossible de charger les paramètres.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyParametre(Parametre p) {
    nomAppCtrl.text = p.nomApp;
    entrepriseCtrl.text = p.entreprise;
    versionCtrl.text = p.version;
    apiUrlCtrl.text = p.apiUrl;

    vitesseMax = p.vitesseMax;
    carburantMin = p.carburantMin;

    notifSOS = p.notifSOS;
    notifPanne = p.notifPanne;
    notifMaintenance = p.notifMaintenance;
    notifCarburant = p.notifCarburant;
    notifVitesse = p.notifVitesse;
    notifConnexion = p.notifConnexion;

    sessionTimeout = p.sessionTimeout;
    doubleAuth = p.doubleAuth;
    journalisation = p.journalisation;

    frequenceGPS = p.frequenceGPS;
    gpsActif = p.gpsActif;
    historiqueGPS = p.historiqueGPS;

    apiActive = p.apiActive;
  }

  @override
  void dispose() {
    nomAppCtrl.dispose();
    entrepriseCtrl.dispose();
    versionCtrl.dispose();
    apiUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(selectedIndex: 7),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paramètres',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Configurez les paramètres techniques et généraux '
                              'de la plateforme SiraFleet.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dangerColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: dangerColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: dangerColor, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(errorMessage!,
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 25),
                        _buildSection(
                          title: 'Informations générales',
                          icon: Icons.info_outline,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: nomAppCtrl,
                                label: 'Nom de la plateforme',
                                hint: 'Ex : SiraFleet',
                                icon: Icons.apps_outlined,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: entrepriseCtrl,
                                label: 'Entreprise',
                                hint: 'Nom de l\u2019entreprise',
                                icon: Icons.business_outlined,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: versionCtrl,
                                label: 'Version de la plateforme',
                                hint: 'Ex : 1.0.0',
                                icon: Icons.new_releases_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Seuils techniques',
                          icon: Icons.tune,
                          child: Column(
                            children: [
                              _buildSlider(
                                label: 'Vitesse maximale autorisée',
                                description:
                                'Une alerte est générée lorsque cette '
                                    'vitesse est dépassée.',
                                value: vitesseMax,
                                min: 40,
                                max: 130,
                                unit: 'km/h',
                                onChanged: (value) {
                                  setState(() => vitesseMax = value);
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildSlider(
                                label: 'Seuil minimum de carburant',
                                description:
                                'Une alerte est générée lorsque le '
                                    'niveau de carburant descend sous ce seuil.',
                                value: carburantMin,
                                min: 5,
                                max: 40,
                                unit: '%',
                                onChanged: (value) {
                                  setState(() => carburantMin = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Notifications système',
                          icon: Icons.notifications_outlined,
                          child: Column(
                            children: [
                              _buildSwitch(
                                label: 'Alertes SOS',
                                description:
                                'Recevoir les alertes déclenchées par '
                                    'le bouton SOS.',
                                value: notifSOS,
                                onChanged: (v) => setState(() => notifSOS = v),
                              ),
                              _buildSwitch(
                                label: 'Équipements en panne',
                                description:
                                'Notifier lorsqu\u2019un équipement '
                                    'technique tombe en panne.',
                                value: notifPanne,
                                onChanged: (v) => setState(() => notifPanne = v),
                              ),
                              _buildSwitch(
                                label: 'Rappels de maintenance',
                                description:
                                'Recevoir les notifications relatives '
                                    'aux opérations de maintenance.',
                                value: notifMaintenance,
                                onChanged: (v) =>
                                    setState(() => notifMaintenance = v),
                              ),
                              _buildSwitch(
                                label: 'Niveau de carburant faible',
                                description:
                                'Notifier lorsque le seuil de carburant '
                                    'est dépassé.',
                                value: notifCarburant,
                                onChanged: (v) =>
                                    setState(() => notifCarburant = v),
                              ),
                              _buildSwitch(
                                label: 'Excès de vitesse',
                                description:
                                'Notifier lorsqu\u2019un véhicule dépasse '
                                    'la vitesse maximale.',
                                value: notifVitesse,
                                onChanged: (v) =>
                                    setState(() => notifVitesse = v),
                              ),
                              _buildSwitch(
                                label: 'Connexion des équipements',
                                description:
                                'Notifier lorsqu\u2019un équipement '
                                    'cesse de communiquer.',
                                value: notifConnexion,
                                onChanged: (v) =>
                                    setState(() => notifConnexion = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Configuration GPS',
                          icon: Icons.gps_fixed,
                          child: Column(
                            children: [
                              _buildSlider(
                                label: 'Fréquence de transmission GPS',
                                description:
                                'Intervalle entre deux positions '
                                    'GPS transmises par le véhicule.',
                                value: frequenceGPS.toDouble(),
                                min: 5,
                                max: 120,
                                unit: 'sec',
                                onChanged: (value) {
                                  setState(
                                          () => frequenceGPS = value.round());
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildSwitch(
                                label: 'Suivi GPS activé',
                                description:
                                'Activer la réception des positions '
                                    'GPS des véhicules.',
                                value: gpsActif,
                                onChanged: (v) => setState(() => gpsActif = v),
                              ),
                              _buildSwitch(
                                label: 'Conserver l\u2019historique GPS',
                                description:
                                'Conserver les anciennes positions '
                                    'pour la consultation technique.',
                                value: historiqueGPS,
                                onChanged: (v) =>
                                    setState(() => historiqueGPS = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Connexion API Laravel',
                          icon: Icons.cloud_outlined,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: apiUrlCtrl,
                                label: 'URL de l\u2019API',
                                hint: 'http://localhost:8000/api',
                                icon: Icons.link_outlined,
                              ),
                              const SizedBox(height: 15),
                              _buildSwitch(
                                label: 'API activée',
                                description:
                                'Autoriser la communication entre '
                                    'Flutter et le backend Laravel.',
                                value: apiActive,
                                onChanged: (v) => setState(() => apiActive = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Sécurité',
                          icon: Icons.lock_outline,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Déconnexion automatique',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Déconnecter automatiquement un '
                                              'utilisateur après une période '
                                              'd\u2019inactivité.',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: sessionTimeout,
                                    items: [15, 30, 60, 120]
                                        .map((value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value min'),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                                () => sessionTimeout = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 25),
                              _buildSwitch(
                                label: 'Authentification renforcée',
                                description:
                                'Activer une authentification '
                                    'supplémentaire pour les comptes '
                                    'administrateurs.',
                                value: doubleAuth,
                                onChanged: (v) => setState(() => doubleAuth = v),
                              ),
                              _buildSwitch(
                                label: 'Journalisation des activités',
                                description:
                                'Enregistrer les actions importantes '
                                    'effectuées sur la plateforme.',
                                value: journalisation,
                                onChanged: (v) =>
                                    setState(() => journalisation = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isSaving ? null : _resetSettings,
                              icon: const Icon(Icons.restore),
                              label: const Text('Réinitialiser'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: isSaving ? null : _saveSettings,
                              icon: isSaving
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.save_outlined),
                              label: Text(isSaving
                                  ? 'Enregistrement...'
                                  : 'Enregistrer les modifications'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        children: [
          Text(
            'Paramètres',
            style: TextStyle(
                color: primaryColor, fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(description,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Text(
              '${value.round()} $unit',
              style: const TextStyle(
                  color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          activeColor: primaryColor,
          inactiveColor: primaryColor.withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
              ],
            ),
          ),
          Switch(value: value, activeColor: accentColor, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);

    final data = {
      'nom_app': nomAppCtrl.text,
      'entreprise': entrepriseCtrl.text,
      'version': versionCtrl.text,
      'vitesse_max': vitesseMax,
      'carburant_min': carburantMin,
      'notif_sos': notifSOS,
      'notif_panne': notifPanne,
      'notif_maintenance': notifMaintenance,
      'notif_carburant': notifCarburant,
      'notif_vitesse': notifVitesse,
      'notif_connexion': notifConnexion,
      'session_timeout': sessionTimeout,
      'double_auth': doubleAuth,
      'journalisation': journalisation,
      'frequence_gps': frequenceGPS,
      'gps_actif': gpsActif,
      'historique_gps': historiqueGPS,
      'api_url': apiUrlCtrl.text,
      'api_active': apiActive,
    };

    try {
      final p = await _service.updateParametres(data);
      _applyParametre(p);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les paramètres ont été enregistrés avec succès.'),
            backgroundColor: accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\u2019enregistrement.'),
            backgroundColor: dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _resetSettings() async {
    setState(() => isSaving = true);

    try {
      final p = await _service.resetParametres();
      _applyParametre(p);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les paramètres ont été réinitialisés.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la réinitialisation.'),
            backgroundColor: dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}