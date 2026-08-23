import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  String? _userId;
  String? _userEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationProvider(this.navigatorKey);

  void startPolling(String userId, String userEmail) {
    _userId = userId;
    _userEmail = userEmail;
    
    // Stop existing timer if any
    stopPolling();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkNotifications();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkNotifications() async {
    if (_userId == null || _userEmail == null) return;

    try {
      // Le backend résout toujours le tuteur via la session connectée (aucun paramètre
      // à fournir) ; _userId/_userEmail ne servent plus qu'à savoir si le polling doit
      // tourner (voir startPolling ci-dessus).
      final notifications = await _apiService.checkTutorNotifications();

      if (notifications.isNotEmpty) {
        // We have new notifications!
        List<String> bookingIds = [];
        for (var notif in notifications) {
          bookingIds.add(notif['booking_id'].toString());
        }

        // Show popup
        _showNotificationPopup(notifications.length);

        // Mark as read in the DB so they don't pop up again
        await _apiService.markNotificationsRead(bookingIds);
      }
    } catch (e) {
      print('Erreur lors de la vérification des notifications: $e');
    }
  }

  void _showNotificationPopup(int count) {
    if (navigatorKey.currentContext == null) return;

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouvelle Réservation 🎉'),
          content: Text(
            count == 1 
              ? 'Un élève vient de réserver un cours avec vous !'
              : 'Vous avez $count nouvelles réservations !'
          ),
          actions: [
            TextButton(
              child: const Text('Compris'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
