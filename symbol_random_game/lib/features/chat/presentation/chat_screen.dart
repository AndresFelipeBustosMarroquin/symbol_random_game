import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/friends/domain/amistad_model.dart';
import 'package:symbol_random_game/features/chat/domain/chat_model.dart';
import 'package:symbol_random_game/features/chat/data/chat_service.dart';
import 'package:symbol_random_game/shared/app_snack.dart';
import 'package:symbol_random_game/shared/static_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.userId, required this.friend});

  final int userId;
  final PersonaAmistad friend;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<MensajeChat> _messages = [];
  Timer? _refreshTimer;
  bool _loading = true;
  bool _sending = false;
  bool _refreshing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = await _service.obtener(
        widget.userId,
        widget.friend.idUsuario,
      );
      if (!mounted) return;
      final didChange =
          messages.length != _messages.length ||
          (messages.isNotEmpty &&
              (_messages.isEmpty ||
                  messages.last.idMensaje != _messages.last.idMensaje));
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      if (didChange) _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      if (!silent || _messages.isEmpty) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _service.enviar(
        userId: widget.userId,
        friendId: widget.friend.idUsuario,
        content: content,
      );
      if (!mounted) return;
      _controller.clear();
      HapticFeedback.selectionClick();
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppSnack.error(context, message: 'No se pudo enviar el mensaje: $error');
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Scaffold(
        resizeToAvoidBottomInset: true,
        body: StaticAppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktopLayout(context) ? 900 : 680,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            tooltip: 'Volver',
                          ),
                          Text(
                            widget.friend.emoji,
                            style: const TextStyle(fontSize: 29),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.friend.nombreUso,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.display(fontSize: 20),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _refresh(),
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar mensajes',
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildMessages()),
                    _composer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading && _messages.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 10),
              Text(
                'No se pudieron cargar los mensajes.\n$_error',
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed: () => _refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_rounded,
                size: 48,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'Todavía no hay mensajes',
                style: AppText.title(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Envía el primero. La conversación quedará guardada para que '
                '${widget.friend.nombreUso} pueda responder cuando quiera.',
                textAlign: TextAlign.center,
                style: AppText.label(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final mine = message.idEmisor == widget.userId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .76,
            ),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
            decoration: BoxDecoration(
              color: mine
                  ? AppColors.primary.withValues(alpha: .86)
                  : AppColors.card.withValues(alpha: .94),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(17),
                topRight: const Radius.circular(17),
                bottomLeft: Radius.circular(mine ? 17 : 4),
                bottomRight: Radius.circular(mine ? 4 : 17),
              ),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: .23),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.contenido,
                    style: AppText.label(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _time(message.fechaEnvio),
                  style: AppText.label(color: Colors.white60, fontSize: 9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .94),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: .35)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 1000,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                counterText: '',
                filled: true,
                fillColor: Colors.black.withValues(alpha: .16),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            tooltip: 'Enviar mensaje',
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
