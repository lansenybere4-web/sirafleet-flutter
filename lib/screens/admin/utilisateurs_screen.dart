/*import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/sidebar_admin.dart';
import 'profil_utilisateur_screen.dart';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<UtilisateursScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final UserService _userService = UserService();

  List<UserModel> _users = [];
  List<RoleModel> _roles = [];

  bool _loading = true;
  String? _loadError;

  String filtreRole = 'Tous';
  String filtreStatut = 'Tous';
  String recherche = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // NAVIGATION : PROFIL
  // ============================================================

  void _voirProfil(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilUtilisateurScreen(
          utilisateur: user,
          sidebar: const SidebarAdmin(selectedIndex: 1),
        ),
      ),
    );
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;

    if (token == null) {
      setState(() {
        _loading = false;
        _loadError = 'Session utilisateur expirée.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _userService.getUsers(token),
        _userService.getRoles(token),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<UserModel>;
        _roles = results[1] as List<RoleModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  String _roleName(String roleId) {
    final matches = _roles.where((r) => r.id == roleId);
    if (matches.isEmpty) return '—';
    return matches.first.name;
  }

  bool _isChauffeurRole(String? roleId) {
    if (roleId == null) return false;
    return _roleName(roleId).toUpperCase() == 'CHAUFFEUR';
  }

  Color _colorForRole(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'ADMIN':
        return dangerColor;
      case 'RESPONSABLE':
        return Colors.orange;
      case 'CHAUFFEUR':
        return accentColor;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Future<XFile?> _pickPhoto() async {
    try {
      final picker = ImagePicker();

      return await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );
    } catch (e) {
      _showMessage('Impossible de sélectionner la photo.', dangerColor);
      return null;
    }
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showForm({UserModel? existing}) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final numTelCtrl = TextEditingController(text: existing?.numTel ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final passwordCtrl = TextEditingController();
    final siteCtrl = TextEditingController(text: existing?.siteAffectation ?? '');

    // Champs spécifiques au chauffeur
    final matriculeCtrl = TextEditingController();
    final permisCtrl = TextEditingController();
    final typePermisCtrl = TextEditingController();

    // Si le compte a déjà une fiche chauffeur, ces champs sont facultatifs :
    // le backend conserve les anciennes valeurs quand ils sont vides.
    final bool ficheExiste = existing?.chauffeurId != null;

    XFile? selectedPhoto;

    String? roleId = existing?.roleId ??
        (_roles.isNotEmpty ? _roles.first.id : null);

    String statut = existing?.statut ?? 'actif';

    bool saving = false;
    String? formError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool estChauffeur = _isChauffeurRole(roleId);

            Future<void> pickPhoto() async {
              final photo = await _pickPhoto();
              if (photo == null) return;

              setDialogState(() {
                selectedPhoto = photo;
              });
            }

            Future<void> submit() async {
              setDialogState(() {
                formError = null;
              });

              final nom = nomCtrl.text.trim();
              final prenom = prenomCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final numTel = numTelCtrl.text.trim();
              final address = addressCtrl.text.trim();
              final password = passwordCtrl.text.trim();

              final matricule = matriculeCtrl.text.trim();
              final permis = permisCtrl.text.trim();
              final typePermis = typePermisCtrl.text.trim();

              // ------------------------------------------------
              // VALIDATION
              // ------------------------------------------------

              if (nom.isEmpty ||
                  prenom.isEmpty ||
                  email.isEmpty ||
                  numTel.isEmpty) {
                setDialogState(() {
                  formError = 'Veuillez remplir tous les champs obligatoires.';
                });
                return;
              }

              if (!_isValidEmail(email)) {
                setDialogState(() {
                  formError = 'Veuillez saisir une adresse email valide.';
                });
                return;
              }


              if (roleId == null) {
                setDialogState(() {
                  formError = 'Veuillez sélectionner un rôle.';
                });
                return;
              }

              if (existing == null && password.length < 8) {
                setDialogState(() {
                  formError =
                  'Le mot de passe doit contenir au moins 8 caractères.';
                });
                return;
              }

              if (existing != null &&
                  password.isNotEmpty &&
                  password.length < 8) {
                setDialogState(() {
                  formError =
                  'Le mot de passe doit contenir au moins 8 caractères.';
                });
                return;
              }

              // Champs chauffeur obligatoires seulement s'il n'y a pas
              // encore de fiche chauffeur pour ce compte.
              if (estChauffeur &&
                  !ficheExiste &&
                  (matricule.isEmpty ||
                      permis.isEmpty ||
                      typePermis.isEmpty)) {
                setDialogState(() {
                  formError =
                  'Veuillez remplir les informations du chauffeur (matricule, permis, type de permis).';
                });
                return;
              }

              final token = context.read<AuthProvider>().token;

              if (token == null) {
                setDialogState(() {
                  formError = 'Session expirée. Veuillez vous reconnecter.';
                });
                return;
              }

              setDialogState(() {
                saving = true;
              });

              // Valeurs envoyées : null si vide (le backend garde l'ancien).
              final String? matriculeToSend =
              estChauffeur && matricule.isNotEmpty ? matricule : null;
              final String? permisToSend =
              estChauffeur && permis.isNotEmpty ? permis : null;
              final String? typePermisToSend =
              estChauffeur && typePermis.isNotEmpty ? typePermis : null;

              try {
                if (existing == null) {
                  await _userService.createUser(
                    token: token,
                    nom: nom,
                    prenom: prenom,
                    email: email,
                    numTel: numTel,
                    password: password,
                    roleId: roleId!,
                    address: address,
                    statut: statut,
                    photo: selectedPhoto,
                    matricule: matriculeToSend,
                    permis: permisToSend,
                    typePermis: typePermisToSend,
                  );
                } else {
                  await _userService.updateUser(
                    token: token,
                    id: existing.id,
                    nom: nom,
                    prenom: prenom,
                    email: email,
                    numTel: numTel,
                    password: password.isEmpty ? null : password,
                    roleId: roleId!,
                    address: address,
                    statut: statut,
                    photo: selectedPhoto,
                    matricule: matriculeToSend,
                    permis: permisToSend,
                    typePermis: typePermisToSend,
                  );
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);

                _showMessage(
                  existing == null
                      ? 'Utilisateur créé avec succès.'
                      : 'Utilisateur modifié avec succès.',
                  accentColor,
                );

                await _loadData();
              } catch (e) {
                setDialogState(() {
                  saving = false;
                  formError = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    existing == null
                        ? Icons.person_add_alt_1
                        : Icons.edit_outlined,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existing == null
                          ? 'Nouvel utilisateur'
                          : 'Modifier l’utilisateur',
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------------- PHOTO ----------------
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: saving ? null : pickPhoto,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _buildFormPhoto(existing, selectedPhoto),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: saving ? null : pickPhoto,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                selectedPhoto == null
                                    ? 'Ajouter une photo de profil'
                                    : 'Changer la photo',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------------- NOM + PRENOM ----------------
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              controller: nomCtrl,
                              label: 'Nom *',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              controller: prenomCtrl,
                              label: 'Prénom *',
                              icon: Icons.person,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: emailCtrl,
                        label: 'Adresse email *',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: numTelCtrl,
                        label: 'Téléphone *',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: addressCtrl,
                        label: 'Adresse',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 14),
                      _formField(
                        controller: siteCtrl,
                        label: 'Site d’affectation',
                        icon: Icons.business_outlined,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: passwordCtrl,
                        label: existing == null
                            ? 'Mot de passe *'
                            : 'Nouveau mot de passe',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        helperText: existing == null
                            ? 'Minimum 8 caractères.'
                            : 'Laissez vide pour conserver l’ancien.',
                      ),

                      const SizedBox(height: 14),

                      // ---------------- ROLE ----------------
                      DropdownButtonFormField<String>(
                        initialValue: roleId,
                        decoration: const InputDecoration(
                          labelText: 'Rôle *',
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role.id,
                            child: Text(role.name),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                          setDialogState(() {
                            roleId = value;
                          });
                        },
                      ),

                      // ---------------- INFOS CHAUFFEUR ----------------
                      if (estChauffeur) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informations chauffeur',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (ficheExiste)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Laissez vide pour conserver les valeurs actuelles.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _formField(
                          controller: matriculeCtrl,
                          label: ficheExiste ? 'Matricule' : 'Matricule *',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: permisCtrl,
                          label: ficheExiste
                              ? 'Numéro de permis'
                              : 'Numéro de permis *',
                          icon: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: typePermisCtrl,
                          label: ficheExiste
                              ? 'Type de permis (B, C, D...)'
                              : 'Type de permis (B, C, D...) *',
                          icon: Icons.directions_car_outlined,
                        ),
                      ],

                      const SizedBox(height: 14),

                      // ---------------- STATUT ----------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              statut == 'actif'
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              color: statut == 'actif'
                                  ? accentColor
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Compte actif',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: statut == 'actif',
                              activeColor: accentColor,
                              onChanged: saving
                                  ? null
                                  : (value) {
                                setDialogState(() {
                                  statut = value ? 'actif' : 'inactif';
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // ---------------- ERREUR ----------------
                      if (formError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formError!,
                            style: const TextStyle(
                              color: dangerColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PHOTO FORMULAIRE
  // ============================================================

  Widget _buildFormPhoto(UserModel? existing, XFile? selectedPhoto) {
    if (selectedPhoto != null) {
      return FutureBuilder<List<int>>(
        future: selectedPhoto.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 55,
              backgroundImage: MemoryImage(
                Uint8List.fromList(snapshot.data!),
              ),
            );
          }

          return _defaultAvatar(radius: 55);
        },
      );
    }

    if (existing?.photoProfil != null && existing!.photoProfil!.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundColor: primaryColor.withValues(alpha: 0.10),
        backgroundImage: NetworkImage(existing.photoProfil!),
      );
    }

    return _defaultAvatar(radius: 55);
  }

  Widget _defaultAvatar({double radius = 23}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryColor.withValues(alpha: 0.10),
      child: Icon(
        Icons.person_outline,
        size: radius,
        color: primaryColor,
      ),
    );
  }

  // ============================================================
  // EMAIL
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // ============================================================
  // ACTIVER / DESACTIVER
  // ============================================================

  Future<void> _toggleStatut(UserModel user) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _userService.updateUser(
        token: token,
        id: user.id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        numTel: user.numTel,
        roleId: user.roleId,
        address: user.address,
        statut: user.statut == 'actif' ? 'inactif' : 'actif',
        photo: null,
      );

      _showMessage(
        user.statut == 'actif' ? 'Compte désactivé.' : 'Compte activé.',
        accentColor,
      );

      await _loadData();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        dangerColor,
      );
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: dangerColor),
              SizedBox(width: 10),
              Text('Supprimer le compte ?'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le compte de '
                '${user.prenom} ${user.nom} ?\n\n'
                'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ANNULER'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final token = context.read<AuthProvider>().token;
                if (token == null) return;

                Navigator.pop(dialogContext);

                try {
                  await _userService.deleteUser(token, user.id);

                  _showMessage('Utilisateur supprimé.', dangerColor);

                  await _loadData();
                } catch (e) {
                  _showMessage(
                    e.toString().replaceFirst('Exception: ', ''),
                    dangerColor,
                  );
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('SUPPRIMER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((user) {
      final texte = recherche.toLowerCase();

      final correspondRecherche = texte.isEmpty ||
          '${user.nom} ${user.prenom}'.toLowerCase().contains(texte) ||
          user.email.toLowerCase().contains(texte) ||
          user.numTel.toLowerCase().contains(texte);

      final roleName = _roleName(user.roleId);

      final correspondRole = filtreRole == 'Tous' || roleName == filtreRole;

      final correspondStatut =
          filtreStatut == 'Tous' || user.statut == filtreStatut;

      return correspondRecherche && correspondRole && correspondStatut;
    }).toList();

    final total = _users.length;
    final admins =
        _users.where((u) => _roleName(u.roleId) == 'ADMIN').length;
    final responsables =
        _users.where((u) => _roleName(u.roleId) == 'RESPONSABLE').length;
    final chauffeurs =
        _users.where((u) => _roleName(u.roleId) == 'CHAUFFEUR').length;
    final actifs = _users.where((u) => u.statut == 'actif').length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(selectedIndex: 1),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                      : _loadError != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;

                            final count = width > 1100
                                ? 5
                                : width > 750
                                ? 3
                                : 2;

                            return GridView.count(
                              crossAxisCount: count,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 2.1,
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStatCard(
                                  Icons.people_outline,
                                  'Total utilisateurs',
                                  total.toString(),
                                  primaryColor,
                                ),
                                _buildStatCard(
                                  Icons.admin_panel_settings_outlined,
                                  'Administrateurs',
                                  admins.toString(),
                                  dangerColor,
                                ),
                                _buildStatCard(
                                  Icons.manage_accounts_outlined,
                                  'Responsables',
                                  responsables.toString(),
                                  Colors.orange,
                                ),
                                _buildStatCard(
                                  Icons.local_shipping_outlined,
                                  'Chauffeurs',
                                  chauffeurs.toString(),
                                  accentColor,
                                ),
                                _buildStatCard(
                                  Icons.check_circle_outline,
                                  'Comptes actifs',
                                  actifs.toString(),
                                  Colors.green,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildUsersSection(filtered),
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

  // ============================================================
  // ETAT ERREUR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 45, color: dangerColor),
          const SizedBox(height: 10),
          Text(
            _loadError!,
            style: const TextStyle(color: dangerColor),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Utilisateurs',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================

  Widget _buildStatCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
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
  // SECTION UTILISATEURS
  // ============================================================

  Widget _buildUsersSection(List<UserModel> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Liste des utilisateurs',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvel utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email ou téléphone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: recherche.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  setState(() {
                    recherche = '';
                  });
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                recherche = value;
              });
            },
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._buildRoleFilters(),
              ..._buildStatusFilters(),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            '${filtered.length} utilisateur(s)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const Divider(),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 45,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Aucun utilisateur trouvé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Modifiez vos critères de recherche.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(_buildUserRow),
        ],
      ),
    );
  }

  // ============================================================
  // FILTRES
  // ============================================================

  List<Widget> _buildRoleFilters() {
    final filters = ['Tous', ..._roles.map((role) => role.name)];

    return filters.map((filter) {
      final selected = filtreRole == filter;

      return ChoiceChip(
        label: Text(filter),
        selected: selected,
        onSelected: (_) {
          setState(() {
            filtreRole = filter;
          });
        },
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
  }

  List<Widget> _buildStatusFilters() {
    const filters = ['Tous', 'actif', 'inactif'];

    const labels = {
      'Tous': 'Tous les statuts',
      'actif': 'Actifs',
      'inactif': 'Inactifs',
    };

    return filters.map((filter) {
      final selected = filtreStatut == filter;

      return ChoiceChip(
        label: Text(labels[filter]!),
        selected: selected,
        onSelected: (_) {
          setState(() {
            filtreStatut = filter;
          });
        },
        selectedColor: accentColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
  }

  // ============================================================
  // LIGNE UTILISATEUR (cliquable → profil)
  // ============================================================

  Widget _buildUserRow(UserModel user) {
    final roleName = _roleName(user.roleId);
    final roleColor = _colorForRole(roleName);
    final actif = user.statut == 'actif';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _voirProfil(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return _buildCompactUserRow(
                    user,
                    roleName,
                    roleColor,
                    actif,
                  );
                }

                return Row(
                  children: [
                    // 1. Photo
                    _buildUserAvatar(user),

                    const SizedBox(width: 12),

                    // 2. Nom + email
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.prenom} ${user.nom}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Téléphone (largeur fixe pour l'alignement)
                    SizedBox(
                      width: 130,
                      child: Text(
                        user.numTel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 4. Rôle
                    SizedBox(
                      width: 160,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleName,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 5. Statut
                    SizedBox(
                      width: 90,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _toggleStatut(user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (actif ? accentColor : Colors.grey)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                actif ? Icons.check_circle : Icons.block,
                                size: 13,
                                color: actif ? accentColor : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                actif ? 'Actif' : 'Inactif',
                                style: TextStyle(
                                  color: actif
                                      ? accentColor
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 6. Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Voir le profil',
                          onPressed: () => _voirProfil(user),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 19,
                          ),
                          color: accentColor,
                        ),
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () => _showForm(existing: user),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          color: primaryColor,
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDelete(user),
                          icon: const Icon(Icons.delete_outline, size: 19),
                          color: dangerColor,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR LISTE
  // ============================================================

  Widget _buildUserAvatar(UserModel user) {
    if (user.photoProfil != null && user.photoProfil!.isNotEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundColor: primaryColor.withValues(alpha: 0.10),
        backgroundImage: NetworkImage(user.photoProfil!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return _defaultAvatar(radius: 23);
  }

  // ============================================================
  // VERSION MOBILE / COMPACTE
  // ============================================================

  Widget _buildCompactUserRow(
      UserModel user,
      String roleName,
      Color roleColor,
      bool actif,
      ) {
    return Column(
      children: [
        Row(
          children: [
            _buildUserAvatar(user),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.prenom} ${user.nom}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: actif ? 'Désactiver' : 'Activer',
              onPressed: () => _toggleStatut(user),
              icon: Icon(
                actif ? Icons.toggle_on : Icons.toggle_off,
                color: actif ? accentColor : Colors.grey,
              ),
            ),
            IconButton(
              tooltip: 'Voir le profil',
              onPressed: () => _voirProfil(user),
              icon: const Icon(Icons.visibility_outlined, size: 19),
              color: accentColor,
            ),
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => _showForm(existing: user),
              icon: const Icon(Icons.edit_outlined, size: 19),
              color: primaryColor,
            ),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline, size: 19),
              color: dangerColor,
            ),
          ],
        ),
      ],
    );
  }
}*/

