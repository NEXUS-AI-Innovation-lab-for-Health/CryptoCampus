import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../services/api_service.dart';

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

  Future<void> _contactTutor(BuildContext context, Listing listing) async {
    final messaging = Provider.of<MessagingProvider>(context, listen: false);
    await messaging.startAndOpenConversation(listing.tutorUserId);
    if (!context.mounted) return;
    if (messaging.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messaging.error!), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.of(context).pushNamed('/messages');
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
        child: Row(
          children: [
            if (Provider.of<AuthProvider>(context).currentUser?.userId != listing.tutorUserId) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactTutor(context, listing),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
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
          ],
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
  final ApiService _apiService = ApiService();
  bool _loadingSlots = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _slots = [];
  final Set<String> _selectedSlotIds = {};
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      // Les créneaux ne sont jamais rattachés à une annonce précise (listing_id reste
      // NULL côté DB : le formulaire de création de créneau, web comme mobile, n'envoie
      // que start_time/end_time). Il faut filtrer par tuteur, comme le fait RequestsList.vue
      // côté web — filtrer par listing_id ne retournait jamais aucun résultat.
      final slots = await _apiService.getAvailability(tutorUserId: widget.listing.tutorUserId);
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
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

  // Réservation simple, exactement comme le modal de RequestsList.vue côté web : aucun
  // virement blockchain n'est déclenché à la réservation (le web ne le fait pas non plus),
  // juste POST /api/bookings avec les créneaux choisis.
  Future<void> _confirm() async {
    if (_selectedSlotIds.isEmpty) return;

    setState(() => _booking = true);

    try {
      await _apiService.createBooking(
        slotIds: _selectedSlotIds.toList(),
        listingId: widget.listing.listingId,
        title: widget.listing.title,
        description: widget.listing.description,
        subject: widget.listing.subject,
        tutorName: widget.listing.tutorName,
        price: widget.listing.pricePerHour,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedSlotIds.length} créneau(x) réservé(s) · ${_totalPrice.toStringAsFixed(2)} CCT',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
                                  subtitle: const Text('1 heure'),
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
          onPressed: _booking ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        if (!_loadingSlots && _errorMessage == null && _slots.isNotEmpty)
          ElevatedButton(
            onPressed: (_booking || _selectedSlotIds.isEmpty) ? null : _confirm,
            child: _booking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Réserver'),
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
