import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/dashboard_screen.dart';
import '../../providers/auth_provider.dart';
import '../responsable/dashboard_screen.dart';
import '../chauffeur/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  static const Color primary =
  Color(0xFF1D3557);

  static const Color background =
  Color(0xFFF5F7FA);

  final _formKey =
  GlobalKey<FormState>();

  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider =
    context.read<AuthProvider>();

    final success =
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted || !success) {
      return;
    }

    final user =
        authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Utilisateur introuvable après connexion.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '========================================',
    );

    debugPrint(
      'Utilisateur : ${user.nom} ${user.prenom}',
    );

    debugPrint(
      'Email : ${user.email}',
    );

    debugPrint(
      'Role brut : "${user.role}"',
    );

    debugPrint(
      'Role normalisé : "${authProvider.normalizedRole}"',
    );

    debugPrint(
      '========================================',
    );

    // ==========================================================
    // DESTINATION
    // ==========================================================

    Widget? destination;

    // ==========================================================
    // ADMIN
    // ==========================================================

    if (authProvider.isAdmin) {
      destination =
      const AdminDashboardScreen();
    }

    // ==========================================================
    // RESPONSABLE DE FLOTTE
    // ==========================================================

    else if (
    authProvider.isResponsableFlotte) {
      destination =
      const ResponsableDashboardScreen();
    }

    // ==========================================================
    // DIRECTEUR
    // ==========================================================

    else if (authProvider.isDirecteur) {
      /*
      Lorsque ton dashboard Directeur
      sera prêt, décommente :

      destination =
          const DirecteurDashboardScreen();
      */

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Dashboard Directeur non disponible pour le moment.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // CHAUFFEUR
    // ==========================================================

    else if (authProvider.isChauffeur) {
      destination =
      const ChauffeurHomeScreen();
    }

    // ==========================================================
    // ROLE INCONNU
    // ==========================================================

    else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Rôle utilisateur non reconnu : "${user.role}"',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // NAVIGATION
    // ==========================================================

    if (!mounted ||
        destination == null) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
          (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final authProvider =
    context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: background,

      body: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 420,
            ),

            child: Card(
              elevation: 4,

              shadowColor:
              Colors.black.withValues(
                alpha: 0.08,
              ),

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),

              child: Padding(
                padding:
                const EdgeInsets.all(32),

                child: Form(
                  key: _formKey,

                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,

                              decoration:
                              BoxDecoration(
                                color: primary,
                                borderRadius:
                                BorderRadius
                                    .circular(16),
                              ),

                              child:
                              const Icon(
                                Icons
                                    .local_shipping_rounded,
                                color:
                                Colors.white,
                                size: 34,
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            const Text(
                              'SiraFleet',
                              style:
                              TextStyle(
                                fontSize: 30,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color: primary,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            const Text(
                              'Gestion intelligente des flottes',
                              textAlign:
                              TextAlign.center,
                              style:
                              TextStyle(
                                fontSize: 13,
                                color:
                                Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      // ==================================================
                      // TITRE
                      // ==================================================

                      const Text(
                        'Connexion',
                        style:
                        TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                          color: primary,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Connectez-vous à votre espace SiraFleet.',
                        style:
                        TextStyle(
                          fontSize: 13,
                          color:
                          Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      TextFormField(
                        controller:
                        _emailController,

                        keyboardType:
                        TextInputType
                            .emailAddress,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        InputDecoration(
                          labelText:
                          'Adresse email',

                          hintText:
                          'exemple@sirafleet.com',

                          prefixIcon:
                          const Icon(
                            Icons
                                .email_outlined,
                          ),

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),
                          ),

                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),

                            borderSide:
                            BorderSide(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                          ),

                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),

                            borderSide:
                            const BorderSide(
                              color: primary,
                              width: 2,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Veuillez saisir votre email.';
                          }

                          if (!value
                              .contains('@')) {
                            return 'Veuillez saisir un email valide.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // PASSWORD
                      // ==================================================

                      TextFormField(
                        controller:
                        _passwordController,

                        obscureText:
                        _obscurePassword,

                        textInputAction:
                        TextInputAction.done,

                        onFieldSubmitted:
                            (_) =>
                            _handleLogin(),

                        decoration:
                        InputDecoration(
                          labelText:
                          'Mot de passe',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),

                          suffixIcon:
                          IconButton(
                            tooltip:
                            _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',

                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                  .visibility_off_outlined
                                  : Icons
                                  .visibility_outlined,
                            ),

                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                          ),

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),
                          ),

                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),

                            borderSide:
                            BorderSide(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                          ),

                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),

                            borderSide:
                            const BorderSide(
                              color: primary,
                              width: 2,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe.';
                          }

                          if (value.length < 8) {
                            return 'Le mot de passe doit contenir au moins 8 caractères.';
                          }

                          return null;
                        },
                      ),

                      // ==================================================
                      // ERREUR
                      // ==================================================

                      if (authProvider
                          .errorMessage !=
                          null) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        Container(
                          width:
                          double.infinity,

                          padding:
                          const EdgeInsets
                              .all(12),

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFFFF1F0,
                            ),

                            borderRadius:
                            BorderRadius
                                .circular(10),
                          ),

                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              const Icon(
                                Icons
                                    .error_outline,
                                color:
                                Colors.red,
                                size: 20,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Expanded(
                                child: Text(
                                  authProvider
                                      .errorMessage!,
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.red,
                                    fontSize:
                                    13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // BOUTON
                      // ==================================================

                      SizedBox(
                        width:
                        double.infinity,

                        height: 50,

                        child:
                        ElevatedButton(
                          onPressed:
                          authProvider
                              .isLoading
                              ? null
                              : _handleLogin,

                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            primary,

                            foregroundColor:
                            Colors.white,

                            elevation: 0,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(12),
                            ),
                          ),

                          child:
                          authProvider
                              .isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              color:
                              Colors.white,
                              strokeWidth:
                              2,
                            ),
                          )
                              : const Text(
                            'Se connecter',
                            style:
                            TextStyle(
                              fontSize:
                              15,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Center(
                        child: Text(
                          'SiraFleet • Gestion intelligente des flottes',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize: 11,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}