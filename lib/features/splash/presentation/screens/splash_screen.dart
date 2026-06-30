import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({super.key, required this.onSplashComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleLogo;
  late Animation<double> _fadeOut;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashTimer();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleLogo = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeOut = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onSplashComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo - Ukuran lebih gede
                    Opacity(
                      opacity: 1.0 - _fadeOut.value,
                      child: Transform.scale(
                        scale: _scaleLogo.value,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: Image.asset(
                            'assets/images/logo1.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8), // DIREKATIN dari 32 ke 8
                    // Tulisan Republik Casual
                    Opacity(
                      opacity: 1.0 - _fadeOut.value,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'REPUBLIK CASUAL',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4), // DIREKATIN dari 8 ke 4
                    // Subtitle
                    Opacity(
                      opacity: 1.0 - _fadeOut.value,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'FASHION STORE',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // DIREKATIN dari 60 ke 40
                    // Progress Bar Matrix Style - Putih
                    Opacity(
                      opacity: 1.0 - _fadeOut.value,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: _buildMatrixProgressBar(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Background efek matrix dots (putih)
  List<Widget> _buildMatrixBackground() {
    final random = DateTime.now().millisecond % 100;
    final dots = <Widget>[];
    for (int i = 0; i < 50; i++) {
      final x = (i * 37 + random) % 100;
      final y = (i * 53 + random * 2) % 100;
      final size = 2.0 + (i % 3);
      final opacity = 0.03 + (i % 5) * 0.02;
      dots.add(
        Positioned(
          left: MediaQuery.of(context).size.width * x / 100,
          top: MediaQuery.of(context).size.height * y / 100,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return dots;
  }

  Widget _buildMatrixProgressBar() {
    return Column(
      children: [
        // Progress bar utama - putih
        Container(
          width: 250,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: List.generate(25, (index) {
              final progress = _progressAnimation.value;
              final isFilled = index / 25 < progress;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? _getMatrixColor(index, progress)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: isFilled ? _buildPixelChar(index, progress) : null,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12), // DIREKATIN dari 16 ke 12
        // Teks progress ala matrix - putih
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '[',
              style: GoogleFonts.leagueSpartan(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w300,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final percent = (_progressAnimation.value * 100).toInt();
                return Text(
                  '${percent.toString().padLeft(3, '0')}%',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 12,
                    color: Colors.white.withValues(
                      alpha: 0.5 + (_progressAnimation.value * 0.5),
                    ),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                );
              },
            ),
            Text(
              ']',
              style: GoogleFonts.leagueSpartan(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 20),
            // Loading dots animation - putih
            _buildLoadingDots(),
          ],
        ),
      ],
    );
  }

  Widget _buildPixelChar(int index, double progress) {
    final chars = ['▮', '▯', '■', '□', '▪', '▫', '◆', '◇'];
    final charIndex =
        (index + DateTime.now().millisecond ~/ 100) % chars.length;
    return Text(
      chars[charIndex],
      style: TextStyle(
        fontSize: 7,
        color: _getMatrixColor(index, progress),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getMatrixColor(int index, double progress) {
    final intensity = 0.5 + (progress * 0.5);
    final white = (180 + (75 * intensity)).toInt();
    final alpha = 0.6 + (0.4 * intensity);

    // Efek berkedip
    final blink = (DateTime.now().millisecond ~/ 150) % 2 == 0 ? 1.0 : 0.8;

    if (index % 3 == 0) {
      return Color.fromARGB((255 * alpha * blink).toInt(), white, white, white);
    } else if (index % 3 == 1) {
      return Color.fromARGB(
        (255 * alpha * blink).toInt(),
        white - 30,
        white - 30,
        white - 30,
      );
    } else {
      return Color.fromARGB(
        (255 * alpha * blink).toInt(),
        white - 50,
        white - 50,
        white - 50,
      );
    }
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dotCount = (DateTime.now().millisecond ~/ 300) % 4;
        return Row(
          children: List.generate(3, (index) {
            final isVisible = index < dotCount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isVisible
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
