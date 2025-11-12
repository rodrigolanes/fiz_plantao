import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'lista_plantoes_screen.dart';
import 'login_screen.dart';
import 'verificacao_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Verifica autenticação e navega após 2.5 segundos
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() async {
    final navigator = Navigator.of(context);

    // Verifica se usuário está logado
    if (AuthService.isLoggedIn) {
      // Verifica se o email foi verificado
      if (!AuthService.emailVerificado) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const VerificacaoEmailScreen()),
        );
      } else {
        // Inicializa sincronização em background ao entrar no app
        SyncService.initialize();

        // Faz o download inicial dos dados do Supabase
        try {
          await SyncService.syncAll();
        } catch (e) {
          // Continua mesmo se falhar (pode estar offline)
        }

        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ListaPlantoesScreen()),
        );
      }
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagem da planta
                Image.asset(
                  'assets/images/plant.png',
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Text(
                  'Fiz Plantão',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organize seus plantões',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[400]!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
