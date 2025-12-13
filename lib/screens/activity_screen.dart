import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  // Theme colors matching the existing Dentix app
  static const Color primaryBeige = Color(0xFFF8F0E3);
  static const Color secondaryBeige = Color(0xFFF1E6D3);
  static const Color primaryBlue = Color(0xFF2E6EB5);
  static const Color lightBlue = Color(0xFF4A8BC8);
  static const Color deepBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color cardWhite = Color(0xFFFFFBF7);
  static const Color softGreen = Color(0xFF6AB04C);
  static const Color warmOrange = Color(0xFFE17055);

  int _currentTab = 2; // Activity tab is selected
  int _selectedTabIndex = 0; // 0 = Upcoming, 1 = Previous
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Sample appointment data
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'doctorName': 'Dr. Hazem EL Beltagy',
      'specialty': 'Implantologist',
      'clinicName': 'Cairo Dental Center',
      'location': 'New Cairo',
      'date': 'Dec 15, 2024',
      'time': '10:00 AM',
      'status': 'Upcoming',
    },
    {
      'doctorName': 'Dr. Sophia Martinez',
      'specialty': 'Cosmetic Dentistry',
      'clinicName': 'Smile Studio',
      'location': 'Nasr City',
      'date': 'Dec 18, 2024',
      'time': '2:00 PM',
      'status': 'Upcoming',
    },
  ];

  final List<Map<String, dynamic>> _previousAppointments = [
    {
      'doctorName': 'Dr. Michael Davidson',
      'specialty': 'Dermatology',
      'clinicName': 'Heliopolis Medical',
      'location': 'Heliopolis',
      'date': 'Nov 28, 2024',
      'time': '11:00 AM',
      'status': 'Completed',
    },
    {
      'doctorName': 'Dr. Rania El Sherif',
      'specialty': 'Orthodontist',
      'clinicName': 'Orthodontic Care',
      'location': '6th of October',
      'date': 'Nov 15, 2024',
      'time': '3:30 PM',
      'status': 'Completed',
    },
    {
      'doctorName': 'Dr. Ahmed Nabil',
      'specialty': 'Periodontist',
      'clinicName': 'Gum Health Clinic',
      'location': 'Sheikh Zayed',
      'date': 'Oct 22, 2024',
      'time': '9:00 AM',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildAppBar(),
            _buildTabSection(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingTab(),
                    _buildPreviousTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardWhite, cardWhite.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Activity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: deepBrown,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your appointments history',
              style: TextStyle(
                color: lightBrown,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: lightBrown,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTabIndex = index;
          });
        },
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Previous'),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _upcomingAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _upcomingAppointments[index];
        return _buildAppointmentCard(appointment, isUpcoming: true);
      },
    );
  }

  Widget _buildPreviousTab() {
    if (_previousAppointments.isEmpty) {
      return _buildEmptyState(isPrevious: true);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _previousAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _previousAppointments[index];
        return _buildAppointmentCard(appointment, isUpcoming: false);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['doctorName'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: deepBrown,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment['specialty'],
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUpcoming ? softGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUpcoming ? softGreen.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  appointment['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isUpcoming ? softGreen : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                size: 16,
                color: lightBrown,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${appointment['clinicName']} • ${appointment['location']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: lightBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: lightBrown,
              ),
              const SizedBox(width: 8),
              Text(
                '${appointment['date']} at ${appointment['time']}',
                style: TextStyle(
                  fontSize: 14,
                  color: lightBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isUpcoming) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showRescheduleDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: primaryBlue.withOpacity(0.3), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showCancelDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade600,
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade200, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showDetailsDialog(appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryBlue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showReviewDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warmOrange.withOpacity(0.1),
                      foregroundColor: warmOrange,
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: warmOrange.withOpacity(0.3), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Add Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isPrevious = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPrevious ? Icons.history_rounded : Icons.calendar_today_rounded,
                size: 64,
                color: primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No appointments yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: deepBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPrevious 
                ? 'Your completed appointments will appear here'
                : 'Book your first appointment to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: lightBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isPrevious) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Switch to Home tab (index 0) in the parent dashboard
                  if (context.findAncestorStateOfType<State>() != null) {
                    // This will be handled by the parent PatientDashboard
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: primaryBlue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Book a Doctor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.schedule_rounded, color: primaryBlue, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Reschedule Appointment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: deepBrown),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature will be available soon. Please contact the clinic directly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: lightBrown, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              child: Icon(Icons.cancel_rounded, color: Colors.red.shade600, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel Appointment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: deepBrown),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to cancel this appointment?',
              textAlign: TextAlign.center,
              style: TextStyle(color: lightBrown, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Keep', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: deepBrown),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Doctor', appointment['doctorName']),
            _buildDetailRow('Specialty', appointment['specialty']),
            _buildDetailRow('Clinic', appointment['clinicName']),
            _buildDetailRow('Location', appointment['location']),
            _buildDetailRow('Date & Time', '${appointment['date']} at ${appointment['time']}'),
            _buildDetailRow('Status', appointment['status']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightBrown),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: deepBrown),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warmOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_rounded, color: warmOrange, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Review',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: deepBrown),
            ),
            const SizedBox(height: 12),
            Text(
              'Review feature coming soon! Help other patients by sharing your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: lightBrown, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: warmOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }


}