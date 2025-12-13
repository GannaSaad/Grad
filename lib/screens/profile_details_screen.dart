import 'package:flutter/material.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();

  // same theme as your HomePage/profile menu
  static const Color bg = Color(0xFFF5E2C0);
  static const Color card = Color(0xFFFDF4DD);
  static const Color accent = Color(0xFF2E6EB5);
  static const Color brown = Colors.brown;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: brown),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(color: brown, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: brown),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFEBD3A8),
                  child: const Icon(Icons.person, size: 44, color: brown),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _label("Full Name"),
            _field(fullNameController, "Enter your name"),
            const SizedBox(height: 14),

            _label("Phone Number"),
            _field(phoneController, "+20 ...", keyboard: TextInputType.phone),
            const SizedBox(height: 14),

            _label("Email"),
            _field(emailController, "example@email.com",
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 14),

            _label("Date Of Birth"),
            _field(
              dobController,
              "DD / MM / YYYY",
              readOnly: true,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 20),
                  firstDate: DateTime(1950),
                  lastDate: now,
                );
                if (picked != null) {
                  dobController.text =
                  "${picked.day.toString().padLeft(2, '0')}/"
                      "${picked.month.toString().padLeft(2, '0')}/"
                      "${picked.year}";
                }
              },
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated (demo)")),
                  );
                },
                child: const Text(
                  "Update Profile",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: brown,
        ),
      ),
    ),
  );

  Widget _field(
      TextEditingController c,
      String hint, {
        TextInputType? keyboard,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
