import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../helpers/session.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session.dart' as app_session;
import 'login_page.dart';
import 'home/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Warna ditebak dari screenshot Figma.
  // Ganti dengan kode hex asli dari Figma kalau berbeda.
  static const Color _rose = Color(0xFFC58A85);
  static const Color _pink = Color(0xFFE7B6B0);
  static const Color _textDark = Color(0xFF3D3533);
  static const Color _hint = Color(0xFF9A8F8D);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agree = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToLogin() {
    if (_isLoading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _register() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Semua kolom wajib diisi');
      return;
    }
    if (name.length < 2) {
      _showMessage('Nama minimal 2 karakter');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Format email tidak valid');
      return;
    }
    if (password.length < 8 || password.length > 16) {
      _showMessage('Password harus 8–16 karakter');
      return;
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(password)) {
      _showMessage('Password harus mengandung huruf dan angka');
      return;
    }
    if (password != confirm) {
      _showMessage('Konfirmasi password tidak sama');
      return;
    }
    if (!_agree) {
      _showMessage('Setujui Syarat & Ketentuan dulu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirm,
        acceptTerms: _agree,
      );

      final hasToken = await app_session.Session.isLoggedIn();
      if (!mounted) return;

      if (hasToken) {
        Session.isLoggedIn = true;
        _showMessage('Registrasi berhasil');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      } else {
        _showMessage('Registrasi berhasil, silakan masuk');
        _goToLogin();
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      debugPrint('Register error: $e');
      _showMessage('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontSize: 12),
      prefixIcon: Icon(icon, color: _textDark, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0x99FFFFFF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _pink),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _rose, width: 1.5),
      ),
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: _hint,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  // Tab "Masuk" / "Daftar" dengan garis bawah.
  Widget _tab(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _rose : const Color(0x33C58A85),
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _rose : const Color(0xFFD9B3AF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Checkbox "Saya setuju dengan Syarat & Ketentuan dan Kebijakan Privasi".
  Widget _buildAgreeRow() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agree,
            onChanged: (value) {
              setState(() {
                _agree = value ?? false;
              });
            },
            activeColor: _rose,
            side: const BorderSide(color: _pink, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Saya setuju dengan ',
              style: TextStyle(color: _textDark, fontSize: 10),
              children: [
                TextSpan(
                  text: 'Syarat & Ketentuan',
                  style: TextStyle(color: _rose),
                ),
                TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: TextStyle(color: _rose),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Panel kaca di bagian bawah layar.
  Widget _buildPanel() {
    final screen = MediaQuery.of(context);
    final bottomSpace = screen.viewInsets.bottom + screen.padding.bottom;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          // Efek kaca: buram pada bunga di belakang panel.
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: screen.size.height * 0.9),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomSpace),
            decoration: const BoxDecoration(
              color: Color(0x66FFFFFF),
              border: Border(
                top: BorderSide(color: Color(0x99FFFFFF)),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab Masuk / Daftar
                  Row(
                    children: [
                      _tab('Masuk', false, _goToLogin),
                      _tab('Daftar', true, () {}),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nama Lengkap
                  _label('Nama Lengkap'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: _textDark, fontSize: 13),
                    decoration: _fieldDecoration(
                      'Masukan nama lengkap Anda',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _label('Email'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: _textDark, fontSize: 13),
                    decoration: _fieldDecoration(
                      'Masukan email Anda',
                      Icons.mail_outline,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  _label('Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: _textDark, fontSize: 13),
                    decoration: _fieldDecoration(
                      'Buat password (min. 8 karakter)',
                      Icons.lock_outline,
                      suffix: _eyeButton(_obscurePassword, () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Konfirmasi Password
                  _label('Konfirmasi Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: _textDark, fontSize: 13),
                    decoration: _fieldDecoration(
                      'Masukan kembali password Anda',
                      Icons.lock_outline,
                      suffix: _eyeButton(_obscureConfirm, () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Syarat & Ketentuan
                  _buildAgreeRow(),
                  const SizedBox(height: 12),

                  // Tombol Daftar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),

                  // Sudah punya akun?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun?',
                        style: TextStyle(color: _hint, fontSize: 11),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Masuk di sini',
                          style: TextStyle(
                            color: _rose,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF4EF),
      // Latar tidak ikut bergeser saat keyboard muncul.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Latar: bunga, logo, dan kalimat (hasil ekspor Figma).
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/Registrasi.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Panel kaca di bagian bawah.
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildPanel(),
          ),
        ],
      ),
    );
  }
}