import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedSubject = 'Mathématiques';
  String _selectedLevel = 'Lycée';

  bool _analyzingCv = false;
  bool _publishingSuggestions = false;
  List<Map<String, dynamic>>? _cvSuggestions; // annonces suggérées par l'IA, éditables

  final List<String> _subjects = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Français',
    'Anglais',
    'Histoire',
    'Géographie',
    'Informatique',
    'Philosophie',
  ];

  final List<String> _levels = [
    'Collège',
    'Lycée',
    'Université (L1-L2)',
    'Université (L3-M1)',
    'Master',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _selectedSubject,
        level: _selectedLevel,
        price: double.parse(_priceController.text.trim()),
        tutorName: currentUser.fullName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce créée et indexée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Génération d'annonces par IA à partir d'un CV (parité CreateRequest.vue) ──

  Future<void> _pickAndAnalyzeCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _analyzingCv = true);
    try {
      final apiService = ApiService();
      final data = await apiService.analyzeCv(result.files.single.bytes!, result.files.single.name);
      final List<dynamic> suggestions = data['suggestions'] ?? [];
      if (!mounted) return;
      setState(() {
        _cvSuggestions = suggestions.map<Map<String, dynamic>>((s) => {
              'title': s['title'] ?? '',
              'description': s['description'] ?? '',
              'subject': s['subject'] ?? _subjects.first,
              'level': s['level'] ?? _levels.first,
              'price': (s['price'] is num) ? (s['price'] as num).toDouble() : 15.0,
              'tutor_name': s['tutor_name'],
              'selected': true,
            }).toList();
        _analyzingCv = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzingCv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _publishSelectedSuggestions() async {
    if (_cvSuggestions == null) return;
    final selected = _cvSuggestions!.where((s) => s['selected'] == true).toList();
    if (selected.isEmpty) return;

    setState(() => _publishingSuggestions = true);

    final apiService = ApiService();
    var published = 0;
    String? lastError;
    for (final s in selected) {
      try {
        await apiService.createListing(
          title: s['title'],
          description: s['description'],
          subject: s['subject'],
          level: s['level'],
          price: (s['price'] as num).toDouble(),
          tutorName: s['tutor_name'],
        );
        published++;
      } catch (e) {
        // On continue avec les suivantes même si l'une échoue, mais on garde le message
        // pour l'afficher si aucune n'a semblé réussir (voir ci-dessous).
        lastError = e.toString().replaceFirst('Exception: ', '');
      }
    }

    if (!mounted) return;
    setState(() => _publishingSuggestions = false);

    final message = published == selected.length
        ? '$published annonce(s) publiée(s)'
        : published > 0
            ? '$published/${selected.length} annonce(s) publiée(s)${lastError != null ? ' — dernière erreur : $lastError' : ''}'
            : 'Échec de la publication${lastError != null ? ' : $lastError' : ''}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: published > 0 ? Colors.green : Colors.red,
      ),
    );
    if (published > 0) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un cours'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Génération d'annonces par IA à partir d'un CV (parité CreateRequest.vue).
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Générer via mon CV (IA)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploadez votre CV en PDF : l\'IA propose automatiquement des annonces de cours à partir de vos compétences.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _analyzingCv ? null : _pickAndAnalyzeCv,
                        icon: _analyzingCv
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file),
                        label: Text(_analyzingCv ? 'Analyse en cours...' : 'Choisir un CV (PDF)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_cvSuggestions != null) ...[
                Text('Suggestions générées par l\'IA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._cvSuggestions!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final suggestion = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: suggestion['selected'] as bool,
                                onChanged: (v) => setState(() => _cvSuggestions![index]['selected'] = v ?? false),
                              ),
                              const Text('Publier cette annonce'),
                            ],
                          ),
                          TextFormField(
                            initialValue: suggestion['title'],
                            decoration: const InputDecoration(labelText: 'Titre'),
                            onChanged: (v) => _cvSuggestions![index]['title'] = v,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: suggestion['description'],
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Description'),
                            onChanged: (v) => _cvSuggestions![index]['description'] = v,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: suggestion['subject'],
                                  decoration: const InputDecoration(labelText: 'Matière'),
                                  onChanged: (v) => _cvSuggestions![index]['subject'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: suggestion['price'].toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Prix (CCT/h)'),
                                  onChanged: (v) => _cvSuggestions![index]['price'] = double.tryParse(v) ?? suggestion['price'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _publishingSuggestions ? null : () => setState(() => _cvSuggestions = null),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _publishingSuggestions ? null : _publishSelectedSuggestions,
                        child: _publishingSuggestions
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Publier la sélection'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Text('...ou créez une annonce manuellement', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
              ],

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Informations de base',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titre de l\'annonce',
                          hintText: 'Ex: Cours de mathématiques niveau lycée',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          if (value.length < 10) {
                            return 'Le titre doit contenir au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez votre expertise et ce que vous proposez...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une description';
                          }
                          if (value.length < 50) {
                            return 'La description doit contenir au moins 50 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Catégorie',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: 'Matière',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.book),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Niveau',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.school),
                        ),
                        items: _levels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tarification',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Prix par heure (CCT)',
                          hintText: '0.0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: 'CCT/h',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un prix';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les paiements se feront via votre wallet CryptoCampus',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(Icons.publish),
                label: const Text('Publier l\'annonce'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'En publiant, vous acceptez que votre annonce soit visible par tous les utilisateurs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
