import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/log_service.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class VerificacaoEmailScreen extends StatefulWidget {
  const VerificacaoEmailScreen({super.key});

  @override
  State<VerificacaoEmailScreen> createState() => _VerificacaoEmailScreenState();
}

class _VerificacaoEmailScreenState extends State<VerificacaoEmailScreen> {
  bool _verificando = false;
  bool _reenviando = false;
  Timer? _timer;
  int _segundosParaReenviar = 0;

  @override
  void initState() {
    super.initState();
    _iniciarVerificacaoAutomatica();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarVerificacaoAutomatica() {
    // Verificar a cada 3 segundos se o email foi verificado
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _verificarEmail();
    });
  }

  Future<void> _verificarEmail() async {
    if (!mounted) return;

    setState(() => _verificando = true);

    try {
      await AuthService.recarregarUsuario();

      if (AuthService.emailVerificado) {
        _timer?.cancel();
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      }
    } catch (e) {
      LogService.ui('Erro ao verificar email', e);
      // Ignora erros durante verificação automática
    } finally {
      if (mounted) {
        setState(() => _verificando = false);
      }
    }
  }

  Future<void> _reenviarEmail() async {
    if (_segundosParaReenviar > 0) return;

    setState(() => _reenviando = true);

    try {
      await AuthService.enviarEmailVerificacao();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de verificação reenviado!'),
          backgroundColor: Colors.teal,
        ),
      );

      // Cooldown de 60 segundos para reenviar
      setState(() => _segundosParaReenviar = 60);

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _segundosParaReenviar--;
          if (_segundosParaReenviar <= 0) {
            timer.cancel();
          }
        });
      });
    } catch (e) {
      LogService.ui('Erro ao reenviar email de verificação', e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reenviando = false);
      }
    }
  }

  Future<void> _cancelarEVoltar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cadastro?'),
        content: const Text(
          'A verificação de email é obrigatória para garantir a segurança da sua conta.\n\n'
          'Se cancelar, você precisará fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar verificando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Fazer logout e voltar para login
      await AuthService.logout();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 80,
                      color: Colors.teal[700],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verifique seu email',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enviamos um email de verificação para:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Clique no link do email para verificar sua conta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_verificando)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verificando...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _segundosParaReenviar > 0 || _reenviando ? null : _reenviarEmail,
                        icon: _reenviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _segundosParaReenviar > 0 ? 'Reenviar em $_segundosParaReenviar s' : 'Reenviar email',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelarEVoltar,
                        icon: const Icon(Icons.logout),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        label: const Text('Cancelar e voltar'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A verificação de email é obrigatória para proteger sua conta.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Não recebeu o email? Verifique a pasta de spam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
