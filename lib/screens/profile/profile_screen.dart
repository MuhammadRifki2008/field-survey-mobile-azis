import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ========================================================
  // API
  // ========================================================

  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static const String profileEndpoint = '$baseUrl/profile';

  static const String imageEndpoint = 'https://sijala.biz.id/api/image';

  // ========================================================
  // STATE
  // ========================================================

  Map<String, dynamic>? profile;

  Future<Uint8List?>? profileImageFuture;

  bool isLoading = true;

  // ========================================================
  // INIT
  // ========================================================

  @override
  void initState() {
    super.initState();

    getProfile();
  }

  // ========================================================
  // GET PROFILE
  // ========================================================

  Future<void> getProfile() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? widget.token;

      debugPrint('================================');
      debugPrint('GET PROFILE');
      debugPrint('TOKEN ADA: ${token.isNotEmpty}');
      debugPrint('================================');

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================================');
      debugPrint('GET PROFILE RESPONSE');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('RESPONSE: ${response.body}');
      debugPrint('================================');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final profileData = Map<String, dynamic>.from(data['data'] ?? {});

        final photo = profileData['photo']?.toString() ?? '';

        debugPrint('================================');
        debugPrint('PROFILE PHOTO');
        debugPrint('PHOTO: $photo');
        debugPrint('================================');

        if (!mounted) return;

        setState(() {
          profile = profileData;

          if (photo.isNotEmpty && photo != 'null') {
            profileImageFuture = fetchProfileImage(photo);
          } else {
            profileImageFuture = null;
          }

          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data profile.');
      }
    } catch (e) {
      debugPrint('GET PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========================================================
  // GET PROFILE IMAGE
  // ========================================================

  Future<Uint8List?> fetchProfileImage(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? widget.token;

      final imageUrl = '$imageEndpoint/$fileName';

      debugPrint('================================');
      debugPrint('GET PROFILE IMAGE');
      debugPrint('IMAGE URL: $imageUrl');
      debugPrint('================================');

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
      );

      debugPrint('IMAGE STATUS: ${response.statusCode}');

      debugPrint(
        'IMAGE CONTENT TYPE: '
        '${response.headers['content-type']}',
      );

      debugPrint(
        'IMAGE SIZE: '
        '${response.bodyBytes.length}',
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        debugPrint('FOTO BERHASIL DIAMBIL');

        return response.bodyBytes;
      }

      debugPrint('FOTO TIDAK BERHASIL DIAMBIL');

      return null;
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');

      return null;
    }
  }

  // ========================================================
  // LOGOUT
  // ========================================================

  Future<void> logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? widget.token;

      if (token.isEmpty) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========================================================
  // REFRESH
  // ========================================================

  Future<void> handleRefresh() async {
    await getProfile();
  }

  // ========================================================
  // PROFILE HEADER
  // ========================================================

  Widget profileHeader() {
    if (profile == null) {
      return const Center(child: Text('Data profile tidak ditemukan.'));
    }

    final name = profile!['name']?.toString() ?? '-';

    final username = profile!['username']?.toString() ?? '-';

    final photo = profile!['photo']?.toString() ?? '';

    return Column(
      children: [
        // FOTO PROFILE
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFE8F0FF),
          child: photo.isNotEmpty && photo != 'null'
              ? FutureBuilder<Uint8List?>(
                  future: profileImageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipOval(
                        child: Image.memory(
                          snapshot.data!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    return const Icon(
                      Icons.person,
                      size: 55,
                      color: Color(0xFF1E4BAF),
                    );
                  },
                )
              : const Icon(Icons.person, size: 55, color: Color(0xFF1E4BAF)),
        ),

        const SizedBox(height: 16),

        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '@$username',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
  // ========================================================
  // INFO ITEM
  // ========================================================

  Widget infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E4BAF), size: 21),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // INFORMATION CARD
  // ========================================================

  Widget informationCard() {
    if (profile == null) {
      return const SizedBox();
    }

    String gender = profile!['gender']?.toString() ?? '-';

    if (gender == 'L') {
      gender = 'Laki-laki';
    } else if (gender == 'P') {
      gender = 'Perempuan';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF1E4BAF)),
              SizedBox(width: 8),
              Text(
                'Informasi Pribadi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 18),

          infoItem(
            icon: Icons.person_outline,
            title: 'Username',
            value: profile!['username']?.toString() ?? '-',
          ),

          infoItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: profile!['email']?.toString() ?? '-',
          ),

          infoItem(
            icon: Icons.phone_outlined,
            title: 'Nomor HP',
            value: profile!['phone']?.toString() ?? '-',
          ),

          infoItem(
            icon: Icons.wc_outlined,
            title: 'Jenis Kelamin',
            value: gender,
          ),

          infoItem(
            icon: Icons.location_on_outlined,
            title: 'Tempat Lahir',
            value: profile!['birth_place']?.toString() ?? '-',
          ),

          infoItem(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal Lahir',
            value: profile!['birth_date']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  // ========================================================
  // EDIT BUTTON
  // ========================================================

  Widget editButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return EditProfilePage(token: widget.token);
              },
            ),
          );

          if (result == true && mounted) {
            await getProfile();
          }
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text(
          'Edit Profil',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4BAF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // LOGOUT BUTTON
  // ========================================================

  Widget logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: logout,
        icon: const Icon(Icons.logout_outlined),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 54, 139),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: handleRefresh,
          color: const Color(0xFF1E4BAF),

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),

            child: Column(
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(color: Color(0xFF1E4BAF)),
                  )
                else ...[
                  profileHeader(),

                  const SizedBox(height: 18),

                  informationCard(),

                  const SizedBox(height: 20),

                  editButton(),

                  const SizedBox(height: 12),

                  logoutButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
