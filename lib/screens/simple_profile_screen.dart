import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_details_screen.dart';
import 'login_page.dart';
import 'patient_dashboard.dart';

class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});

  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> with TickerProviderStateMixin {
  int _currentTab = 3; // Profile tab is selected
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced color palette matching dashboard
  static const Color primaryBeige = Color(0xFFF8F0E3);
  static const Color secondaryBeige = Color(0xFFF1E6D3);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color primaryBlue = Color(0xFF2E6EB5);
  static const Color darkBlue = Color(0xFF1E4A73);
  static const Color lightBlue = Color(0xFF4A8BC8);
  static const Color softGreen = Color(0xFF6AB04C);
  static const Color warmOrange = Color(0xFFE17055);
  static const Color deepBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color cardWhite = Color(0xFFFFFBF7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBeige,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBeige, secondaryBeige],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 32),
                        _buildProfileOptions(),
                        const SizedBox(height: 32),
                        _buildLogoutSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: deepBrown,
                  size: 20,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            "My Profile",
            style: TextStyle(
              color: deepBrown,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardWhite, cardWhite.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 25,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withOpacity(0.1),
                      lightBlue.withOpacity(0.05)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: primaryBlue,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: softGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: softGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'John Doe',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: deepBrown,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'john.doe@email.com',
              style: TextStyle(
                fontSize: 15,
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: lightBrown,
              ),
              const SizedBox(width: 6),
              Text(
                'Member since 2024',
                style: TextStyle(
                  fontSize: 14,
                  color: lightBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Personal Details',
        'subtitle': 'Update your information',
        'color': primaryBlue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
          );
        },
      },
      {
        'icon': Icons.favorite_outline_rounded,
        'title': 'Favorite Doctors',
        'subtitle': 'View your saved doctors',
        'color': Colors.red.shade400,
        'onTap': () {
          // Navigate to favorites
        },
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Appointment History',
        'subtitle': 'View past appointments',
        'color': warmOrange,
        'onTap': () {
          // Navigate to appointment history
        },
      },
      {
        'icon': Icons.medical_information_outlined,
        'title': 'Medical Records',
        'subtitle': 'Access your health data',
        'color': softGreen,
        'onTap': () {
          // Navigate to medical records
        },
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'subtitle': 'App preferences and privacy',
        'color': Colors.grey.shade600,
        'onTap': () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Settings screen coming soon!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact us',
        'color': accentGold,
        'onTap': () {
          // Navigate to help
        },
      },
    ];

    return Column(
      children: options.map((option) =>
          _buildProfileOption(
            context,
            icon: option['icon'] as IconData,
            title: option['title'] as String,
            subtitle: option['subtitle'] as String,
            color: option['color'] as Color,
            onTap: option['onTap'] as VoidCallback,
          )).toList(),
    );
  }

  Widget _buildProfileOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardWhite, cardWhite.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: deepBrown,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: lightBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardWhite, cardWhite.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showLogoutDialog(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade50,
                  Colors.red.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: deepBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context); // Close dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.red.shade600.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryBeige, secondaryBeige],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightBrown,
        currentIndex: _currentTab,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onTap: (index) {
          HapticFeedback.selectionClick();
          if (index == 3) {
            // Already on profile screen
            return;
          } else {
            // Navigate back to dashboard with selected tab
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDashboard(initialTab: index),
              ),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _currentTab == 1 ? primaryBlue : lightBrown,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/shagy.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            label: 'Dr. Shagy',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}