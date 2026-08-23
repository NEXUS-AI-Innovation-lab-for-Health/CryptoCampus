import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class MessagingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  io.Socket? _socket;

  List<ConversationModel> _conversations = [];
  int? _activeConversationId;
  List<MessageModel> _activeMessages = [];
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  int? get activeConversationId => _activeConversationId;
  List<MessageModel> get activeMessages => _activeMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadTotal => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ConversationModel? get activeConversation {
    if (_activeConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.conversationId == _activeConversationId);
    } catch (_) {
      return null;
    }
  }

  /// Connecte le socket temps réel — appelé une fois l'utilisateur authentifié (voir
  /// main.dart, même pattern que NotificationProvider branché sur AuthProvider).
  void connect() {
    if (_socket != null) return;

    // transports: ['websocket'] uniquement : le transport de polling HTTP de ce package
    // n'envoie pas les cookies (withCredentials non configuré dedans), ce qui ferait
    // échouer l'auth par session côté serveur dès la poignée de main. Une WebSocket
    // navigateur native, elle, envoie toujours les cookies du même site automatiquement
    // — recommandé par la doc du package pour Flutter/Dart VM.
    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setPath(ApiConfig.socketPath)
          .setTransports(['websocket'])
          .build(),
    );

    _socket!.on('message:new', (data) {
      final conversationId = data['conversationId'] as int;
      final message = MessageModel.fromJson(Map<String, dynamic>.from(data['message']));
      _handleIncomingMessage(conversationId, message);
    });

    _socket!.on('message:read', (data) {
      final conversationId = data['conversationId'] as int;
      _handleReadReceipt(conversationId);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _conversations = [];
    _activeConversationId = null;
    _activeMessages = [];
    notifyListeners();
  }

  void _handleIncomingMessage(int conversationId, MessageModel message) {
    final index = _conversations.indexWhere((c) => c.conversationId == conversationId);
    if (index == -1) {
      // Conversation jamais vue par ce client : on recharge tout pour avoir les infos
      // du nouvel interlocuteur, plutôt que de bricoler un ConversationModel partiel ici.
      loadConversations();
    } else {
      final conv = _conversations.removeAt(index);
      conv.unreadCount += 1;
      _conversations.insert(0, conv);
    }

    if (_activeConversationId == conversationId) {
      _activeMessages = [..._activeMessages, message];
      markActiveConversationRead();
    }

    notifyListeners();
  }

  void _handleReadReceipt(int conversationId) {
    // Notification que l'autre participant a lu nos messages — pas d'état local à
    // mettre à jour pour l'instant (pas d'accusé de lecture affiché dans l'UI), mais on
    // notifie quand même pour un futur indicateur.
    notifyListeners();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère (ou crée) la conversation avec cet utilisateur puis l'ouvre directement.
  Future<void> startAndOpenConversation(String otherUserId) async {
    try {
      final conversationId = await _apiService.startConversation(otherUserId);
      await loadConversations();
      await openConversation(conversationId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> openConversation(int conversationId) async {
    _activeConversationId = conversationId;
    _activeMessages = [];
    _isLoading = true;
    notifyListeners();

    try {
      _activeMessages = await _apiService.getMessages(conversationId);
      markActiveConversationRead();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void closeActiveConversation() {
    _activeConversationId = null;
    _activeMessages = [];
    notifyListeners();
  }

  Future<bool> sendMessage(String content) async {
    if (_activeConversationId == null || content.trim().isEmpty) return false;
    try {
      final message = await _apiService.sendMessage(_activeConversationId!, content.trim());
      _activeMessages = [..._activeMessages, message];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void markActiveConversationRead() {
    if (_activeConversationId == null) return;
    final index = _conversations.indexWhere((c) => c.conversationId == _activeConversationId);
    if (index != -1) _conversations[index].unreadCount = 0;
    _apiService.markConversationRead(_activeConversationId!).catchError((_) {});
  }
}
