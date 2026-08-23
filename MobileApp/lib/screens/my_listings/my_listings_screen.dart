import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/messaging_provider.dart';
import '../../services/api_service.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final ApiService _apiService = ApiService();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final listings = await _apiService.getMyListings();
      if (mounted) setState(() { _listings = listings; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _delete(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: Text(listing.title),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _apiService.deleteListing(listing.listingId);
      await _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showInterests(Listing listing) async {
    try {
      final data = await _apiService.getListingInterests(listing.listingId);
      if (!mounted) return;
      final count = data['count'] ?? 0;
      // `people` n'est présent que pour le propriétaire de l'annonce (voir server.js).
      final List<dynamic> people = data['people'] is List ? data['people'] : [];

      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count personne(s) intéressée(s)', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (people.isNotEmpty)
                ...people.map((p) => ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(p['fullName'] ?? '—'),
                      subtitle: Text(p['email'] ?? ''),
                      trailing: p['userId'] != null
                          ? IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              tooltip: 'Contacter',
                              onPressed: () async {
                                final messaging = Provider.of<MessagingProvider>(context, listen: false);
                                await messaging.startAndOpenConversation(p['userId'].toString());
                                if (!mounted) return;
                                Navigator.of(context).pop(); // ferme le bottom sheet
                                Navigator.of(context).pushNamed('/messages');
                              },
                            )
                          : null,
                    ))
              else if (count == 0)
                const Text('Personne pour le moment.')
              else
                const Text('Détails non disponibles.'),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditDialog(Listing listing) async {
    final titleController = TextEditingController(text: listing.title);
    final descController = TextEditingController(text: listing.description);
    final priceController = TextEditingController(text: listing.pricePerHour.toString());
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'annonce'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Prix par heure (CCT)'),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      return (p == null || p <= 0) ? 'Prix invalide' : null;
                    },
                  ),
                ],
              ),
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
                        await _apiService.updateListing(
                          listingId: listing.listingId,
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          subject: listing.subject,
                          level: listing.level,
                          price: double.parse(priceController.text),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        await _fetch();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes annonces')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : _listings.isEmpty
                  ? const Center(child: Text('Vous n\'avez publié aucune annonce.'))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${listing.subject} · ${listing.level} · ${listing.pricePerHour.toStringAsFixed(2)} CCT/h'),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showInterests(listing),
                                        icon: const Icon(Icons.people_outline, size: 18),
                                        label: const Text('Intéressés'),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () => _showEditDialog(listing),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _delete(listing),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
