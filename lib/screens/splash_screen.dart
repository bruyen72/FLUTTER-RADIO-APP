import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────
  late final AnimationController _mainCtrl;   // sequência principal
  late final AnimationController _pulseCtrl;  // anéis pulsando
  late final AnimationController _dotsCtrl;   // dots saltando

  // ── Animações ────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOffset;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _lineOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _ringPulse;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Logo: spring bounce de 0.2 → 1.0 + fade-in rápido
    _logoScale = Tween(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.18, curve: Curves.easeIn),
      ),
    );

    // "TECPOINT": desliza de baixo + fade
    _titleOffset = Tween(begin: 32.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
      ),
    );

    // Linha decorativa
    _lineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.58, 0.76, curve: Curves.easeOut),
      ),
    );

    // Subtítulo: fade depois da linha
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.64, 0.82, curve: Curves.easeOut),
      ),
    );

    // Dots: aparecem por último
    _dotsOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.78, 0.94, curve: Curves.easeOut),
      ),
    );

    // Anéis: escala 0.92 ↔ 1.08 em loop
    _ringPulse = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _mainCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050e08),
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl, _dotsCtrl]),
        builder: (_, __) {
          final op = _logoOpacity.value;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Color(0xFF0b2214), Color(0xFF050e08)],
              ),
            ),
            child: Stack(
              children: [
                // ── Anéis pulsantes ──────────────────────
                Center(child: _buildRings(op)),

                // ── Conteúdo principal ───────────────────
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // Logo com glow verde
                      Opacity(
                        opacity: op,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 114, height: 114,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16a34a).withOpacity(0.5 * op),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF22c55e).withOpacity(0.22 * op),
                                  blurRadius: 120,
                                  spreadRadius: 30,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 38),

                      // "TECPOINT"
                      Transform.translate(
                        offset: Offset(0, _titleOffset.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: const Text(
                            'TECPOINT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 11,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Linha decorativa gradiente
                      Opacity(
                        opacity: _lineOpacity.value,
                        child: Container(
                          width: 70, height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF15803d),
                                Color(0xFF22c55e),
                                Color(0xFF15803d),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtítulo
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: const Text(
                          'Gerenciador de Ordens de Serviço',
                          style: TextStyle(
                            color: Color(0xFF92b89e),
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 68),

                      // Dots saltando
                      Opacity(
                        opacity: _dotsOpacity.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, _buildDot),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Rodapé ──────────────────────────────
                Positioned(
                  bottom: 30, left: 0, right: 0,
                  child: Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const Text(
                      '© 2026 TECPOINT  ·  UniSENAI MT',
                      style: TextStyle(color: Color(0xFF2a5238), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Anéis concêntricos pulsantes ─────────────────────────────
  Widget _buildRings(double op) {
    return SizedBox(
      width: 360, height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow central
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF16a34a).withOpacity(0.07 * op),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Anel interno — fixo
          Container(
            width: 152, height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF16a34a).withOpacity(0.18 * op),
                width: 1.5,
              ),
            ),
          ),
          // Anel médio — pulsa devagar
          Transform.scale(
            scale: 1.0 + (_ringPulse.value - 0.92) * 1.2,
            child: Container(
              width: 230, height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF16a34a).withOpacity(0.10 * op),
                  width: 1,
                ),
              ),
            ),
          ),
          // Anel externo — pulsa mais
          Transform.scale(
            scale: _ringPulse.value,
            child: Container(
              width: 330, height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF16a34a).withOpacity(0.05 * op),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dot individual com fase defasada ─────────────────────────
  Widget _buildDot(int index) {
    final phase = (_dotsCtrl.value + index / 3) % 1.0;
    final t = math.sin(phase * math.pi).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, -9 * t),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromRGBO(22, 163, 74, 0.20 + 0.80 * t),
          boxShadow: t > 0.4
              ? [
                  BoxShadow(
                    color: const Color(0xFF16a34a).withOpacity(t * 0.6),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
