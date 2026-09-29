import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Shown every time the app starts: the big icon bounces in with a welcome
/// line, then [onDone] runs by itself after [duration]. Tapping skips ahead.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onDone,
    this.duration = const Duration(seconds: 3),
  });

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final _iconScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.elasticOut),
  );
  late final _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 1, curve: Curves.easeOut),
  );

  late final Timer _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Container(
          decoration: const BoxDecoration(
            // Sky to meadow, the same colours as the icon.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBFE3FF), Color(0xFFEAF6FF), Color(0xFF7BD389)],
              stops: [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _iconScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/icon_round.png',
                          width: 220,
                          height: 220,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            l10n.welcomeTitle,
                            textAlign: TextAlign.center,
                            style: text.headlineMedium?.copyWith(
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.welcomeSubtitle,
                            textAlign: TextAlign.center,
                            style: text.titleMedium?.copyWith(
                              color: const Color(0xFF2E4A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        l10n.welcomeTagline,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: const Color(0xFF1B3A24),
                          fontStyle: FontStyle.italic,
                        ),
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
}
