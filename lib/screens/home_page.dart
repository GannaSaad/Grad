// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'simple_profile_screen.dart';
import 'doctor_booking_screen.dart';
import '../models/doctor.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortOption { az, rating }

class _HomePageState extends State<HomePage> {
  // ---------------------------------------------------------------------------
  // THEME (MATCH PatientDashboard)
  // ---------------------------------------------------------------------------
  static const Color primaryBeige = Color(0xFFF8F0E3);
  static const Color secondaryBeige = Color(0xFFF1E6D3);
  static const Color primaryBlue = Color(0xFF2E6EB5);
  static const Color lightBlue = Color(0xFF4A8BC8);
  static const Color deepBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color cardWhite = Color(0xFFFFFBF7);

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  final List<Doctor> _allDoctors = [
    Doctor(
      name: 'Dr. Hazem EL Beltagy, Ph.D.',
      title: 'Implantologist',
      field: 'Implantology',
      location: 'New Cairo',
      imageAsset: 'assets/images/doctor2.jpg',
      patients: 116,
      years: 3,
      rating: 4.9,
      reviews: 96,
    ),
    Doctor(
      name: 'Dr. Michael Davidson, M.D.',
      title: 'Solar Dermatology',
      field: 'Dermatology',
      location: 'Heliopolis',
      imageAsset: 'assets/images/doctor.jpg',
      patients: 80,
      years: 5,
      rating: 4.7,
      reviews: 55,
    ),
    Doctor(
      name: 'Dr. Olivia Turner, M.D.',
      title: 'Dermato-Endocrinology',
      field: 'Endocrinology',
      location: 'New Cairo',
      imageAsset: 'assets/images/doctor3.png',
      patients: 95,
      years: 4,
      rating: 4.8,
      reviews: 72,
    ),
    Doctor(
      name: 'Dr. Sophia Martinez, Ph.D.',
      title: 'Cosmetic Bioengineering',
      field: 'Cosmetic Dentistry',
      location: 'Nasr City',
      imageAsset: 'assets/images/doctor.jpg',
      patients: 130,
      years: 6,
      rating: 4.9,
      reviews: 120,
    ),
    Doctor(
      name: 'Dr. Karim Saeed, M.D.',
      title: 'Pediatric Dentist',
      field: 'Pediatrics',
      location: 'Maadi',
      imageAsset: 'assets/images/doctor.jpg',
      patients: 60,
      years: 2,
      rating: 4.6,
      reviews: 40,
    ),
    Doctor(
      name: 'Dr. Rania El Sherif, D.D.S.',
      title: 'Orthodontist',
      field: 'Orthodontics',
      location: '6th of October',
      imageAsset: 'assets/images/doctor7.jpg',
      patients: 90,
      years: 4,
      rating: 4.8,
      reviews: 70,
    ),
    Doctor(
      name: 'Dr. Ahmed Nabil, M.D.',
      title: 'Periodontist',
      field: 'Periodontology',
      location: 'Sheikh Zayed',
      imageAsset: 'assets/images/doctor5.png',
      patients: 75,
      years: 3,
      rating: 4.7,
      reviews: 52,
    ),
    Doctor(
      name: 'Dr. Laila Hassan, M.Sc.',
      title: 'Family Dentist',
      field: 'General Dentistry',
      location: 'New Cairo',
      imageAsset: 'assets/images/doctor6.jpg',
      patients: 110,
      years: 5,
      rating: 4.8,
      reviews: 88,
    ),
  ];

  SortOption _sortOption = SortOption.az;
  String _selectedField = 'All';
  String _selectedLocation = 'All';
  bool _favoritesOnly = false;
  bool _nearMe = false;

  Position? _currentPosition;
  String _searchQuery = '';

  /// bottom-nav current tab:
  /// 0 = Home, 1 = Dr. Shagy, 2 = Activity, 3 = Profile (opens SimpleProfileScreen)
  int _currentTab = 0;

