import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      await _apiService.uploadAvatar(result.files.single.bytes!, result.files.single.name);
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    try {
      await _apiService.deleteAvatar();
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _showResetPasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Au moins 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
                  validator: (v) => v != newController.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await _apiService.resetPassword(currentController.text, newController.text);
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mot de passe mis à jour'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonLocationsDialog() {
    final modes = ['Visio', 'Presentiel', 'Hybride'];
    final tools = ['Zoom', 'Teams', 'Google Meet', 'Discord', 'Autre'];
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    String mode = user?.lessonMode ?? 'Visio';
    String tool = user?.visioTool ?? 'Zoom';
    final placesController = TextEditingController(text: (user?.lessonPlaces ?? ['Visio']).join(', '));
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Localisation des cours'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Mode de cours'),
                  items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => mode = v!),
                ),
                if (mode == 'Visio' || mode == 'Hybride') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tool,
                    decoration: const InputDecoration(labelText: 'Outil de visio'),
                    items: tools.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => tool = v!),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: placesController,
                  decoration: const InputDecoration(labelText: 'Lieux (séparés par des virgules)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      final places = placesController.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      try {
                        await _apiService.updateLessonLocations(
                          lessonMode: mode,
                          visioTool: tool,
                          lessonPlaces: places.isEmpty ? ['Visio'] : places,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        if (mounted) {
                          await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _becomeTutor() async {
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devenir tuteur/tutrice'),
        content: const Text(
          'Cette action est définitive : vous ne pourrez plus revenir en arrière. Continuer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Continuer')),
        ],
      ),
    );
    if (confirmed1 != true || !mounted) return;

    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Confirmation finale'),
        content: const Text('Confirmer : devenir tuteur définitivement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed2 != true || !mounted) return;

    try {
      await _apiService.becomeTutor(lessonMode: 'Visio', visioTool: 'Zoom', lessonPlaces: ['Visio']);
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes maintenant tuteur/tutrice !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action supprimera définitivement : votre profil, votre wallet et solde '
          'blockchain, vos annonces créées, vos transactions, vos réservations et messages. '
          'Continuer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed1 != true || !mounted) return;

    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Dernière confirmation'),
        content: const Text('Êtes-vous vraiment sûr(e) ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed2 != true || !mounted) return;

    try {
      await _apiService.deleteAccount();
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isTutor = user?.isTutor ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage('${ApiConfig.baseUrl}${user.avatarUrl}')
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 32, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white,
                                child: _uploadingAvatar
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.camera_alt, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (user.avatarUrl != null)
                        TextButton(onPressed: _removeAvatar, child: const Text('Retirer ma photo de profil')),
                      const SizedBox(height: 8),
                      Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Chip(label: Text(isTutor ? 'Tuteur' : 'Étudiant')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Sécurité et compte', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Changer le mot de passe'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showResetPasswordDialog,
                      ),
                      if (isTutor)
                        ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: const Text('Localisation des cours'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showLessonLocationsDialog,
                        ),
                      if (!isTutor)
                        ListTile(
                          leading: const Icon(Icons.upgrade),
                          title: const Text('Devenir tuteur/tutrice'),
                          subtitle: const Text('Action définitive'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _becomeTutor,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
                    onTap: _deleteAccount,
                  ),
                ),
              ],
            ),
    );
  }
}
