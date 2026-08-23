import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final slots = await _apiService.getMyAvailability();
      slots.sort((a, b) => DateTime.parse(a['start_time']).compareTo(DateTime.parse(b['start_time'])));
      if (mounted) {
        setState(() {
          _slots = slots;
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

  Future<void> _deleteSlot(Map<String, dynamic> slot) async {
    final slotId = slot['slot_id'].toString();
    setState(() => _deleting.add(slotId));
    try {
      await _apiService.deleteAvailability(slotId);
      await _fetchSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(slotId));
    }
  }

  Future<void> _showCreateSlotDialog() async {
    DateTime? date;
    TimeOfDay? startTime;
    double durationHours = 1;
    bool submitting = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nouveau créneau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'L\'heure de début doit être à XX:00 ou XX:30.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(date == null ? 'Choisir une date' : DateFormat('dd/MM/yyyy').format(date!)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(startTime == null ? 'Choisir une heure' : startTime!.format(dialogContext)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: const TimeOfDay(hour: 14, minute: 0),
                  );
                  if (picked != null && (picked.minute == 0 || picked.minute == 30)) {
                    setDialogState(() => startTime = picked);
                  } else if (picked != null) {
                    setDialogState(() => errorText = 'L\'heure doit être à :00 ou :30');
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Durée : '),
                  Expanded(
                    child: Slider(
                      value: durationHours,
                      min: 1,
                      max: 4,
                      divisions: 6,
                      label: '${durationHours.toStringAsFixed(1)}h',
                      onChanged: (v) => setDialogState(() => durationHours = v),
                    ),
                  ),
                  Text('${durationHours.toStringAsFixed(1)}h'),
                ],
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
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
                      if (date == null || startTime == null) {
                        setDialogState(() => errorText = 'Date et heure requises');
                        return;
                      }
                      final start = DateTime(date!.year, date!.month, date!.day, startTime!.hour, startTime!.minute);
                      final end = start.add(Duration(minutes: (durationHours * 60).round()));
                      setDialogState(() => submitting = true);
                      try {
                        await _apiService.createAvailability(start, end);
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        await _fetchSlots();
                      } catch (e) {
                        setDialogState(() {
                          submitting = false;
                          errorText = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes disponibilités')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSlotDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau créneau'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : _slots.isEmpty
                  ? const Center(child: Text('Aucun créneau créé pour le moment.'))
                  : RefreshIndicator(
                      onRefresh: _fetchSlots,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _slots.length,
                        itemBuilder: (context, index) {
                          final slot = _slots[index];
                          final start = DateTime.parse(slot['start_time']).toLocal();
                          final end = DateTime.parse(slot['end_time']).toLocal();
                          final isBooked = slot['is_booked'] == true;
                          final slotId = slot['slot_id'].toString();
                          final deleting = _deleting.contains(slotId);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                isBooked ? Icons.event_busy : Icons.event_available,
                                color: isBooked ? Colors.orange : Colors.green,
                              ),
                              title: Text(DateFormat('EEEE dd/MM/yyyy', 'fr_FR').format(start)),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}'
                                '${isBooked ? '  ·  Réservé' : '  ·  Disponible'}',
                              ),
                              trailing: isBooked
                                  ? null
                                  : deleting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _deleteSlot(slot),
                                        ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