  // ---------------------------------------------------------------------------
  // LOCATION HANDLING
  // ---------------------------------------------------------------------------
  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationDialog(
        'Location is disabled',
        'Please enable location services in your device settings.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await _showLocationDialog(
        'Location permission denied',
        'Please enable location permission for Dentix in app settings.',
      );
      return false;
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    return true;
  }

  Future<void> _showLocationDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER + SORT
  // ---------------------------------------------------------------------------
  String _nameForSort(String name) {
    final lower = name.toLowerCase();
    if (lower.startsWith('dr. ')) return name.substring(4);
    return name;
  }

  List<Doctor> get _visibleDoctors {
    var docs = List<Doctor>.of(_allDoctors);

    if (_favoritesOnly) {
      docs = docs.where((d) => d.isFavorite).toList();
    }

    if (_selectedField != 'All') {
      docs = docs.where((d) => d.field == _selectedField).toList();
    }

    if (_nearMe) {
      docs = docs.where((d) => d.location == 'New Cairo').toList();
    } else if (_selectedLocation != 'All') {
      docs = docs.where((d) => d.location == _selectedLocation).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      docs = docs.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.field.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q);
      }).toList();
    }

    docs.sort((a, b) {
      switch (_sortOption) {
        case SortOption.az:
          return _nameForSort(a.name).compareTo(_nameForSort(b.name));
        case SortOption.rating:
          return b.rating.compareTo(a.rating);
      }
    });

    return docs;
  }

  List<String> get _fields {
    final set = <String>{'All'};
    for (final d in _allDoctors) {
      set.add(d.field);
    }
    return set.toList();
  }

  List<String> get _locations {
    final set = <String>{'All'};
    for (final d in _allDoctors) {
      set.add(d.location);
    }
    return set.toList();
  }

  // ---------------------------------------------------------------------------
  // UI ROOT
  // ---------------------------------------------------------------------------
  String _titleForTab() {
    switch (_currentTab) {
      case 2:
        return 'Activity';
      case 1:
        return 'Dr. Shagy';
      case 0:
      default:
        return 'Doctors';
    }
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTopHeaderCard(),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildBodyForTab()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP HEADER CARD
  // ---------------------------------------------------------------------------
  Widget _buildTopHeaderCard() {
    final title = _titleForTab();

    return Container(
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
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: deepBrown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: deepBrown,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: deepBrown,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (_currentTab == 0) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openSearchSheet,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: deepBrown.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.search_rounded, color: deepBrown, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openSortSheet,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: deepBrown.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.tune_rounded, color: deepBrown, size: 20),
              ),
            ),
          ] else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------
  Widget _buildBodyForTab() {
    switch (_currentTab) {
      case 2:
        return const Center(child: Text('Activity coming soon'));
      case 1:
        return const Center(child: Text('Dr. Shagy page coming soon'));
      case 0:
      default:
        return Column(
          children: [
            _buildFiltersSection(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _visibleDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = _visibleDoctors[index];
                  return _buildDoctorCard(doctor);
                },
              ),
            ),
          ],
        );
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER STRIP
  // ---------------------------------------------------------------------------
  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: deepBrown,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(
                  label: _sortOption == SortOption.az ? 'A–Z' : 'Rating',
                  icon: Icons.sort_by_alpha,
                  selected: true,
                  onTap: _openSortSheet,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  label: '❤',
                  selected: _favoritesOnly,
                  onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  label: 'Near me',
                  icon: Icons.location_on_outlined,
                  selected: _nearMe,
                  onTap: () async {
                    final ok = await _ensureLocationPermission();
                    if (!ok) {
                      _showSnack('Location permission is required to use Near me');
                      return;
                    }
                    setState(() {
                      _nearMe = !_nearMe;
                      _selectedLocation = 'All';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildChip(
                  label: _selectedField == 'All' ? 'Field' : _selectedField,
                  icon: Icons.medical_information_outlined,
                  selected: _selectedField != 'All',
                  onTap: _openFieldSheet,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  label: _selectedLocation == 'All' ? 'Location' : _selectedLocation,
                  icon: Icons.place_outlined,
                  selected: _selectedLocation != 'All',
                  onTap: _openLocationSheet,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    bool selected = false,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            if (icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DOCTOR CARD
  // ---------------------------------------------------------------------------
  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1D199),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              doctor.imageAsset,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.title,
                  style: TextStyle(fontSize: 13, color: deepBrown),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doctor.field} • ${doctor.location}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailsPage(doctor: doctor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white, // ✅ makes text white
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      child: const Text(
                        'Info',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white, // ✅ force white
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _roundIconButton(
                      icon: Icons.calendar_today_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorBookingPage(doctor: doctor),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _roundIconButton(
                      icon: Icons.rate_review,
                      onTap: () => _showDoctorInfo(doctor),
                    ),
                    const SizedBox(width: 6),
                    _roundIconButton(
                      icon: doctor.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: doctor.isFavorite ? Colors.redAccent : Colors.white,
                      iconColor: doctor.isFavorite ? Colors.white : primaryBlue,
                      onTap: () => setState(() => doctor.isFavorite = !doctor.isFavorite),
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

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = Colors.black54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH MODAL
  // ---------------------------------------------------------------------------
  void _openSearchSheet() {
    final controller = TextEditingController(text: _searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search doctors',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Name, field, or location',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (value) {
                  setState(() => _searchQuery = value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => _searchQuery = controller.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SORT + FILTER SHEETS
  // ---------------------------------------------------------------------------
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('A–Z'),
                onTap: () {
                  setState(() => _sortOption = SortOption.az);
                  Navigator.pop(context);
                },
                leading: Radio<SortOption>(
                  value: SortOption.az,
                  groupValue: _sortOption,
                  onChanged: (v) {
                    setState(() => _sortOption = v!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Rating (best → worst)'),
                onTap: () {
                  setState(() => _sortOption = SortOption.rating);
                  Navigator.pop(context);
                },
                leading: Radio<SortOption>(
                  value: SortOption.rating,
                  groupValue: _sortOption,
                  onChanged: (v) {
                    setState(() => _sortOption = v!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFieldSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _fields
                .map(
                  (f) => ListTile(
                title: Text(f),
                onTap: () {
                  setState(() => _selectedField = f);
                  Navigator.pop(context);
                },
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }

  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _locations
                .map(
                  (loc) => ListTile(
                title: Text(loc),
                onTap: () {
                  setState(() {
                    _nearMe = false;
                    _selectedLocation = loc;
                  });
                  Navigator.pop(context);
                },
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DOCTOR INFO + REVIEW (BOTTOM SHEET)
  // ---------------------------------------------------------------------------
  void _showDoctorInfo(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        var tempRating = 0;
        final commentController = TextEditingController();

        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.asset(
                            doctor.imageAsset,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                doctor.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: deepBrown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor.reviews == 0
                                    ? 'No reviews yet'
                                    : '⭐ ${doctor.rating.toStringAsFixed(1)} (${doctor.reviews} reviews)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Leave a quick review',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final filled = starIndex <= tempRating;
                        return IconButton(
                          onPressed: () => setModalState(() => tempRating = starIndex),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write a short comment (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (tempRating > 0) {
                            setState(() {
                              doctor.rating =
                                  (doctor.rating * doctor.reviews + tempRating) /
                                      (doctor.reviews + 1);
                              doctor.reviews += 1;
                            });
                          }
                          Navigator.pop(context);
                          _showSnack('Thanks for your review!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION (Profile -> SimpleProfileScreen)
  // ---------------------------------------------------------------------------
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
        onTap: (index) async {
          HapticFeedback.selectionClick();

          if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimpleProfileScreen()),
            );
            return;
          }

          setState(() => _currentTab = index);
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

// ============================================================================
// DOCTOR DETAILS PAGE
// ============================================================================
class DoctorDetailsPage extends StatelessWidget {
  const DoctorDetailsPage({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomePageState.primaryBeige,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_HomePageState.primaryBeige, _HomePageState.secondaryBeige],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _detailsTopHeader(context),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: AssetImage(doctor.imageAsset),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          doctor.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _HomePageState.deepBrown,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          '${doctor.field} • ${doctor.location}',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              doctor.reviews == 0
                                  ? 'No reviews yet'
                                  : '${doctor.rating.toStringAsFixed(1)} (${doctor.reviews} reviews)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DoctorStat(
                            icon: Icons.person_outline,
                            label: 'Patients',
                            value: '${doctor.patients}+',
                          ),
                          _DoctorStat(
                            icon: Icons.verified_outlined,
                            label: 'Years',
                            value: '${doctor.years}+',
                          ),
                          _DoctorStat(
                            icon: Icons.star_border,
                            label: 'Rating',
                            value: doctor.rating.toStringAsFixed(1),
                          ),
                          _DoctorStat(
                            icon: Icons.chat_bubble_outline,
                            label: 'Reviews',
                            value: '${doctor.reviews}+',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'About Me',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consultant of Smile design and implantologist. '
                            'Specialized in Adult Dentistry, Pediatric Dentistry, '
                            'Orthodontics, Cosmetic Dentistry, Implantology and '
                            'Oral Rehabilitation.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorBookingPage(doctor: doctor),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _HomePageState.primaryBlue,
                            foregroundColor: Colors.white, // ✅ text white
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Book Appointment',
                            style: TextStyle(
                              color: Colors.white, // ✅ force white
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
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
      ),
    );
  }

  Widget _detailsTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_HomePageState.cardWhite, _HomePageState.cardWhite.withOpacity(0.85)],
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
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _HomePageState.deepBrown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _HomePageState.deepBrown,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Doctor Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _HomePageState.deepBrown,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _DoctorStat extends StatelessWidget {
  const _DoctorStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _HomePageState.cardWhite,
          child: Icon(icon, color: _HomePageState.deepBrown),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
