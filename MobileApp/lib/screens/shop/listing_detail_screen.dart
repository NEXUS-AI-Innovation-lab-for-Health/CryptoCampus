import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/blockchain_provider.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key});

  Color _getSubjectColor(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) return Colors.blue;
    if (subjectLower.contains('physiq') || subjectLower.contains('chimie')) return Colors.orange;
    if (subjectLower.contains('français') || subjectLower.contains('anglais')) return Colors.purple;
    if (subjectLower.contains('info') || subjectLower.contains('program')) return Colors.green;
    return Colors.grey;
  }

  void _showPaymentDialog(BuildContext context, Listing listing) {
    final _hoursController = TextEditingController(text: '1');
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réserver des heures'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prix: ${listing.pricePerHour.toStringAsFixed(2)} CCT/heure',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'heures',
                  hintText: '1',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<BlockchainProvider>(
                builder: (context, blockchainProvider, child) {
                  final hours = double.tryParse(_hoursController.text) ?? 1;
                  final total = listing.pricePerHour * hours;
                  return Text(
                    'Total: ${total.toStringAsFixed(4)} CCT',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                
                final hours = double.parse(_hoursController.text);
                final total = listing.pricePerHour * hours;
                
                // Simuler une adresse de tuteur (dans un vrai système, cela viendrait de la BDD)
                final tutorAddress = '0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0';
                
                final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);
                final success = await blockchainProvider.sendTransaction(
                  toAddress: tutorAddress,
                  amount: total,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Paiement effectué avec succès! ${hours}h réservées.'
                        : 'Erreur lors du paiement'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Payer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = ModalRoute.of(context)!.settings.arguments as Listing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'annonce'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: _getSubjectColor(listing.subject),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Par ${listing.tutorName ?? "Tuteur"}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${listing.pricePerHour.toStringAsFixed(2)} CCT / heure',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Row(
                    children: [
                      Chip(
                        label: Text(listing.subject),
                        backgroundColor: _getSubjectColor(listing.subject).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _getSubjectColor(listing.subject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(listing.level),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(listing.isActive ? 'Actif' : 'Inactif'),
                        backgroundColor: listing.isActive 
                            ? Colors.green[100] 
                            : Colors.red[100],
                        labelStyle: TextStyle(
                          color: listing.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info cards
                  _InfoCard(
                    icon: Icons.calendar_today,
                    title: 'Créé le',
                    value: '${listing.createdAt.day}/${listing.createdAt.month}/${listing.createdAt.year}',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.person,
                    title: 'ID Tuteur',
                    value: '#${listing.tutorUserId}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: listing.isActive 
              ? () => _showPaymentDialog(context, listing)
              : null,
          icon: const Icon(Icons.payment),
          label: const Text('Réserver et payer'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
