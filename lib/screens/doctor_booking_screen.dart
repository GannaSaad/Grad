import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/doctor.dart';

class TimeSlot {
  final String time;
  final bool isBooked;
  final bool isAvailable;

  TimeSlot({
    required this.time,
    this.isBooked = false,
    this.isAvailable = true,
  });
}

class DoctorBookingPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorBookingPage({super.key, required this.doctor});

  @override
  State<DoctorBookingPage> createState() => _DoctorBookingPageState();
}

class _DoctorBookingPageState extends State<DoctorBookingPage> {
  // Theme colors matching the app
  static const Color primaryBeige = Color(0xFFF8F0E3);
  static const Color secondaryBeige = Color(0xFFF1E6D3);
  static const Color primaryBlue = Color(0xFF2E6EB5);
  static const Color lightBlue = Color(0xFF4A8BC8);
  static const Color deepBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color cardWhite = Color(0xFFFFFBF7);
  static const Color softGreen = Color(0xFF6AB04C);
  static const Color warmOrange = Color(0xFFE17055);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // Sample booked dates and times
  final Map<DateTime, List<String>> _bookedSlots = {
    DateTime(2024, 12, 15): ['09:00 AM', '02:00 PM', '04:00 PM'],
    DateTime(2024, 12, 16): ['10:00 AM', '11:00 AM', '03:00 PM'],
    DateTime(2024, 12, 18): ['09:00 AM', '01:00 PM'],
    DateTime(2024, 12, 20): ['02:00 PM', '03:00 PM', '04:00 PM'],
  };

  // Available time slots for each day
  final List<String> _allTimeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<TimeSlot> _getTimeSlotsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final bookedTimes = _bookedSlots[normalizedDay] ?? [];

    return _allTimeSlots.map((time) {
      final isBooked = bookedTimes.contains(time);
      final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      return TimeSlot(
        time: time,
        isBooked: isBooked,
        isAvailable: !isWeekend && !isPast && !isBooked,
      );
    }).toList();
  }

  bool _isDayFullyBooked(DateTime day) {
    final slots = _getTimeSlotsForDay(day);
    return slots.every((slot) => !slot.isAvailable);
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorInfo(),
                      const SizedBox(height: 24),
                      _buildCalendarSection(),
                      const SizedBox(height: 24),
                      if (_selectedDay != null) _buildTimeSlots(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTimeSlot != null ? _buildBookButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
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
            "Book Appointment",
            style: TextStyle(
              color: deepBrown,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo() {
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.doctor.imageAsset,
                height: 80,
                width: 80,
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
                  widget.doctor.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: deepBrown,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.doctor.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: lightBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.doctor.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.doctor.rating} (${widget.doctor.reviews})',
                      style: TextStyle(
                        fontSize: 13,
                        color: lightBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCalendarSection() {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: deepBrown,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TableCalendar<String>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: deepBrown,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: primaryBlue,
                size: 28,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: primaryBlue,
                size: 28,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: TextStyle(
                color: deepBrown,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: BoxDecoration(
                color: warmOrange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isFullyBooked = _isDayFullyBooked(day);
                final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

                if (isWeekend) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                if (isFullyBooked) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                return null;
              },
              markerBuilder: (context, day, events) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final hasBookedSlots = _bookedSlots.containsKey(normalizedDay);

                if (hasBookedSlots && !_isDayFullyBooked(day)) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: warmOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedTimeSlot = null; // Reset time selection
                });
                HapticFeedback.selectionClick();
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLegendItem(
                color: softGreen,
                label: 'Available',
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: warmOrange,
                label: 'Partially booked',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(
                color: Colors.red.shade400,
                label: 'Fully booked',
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: Colors.grey.shade400,
                label: 'Unavailable',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: lightBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    final timeSlots = _getTimeSlotsForDay(_selectedDay!);
    final isWeekend = _selectedDay!.weekday == DateTime.saturday || _selectedDay!.weekday == DateTime.sunday;

    if (isWeekend) {
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
        child: Column(
          children: [
            Icon(
              Icons.weekend_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Weekend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Doctor is not available on weekends',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Available Times',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: deepBrown,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final slot = timeSlots[index];
              final isSelected = _selectedTimeSlot == slot.time;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: slot.isAvailable ? () {
                    setState(() {
                      _selectedTimeSlot = isSelected ? null : slot.time;
                    });
                    HapticFeedback.selectionClick();
                  } : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: slot.isBooked
                          ? Colors.red.shade100
                          : slot.isAvailable
                          ? isSelected
                          ? primaryBlue
                          : Colors.white
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: slot.isBooked
                            ? Colors.red.shade300
                            : slot.isAvailable
                            ? isSelected
                            ? primaryBlue
                            : Colors.grey.shade300
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: slot.isAvailable && !slot.isBooked ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        slot.time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: slot.isBooked
                              ? Colors.red.shade600
                              : slot.isAvailable
                              ? isSelected
                              ? Colors.white
                              : deepBrown
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showBookingConfirmation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    final formattedDate = '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}';

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
                  color: softGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: softGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirm Booking',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: deepBrown,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow('Doctor', widget.doctor.name),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Date', formattedDate),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Time', _selectedTimeSlot!),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Location', widget.doctor.location),
                  ],
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
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                        _confirmBooking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryBlue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirm',
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

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: lightBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: deepBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _confirmBooking() {
    final normalizedDay =
    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    setState(() {
      if (_bookedSlots.containsKey(normalizedDay)) {
        _bookedSlots[normalizedDay]!.add(_selectedTimeSlot!);
      } else {
        _bookedSlots[normalizedDay] = [_selectedTimeSlot!];
      }
      _selectedTimeSlot = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Appointment booked successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // ⬇️ REDIRECT TO HOME AFTER SHORT DELAY
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }
}