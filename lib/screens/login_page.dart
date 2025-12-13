// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as g;

import 'sign_up_page.dart';
import 'forgot_password_page.dart';
import 'patient_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Single GoogleSignIn instance
  final g.GoogleSignIn _googleSignIn = g.GoogleSignIn();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================================
  // EMAIL / PASSWORD LOGIN
  // ========================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null && !user.emailVerified) {
        setState(() {
          _errorMessage = 'Your email is not verified. Check your inbox.';
        });
        await user.sendEmailVerification();
        return;
      }

      // OPTIONAL: show a small toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged in successfully!')),
      );

      // ===== NAVIGATE TO PATIENT DASHBOARD =====
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Login failed');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ========================================================
  // GOOGLE SIGN-IN
  // ========================================================
  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Make sure any previous session is cleared
      await _googleSignIn.signOut();

      final g.GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn(); // opens the Google chooser

      // User cancelled the dialog
      if (googleUser == null) {
        setState(() => _errorMessage = 'Google sign-in cancelled.');
        return;
      }

      final g.GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        setState(() => _errorMessage = 'No Google token received.');
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged in with Google!')),
      );

      // ===== NAVIGATE TO PATIENT DASHBOARD =====
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Google sign-in failed');
    } catch (e) {
      // ApiException(8, ...) and similar end up here
      setState(() => _errorMessage =
      'Couldn\'t sign in with Google. Check your internet and Firebase config, then try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ========================================================
  // (UNUSED NOW) DIRECT RESET FROM LOGIN
  // ========================================================
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first.')),
      );
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset email sent.')),
    );
  }

  // ========================================================
  // UI
  // ========================================================
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to Dentix',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildLoginCard(),

                  const SizedBox(height: 28),

                  _buildToothPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // LOGIN CARD
  // ========================================================
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(radius: 6, backgroundColor: Color(0xFFD2A35C)),
              SizedBox(width: 8),
              Text(
                'Log In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Email'),
                  _inputField(_emailController, false),

                  const SizedBox(height: 16),

                  _label('Password'),
                  _inputField(
                    _passwordController,
                    true,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // Go to forgot password screen
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'forgot password ?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A8BC8),
                      ),
                    ),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  _loginButton(),

                  const SizedBox(height: 14),

                  _divider(),

                  const SizedBox(height: 14),

                  _googleButton(),

                  const SizedBox(height: 14),

                  _signUpLink(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),
        ],
      ),
    );
  }

  // ========================================================
  // TOOTH PANEL (BOTTOM)
  // ========================================================
  Widget _buildToothPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE9BF72),
              Color(0xFFD8A861),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: const Alignment(0, 0.95),
              child: Container(
                height: 32,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.45),
              child: Image.asset(
                'assets/images/tooth.png',
                height: 230,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // SMALL HELPERS
  // ========================================================
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  Widget _inputField(
      TextEditingController c,
      bool isPassword, {
        Widget? suffix,
      }) {
    return TextFormField(
      controller: c,
      obscureText: isPassword ? _obscurePassword : false,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
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
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _loading
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.2,
            ),
          )
              : const Text(
            'Log in',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _loading ? null : _signInWithGoogle,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', height: 20),
            const SizedBox(width: 12),
            const Text(
              'Sign in with Google',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have account? ",
          style: TextStyle(fontSize: 13),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            );
          },
          child: const Text(
            'Create an account',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A8BC8),
            ),
          ),
        ),
      ],
    );
  }
}
