import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/court_hero.dart';
import 'widgets/email_auth_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSubmitting = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Não foi possível entrar com o Google.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _openEmailSheet({required bool isSignUp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmailAuthSheet(isSignUp: isSignUp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CourtHero(),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vindo de volta', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'Registre placares, acompanhe seu rating e dispute o topo do ranking da sua arena.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(backgroundColor: AppColors.textPrimary, foregroundColor: const Color(0xFF1A2E2B)),
                      icon: const Icon(Icons.g_mobiledata, size: 26),
                      label: const Text('Continuar com Google'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _openEmailSheet(isSignUp: false),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Continuar com e-mail'),
                    ),
                    const SizedBox(height: 20),
                    const Row(children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OU', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => _openEmailSheet(isSignUp: true),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                            children: [
                              TextSpan(text: 'Não tem conta? '),
                              TextSpan(text: 'Criar conta grátis', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
