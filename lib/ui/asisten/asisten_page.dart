import 'dart:core';

import 'package:flutter/material.dart';
import 'package:smart_wedding_planning_system/services/api_client.dart';
import 'package:smart_wedding_planning_system/services/session.dart' as app_session;
import 'package:smart_wedding_planning_system/services/wedding_feature_service.dart';

import '../bottom_navigation.dart';

class AsistenPage extends StatefulWidget {
  const AsistenPage({
    super.key,
    this.onBerandaTap,
    this.onRencanaTap,
    this.onChatTap,
    this.onUserTap,
  });

  final VoidCallback? onBerandaTap;
  final VoidCallback? onRencanaTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onUserTap;

  @override
  State<AsistenPage> createState() => _AsistenPageState();
}

class _AsistenPageState extends State<AsistenPage> {
  static const Color _rose = Color(0xFFC58A85);
  static const Color _dark = Color(0xFF493B38);
  static const Color _hint = Color(0xFFA18F89);
  static const Color _pink = Color(0xFFF0D3CD);
  static const Color _lightPink = Color(0xFFFFF2EE);
  static const Color _line = Color(0xFFF0DFDA);

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  String _userName = 'Deka';
  bool _isSending = false;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initAssistant();
  }

  Future<void> _initAssistant() async {
    try {
      final profile = await app_session.Session.getUserProfile();
      final fullName = profile['name']?.trim() ?? '';
      if (fullName.isNotEmpty) {
        _userName = fullName.split(' ').first;
      }

      // Muat sesi dan riwayat dari endpoint chatbot yang benar.
      await WeddingFeatureService.getCurrentPlan();
      final sessionsResponse = await ApiClient.get('/chatbot/sessions');
      final sessions = sessionsResponse is List
          ? sessionsResponse
          : <dynamic>[];
      final storedSessionId = await app_session.Session.getChatbotSessionId();
      String? sessionId = storedSessionId;
      if (sessions.isNotEmpty) {
        final matching = sessions.where((item) =>
            item is Map<String, dynamic> &&
            item['id']?.toString() == storedSessionId);
        final selected = matching.isNotEmpty
            ? matching.first
            : sessions.first;
        if (selected is Map<String, dynamic>) {
          sessionId = selected['id']?.toString();
        }
      }
      if (sessionId != null && sessionId.isNotEmpty) {
        await app_session.Session.saveChatbotSessionId(sessionId);
      }

      final historyData = sessionId == null
          ? <dynamic>[]
          : await ApiClient.get('/chatbot/sessions/$sessionId/messages');
      final historyList = historyData is List ? historyData : <dynamic>[];
      if (!mounted) return;

      setState(() {
        _messages.clear();
        _messages.add({
          'type': 'greeting',
          'isUser': false,
          'text':
              'Halo, $_userName!\nAku di sini untuk bantu persiapanmu. Kita wujudkan hari bahagiamu, selangkah demi selangkah.',
        });

        for (final item in historyList) {
          if (item is! Map<String, dynamic>) continue;
          final role = (item['role'] ?? item['sender'] ?? '').toString().toLowerCase();
          final isUser = item['isUser'] == true || role == 'user';
          final text = (item['content'] ??
                  item['message'] ??
                  item['text'] ??
                  item['reply'] ??
                  '')
              .toString()
              .trim();
          if (text.isEmpty) continue;

          final rawTime = item['createdAt'] ?? item['timestamp'];
          final parsedTime = rawTime != null
              ? DateTime.tryParse(rawTime.toString())?.toLocal()
              : null;

          _messages.add({
            'type': 'text',
            'isUser': isUser,
            'text': text,
            'time': parsedTime != null
                ? '${parsedTime.hour.toString().padLeft(2, '0')}.${parsedTime.minute.toString().padLeft(2, '0')}'
                : _currentTime(),
          });
        }
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Init assistant error: $e');
      if (!mounted) return;
      setState(() {
        if (_messages.isEmpty) {
          _messages.add({
            'type': 'greeting',
            'isUser': false,
            'text':
                'Halo, $_userName!\nAku di sini untuk bantu persiapanmu. Kita wujudkan hari bahagiamu, selangkah demi selangkah.',
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DCD6),
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/images/home.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF8F5),
                        Color(0xFFF0D1CA),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER SAMA DENGAN HOME
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 5),
                  child: _buildHeader(),
                ),

                // JUDUL
                _buildTitle(),

                // AREA CHAT
                Expanded(
                  child: _buildChatArea(),
                ),

                // INPUT PESAN
                _buildMessageInput(),

                const SizedBox(height: 7),

                const Text(
                  'Saran AI sebagai panduan, keputusan tetap di tanganmu.',
                  style: TextStyle(
                    fontSize: 8,
                    color: _hint,
                  ),
                ),

                const SizedBox(height: 9),

                // BOTTOM NAVIGATION SAMA DENGAN HOME
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // HEADER - DISESUAIKAN DENGAN HOME PAGE
  // ==================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogo(),

        Transform.translate(
          offset: const Offset(0, -8),
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                _buildBell(),
                const SizedBox(width: 10),
                _buildProfileMenu(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo_header.png',
      width: 145,
      height: 55,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      errorBuilder: (context, error, stackTrace) {
        return const Text(
          '♡ wedding+',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 22,
            color: _rose,
          ),
        );
      },
    );
  }

  Widget _buildBell() {
    return GestureDetector(
      onTap: () {
        _showMessage('Notifikasi belum tersedia');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _rose.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 22,
              color: _dark,
            ),
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return GestureDetector(
      onTap: () {
        (widget.onUserTap ??
            () => navigateToBottomTab(context, AppRoutes.user))();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _rose.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFE7B6B0),
              child: Icon(
                Icons.person,
                size: 17,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down,
              size: 19,
              color: _dark,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // JUDUL ASISTEN
  // ==================================================

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 5, 19, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: _rose,
              size: 21,
            ),
          ),
          const SizedBox(width: 17),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asisten Pernikahan',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 21,
                  color: _dark,
                ),
              ),
              Text(
                'Teman cerita menuju hari bahagia.',
                style: TextStyle(
                  fontSize: 9,
                  color: _hint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // AREA CHAT
  // ==================================================

  Widget _buildChatArea() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(19, 2, 19, 12),
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: _rose,
              size: 12,
            ),
            const SizedBox(width: 5),
            const Text(
              'Asisten Wedding+',
              style: TextStyle(
                fontSize: 9,
                color: _rose,
              ),
            ),
            const Spacer(),
            Text(
              'Hari ini · ${_currentTime()}',
              style: const TextStyle(
                fontSize: 8,
                color: _hint,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        ..._messages.map((message) {
          if (message['isUser'] == true) {
            return _buildUserMessage(
              message['text'].toString(),
              time: message['time']?.toString(),
            );
          }

          if (message['type'] == 'recommendation') {
            return _buildRecommendation(message['text'].toString());
          }

          return _buildAssistantMessage(message['text'].toString());
        }),

        if (_isSending)
          _buildAssistantMessage('Sedang mengetik...'),

        const SizedBox(height: 10),

        Text(
          'Lanjut bahas apa, $_userName?',
          style: const TextStyle(
            fontSize: 9,
            color: _hint,
          ),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _suggestionChip('Tips hemat budget'),
            _suggestionChip('Tanya vendor apa?'),
          ],
        ),
      ],
    );
  }

  Widget _buildAssistantMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            height: 1.5,
            color: _dark,
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(String text, {String? time}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 250),
          margin: const EdgeInsets.only(bottom: 3, top: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: _pink,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(13),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              color: _dark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 2, bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time ?? _currentTime(),
                style: const TextStyle(
                  fontSize: 8,
                  color: _hint,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.done_all,
                color: _rose,
                size: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                height: 1.5,
                color: _dark,
              ),
            ),

            const SizedBox(height: 8),

            _recommendationItem(
              Icons.home_work_outlined,
              'Konfirmasi venue resepsi',
              'Pastikan tanggal & jadwal pelunasan.',
            ),

            _recommendationItem(
              Icons.restaurant,
              'Pilih vendor katering',
              'Jadwalkan food tasting & cek paket.',
            ),

            _recommendationItem(
              Icons.people_outline,
              'Finalisasi daftar tamu',
              'Cocokkan jumlah tamu dengan budget.',
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                height: 1,
                color: _line,
              ),
            ),

            GestureDetector(
              onTap: () {
                (widget.onRencanaTap ??
                    () => navigateToBottomTab(context, AppRoutes.rencana))();
              },
              child: const Row(
                children: [
                  Text(
                    'Lihat rencana pernikahanku',
                    style: TextStyle(
                      fontSize: 9,
                      color: _rose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    color: _rose,
                    size: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: _lightPink,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: _rose,
              size: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 8,
                    color: _hint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: _isSending ? null : () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: _rose.withValues(alpha: 0.7),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 8,
            color: _rose,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // INPUT CHAT
  // ==================================================

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Container(
        padding: const EdgeInsets.only(left: 13, right: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan untuk asisten...',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: _hint,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),

            GestureDetector(
              onTap: _isSending ? null : () => _sendMessage(),
              child: Opacity(
                opacity: _isSending ? 0.6 : 1.0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: _rose,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_outlined,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage([String? suggestedText]) async {
    if (_isSending) return;

    final message = suggestedText ?? _messageController.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'type': 'text',
        'text': message,
        'time': _currentTime(),
      });
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      var replyText = await WeddingFeatureService.askAssistant(message);

      if (replyText.trim().isEmpty) {
        replyText =
            'Maaf, aku belum bisa memproses pertanyaan itu sekarang. Coba tanyakan dengan kalimat lain ya.';
      }

      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'type': 'text',
          'text': replyText.trim(),
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'type': 'text',
          'text': 'Maaf terjadi kendala: ${e.message}',
        });
      });
    } catch (e) {
      debugPrint('AI chat error: $e');
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'type': 'text',
          'text':
              'Koneksi ke asisten sedang terganggu. Pastikan server aktif lalu coba lagi ya.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================================================
  // BOTTOM NAVIGATION - SAMA DENGAN HOME
  // ==================================================

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_outlined,
            'Beranda',
            widget.onBerandaTap ??
                () => navigateToBottomTab(context, AppRoutes.home),
          ),
          _navItem(
            Icons.calendar_month_outlined,
            'Rencana',
            widget.onRencanaTap ??
                () => navigateToBottomTab(context, AppRoutes.rencana),
          ),
          _navItem(
            Icons.chat_bubble_outline,
            'Chat',
            widget.onChatTap ??
                () => navigateToBottomTab(context, AppRoutes.chat),
            selected: true,
          ),
          _navItem(
            Icons.person_outline,
            'User',
            widget.onUserTap ??
                () => navigateToBottomTab(context, AppRoutes.user),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        _showMessage('Navigasi $label belum dihubungkan');
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected ? _dark : const Color(0xFF8E8582),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: selected ? _dark : _hint,
                decoration: selected
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationThickness: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // HELPER
  // ==================================================

  String _currentTime() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}