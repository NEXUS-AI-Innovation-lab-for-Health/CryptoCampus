import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _lessonPlacesController = TextEditingController(text: 'Visio');
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // null tant que l'utilisateur n'a pas choisi — impossible de soumettre sans choix,
  // comme côté web (Login.vue).
  String? _desiredRole; // 'student' | 'tutor'
  String _lessonMode = 'Visio';
  String _visioTool = 'Zoom';

  static const _lessonModes = ['Visio', 'Presentiel', 'Hybride'];
  static const _visioTools = ['Zoom', 'Teams', 'Google Meet', 'Discord', 'Autre'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _referralCodeController.dispose();
    _lessonPlacesController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_desiredRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez si vous créez un compte étudiant ou tuteur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final lessonPlaces = _lessonPlacesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final error = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      desiredRole: _desiredRole!,
      referralCode: _desiredRole == 'student' ? _referralCodeController.text.trim() : null,
      lessonMode: _desiredRole == 'tutor' ? _lessonMode : null,
      visioTool: _desiredRole == 'tutor' && (_lessonMode == 'Visio' || _lessonMode == 'Hybride')
          ? _visioTool
          : null,
      lessonPlaces: _desiredRole == 'tutor' ? (lessonPlaces.isEmpty ? ['Visio'] : lessonPlaces) : null,
    );

    if (!mounted) return;

    if (error == null) {
      // Inscription réussie : on connecte directement l'utilisateur, comme le fait
      // Login.vue (auto-switch + auto-login après inscription).
      final loginError = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (loginError == null) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _roleChoiceButton({
    required String role,
    required String emoji,
    required String label,
  }) {
    final selected = _desiredRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _desiredRole = role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Veuillez entrer votre prénom' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Veuillez entrer votre nom' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                    if (!value.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                    if (value.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Je crée un compte...', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _roleChoiceButton(role: 'student', emoji: '🎓', label: 'Étudiant(e)'),
                    const SizedBox(width: 12),
                    _roleChoiceButton(role: 'tutor', emoji: '👨‍🏫', label: 'Tuteur/Tutrice'),
                  ],
                ),
                if (_desiredRole == 'student') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _referralCodeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: 'Code de parrainage',
                      hintText: 'Ex : AB12CD34',
                      helperText: 'Un code de parrainage valide est obligatoire pour créer un compte étudiant.',
                      prefixIcon: const Icon(Icons.card_giftcard_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (_desiredRole == 'student' && (value == null || value.trim().isEmpty)) {
                        return 'Le code de parrainage est requis';
                      }
                      return null;
                    },
                  ),
                ],
                if (_desiredRole == 'tutor') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _lessonMode,
                    decoration: InputDecoration(
                      labelText: 'Mode de cours',
                      prefixIcon: const Icon(Icons.cast_for_education_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _lessonModes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) => setState(() => _lessonMode = value!),
                  ),
                  if (_lessonMode == 'Visio' || _lessonMode == 'Hybride') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _visioTool,
                      decoration: InputDecoration(
                        labelText: 'Outil de visio',
                        prefixIcon: const Icon(Icons.videocam_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _visioTools
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) => setState(() => _visioTool = value!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lessonPlacesController,
                    decoration: InputDecoration(
                      labelText: 'Lieux de cours',
                      hintText: 'Ex : Visio, Paris 15e',
                      helperText: 'Séparez plusieurs lieux par une virgule.',
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('S\'inscrire', style: TextStyle(fontSize: 16)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
