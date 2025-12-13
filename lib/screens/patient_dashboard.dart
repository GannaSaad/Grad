import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'simple_profile_screen.dart';
import 'activity_screen.dart';


class PatientDashboard extends StatefulWidget {
  final int initialTab;

  const PatientDashboard({super.key, this.initialTab = 0});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced color palette
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

  // ✅ NEW: dark beige for Dentix Assistant logo background
  static const Color darkBeige = Color(0xFFE0C28A);

  // Sample data
  final bool hasUpcomingAppointment = true;
  final String nextAppointmentText = "Tomorrow at 3:30 PM";
  final int allergiesCount = 2;
  final String insuranceStatus = "Active";
  final bool hasHistoryUpdate = true;
  final double dentixBalance = 150.75;
  final List<String> alerts = ["Treatment plan added", "Medical history updated"];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      body: _buildBodyForTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBodyForTab() {
    switch (_currentTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildDentixAssistant();
      case 2:
        return _buildActivity();
      case 3:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryBeige, secondaryBeige],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingHeader(),
                  const SizedBox(height: 28),
                  _buildPrimaryActionSection(),
                  const SizedBox(height: 28),
                  _buildQuickHealthSnapshot(),
                  const SizedBox(height: 28),
                  _buildRecommendedForYou(),
                  const SizedBox(height: 28),
                  if (hasUpcomingAppointment) ...[
                    _buildUpcomingAppointment(),
                    const SizedBox(height: 28),
                  ],
                  _buildMedicalRecordsAccess(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    Color greetingColor;

    if (hour < 12) {
      greeting = "Good morning";
      greetingIcon = Icons.wb_sunny;
      greetingColor = warmOrange;
    } else if (hour < 17) {
      greeting = "Good afternoon";
      greetingIcon = Icons.wb_sunny_outlined;
      greetingColor = accentGold;
    } else {
      greeting = "Good evening";
      greetingIcon = Icons.nights_stay;
      greetingColor = primaryBlue;
    }

    return Container(
      width: double.infinity,
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
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greetingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  greetingIcon,
                  color: greetingColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '$greeting 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: deepBrown,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasUpcomingAppointment
                  ? primaryBlue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUpcomingAppointment
                    ? primaryBlue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasUpcomingAppointment
                      ? Icons.schedule
                      : Icons.event_available,
                  color: hasUpcomingAppointment
                      ? primaryBlue
                      : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasUpcomingAppointment
                        ? 'Next appointment: $nextAppointmentText'
                        : 'No upcoming appointments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasUpcomingAppointment
                          ? primaryBlue
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionSection() {
    return Column(
      children: [
        _buildActionCard(
          title: 'Book a Doctor',
          subtitle: 'Find and book a specialist',
          icon: Icons.medical_services_rounded,
          gradient: const LinearGradient(
            colors: [primaryBlue, lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildDentixAssistantCard(),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'My Appointments',
          subtitle: 'View, reschedule, or cancel visits',
          icon: Icons.calendar_month_rounded,
          gradient: const LinearGradient(
            colors: [warmOrange, Color(0xFFFF6B35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to appointments
          },
        ),
      ],
    );
  }

  // ✅ UPDATED #1: Dentix Assistant card beige logo background
  Widget _buildDentixAssistantCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _currentTab = 1);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardWhite, cardWhite.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkBeige, Color(0xFFF1D199)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: darkBeige.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/shagy.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dentix Assistant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: deepBrown,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Describe symptoms and get instant guidance',
                      style: TextStyle(
                        fontSize: 15,
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
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardWhite, cardWhite.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: deepBrown,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
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
    );
  }

  Widget _buildQuickHealthSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Health Snapshot',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: deepBrown,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildHealthCard(
                title: 'Allergies',
                value: '$allergiesCount',
                icon: Icons.warning_amber_rounded,
                color: warmOrange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHealthCard(
                title: 'Insurance',
                value: insuranceStatus,
                icon: Icons.shield_rounded,
                color: softGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHealthCard(
                title: 'History',
                value: hasHistoryUpdate ? 'Updated' : 'Current',
                icon: Icons.history_rounded,
                color: hasHistoryUpdate ? primaryBlue : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: lightBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: deepBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED #2: Fix overflow by increasing height + fixed button height
  Widget _buildRecommendedForYou() {
    final doctors = [
      {
        'name': 'Dr. Sarah Ahmed',
        'specialty': 'Orthodontist',
        'image': 'assets/images/doctor2.jpg',
        'rating': '4.9',
        'reviews': '127',
      },
      {
        'name': 'Dr. Michael Chen',
        'specialty': 'Implantologist',
        'image': 'assets/images/doctor3.png',
        'rating': '4.8',
        'reviews': '89',
      },
      {
        'name': 'Dr. Laila Hassan',
        'specialty': 'General Dentist',
        'image': 'assets/images/doctor6.jpg',
        'rating': '4.7',
        'reviews': '156',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended For You',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: deepBrown,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 270, // ✅ was 240
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(
                  right: index < doctors.length - 1 ? 16 : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => HapticFeedback.lightImpact(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF1D199),
                            const Color(0xFFF1D199).withOpacity(0.8),
                          ],
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
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.asset(
                                doctor['image']!,
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            doctor['name']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doctor['specialty']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: lightBrown,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: accentGold,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor['rating']} (${doctor['reviews']})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lightBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doctor['available']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: deepBrown,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 42, // ✅ fixed height prevents overflow
                            child: ElevatedButton(
                              onPressed: () => HapticFeedback.lightImpact(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: primaryBlue.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.1),
            lightBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryBlue.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Upcoming Appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.asset(
                    'assets/images/doctor2.jpg',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Sarah Ahmed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: deepBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Orthodontist',
                      style: TextStyle(
                        fontSize: 15,
                        color: lightBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'New Cairo Clinic • $nextAppointmentText',
                      style: TextStyle(
                        fontSize: 13,
                        color: lightBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => HapticFeedback.lightImpact(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => HapticFeedback.lightImpact(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade400, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red.shade400,
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
  }

  // ✅ UPDATED #3: Removed Lab Results / Prescriptions / X-Rays cards
  Widget _buildMedicalRecordsAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Records',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: deepBrown,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_information_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Access Your Records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: deepBrown,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'View medical history, prescriptions, and test results',
                          style: TextStyle(
                            fontSize: 14,
                            color: lightBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ✅ Removed the 3 small cards row here

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Navigate to full medical records
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryBlue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'View All Records',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // still here if you use it elsewhere; safe to keep
  Widget _buildRecordCard(String title, String count, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: deepBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDentixAssistant() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryBeige, secondaryBeige],
        ),
      ),
      child: const Center(
        child: Text(
          'Dentix Assistant\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: deepBrown,
          ),
        ),
      ),
    );
  }

  Widget _buildActivity() {
    return const ActivityScreen();
  }

  Widget _buildProfile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryBeige, secondaryBeige],
        ),
      ),
      child: const Center(
        child: Text(
          'Profile\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: deepBrown,
          ),
        ),
      ),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimpleProfileScreen()),
            );
          } else {
            setState(() => _currentTab = index);
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
