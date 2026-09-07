import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  bool get hasUnread => unreadCount > 0;

  // ============================================================
  // INITIALISATION
  // ============================================================

  void loadNotifications() {
    if (_notifications.isNotEmpty) return;

    _notifications.addAll([
      NotificationModel(
        id: 1,
        title: 'Nouvelle mission',
        message:
        'Une nouvelle mission vous a été affectée par le responsable.',
        type: 'mission',
        createdAt: DateTime.now().subtract(
          const Duration(minutes: 5),
        ),
      ),

      NotificationModel(
        id: 2,
        title: 'Mission modifiée',
        message:
        'L\'heure de départ de la mission #M-0245 a été modifiée.',
        type: 'mission_update',
        createdAt: DateTime.now().subtract(
          const Duration(minutes: 30),
        ),
      ),

      NotificationModel(
        id: 3,
        title: 'Information',
        message:
        'Veuillez vérifier l\'état de votre camion avant le départ.',
        type: 'info',
        createdAt: DateTime.now().subtract(
          const Duration(hours: 1),
        ),
        isRead: true,
      ),

      NotificationModel(
        id: 4,
        title: 'Incident signalé',
        message:
        'Un incident a été signalé concernant votre véhicule.',
        type: 'incident',
        createdAt: DateTime.now().subtract(
          const Duration(hours: 2),
        ),
      ),
    ]);

    notifyListeners();
  }

  // ============================================================
  // AJOUTER UNE NOTIFICATION
  // ============================================================

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // ============================================================
  // MARQUER UNE NOTIFICATION COMME LUE
  // ============================================================

  void markAsRead(int id) {
    final index = _notifications.indexWhere(
          (notification) => notification.id == id,
    );

    if (index == -1) return;

    _notifications[index].isRead = true;
    notifyListeners();
  }

  // ============================================================
  // MARQUER TOUT COMME LU
  // ============================================================

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }

    notifyListeners();
  }

  // ============================================================
  // SUPPRIMER UNE NOTIFICATION
  // ============================================================

  void removeNotification(int id) {
    _notifications.removeWhere(
          (notification) => notification.id == id,
    );

    notifyListeners();
  }

  // ============================================================
  // SUPPRIMER TOUTES LES NOTIFICATIONS
  // ============================================================

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}