import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'email_verification.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherAllergyController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _gender = 'Male';
  bool _hasAllergies = false;
  String? _selectedAllergy;
  bool _hasInsurance = false;

  bool _loading = false;
  String? _errorMessage;

  final List<String> _allergiesOptions = [
    'Penicillin',
    'Aspirin',
    'Ibuprofen',
    'Local anesthetics',
    'Latex',
    'Nickel / metals',
    'Food - nuts',
    'Food - seafood',
    'Pollen / dust',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      _dobController.text =
      "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation for allergies
    if (_hasAllergies) {
      if (_selectedAllergy == null) {
        setState(() {
          _errorMessage = 'Please select your allergy.';
        });
        return;
      }
      if (_selectedAllergy == 'Other' &&
          _otherAllergyController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please specify your allergy.';
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Check your email for verification.'),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EmailVerificationPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already in use.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        case 'weak-password':
          msg = 'Password is too weak.';
          break;
        default:
          msg = e.message ?? 'Something went wrong.';
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
              Color(0xFFF5E2C0), // match login
              Color(0xFFE0AF6F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width > 430 ? 430 : size.width * 0.95,
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/dr_shagy_logo.jpg',
                            height: 70,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dentix',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Required';
                          }
                          if (!RegExp(r'^\d+$').hasMatch(value)) {
                            return 'Digits only';
                          }
                          if (value.length != 11) {
                            return 'Phone number must be 11 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Male'),
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (v) {
                                setState(() => _gender = v!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Female'),
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (v) {
                                setState(() => _gender = v!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Date of birth',
                            controller: _dobController,
                            suffixIcon:
                            const Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Required';
                          }
                          if (v.length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Required';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Allergies',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _hasAllergies,
                            onChanged: (v) {
                              setState(() {
                                _hasAllergies = v;
                                if (!v) {
                                  _selectedAllergy = null;
                                  _otherAllergyController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_hasAllergies) ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Select allergy'),
                          value: _selectedAllergy,
                          items: _allergiesOptions
                              .map(
                                (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a),
                            ),
                          )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedAllergy = v);
                          },
                          validator: (v) {
                            if (_hasAllergies && v == null) {
                              return 'Select an allergy';
                            }
                            return null;
                          },
                        ),
                        if (_selectedAllergy == 'Other') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otherAllergyController,
                            decoration:
                            _inputDecoration('Type your allergy'),
                            validator: (v) {
                              if (_hasAllergies &&
                                  _selectedAllergy == 'Other' &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Please specify your allergy';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medical insurance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _hasInsurance,
                            onChanged: (v) {
                              setState(() => _hasInsurance = v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF5D18C),
                                Color(0xFFE9BF72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _signUp,
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: suffixIcon,
      ),
    );
  }
}