// lib/screens/admin/utilisateurs_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_export_service.dart';
import '../../services/user_service.dart';
import '../../widgets/sidebar_admin.dart';
import '../../widgets/user_avatar.dart';
import 'profil_utilisateur_screen.dart';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<UtilisateursScreen> {
  static const Color primaryColor = Color(0xFF1D3557);
  static const Color accentColor = Color(0xFF2A9D8F);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  final UserService _userService = UserService();

  List<UserModel> _users = [];
  List<RoleModel> _roles = [];

  bool _loading = true;
  String? _loadError;

  String filtreRole = 'Tous';
  String filtreStatut = 'Tous';
  String recherche = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // NAVIGATION : PROFIL
  // ============================================================

  void _voirProfil(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilUtilisateurScreen(
          utilisateur: user,
          sidebar: const SidebarAdmin(selectedIndex: 1),
        ),
      ),
    );
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;

    if (token == null) {
      setState(() {
        _loading = false;
        _loadError = 'Session utilisateur expirée.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _userService.getUsers(token),
        _userService.getRoles(token),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<UserModel>;
        _roles = results[1] as List<RoleModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> _exporter(List<UserModel> users) async {
    try {
      await UserExportService.exporter(users);
      _showMessage('Export Excel généré.', accentColor);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  String _roleName(String roleId) {
    final matches = _roles.where((r) => r.id == roleId);
    if (matches.isEmpty) return '—';
    return matches.first.name;
  }

  bool _isChauffeurRole(String? roleId) {
    if (roleId == null) return false;
    return _roleName(roleId).toUpperCase() == 'CHAUFFEUR';
  }

  Color _colorForRole(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'ADMIN':
        return dangerColor;
      case 'RESPONSABLE':
        return Colors.orange;
      case 'CHAUFFEUR':
        return accentColor;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Future<XFile?> _pickPhoto() async {
    try {
      final picker = ImagePicker();

      return await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );
    } catch (e) {
      _showMessage('Impossible de sélectionner la photo.', dangerColor);
      return null;
    }
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  void _showForm({UserModel? existing}) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final numTelCtrl = TextEditingController(text: existing?.numTel ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final siteCtrl =
    TextEditingController(text: existing?.siteAffectation ?? '');
    final passwordCtrl = TextEditingController();

    // Champs spécifiques au chauffeur
    final matriculeCtrl = TextEditingController();
    final permisCtrl = TextEditingController();
    final typePermisCtrl = TextEditingController();
    DateTime? dateEmbauche = DateTime.tryParse(existing?.dateEmbauche ?? '');

    // Si le compte a déjà une fiche chauffeur, ces champs sont facultatifs :
    // le backend conserve les anciennes valeurs quand ils sont vides.
    final bool ficheExiste = existing?.chauffeurId != null;

    XFile? selectedPhoto;
    Uint8List? photoBytes; // aperçu (lu une seule fois)

    String? roleId =
        existing?.roleId ?? (_roles.isNotEmpty ? _roles.first.id : null);

    String statut = existing?.statut ?? 'actif';

    bool saving = false;
    String? formError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool estChauffeur = _isChauffeurRole(roleId);

            Future<void> pickPhoto() async {
              final photo = await _pickPhoto();
              if (photo == null) return;

              final bytes = await photo.readAsBytes();

              setDialogState(() {
                selectedPhoto = photo;
                photoBytes = bytes;
              });
            }

            Future<void> pickDate() async {
              final d = await showDatePicker(
                context: context,
                initialDate: dateEmbauche ?? DateTime.now(),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (d == null) return;
              setDialogState(() => dateEmbauche = d);
            }

            Future<void> submit() async {
              setDialogState(() => formError = null);

              final nom = nomCtrl.text.trim();
              final prenom = prenomCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final numTel = numTelCtrl.text.trim();
              final address = addressCtrl.text.trim();
              final site = siteCtrl.text.trim();
              final password = passwordCtrl.text.trim();

              final matricule = matriculeCtrl.text.trim();
              final permis = permisCtrl.text.trim();
              final typePermis = typePermisCtrl.text.trim();

              // ------------------------------------------------
              // VALIDATION
              // ------------------------------------------------

              if (nom.isEmpty ||
                  prenom.isEmpty ||
                  email.isEmpty ||
                  numTel.isEmpty ||
                  site.isEmpty) {
                setDialogState(() {
                  formError = 'Veuillez remplir tous les champs obligatoires.';
                });
                return;
              }

              if (!_isValidEmail(email)) {
                setDialogState(() {
                  formError = 'Veuillez saisir une adresse email valide.';
                });
                return;
              }

              if (roleId == null) {
                setDialogState(() {
                  formError = 'Veuillez sélectionner un rôle.';
                });
                return;
              }

              if (existing == null && password.length < 8) {
                setDialogState(() {
                  formError =
                  'Le mot de passe doit contenir au moins 8 caractères.';
                });
                return;
              }

              if (existing != null &&
                  password.isNotEmpty &&
                  password.length < 8) {
                setDialogState(() {
                  formError =
                  'Le mot de passe doit contenir au moins 8 caractères.';
                });
                return;
              }

              // Champs chauffeur obligatoires seulement s'il n'y a pas
              // encore de fiche chauffeur pour ce compte.
              if (estChauffeur &&
                  !ficheExiste &&
                  (matricule.isEmpty || permis.isEmpty || typePermis.isEmpty)) {
                setDialogState(() {
                  formError =
                  'Veuillez remplir les informations du chauffeur (matricule, permis, type de permis).';
                });
                return;
              }

              final token = context.read<AuthProvider>().token;

              if (token == null) {
                setDialogState(() {
                  formError = 'Session expirée. Veuillez vous reconnecter.';
                });
                return;
              }

              setDialogState(() => saving = true);

              // Valeurs envoyées : null si vide (le backend garde l'ancien).
              final String? matriculeToSend =
              estChauffeur && matricule.isNotEmpty ? matricule : null;
              final String? permisToSend =
              estChauffeur && permis.isNotEmpty ? permis : null;
              final String? typePermisToSend =
              estChauffeur && typePermis.isNotEmpty ? typePermis : null;
              final String? dateToSend = estChauffeur && dateEmbauche != null
                  ? _formatDate(dateEmbauche!)
                  : null;

              try {
                if (existing == null) {
                  await _userService.createUser(
                    token: token,
                    nom: nom,
                    prenom: prenom,
                    email: email,
                    numTel: numTel,
                    password: password,
                    roleId: roleId!,
                    address: address,
                    statut: statut,
                    siteAffectation: site,
                    photo: selectedPhoto,
                    matricule: matriculeToSend,
                    permis: permisToSend,
                    typePermis: typePermisToSend,
                    dateEmbauche: dateToSend,
                  );
                } else {
                  await _userService.updateUser(
                    token: token,
                    id: existing.id,
                    nom: nom,
                    prenom: prenom,
                    email: email,
                    numTel: numTel,
                    password: password.isEmpty ? null : password,
                    roleId: roleId!,
                    address: address,
                    statut: statut,
                    siteAffectation: site,
                    photo: selectedPhoto,
                    matricule: matriculeToSend,
                    permis: permisToSend,
                    typePermis: typePermisToSend,
                    dateEmbauche: dateToSend,
                  );
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);

                _showMessage(
                  existing == null
                      ? 'Utilisateur créé avec succès.'
                      : 'Utilisateur modifié avec succès.',
                  accentColor,
                );

                await _loadData();
              } catch (e) {
                setDialogState(() {
                  saving = false;
                  formError = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    existing == null
                        ? Icons.person_add_alt_1
                        : Icons.edit_outlined,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existing == null
                          ? 'Nouvel utilisateur'
                          : 'Modifier l’utilisateur',
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------------- PHOTO ----------------
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: saving ? null : pickPhoto,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _buildFormPhoto(existing, photoBytes),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: saving ? null : pickPhoto,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                selectedPhoto == null
                                    ? 'Ajouter une photo de profil'
                                    : 'Changer la photo',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------------- NOM + PRENOM ----------------
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              controller: nomCtrl,
                              label: 'Nom *',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              controller: prenomCtrl,
                              label: 'Prénom *',
                              icon: Icons.person,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: emailCtrl,
                        label: 'Adresse email *',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: numTelCtrl,
                        label: 'Téléphone *',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: addressCtrl,
                        label: 'Adresse',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: siteCtrl,
                        label: 'Site d’affectation *',
                        icon: Icons.business_outlined,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller: passwordCtrl,
                        label: existing == null
                            ? 'Mot de passe *'
                            : 'Nouveau mot de passe',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        helperText: existing == null
                            ? 'Minimum 8 caractères.'
                            : 'Laissez vide pour conserver l’ancien.',
                      ),

                      const SizedBox(height: 14),

                      // ---------------- ROLE ----------------
                      DropdownButtonFormField<String>(
                        initialValue: roleId,
                        decoration: const InputDecoration(
                          labelText: 'Rôle *',
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role.id,
                            child: Text(role.name),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                          setDialogState(() => roleId = value);
                        },
                      ),

                      // ---------------- INFOS CHAUFFEUR ----------------
                      if (estChauffeur) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informations chauffeur',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (ficheExiste)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Laissez vide pour conserver les valeurs actuelles.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _formField(
                          controller: matriculeCtrl,
                          label: ficheExiste ? 'Matricule' : 'Matricule *',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: permisCtrl,
                          label: ficheExiste
                              ? 'Numéro de permis'
                              : 'Numéro de permis *',
                          icon: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: typePermisCtrl,
                          label: ficheExiste
                              ? 'Type de permis (B, C, D...)'
                              : 'Type de permis (B, C, D...) *',
                          icon: Icons.directions_car_outlined,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : pickDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              dateEmbauche == null
                                  ? 'Date d’embauche'
                                  : 'Embauché le ${_formatDate(dateEmbauche!)}',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // ---------------- STATUT ----------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              statut == 'actif'
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              color:
                              statut == 'actif' ? accentColor : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Compte actif',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: statut == 'actif',
                              activeColor: accentColor,
                              onChanged: saving
                                  ? null
                                  : (value) {
                                setDialogState(() {
                                  statut = value ? 'actif' : 'inactif';
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // ---------------- ERREUR ----------------
                      if (formError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formError!,
                            style: const TextStyle(
                              color: dangerColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PHOTO FORMULAIRE
  // ============================================================

  Widget _buildFormPhoto(UserModel? existing, Uint8List? photoBytes) {
    if (photoBytes != null) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: MemoryImage(photoBytes),
      );
    }

    return UserAvatar(url: existing?.photoProfil, radius: 55);
  }

  // ============================================================
  // EMAIL
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // ============================================================
  // ACTIVER / DESACTIVER
  // ============================================================

  Future<void> _toggleStatut(UserModel user) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _userService.updateUser(
        token: token,
        id: user.id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        numTel: user.numTel,
        roleId: user.roleId,
        address: user.address,
        siteAffectation: user.siteAffectation,
        statut: user.statut == 'actif' ? 'inactif' : 'actif',
        photo: null,
      );

      _showMessage(
        user.statut == 'actif' ? 'Compte désactivé.' : 'Compte activé.',
        accentColor,
      );

      await _loadData();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), dangerColor);
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: dangerColor),
              SizedBox(width: 10),
              Text('Supprimer le compte ?'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le compte de '
                '${user.prenom} ${user.nom} ?\n\n'
                'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ANNULER'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final token = context.read<AuthProvider>().token;
                if (token == null) return;

                Navigator.pop(dialogContext);

                try {
                  await _userService.deleteUser(token, user.id);

                  _showMessage('Utilisateur supprimé.', dangerColor);

                  await _loadData();
                } catch (e) {
                  _showMessage(
                    e.toString().replaceFirst('Exception: ', ''),
                    dangerColor,
                  );
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('SUPPRIMER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((user) {
      final texte = recherche.toLowerCase();

      final correspondRecherche = texte.isEmpty ||
          '${user.nom} ${user.prenom}'.toLowerCase().contains(texte) ||
          user.email.toLowerCase().contains(texte) ||
          user.numTel.toLowerCase().contains(texte) ||
          user.siteAffectation.toLowerCase().contains(texte);

      final roleName = _roleName(user.roleId);

      final correspondRole = filtreRole == 'Tous' || roleName == filtreRole;

      final correspondStatut =
          filtreStatut == 'Tous' || user.statut == filtreStatut;

      return correspondRecherche && correspondRole && correspondStatut;
    }).toList();

    final total = _users.length;
    final admins = _users.where((u) => _roleName(u.roleId) == 'ADMIN').length;
    final responsables =
        _users.where((u) => _roleName(u.roleId) == 'RESPONSABLE').length;
    final chauffeurs =
        _users.where((u) => _roleName(u.roleId) == 'CHAUFFEUR').length;
    final actifs = _users.where((u) => u.statut == 'actif').length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(selectedIndex: 1),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                      : _loadError != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;

                            final count = width > 1100
                                ? 5
                                : width > 750
                                ? 3
                                : 2;

                            return GridView.count(
                              crossAxisCount: count,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 2.1,
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStatCard(
                                  Icons.people_outline,
                                  'Total utilisateurs',
                                  total.toString(),
                                  primaryColor,
                                ),
                                _buildStatCard(
                                  Icons.admin_panel_settings_outlined,
                                  'Administrateurs',
                                  admins.toString(),
                                  dangerColor,
                                ),
                                _buildStatCard(
                                  Icons.manage_accounts_outlined,
                                  'Responsables',
                                  responsables.toString(),
                                  Colors.orange,
                                ),
                                _buildStatCard(
                                  Icons.local_shipping_outlined,
                                  'Chauffeurs',
                                  chauffeurs.toString(),
                                  accentColor,
                                ),
                                _buildStatCard(
                                  Icons.check_circle_outline,
                                  'Comptes actifs',
                                  actifs.toString(),
                                  Colors.green,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildUsersSection(filtered),
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

  // ============================================================
  // ETAT ERREUR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 45, color: dangerColor),
          const SizedBox(height: 10),
          Text(_loadError!, style: const TextStyle(color: dangerColor)),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Utilisateurs',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================

  Widget _buildStatCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
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
  // SECTION UTILISATEURS
  // ============================================================

  Widget _buildUsersSection(List<UserModel> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Liste des utilisateurs',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: filtered.isEmpty ? null : () => _exporter(filtered),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Exporter Excel'),
                style: OutlinedButton.styleFrom(foregroundColor: accentColor),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvel utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email, téléphone ou site...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: recherche.isNotEmpty
                  ? IconButton(
                onPressed: () => setState(() => recherche = ''),
                icon: const Icon(Icons.clear),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => recherche = value),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [..._buildRoleFilters(), ..._buildStatusFilters()],
          ),
          const SizedBox(height: 15),
          Text(
            '${filtered.length} utilisateur(s)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const Divider(),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 45,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Aucun utilisateur trouvé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Modifiez vos critères de recherche.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildListHeader(),
            ...filtered.map(_buildUserRow),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EN-TETE DE LA LISTE (colonnes)
  // ============================================================

  Widget _buildListHeader() {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Color(0xFF6B7280),
      letterSpacing: 0.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              SizedBox(width: 58),
              Expanded(flex: 3, child: Text('UTILISATEUR', style: style)),
              SizedBox(width: 130, child: Text('TÉLÉPHONE', style: style)),
              SizedBox(
                width: 150,
                child: Text('SITE D’AFFECTATION', style: style),
              ),
              SizedBox(
                width: 160,
                child: Center(child: Text('RÔLE', style: style)),
              ),
              SizedBox(width: 10),
              SizedBox(width: 90, child: Text('STATUT', style: style)),
              SizedBox(width: 8),
              SizedBox(
                width: 144,
                child: Center(child: Text('ACTIONS', style: style)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTRES
  // ============================================================

  List<Widget> _buildRoleFilters() {
    final filters = ['Tous', ..._roles.map((role) => role.name)];

    return filters.map((filter) {
      final selected = filtreRole == filter;

      return ChoiceChip(
        label: Text(filter),
        selected: selected,
        onSelected: (_) => setState(() => filtreRole = filter),
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
  }

  List<Widget> _buildStatusFilters() {
    const filters = ['Tous', 'actif', 'inactif'];

    const labels = {
      'Tous': 'Tous les statuts',
      'actif': 'Actifs',
      'inactif': 'Inactifs',
    };

    return filters.map((filter) {
      final selected = filtreStatut == filter;

      return ChoiceChip(
        label: Text(labels[filter]!),
        selected: selected,
        onSelected: (_) => setState(() => filtreStatut = filter),
        selectedColor: accentColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
  }

  // ============================================================
  // LIGNE UTILISATEUR (cliquable → profil)
  // ============================================================

  Widget _buildUserRow(UserModel user) {
    final roleName = _roleName(user.roleId);
    final roleColor = _colorForRole(roleName);
    final actif = user.statut == 'actif';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _voirProfil(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return _buildCompactUserRow(
                    user,
                    roleName,
                    roleColor,
                    actif,
                  );
                }

                return Row(
                  children: [
                    // 1. Photo
                    UserAvatar(url: user.photoProfil, radius: 23),

                    const SizedBox(width: 12),

                    // 2. Nom + email
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.prenom} ${user.nom}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Téléphone
                    SizedBox(
                      width: 130,
                      child: Text(
                        user.numTel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 3b. Site d'affectation
                    SizedBox(
                      width: 150,
                      child: Text(
                        user.siteAffectation.isEmpty
                            ? '—'
                            : user.siteAffectation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 4. Rôle
                    SizedBox(
                      width: 160,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleName,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 5. Statut
                    SizedBox(
                      width: 90,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _toggleStatut(user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (actif ? accentColor : Colors.grey)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                actif ? Icons.check_circle : Icons.block,
                                size: 13,
                                color: actif ? accentColor : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                actif ? 'Actif' : 'Inactif',
                                style: TextStyle(
                                  color: actif
                                      ? accentColor
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 6. Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Voir le profil',
                          onPressed: () => _voirProfil(user),
                          icon: const Icon(Icons.visibility_outlined, size: 19),
                          color: accentColor,
                        ),
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () => _showForm(existing: user),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          color: primaryColor,
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDelete(user),
                          icon: const Icon(Icons.delete_outline, size: 19),
                          color: dangerColor,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VERSION MOBILE / COMPACTE
  // ============================================================

  Widget _buildCompactUserRow(
      UserModel user,
      String roleName,
      Color roleColor,
      bool actif,
      ) {
    return Column(
      children: [
        Row(
          children: [
            UserAvatar(url: user.photoProfil, radius: 23),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.prenom} ${user.nom}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  if (user.siteAffectation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Site : ${user.siteAffectation}',
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: actif ? 'Désactiver' : 'Activer',
              onPressed: () => _toggleStatut(user),
              icon: Icon(
                actif ? Icons.toggle_on : Icons.toggle_off,
                color: actif ? accentColor : Colors.grey,
              ),
            ),
            IconButton(
              tooltip: 'Voir le profil',
              onPressed: () => _voirProfil(user),
              icon: const Icon(Icons.visibility_outlined, size: 19),
              color: accentColor,
            ),
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => _showForm(existing: user),
              icon: const Icon(Icons.edit_outlined, size: 19),
              color: primaryColor,
            ),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline, size: 19),
              color: dangerColor,
            ),
          ],
        ),
      ],
    );
  }
}
