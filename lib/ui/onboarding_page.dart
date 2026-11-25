
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

// =====================================================
// WARNA WEDDING+
// =====================================================

const Color rose = Color(0xFFD38E88);
const Color pink = Color(0xFFF4D4D1);
const Color cream = Color(0xFFFFF7F2);
const Color darkText = Color(0xFF6F514E);

// =====================================================
// FONT STYLE
// =====================================================

// Playfair Display untuk semua judul
TextStyle headingStyle({
  double size = 22,
  Color color = darkText,
}) {
  return GoogleFonts.playfairDisplay(
    fontSize: size,
    color: color,
    height: 1.15,
  );
}

// Montserrat untuk deskripsi dan isi
TextStyle bodyStyle({
  double size = 11,
  Color color = Colors.black54,
}) {
  return GoogleFonts.montserrat(
    fontSize: size,
    color: color,
    height: 1.3,
  );
}

// =====================================================
// ONBOARDING PAGE
// =====================================================

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  final PageController _pageController = PageController();

  int currentPage = 0;

  // =====================================================
  // NAVIGASI
  // =====================================================

  void nextPage() {
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // =====================================================
  // BUILD UTAMA
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),

        onPageChanged: (index) {
          setState(() {
            currentPage = index;
          });
        },

        children: [
          _buildSob1(),
          _buildSob2(),
          _buildSob3(),
        ],
      ),
    );
  }

  // =====================================================
  // LOGO
  // =====================================================

  Widget _buildLogo() {
    return Transform.translate(
      offset: const Offset(-25, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'assets/images/logo_header.png',
          width: 145,
          height: 55,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // =====================================================
  // TOMBOL
  // =====================================================

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 35,
      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white.withOpacity(0.35),

          side: const BorderSide(
            color: Colors.white70,
            width: 1,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
        ),

        child: Text(
          text,
          style: bodyStyle(
            size: 10,
            color: Colors.black87,
          ).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SOB 1
  // =====================================================

  Widget _buildSob1() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8F6),
            Color(0xFFE9B9B6),
          ],
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              _buildLogo(),

              const SizedBox(height: 25),

              // Judul SOB 1
              RichText(
                text: TextSpan(
                  style: headingStyle(size: 23),
                  children: const [
                    TextSpan(
                      text: 'Bingung\n'
                          'Merencanakan\n'
                          'Pernikahan ',
                    ),
                    TextSpan(
                      text: 'Anda?',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Deskripsi SOB 1
              Text(
                'Tenang, Anda tidak sendirian.\n'
                'Kami siap membantu mewujudkan\n'
                'pernikahan impian anda.',
                style: bodyStyle(size: 10),
              ),

              // Ilustrasi perempuan
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/sob1_woman.svg',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: _buildButton(
                  text: 'Lanjut',
                  onPressed: nextPage,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SOB 2
  // =====================================================

  Widget _buildSob2() {
    return Container(
      color: cream,

      child: Stack(
        children: [

          // Background floral SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/background.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 20),

                  _buildLogo(),

                  const SizedBox(height: 20),

                  // Judul SOB 2
                  RichText(
                    text: TextSpan(
                      style: headingStyle(size: 22),
                      children: const [
                        TextSpan(
                          text: 'Rencanakan\n'
                              'Pernikahan ',
                        ),
                        TextSpan(
                          text: 'Impianmu',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Deskripsi SOB 2
                  Text(
                    'Susun rencana pernikahan sesuai\n'
                    'keinginanmu dengan lebih mudah\n'
                    'dan terorganisir.',
                    style: bodyStyle(size: 10),
                  ),

                  const SizedBox(height: 24),

                  // Daftar card fitur
                  Expanded(
                    child: Column(
                      children: [

                        _buildFeatureCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Planing',
                          description:
                              'Atur acara pernikahan\n'
                              'dan atur pengeluaran anda',
                        ),

                        _buildFeatureCard(
                          icon: Icons.diamond_outlined,
                          title: 'Discover',
                          description:
                              'Temukan paket maupun layanan\n'
                              'sesuai anggaran pernikahan anda',
                        ),

                        _buildFeatureCard(
                          icon: Icons.handshake_outlined,
                          title: 'Together',
                          description:
                              'Atur jadwal, tugas dan rencanakan\n'
                              'tabungan bersama pasangan anda',
                        ),

                        _buildFeatureCard(
                          icon: Icons.support_agent,
                          title: 'Asistant',
                          description:
                              'Dapatkan bantuan dan informasi\n'
                              'untuk persiapan pernikahan anda',
                        ),
                      ],
                    ),
                  ),

                  // Tombol navigasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      _buildButton(
                        text: 'Kembali',
                        onPressed: previousPage,
                      ),

                      _buildButton(
                        text: 'Lanjut',
                        onPressed: nextPage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CARD FITUR SOB 2
  // =====================================================

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      height: 66,

      margin: const EdgeInsets.only(bottom: 7),

      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFF1D5D0),
          width: 0.8,
        ),

        boxShadow: [
          BoxShadow(
            color: rose.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [

          // Icon fitur
          Container(
            width: 36,
            height: 36,

            decoration: BoxDecoration(
              color: const Color(0xFFF4D6D2),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Icon(
              icon,
              color: darkText,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          // Judul dan isi card
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // JUDUL CARD: PLAYFAIR DISPLAY
                Text(
                  title,
                  style: headingStyle(
                    size: 17,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 2),

                // ISI CARD: MONTSERRAT
                Text(
                  description,
                  style: bodyStyle(
                    size: 8,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SOB 3
  // =====================================================

  Widget _buildSob3() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.55, 1.0],
          colors: [
            Color(0xFFFBF3ED),
            Color(0xFFF5DDD6),
            Color(0xFFE7B5B1),
          ],
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              _buildLogo(),

              const SizedBox(height: 25),

              // Judul SOB 3
              RichText(
                text: TextSpan(
                  style: headingStyle(size: 22),
                  children: const [
                    TextSpan(
                      text: 'Satu Langkah\n'
                          'Menuju Hari\n',
                    ),
                    TextSpan(
                      text: 'Istimewa',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Deskripsi SOB 3
              Text(
                'Persiapkan setiap momen pernikahanmu\n'
                'dengan lebih mudah, terarah, dan sesuai\n'
                'impianmu bersama Wedding+',
                style: bodyStyle(size: 10),
              ),

              // Ilustrasi perempuan duduk
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/sob3_woman.svg',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),

              // Tombol navigasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _buildButton(
                    text: 'Kembali',
                    onPressed: previousPage,
                  ),

                  _buildButton(
                    text: 'Mulai',
                    onPressed: finishOnboarding,
                  ),
                ],
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}