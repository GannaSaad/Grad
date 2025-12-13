// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        _infoMessage =
        'We sent a password reset link to $email.\nPlease check your inbox (and spam).';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Failed to send reset email.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5E2C0),
              Color(0xFFE0AF6F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width > 430 ? 430 : size.width * 0.95,
              ),
              child: _buildCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 6, backgroundColor: Color(0xFFD2A35C)),
                SizedBox(width: 8),
                Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'Enter the email address you used to create your account. '
                  'We will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.black87),
            ),

            const SizedBox(height: 22),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],

            if (_infoMessage != null) ...[
              Text(
                _infoMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5D18C), Color(0xFFE9BF72)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Send reset link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to login',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A8BC8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
