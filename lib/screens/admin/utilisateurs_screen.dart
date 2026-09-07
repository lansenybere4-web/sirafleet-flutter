import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/sidebar_admin.dart';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() =>
      _UtilisateursScreenState();
}

class _UtilisateursScreenState
    extends State<UtilisateursScreen> {
  static const Color primaryColor =
  Color(0xFF1D3557);

  static const Color accentColor =
  Color(0xFF2A9D8F);

  static const Color dangerColor =
  Color(0xFFE63946);

  static const Color backgroundColor =
  Color(0xFFF5F7FA);

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
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    final token =
        context.read<AuthProvider>().token;

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
        _users =
        results[0] as List<UserModel>;

        _roles =
        results[1] as List<RoleModel>;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e
            .toString()
            .replaceFirst('Exception: ', '');

        _loading = false;
      });
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  String _roleName(String roleId) {
    final matches =
    _roles.where((r) => r.id == roleId);

    if (matches.isEmpty) {
      return '—';
    }

    return matches.first.name;
  }

  /// Renvoie vrai si l'identifiant de rôle passé correspond au
  /// rôle "Chauffeur" (comparaison insensible à la casse).
  bool _isChauffeurRole(String? roleId) {
    if (roleId == null) {
      return false;
    }

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
      _showMessage(
        'Impossible de sélectionner la photo.',
        dangerColor,
      );

      return null;
    }
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  void _showForm({
    UserModel? existing,
  }) {
    final nomCtrl = TextEditingController(
      text: existing?.nom ?? '',
    );

    final prenomCtrl = TextEditingController(
      text: existing?.prenom ?? '',
    );

    final emailCtrl = TextEditingController(
      text: existing?.email ?? '',
    );

    final numTelCtrl = TextEditingController(
      text: existing?.numTel ?? '',
    );

    final addressCtrl = TextEditingController(
      text: existing?.address ?? '',
    );

    final passwordCtrl =
    TextEditingController();

    // ========================================================
    // CHAMPS SPECIFIQUES AU CHAUFFEUR
    // ========================================================

    final matriculeCtrl = TextEditingController();
    final permisCtrl = TextEditingController();
    final typePermisCtrl = TextEditingController();

    XFile? selectedPhoto;

    String? roleId =
        existing?.roleId ??
            (_roles.isNotEmpty
                ? _roles.first.id
                : null);

    String statut =
        existing?.statut ?? 'actif';

    bool saving = false;
    String? formError;

    showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            final bool estChauffeur =
            _isChauffeurRole(roleId);

            Future<void> pickPhoto() async {
              final photo =
              await _pickPhoto();

              if (photo == null) {
                return;
              }

              setDialogState(() {
                selectedPhoto = photo;
              });
            }

            Future<void> submit() async {
              setDialogState(() {
                formError = null;
              });

              final nom =
              nomCtrl.text.trim();

              final prenom =
              prenomCtrl.text.trim();

              final email =
              emailCtrl.text.trim();

              final numTel =
              numTelCtrl.text.trim();

              final address =
              addressCtrl.text.trim();

              final password =
              passwordCtrl.text.trim();

              final matricule =
              matriculeCtrl.text.trim();

              final permis =
              permisCtrl.text.trim();

              final typePermis =
              typePermisCtrl.text.trim();

              // ------------------------------------------------
              // VALIDATION
              // ------------------------------------------------

              if (nom.isEmpty ||
                  prenom.isEmpty ||
                  email.isEmpty ||
                  numTel.isEmpty) {
                setDialogState(() {
                  formError =
                  'Veuillez remplir tous les champs obligatoires.';
                });
                return;
              }

              if (!_isValidEmail(email)) {
                setDialogState(() {
                  formError =
                  'Veuillez saisir une adresse email valide.';
                });
                return;
              }

              if (roleId == null) {
                setDialogState(() {
                  formError =
                  'Veuillez sélectionner un rôle.';
                });
                return;
              }

              if (existing == null &&
                  password.length < 8) {
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

              // ------------------------------------------------
              // VALIDATION SPECIFIQUE AU ROLE CHAUFFEUR
              // ------------------------------------------------

              if (estChauffeur &&
                  (matricule.isEmpty ||
                      permis.isEmpty ||
                      typePermis.isEmpty)) {
                setDialogState(() {
                  formError =
                  'Veuillez remplir les informations du chauffeur (matricule, permis, type de permis).';
                });
                return;
              }

              final token =
                  context
                      .read<AuthProvider>()
                      .token;

              if (token == null) {
                setDialogState(() {
                  formError =
                  'Session expirée. Veuillez vous reconnecter.';
                });
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                // ----------------------------------------------
                // CREATION
                // ----------------------------------------------

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
                    matricule:
                    estChauffeur ? matricule : null,
                    permis:
                    estChauffeur ? permis : null,
                    typePermis:
                    estChauffeur ? typePermis : null,
                  );
                }

                // ----------------------------------------------
                // MODIFICATION
                // ----------------------------------------------

                else {
                  await _userService.updateUser(
                    token: token,
                    id: existing.id,
                    nom: nom,
                    prenom: prenom,
                    email: email,
                    numTel: numTel,
                    password: password.isEmpty
                        ? null
                        : password,
                    roleId: roleId!,
                    address: address,
                    statut: statut,
                    photo: selectedPhoto,
                    matricule:
                    estChauffeur ? matricule : null,
                    permis:
                    estChauffeur ? permis : null,
                    typePermis:
                    estChauffeur ? typePermis : null,
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

                  formError = e
                      .toString()
                      .replaceFirst(
                    'Exception: ',
                    '',
                  );
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
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // ========================================
                      // PHOTO
                      // ========================================

                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: saving
                                  ? null
                                  : pickPhoto,
                              child: Stack(
                                alignment:
                                Alignment.bottomRight,
                                children: [
                                  _buildFormPhoto(
                                    existing,
                                    selectedPhoto,
                                  ),

                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration:
                                    BoxDecoration(
                                      color:
                                      primaryColor,
                                      shape:
                                      BoxShape.circle,
                                      border:
                                      Border.all(
                                        color:
                                        Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                    const Icon(
                                      Icons
                                          .camera_alt_outlined,
                                      size: 18,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            TextButton.icon(
                              onPressed:
                              saving
                                  ? null
                                  : pickPhoto,
                              icon: const Icon(
                                Icons
                                    .photo_library_outlined,
                              ),
                              label: Text(
                                selectedPhoto ==
                                    null
                                    ? 'Ajouter une photo de profil'
                                    : 'Changer la photo',
                              ),
                              style:
                              TextButton
                                  .styleFrom(
                                foregroundColor:
                                primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ========================================
                      // NOM + PRENOM
                      // ========================================

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                              nomCtrl,
                              decoration:
                              const InputDecoration(
                                labelText:
                                'Nom *',
                                prefixIcon:
                                Icon(
                                  Icons
                                      .person_outline,
                                ),
                                border:
                                OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: TextField(
                              controller:
                              prenomCtrl,
                              decoration:
                              const InputDecoration(
                                labelText:
                                'Prénom *',
                                prefixIcon:
                                Icon(
                                  Icons.person,
                                ),
                                border:
                                OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // EMAIL
                      // ========================================

                      TextField(
                        controller:
                        emailCtrl,
                        keyboardType:
                        TextInputType
                            .emailAddress,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Adresse email *',
                          prefixIcon:
                          Icon(
                            Icons
                                .email_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // TELEPHONE
                      // ========================================

                      TextField(
                        controller:
                        numTelCtrl,
                        keyboardType:
                        TextInputType.phone,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Téléphone *',
                          prefixIcon:
                          Icon(
                            Icons
                                .phone_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // ADRESSE
                      // ========================================

                      TextField(
                        controller:
                        addressCtrl,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Adresse',
                          prefixIcon:
                          Icon(
                            Icons
                                .location_on_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // MOT DE PASSE
                      // ========================================

                      TextField(
                        controller:
                        passwordCtrl,
                        obscureText: true,
                        decoration:
                        InputDecoration(
                          labelText: existing ==
                              null
                              ? 'Mot de passe *'
                              : 'Nouveau mot de passe',
                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),
                          helperText: existing ==
                              null
                              ? 'Minimum 8 caractères.'
                              : 'Laissez vide pour conserver l’ancien.',
                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // ROLE
                      // ========================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                        roleId,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Rôle *',
                          prefixIcon:
                          Icon(
                            Icons
                                .admin_panel_settings_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items:
                        _roles.map(
                              (role) {
                            return DropdownMenuItem<
                                String>(
                              value:
                              role.id,
                              child:
                              Text(
                                role.name,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                        saving
                            ? null
                            : (value) {
                          setDialogState(
                                () {
                              roleId =
                                  value;
                            },
                          );
                        },
                      ),

                      // ========================================
                      // INFORMATIONS CHAUFFEUR (si rôle = chauffeur)
                      // ========================================

                      if (estChauffeur) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        const Divider(),

                        const SizedBox(
                          height: 6,
                        ),

                        const Align(
                          alignment:
                          Alignment.centerLeft,
                          child: Text(
                            'Informations chauffeur',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        TextField(
                          controller:
                          matriculeCtrl,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Matricule *',
                            prefixIcon: Icon(
                              Icons
                                  .badge_outlined,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller:
                          permisCtrl,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Numéro de permis *',
                            prefixIcon: Icon(
                              Icons
                                  .credit_card_outlined,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller:
                          typePermisCtrl,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Type de permis (B, C, D...) *',
                            prefixIcon: Icon(
                              Icons
                                  .motorcycle_outlined,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 14,
                      ),

                      // ========================================
                      // STATUT
                      // ========================================

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration:
                        BoxDecoration(
                          border:
                          Border.all(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              statut ==
                                  'actif'
                                  ? Icons
                                  .check_circle_outline
                                  : Icons
                                  .block_outlined,
                              color:
                              statut ==
                                  'actif'
                                  ? accentColor
                                  : Colors
                                  .grey,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Expanded(
                              child: Text(
                                'Compte actif',
                                style:
                                TextStyle(
                                  fontSize:
                                  13,
                                  fontWeight:
                                  FontWeight
                                      .w500,
                                ),
                              ),
                            ),
                            Switch(
                              value:
                              statut ==
                                  'actif',
                              activeColor:
                              accentColor,
                              onChanged:
                              saving
                                  ? null
                                  : (value) {
                                setDialogState(
                                      () {
                                    statut =
                                    value
                                        ? 'actif'
                                        : 'inactif';
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ========================================
                      // ERREUR
                      // ========================================

                      if (formError !=
                          null) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        Container(
                          width:
                          double.infinity,
                          padding:
                          const EdgeInsets
                              .all(10),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFFFF1F0,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                          ),
                          child: Text(
                            formError!,
                            style:
                            const TextStyle(
                              color:
                              dangerColor,
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
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(
                    dialogContext,
                  ),
                  child:
                  const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed:
                  saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Enregistrer',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    primaryColor,
                    foregroundColor:
                    Colors.white,
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

  Widget _buildFormPhoto(
      UserModel? existing,
      XFile? selectedPhoto,
      ) {
    if (selectedPhoto != null) {
      return FutureBuilder<List<int>>(
        future: selectedPhoto.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 55,
              backgroundImage:
              MemoryImage(
                Uint8List.fromList(
                  snapshot.data!,
                ),
              ),
            );
          }

          return _defaultAvatar(
            radius: 55,
          );
        },
      );
    }

    if (existing?.photoProfil != null &&
        existing!.photoProfil!.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundColor:
        primaryColor.withValues(
          alpha: 0.10,
        ),
        backgroundImage:
        NetworkImage(
          existing.photoProfil!,
        ),
      );
    }

    return _defaultAvatar(
      radius: 55,
    );
  }

  Widget _defaultAvatar({
    double radius = 23,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
      primaryColor.withValues(
        alpha: 0.10,
      ),
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
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ============================================================
  // ACTIVER / DESACTIVER
  // ============================================================

  Future<void> _toggleStatut(
      UserModel user,
      ) async {
    final token =
        context.read<AuthProvider>().token;

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
        statut: user.statut == 'actif'
            ? 'inactif'
            : 'actif',
        photo: null,
      );

      _showMessage(
        user.statut == 'actif'
            ? 'Compte désactivé.'
            : 'Compte activé.',
        accentColor,
      );

      await _loadData();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        dangerColor,
      );
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  void _confirmDelete(
      UserModel user,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: dangerColor,
              ),
              SizedBox(width: 10),
              Text(
                'Supprimer le compte ?',
              ),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le compte de '
                '${user.prenom} ${user.nom} ?\n\n'
                'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                  ),
              child:
              const Text('ANNULER'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final token = context
                    .read<AuthProvider>()
                    .token;

                if (token == null) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                try {
                  await _userService
                      .deleteUser(
                    token,
                    user.id,
                  );

                  _showMessage(
                    'Utilisateur supprimé.',
                    dangerColor,
                  );

                  await _loadData();
                } catch (e) {
                  _showMessage(
                    e.toString()
                        .replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    dangerColor,
                  );
                }
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label:
              const Text('SUPPRIMER'),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                dangerColor,
                foregroundColor:
                Colors.white,
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

  void _showMessage(
      String message,
      Color color,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final filtered = _users.where(
          (user) {
        final texte =
        recherche.toLowerCase();

        final correspondRecherche =
            texte.isEmpty ||
                '${user.nom} ${user.prenom}'
                    .toLowerCase()
                    .contains(texte) ||
                user.email
                    .toLowerCase()
                    .contains(texte) ||
                user.numTel
                    .toLowerCase()
                    .contains(texte);

        final roleName =
        _roleName(user.roleId);

        final correspondRole =
            filtreRole == 'Tous' ||
                roleName == filtreRole;

        final correspondStatut =
            filtreStatut == 'Tous' ||
                user.statut ==
                    filtreStatut;

        return correspondRecherche &&
            correspondRole &&
            correspondStatut;
      },
    ).toList();

    final total = _users.length;

    final admins = _users
        .where(
          (u) =>
      _roleName(u.roleId) ==
          'ADMIN',
    )
        .length;

    final responsables = _users
        .where(
          (u) =>
      _roleName(u.roleId) ==
          'RESPONSABLE',
    )
        .length;

    final chauffeurs = _users
        .where(
          (u) =>
      _roleName(u.roleId) ==
          'CHAUFFEUR',
    )
        .length;

    final actifs = _users
        .where(
          (u) => u.statut == 'actif',
    )
        .length;

    return Scaffold(
      backgroundColor:
      backgroundColor,
      body: Row(
        children: [
          const SidebarAdmin(
            selectedIndex: 1,
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _loading
                      ? const Center(
                    child:
                    CircularProgressIndicator(
                      color:
                      primaryColor,
                    ),
                  )
                      : _loadError != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                    padding:
                    const EdgeInsets
                        .all(24),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        // ==================================
                        // STATISTIQUES
                        // ==================================

                        LayoutBuilder(
                          builder:
                              (
                              context,
                              constraints,
                              ) {
                            final width =
                                constraints
                                    .maxWidth;

                            final count =
                            width >
                                1100
                                ? 5
                                : width >
                                750
                                ? 3
                                : 2;

                            return GridView
                                .count(
                              crossAxisCount:
                              count,
                              crossAxisSpacing:
                              14,
                              mainAxisSpacing:
                              14,
                              childAspectRatio:
                              2.1,
                              shrinkWrap:
                              true,
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

                        const SizedBox(
                          height: 24,
                        ),

                        _buildUsersSection(
                          filtered,
                        ),
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
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 45,
            color: dangerColor,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            _loadError!,
            style:
            const TextStyle(
              color: dangerColor,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          ElevatedButton(
            onPressed: _loadData,
            child:
            const Text('Réessayer'),
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: 25,
      ),
      decoration:
      const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Utilisateurs',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh,
              color: primaryColor,
            ),
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
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
            BoxDecoration(
              color:
              color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    primaryColor,
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

  Widget _buildUsersSection(
      List<UserModel> filtered,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Liste des utilisateurs',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed:
                    () => _showForm(),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  'Nouvel utilisateur',
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          TextField(
            decoration:
            InputDecoration(
              hintText:
              'Rechercher par nom, email ou téléphone...',
              prefixIcon:
              const Icon(
                Icons.search,
              ),
              suffixIcon:
              recherche.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  setState(
                        () {
                      recherche =
                      '';
                    },
                  );
                },
                icon:
                const Icon(
                  Icons.clear,
                ),
              )
                  : null,
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
            ),
            onChanged:
                (value) {
              setState(() {
                recherche =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 15,
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._buildRoleFilters(),
              ..._buildStatusFilters(),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            '${filtered.length} utilisateur(s)',
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 11,
            ),
          ),

          const Divider(),

          if (filtered.isEmpty)
            Padding(
              padding:
              const EdgeInsets.symmetric(
                vertical: 35,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons
                          .people_outline,
                      size: 45,
                      color: Colors
                          .grey
                          .shade400,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Aucun utilisateur trouvé',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        color:
                        primaryColor,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Modifiez vos critères de recherche.',
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(
              _buildUserRow,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTRES ROLES
  // ============================================================

  List<Widget> _buildRoleFilters() {
    final filters = [
      'Tous',
      ..._roles.map(
            (role) => role.name,
      ),
    ];

    return filters.map(
          (filter) {
        final selected =
            filtreRole == filter;

        return ChoiceChip(
          label: Text(filter),
          selected: selected,
          onSelected: (_) {
            setState(() {
              filtreRole =
                  filter;
            });
          },
          selectedColor:
          primaryColor,
          labelStyle:
          TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // FILTRES STATUT
  // ============================================================

  List<Widget> _buildStatusFilters() {
    const filters = [
      'Tous',
      'actif',
      'inactif',
    ];

    const labels = {
      'Tous':
      'Tous les statuts',
      'actif': 'Actifs',
      'inactif': 'Inactifs',
    };

    return filters.map(
          (filter) {
        final selected =
            filtreStatut == filter;

        return ChoiceChip(
          label: Text(
            labels[filter]!,
          ),
          selected: selected,
          onSelected: (_) {
            setState(() {
              filtreStatut =
                  filter;
            });
          },
          selectedColor:
          accentColor,
          labelStyle:
          TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // LIGNE UTILISATEUR
  // ============================================================

  Widget _buildUserRow(
      UserModel user,
      ) {
    final roleName =
    _roleName(user.roleId);

    final roleColor =
    _colorForRole(roleName);

    final actif =
        user.statut == 'actif';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration:
      BoxDecoration(
        color: backgroundColor,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          if (constraints
              .maxWidth <
              700) {
            return _buildCompactUserRow(
              user,
              roleName,
              roleColor,
              actif,
            );
          }

          return Row(
            children: [
              _buildUserAvatar(user),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      '${user.prenom} ${user.nom}',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      user.email,
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  user.numTel,
                  style:
                  const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: roleColor
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Text(
                  roleName,
                  style:
                  TextStyle(
                    color: roleColor,
                    fontSize: 10,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              InkWell(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                onTap: () =>
                    _toggleStatut(
                      user,
                    ),
                child: Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: (actif
                        ? accentColor
                        : Colors.grey)
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        actif
                            ? Icons
                            .check_circle
                            : Icons.block,
                        size: 13,
                        color: actif
                            ? accentColor
                            : Colors.grey,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        actif
                            ? 'Actif'
                            : 'Inactif',
                        style:
                        TextStyle(
                          color: actif
                              ? accentColor
                              : Colors
                              .grey
                              .shade600,
                          fontSize: 10,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              IconButton(
                tooltip:
                'Modifier',
                onPressed: () =>
                    _showForm(
                      existing: user,
                    ),
                icon:
                const Icon(
                  Icons
                      .edit_outlined,
                  size: 19,
                ),
                color:
                primaryColor,
              ),

              IconButton(
                tooltip:
                'Supprimer',
                onPressed: () =>
                    _confirmDelete(
                      user,
                    ),
                icon:
                const Icon(
                  Icons
                      .delete_outline,
                  size: 19,
                ),
                color:
                dangerColor,
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // AVATAR LISTE
  // ============================================================

  Widget _buildUserAvatar(
      UserModel user,
      ) {
    if (user.photoProfil != null &&
        user.photoProfil!.isNotEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundColor:
        primaryColor.withValues(
          alpha: 0.10,
        ),
        backgroundImage:
        NetworkImage(
          user.photoProfil!,
        ),
        onBackgroundImageError:
            (_, __) {},
      );
    }

    return _defaultAvatar(
      radius: 23,
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
            _buildUserAvatar(user),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    '${user.prenom} ${user.nom}',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight
                          .bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    user.email,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        Row(
          children: [
            Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                roleColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),
              ),
              child: Text(
                roleName,
                style:
                TextStyle(
                  color: roleColor,
                  fontSize: 9,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const Spacer(),

            IconButton(
              tooltip:
              actif
                  ? 'Désactiver'
                  : 'Activer',
              onPressed: () =>
                  _toggleStatut(
                    user,
                  ),
              icon: Icon(
                actif
                    ? Icons.toggle_on
                    : Icons.toggle_off,
                color: actif
                    ? accentColor
                    : Colors.grey,
              ),
            ),

            IconButton(
              tooltip:
              'Modifier',
              onPressed: () =>
                  _showForm(
                    existing: user,
                  ),
              icon:
              const Icon(
                Icons
                    .edit_outlined,
                size: 19,
              ),
              color:
              primaryColor,
            ),

            IconButton(
              tooltip:
              'Supprimer',
              onPressed: () =>
                  _confirmDelete(
                    user,
                  ),
              icon:
              const Icon(
                Icons
                    .delete_outline,
                size: 19,
              ),
              color:
              dangerColor,
            ),
          ],
        ),
      ],
    );
  }
}
