
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'success_page.dart';

class EmailVerificationPage extends StatefulWidget {   // 👈 NAME
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    _checking = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && refreshedUser.emailVerified) {
          _timer?.cancel();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SuccessPage()),
          );
        }
      }
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'We sent you a verification email.\n\n'
                    'Please open your email, click the link,\n'
                'If you do not see it, check spam emails',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
