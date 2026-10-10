import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/chat/chat_screen.dart';
import 'package:symbol_random_game/features/profile/profile_screen.dart';
import 'package:symbol_random_game/features/friends/amistad_model.dart';
import 'package:symbol_random_game/features/friends/amistad_service.dart';
import 'package:symbol_random_game/shared/app_snack.dart';
import 'package:symbol_random_game/shared/static_background.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.userId});

  final int userId;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _service = AmistadService();
  late Future<AmistadesUsuario> _friendships;
  final Set<int> _busyUsers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _friendships = _service.obtener(widget.userId);
  }

  Future<void> _run(PersonaAmistad person, Future<void> Function() action) async {
    if (!_busyUsers.add(person.idUsuario)) return;
    setState(() {});
    try {
      await action();
      if (!mounted) return;
      setState(_load);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        message: 'No se pudo actualizar la amistad: $error',
      );
    } finally {
      _busyUsers.remove(person.idUsuario);
      if (mounted) setState(() {});
    }
  }

  Future<void> _removeFriend(PersonaAmistad person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar amistad?'),
        content: Text('¿Quieres quitar a ${person.nombreUso} de tus amigos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('QUITAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(person, () => _service.eliminar(widget.userId, person.idUsuario));
    }
  }

  void _openProfile(PersonaAmistad person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: person.idUsuario,
          viewerId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _openChat(PersonaAmistad person) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(userId: widget.userId, friend: person),
      ),
    );
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Scaffold(
        body: StaticAppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktopLayout(context) ? 1000 : 680,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            tooltip: 'Volver',
                          ),
                          Expanded(
                            child: Center(
                              child: GradientText(
                                'AMISTADES',
                                style: AppText.display(
                                  fontSize: 25,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(_load),
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<AmistadesUsuario>(
                        future: _friendships,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryLight,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_rounded,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No se pudieron cargar tus amistades.\n${snapshot.error}',
                                      textAlign: TextAlign.center,
                                    ),
                                    TextButton.icon(
                                      onPressed: () => setState(_load),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('REINTENTAR'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final data = snapshot.data!;
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            children: [
                              _sectionTitle(
                                'SOLICITUDES RECIBIDAS',
                                data.recibidas.length,
                              ),
                              if (data.recibidas.isEmpty)
                                const _EmptyFriendsMessage(
                                  text: 'No tienes solicitudes pendientes.',
                                )
                              else
                                for (final person in data.recibidas)
                                  _incomingRequestRow(
                                    person,
                                  ),
                              const SizedBox(height: 22),
                              _sectionTitle(
                                'TUS AMIGOS',
                                data.amigos.length,
                              ),
                              if (data.amigos.isEmpty)
                                const _EmptyFriendsMessage(
                                  text:
                                      'Cuando aceptes o envíes una solicitud, tus amigos aparecerán aquí.',
                                )
                              else
                                for (final person in data.amigos)
                                  _personRow(
                                    person,
                                    label: 'Toca para abrir el chat',
                                    onTap: () => _openChat(person),
                                    actions: [
                                      IconButton(
                                        tooltip: 'Ver perfil',
                                        onPressed: () => _openProfile(person),
                                        icon: const Icon(
                                          Icons.account_circle_outlined,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Quitar amistad',
                                        onPressed: _busyUsers.contains(
                                          person.idUsuario,
                                        )
                                            ? null
                                            : () => _removeFriend(person),
                                        icon: const Icon(
                                          Icons.person_remove_alt_1_rounded,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                              const SizedBox(height: 22),
                              _sectionTitle(
                                'SOLICITUDES ENVIADAS',
                                data.enviadas.length,
                              ),
                              if (data.enviadas.isEmpty)
                                const _EmptyFriendsMessage(
                                  text: 'No tienes solicitudes enviadas.',
                                )
                              else
                                for (final person in data.enviadas)
                                  _personRow(
                                    person,
                                    label: 'Pendiente de respuesta',
                                    actions: [
                                      IconButton(
                                        tooltip: 'Cancelar solicitud',
                                        onPressed: _busyUsers.contains(
                                          person.idUsuario,
                                        )
                                            ? null
                                            : () => _run(
                                                  person,
                                                  () => _service.eliminar(
                                                    widget.userId,
                                                    person.idUsuario,
                                                  ),
                                                ),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppText.title(fontSize: 12, letterSpacing: 1.2),
          ),
        ),
        Text(
          '$count',
          style: AppText.label(
            color: AppColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _incomingRequestRow(PersonaAmistad person) {
    final busy = _busyUsers.contains(person.idUsuario);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: .5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: .2),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: .55),
                  ),
                ),
                child: Text(person.emoji, style: const TextStyle(fontSize: 27)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.nombreUso,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Quiere agregarte a sus amistades',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.mark_email_unread_rounded,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            const SizedBox(
              height: 38,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _run(
                      person,
                      () => _service.aceptar(
                        widget.userId,
                        person.idUsuario,
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                    label: const Text('ACEPTAR'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: AppText.label(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _run(
                      person,
                      () => _service.eliminar(
                        widget.userId,
                        person.idUsuario,
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('RECHAZAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .22),
                      ),
                      textStyle: AppText.label(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _personRow(
    PersonaAmistad person, {
    required String label,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap ?? () => _openProfile(person),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Text(person.emoji, style: const TextStyle(fontSize: 29)),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.nombreUso,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title(fontSize: 14),
                          ),
                          Text(
                            label,
                            style: AppText.label(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (person.mensajesNoVistos > 0) ...[
                      const SizedBox(width: 8),
                      Semantics(
                        label:
                            '${person.mensajesNoVistos} mensajes nuevos sin leer',
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(
                                alpha: .7,
                              ),
                            ),
                          ),
                          child: Text(
                            person.mensajesNoVistos > 99
                                ? '99+'
                                : '${person.mensajesNoVistos}',
                            textAlign: TextAlign.center,
                            style: AppText.label(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_busyUsers.contains(person.idUsuario))
            const SizedBox(
              width: 44,
              height: 44,
              child: Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            ...actions,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _EmptyFriendsMessage extends StatelessWidget {
  const _EmptyFriendsMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.label(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}
