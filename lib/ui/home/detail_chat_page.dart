
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/session.dart' as app_session;

class DetailChatPage extends StatefulWidget {
  // ID percakapan dikirim dari halaman Chat.
  final String? conversationId;

  const DetailChatPage({
    super.key,
    this.conversationId,
  });

  @override
  State<DetailChatPage> createState() => _DetailChatPageState();
}

class _DetailChatPageState extends State<DetailChatPage> {
  static const Color _rose = Color(0xFFC58A85);
  static const Color _dark = Color(0xFF493B38);
  static const Color _hint = Color(0xFF9A8985);

  // ============================================================
  // DATA DARI BACKEND
  // ============================================================

  String? vendorName;
  String? vendorCategory;
  String? vendorLocation;
  String? vendorInitial;
  bool? isVendorOnline;

  String? packageName;
  String? packageDescription;
  String? packagePrice;
  String? packageImage;

  List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    if (widget.conversationId != null &&
        widget.conversationId!.isNotEmpty) {
      _fetchChatDetail();
    } else {
      _errorMessage = 'ID percakapan belum tersedia.';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET DETAIL CHAT DARI BACKEND
  //
  // CONTOH FORMAT RESPONSE YANG DIHARAPKAN:
  //
  // {
  //   "data": {
  //     "vendor": {
  //       "name": "...",
  //       "category": "...",
  //       "location": "...",
  //       "initial": "...",
  //       "isOnline": true
  //     },
  //     "package": {
  //       "name": "...",
  //       "description": "...",
  //       "price": "...",
  //       "image": "..."
  //     },
  //     "messages": [
  //       {
  //         "id": 1,
  //         "message": "...",
  //         "time": "...",
  //         "isMe": false
  //       }
  //     ]
  //   }
  // }
  //
  // TODO BACKEND:
  // Sesuaikan struktur response dengan API milikmu.
  // ============================================================

  Future<void> _fetchChatDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = widget.conversationId!;
      final detail = await ApiClient.get('/chat/conversations/$id');
      final messagesResponse =
          await ApiClient.get('/chat/conversations/$id/messages');
      final profile = await app_session.Session.getUserProfile();
      final currentUserId = profile['id'];

      if (detail is! Map<String, dynamic>) {
        throw ApiException('Format detail percakapan tidak sesuai.', 500);
      }
      final vendor = detail['vendor'] is Map<String, dynamic>
          ? detail['vendor'] as Map<String, dynamic>
          : <String, dynamic>{};
      final package = detail['package'] is Map<String, dynamic>
          ? detail['package'] as Map<String, dynamic>
          : <String, dynamic>{};
      final rawMessages =
          messagesResponse is List ? messagesResponse : <dynamic>[];
      final mappedMessages = rawMessages
          .whereType<Map<String, dynamic>>()
          .map((item) {
        final createdAt = DateTime.tryParse(
          (item['createdAt'] ?? '').toString(),
        )?.toLocal();
        final attachment = item['attachmentUrl']?.toString();
        return <String, dynamic>{
          'id': item['id']?.toString(),
          'message': (item['content'] ?? attachment ?? '').toString(),
          'time': createdAt == null
              ? ''
              : '${createdAt.hour.toString().padLeft(2, '0')}.'
                  '${createdAt.minute.toString().padLeft(2, '0')}',
          'isMe': item['senderId']?.toString() == currentUserId,
          'type': item['type']?.toString() ?? 'text',
          'createdAt': createdAt,
        };
      }).toList()
        ..sort((a, b) {
          final aDate = a['createdAt'] as DateTime?;
          final bDate = b['createdAt'] as DateTime?;
          if (aDate == null || bDate == null) return 0;
          return aDate.compareTo(bDate);
        });

      if (!mounted) return;
      setState(() {
        vendorName = vendor['storeName']?.toString();
        vendorCategory = 'Vendor';
        vendorLocation = vendor['city']?.toString();
        vendorInitial = (vendor['storeName'] ?? 'V')
            .toString()
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
            .join();
        isVendorOnline = null;
        packageName = package['name']?.toString();
        packageDescription = package['description']?.toString();
        packagePrice = package['price']?.toString();
        packageImage = package['imageUrl']?.toString();
        _messages = mappedMessages;
      });

      await ApiClient.patch('/chat/conversations/$id/read');
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memuat percakapan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // POST KIRIM PESAN KE BACKEND
  //
  // CONTOH REQUEST BODY:
  // {
  //   "message": "Isi pesan"
  // }
  //
  // TODO BACKEND:
  // Sesuaikan endpoint dan field request dengan API milikmu.
  // ============================================================

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    final id = widget.conversationId;
    if (id == null || id.isEmpty) {
      _showMessage('ID percakapan belum tersedia.');
      return;
    }

    setState(() => _isSending = true);
    try {
      await ApiClient.post(
        '/chat/messages',
        body: {
          'conversationId': id,
          'type': 'text',
          'content': message,
        },
      );
      _messageController.clear();
      await _fetchChatDetail();
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Gagal mengirim pesan. Periksa koneksi backend.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }
    return value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dark,
      ),
    );
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

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glass({
    required Widget child,
    double radius = 18,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFFFF8F5)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildChatHeader(),

                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _rose,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Expanded(
                    child: _buildErrorState(),
                  )
                else ...[
                  _buildVendorInfo(),
                  _buildPackageCard(),
                  const SizedBox(height: 8),

                  const Text(
                    'Hari ini',
                    style: TextStyle(
                      fontSize: 9,
                      color: _hint,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: _buildMessages(),
                  ),
                ],

                _buildMessageInput(),

                const SizedBox(height: 8),

                Text(
                  vendorName == null
                      ? 'Percakapan Anda dengan penyedia.'
                      : 'Percakapan Anda dengan ${vendorName!}.',
                  style: const TextStyle(
                    fontSize: 8,
                    color: _hint,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: _rose,
              size: 35,
            ),
            const SizedBox(height: 10),
            const Text(
              'Data percakapan belum tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: _hint,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _fetchChatDetail,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: _rose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER LOGO
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo_header.png',
            width: 110,
            height: 48,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => const Text(
              'wedding+',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                color: _rose,
              ),
            ),
          ),

          Row(
            children: [
              _headerCircle(
                Icons.notifications_none,
                showDot: true,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFF0D8D3),
                      child: Icon(
                        Icons.person,
                        size: 15,
                        color: _rose,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: _dark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCircle(
    IconData icon, {
    bool showDot = false,
  }) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _rose.withOpacity(0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 19, color: _dark),
          if (showDot)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // JUDUL CHAT
  // ============================================================

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 3, 18, 7),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: _rose,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat Penyedia',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 21,
                  color: _dark,
                ),
              ),
              Text(
                'Diskusikan paket untuk hari bahagiamu.',
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

  // ============================================================
  // INFORMASI VENDOR DARI BACKEND
  // ============================================================

  Widget _buildVendorInfo() {
    final initial = _display(vendorInitial);
    final online = isVendorOnline == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 9),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF0D8D3),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                color: _rose,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display(vendorName),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 14,
                    color: _dark,
                  ),
                ),

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${_display(vendorCategory)} · '
                        '${_display(vendorLocation)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: _hint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: online ? Colors.green : _hint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 9,
                        color: online ? Colors.green : _hint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.more_vert,
            color: _rose,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMASI PAKET DARI BACKEND
  // ============================================================

  Widget _buildPackageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi paket',
            style: TextStyle(
              fontSize: 8,
              color: _hint,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildPackageImage(),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _display(packageName),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 12,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _display(packageDescription),
                      style: const TextStyle(
                        fontSize: 8,
                        color: _hint,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _display(packagePrice),
                      style: const TextStyle(
                        fontSize: 8,
                        color: _rose,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: _rose,
                size: 19,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageImage() {
    if (packageImage != null &&
        packageImage!.trim().isNotEmpty) {
      return Image.network(
        packageImage!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _packagePlaceholder(),
      );
    }

    return _packagePlaceholder();
  }

  Widget _packagePlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF0D8D3),
      child: const Icon(
        Icons.image_outlined,
        color: _rose,
      ),
    );
  }

  
  // PESAN DARI DATABASE
  

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pesan.',
          style: TextStyle(
            fontSize: 10,
            color: _hint,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final item = _messages[index];

        // TODO BACKEND:
        // Sesuaikan field isMe dengan response API.
        final bool isMe = item['isMe'] == true;

        final message = item['message']?.toString() ?? '';
        final time = item['time']?.toString() ?? '';

        return Align(
          alignment: isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFFF0D4CF)
                        : Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(11),
                      topRight: const Radius.circular(11),
                      bottomLeft:
                          Radius.circular(isMe ? 11 : 3),
                      bottomRight:
                          Radius.circular(isMe ? 3 : 11),
                    ),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: _dark,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 7,
                        color: _hint,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 11,
                        color: _rose,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // INPUT DAN KIRIM PESAN
  // ============================================================

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _rose.withOpacity(0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_file,
            color: _rose,
            size: 19,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Tulis pesan ke penyedia...',
                hintStyle: TextStyle(
                  fontSize: 10,
                  color: _hint,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 11,
                color: _dark,
              ),
            ),
          ),

          const SizedBox(width: 7),

          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _rose,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 17,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
