import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final ApiService _apiService = ApiService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';
  final Set<String> _updating = {};

  static const _statusFilters = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];
  static const _statusLabels = {
    'all': 'Toutes',
    'pending': 'En attente',
    'confirmed': 'Confirmées',
    'completed': 'Terminées',
    'cancelled': 'Annulées',
  };

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Le backend filtre toujours sur la session connectée (impossible de consulter les
      // réservations d'un autre utilisateur) : aucun paramètre à fournir.
      final bookings = await _apiService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(BookingModel booking, String status) async {
    setState(() => _updating.add(booking.bookingId));
    try {
      await _apiService.updateBookingStatus(booking.bookingId, status);
      await _fetchBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove(booking.bookingId));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

  List<Widget> _actionsFor(BookingModel booking, bool isStudent) {
    final updating = _updating.contains(booking.bookingId);
    if (updating) {
      return [const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))];
    }
    final actions = <Widget>[];
    if (booking.status == 'pending' || booking.status == 'confirmed') {
      if (!isStudent && booking.status == 'pending') {
        actions.add(TextButton(
          onPressed: () => _updateStatus(booking, 'confirmed'),
          child: const Text('Confirmer'),
        ));
      }
      if (!isStudent && booking.status == 'confirmed') {
        actions.add(TextButton(
          onPressed: () => _updateStatus(booking, 'completed'),
          child: const Text('Terminer'),
        ));
      }
      actions.add(TextButton(
        onPressed: () => _updateStatus(booking, 'cancelled'),
        child: const Text('Annuler', style: TextStyle(color: Colors.red)),
      ));
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.userId;
    final filtered = _statusFilter == 'all'
        ? _bookings
        : _bookings.where((b) => b.status.toLowerCase() == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _statusFilters.map((s) {
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_statusLabels[s]!),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = s),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur: $_error'))
                    : filtered.isEmpty
                        ? const Center(child: Text('Aucune réservation trouvée.'))
                        : RefreshIndicator(
                            onRefresh: _fetchBookings,
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final booking = filtered[index];
                                final isStudent = currentUserId != null && booking.isOwnedByStudent(currentUserId);
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(booking.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Chip(
                                              label: Text(
                                                booking.status.toUpperCase(),
                                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                              ),
                                              backgroundColor: _getStatusColor(booking.status),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (booking.subject != null) Text('Sujet : ${booking.subject}'),
                                        // Le tuteur voit le nom de l'étudiant qui a réservé ;
                                        // l'étudiant voit le nom du tuteur — jamais les deux.
                                        if (!isStudent && booking.studentName != null)
                                          Text('Étudiant : ${booking.studentName}'),
                                        if (isStudent && booking.tutorName != null)
                                          Text('Tuteur : ${booking.tutorName}'),
                                        Text('Début : ${_formatDate(booking.startTime)}'),
                                        if (booking.price != null) Text('Prix : ${booking.price!.toStringAsFixed(2)} CCT'),
                                        if (_actionsFor(booking, isStudent).isNotEmpty) ...[
                                          const Divider(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: _actionsFor(booking, isStudent),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
