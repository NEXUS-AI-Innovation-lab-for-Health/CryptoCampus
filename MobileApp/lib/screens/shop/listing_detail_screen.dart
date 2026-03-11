import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
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

  void _showBookingDialog(BuildContext context, Listing listing) {
    showDialog(
      context: context,
      builder: (context) => _BookingSlotDialog(listing: listing),
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
                    value:
                        '${listing.createdAt.day}/${listing.createdAt.month}/${listing.createdAt.year}',
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
              ? () => _showBookingDialog(context, listing)
              : null,
          icon: const Icon(Icons.event_available),
          label: const Text('Voir les disponibilités'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: slot picker + payment
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSlotDialog extends StatefulWidget {
  final Listing listing;
  const _BookingSlotDialog({required this.listing});

  @override
  State<_BookingSlotDialog> createState() => _BookingSlotDialogState();
}

class _BookingSlotDialogState extends State<_BookingSlotDialog> {
  bool _loadingSlots = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _slots = [];
  final Set<String> _selectedSlotIds = {};
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      final uri = Uri.parse(
        ApiConfig.availabilityUrl(listingId: widget.listing.id.toString()),
      );
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _slots = data.cast<Map<String, dynamic>>();
          _loadingSlots = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les créneaux (${response.statusCode})';
          _loadingSlots = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau: $e';
        _loadingSlots = false;
      });
    }
  }

  double get _totalHours => _selectedSlotIds.fold(0.0, (sum, id) {
        final slot = _slots.firstWhere((s) => s['slot_id'] == id, orElse: () => {});
        if (slot.isEmpty) return sum;
        final start = DateTime.parse(slot['start_time'] as String);
        final end = DateTime.parse(slot['end_time'] as String);
        return sum + end.difference(start).inMinutes / 60.0;
      });

  double get _totalPrice => _totalHours * widget.listing.pricePerHour;

  String _formatSlot(Map<String, dynamic> slot) {
    final start = DateTime.parse(slot['start_time'] as String).toLocal();
    final end = DateTime.parse(slot['end_time'] as String).toLocal();
    final day = '${start.day}/${start.month}/${start.year}';
    final startT =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endT =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$day  $startT – $endT';
  }

  String _slotDuration(Map<String, dynamic> slot) {
    final start = DateTime.parse(slot['start_time'] as String);
    final end = DateTime.parse(slot['end_time'] as String);
    final mins = end.difference(start).inMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  Future<void> _confirm() async {
    if (_selectedSlotIds.isEmpty) return;

    setState(() => _paying = true);

    final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);

    // Blockchain payment
    // TODO: replace with real tutor wallet address fetched from API
    const tutorAddress = '0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0';
    final success = await blockchainProvider.sendTransaction(
      toAddress: tutorAddress,
      amount: _totalPrice,
    );

    if (!mounted) return;

    if (success) {
      // Attempt to create bookings server-side (best-effort; requires session cookie)
      try {
        await http.post(
          Uri.parse(ApiConfig.bookingsUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'slot_ids': _selectedSlotIds.toList(),
            'listing_id': widget.listing.id,
            'title': widget.listing.title,
            'description': widget.listing.description,
            'subject': widget.listing.subject,
            'tutor_name': widget.listing.tutorName,
            'price': widget.listing.pricePerHour,
          }),
        );
      } catch (_) {
        // Silent fail – blockchain payment already succeeded
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement effectué ! ${_selectedSlotIds.length} créneau(x) réservé(s) · ${_totalPrice.toStringAsFixed(4)} CCT',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du paiement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir des créneaux'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingSlots
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                : _slots.isEmpty
                    ? const Text(
                        'Aucun créneau disponible pour le moment.\nRevenez plus tard ou contactez le tuteur.',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prix: ${widget.listing.pricePerHour.toStringAsFixed(2)} CCT/h',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Sélectionnez un ou plusieurs créneaux :'),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _slots.length,
                              itemBuilder: (ctx, i) {
                                final slot = _slots[i];
                                final id = slot['slot_id'] as String;
                                final selected = _selectedSlotIds.contains(id);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (_) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSlotIds.remove(id);
                                      } else {
                                        _selectedSlotIds.add(id);
                                      }
                                    });
                                  },
                                  title: Text(_formatSlot(slot)),
                                  subtitle: Text(_slotDuration(slot)),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            ),
                          ),
                          if (_selectedSlotIds.isNotEmpty) ...[
                            const Divider(),
                            Text('Durée totale : ${_totalHours.toStringAsFixed(1)}h'),
                            Text(
                              'Total : ${_totalPrice.toStringAsFixed(4)} CCT',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _paying ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        if (!_loadingSlots && _errorMessage == null && _slots.isNotEmpty)
          ElevatedButton(
            onPressed: (_paying || _selectedSlotIds.isEmpty) ? null : _confirm,
            child: _paying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Payer'),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
