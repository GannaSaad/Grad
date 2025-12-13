import 'package:flutter/material.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // THEME BACKGROUND (Dentix gradient)
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

        child: Column(
          children: [
            // TOP IMAGE
            SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/doctor.jpg',   // <-- ADD THIS IMAGE
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),

                  // CENTERED “Dentix” IN ORANGE
                  Positioned(
                    bottom: 20,
                    child: Text(
                      "Dentix",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD2A35C),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Your Dentist, Just a\nTap Away.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Your smile’s best friend — Dentix helps you find reliable dentists, "
                    "book visits, and manage your dental health effortlessly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // CREATE ACCOUNT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5D18C), Color(0xFFE9BF72)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // LOGIN LINK
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? ",
                    style: TextStyle(fontSize: 14)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  child: const Text(
                    "Log In",
                    style: TextStyle(
                      color: Color(0xFF4A8BC8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
