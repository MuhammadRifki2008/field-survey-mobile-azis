import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final String token;

  const EditProfilePage({super.key, required this.token});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  // API
  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static const String profileUrl = '$baseUrl/profile';

  static const String updateUrl = '$baseUrl/profile/update';

  static const String imageUrl = 'https://sijala.biz.id/api/image';

  // ============================================================
  // CONTROLLER

  final TextEditingController nameController = TextEditingController();

  final TextEditingController usernameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController birthPlaceController = TextEditingController();

  final TextEditingController birthDateController = TextEditingController();

  // STATE

  String gender = '';

  String photo = '';

  Uint8List? selectedImage;

  bool isLoading = true;

  bool isSaving = false;

  final ImagePicker picker = ImagePicker();

  // INIT

  @override
  void initState() {
    super.initState();

    getProfile();
  }

  // DISPOSE

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();

    super.dispose();
  }

  // TOKEN

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final savedToken = prefs.getString('token');

    if (savedToken != null && savedToken.isNotEmpty) {
      return savedToken;
    }

    return widget.token;
  }

  // AMBIL NILAI DARI MAP

  String getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString();
      }
    }

    return '';
  }

  // FORMAT TANGGAL

  String formatBirthDate(String value) {
    if (value.isEmpty || value == 'null') {
      return '';
    }

    if (value.length >= 10) {
      final firstTen = value.substring(0, 10);

      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(firstTen)) {
        return firstTen;
      }
    }

    return value;
  }

  // NORMALISASI GENDER

  String normalizeGender(String value) {
    final genderValue = value.trim().toUpperCase();

    if (genderValue == 'L' ||
        genderValue == 'LAKI-LAKI' ||
        genderValue == 'LAKI LAKI' ||
        genderValue == 'MALE' ||
        genderValue == 'PRIA') {
      return 'L';
    }

    if (genderValue == 'P' ||
        genderValue == 'PEREMPUAN' ||
        genderValue == 'FEMALE' ||
        genderValue == 'WANITA') {
      return 'P';
    }

    return '';
  }

  // GET PROFILE

  Future<void> getProfile() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final token = await getToken();

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      debugPrint('======================================');
      debugPrint('EDIT PROFILE - GET PROFILE');
      debugPrint('======================================');
      debugPrint('TOKEN ADA: ${token.isNotEmpty}');

      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('STATUS PROFILE: ${response.statusCode}');
      debugPrint('BODY PROFILE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data profile. Status: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Format response API tidak valid.');
      }

      final responseData = Map<String, dynamic>.from(decoded);

      dynamic rawData = responseData['data'];

      Map<String, dynamic> profile = {};

      if (rawData is Map) {
        profile = Map<String, dynamic>.from(rawData);
      }

      if (profile['user'] is Map) {
        profile = Map<String, dynamic>.from(profile['user']);
      }

      if (profile['profile'] is Map) {
        profile = Map<String, dynamic>.from(profile['profile']);
      }

      debugPrint('======================================');
      debugPrint('DATA AKUN YANG DITERIMA');
      debugPrint(profile.toString());
      debugPrint('======================================');

      final name = getValue(profile, ['name', 'nama', 'full_name', 'fullname']);

      final username = getValue(profile, ['username', 'user_name']);

      final email = getValue(profile, ['email']);

      final phone = getValue(profile, [
        'phone',
        'no_hp',
        'nomor_hp',
        'phone_number',
        'telephone',
      ]);

      final genderValue = getValue(profile, ['gender', 'jenis_kelamin']);

      final birthPlace = getValue(profile, [
        'birth_place',
        'tempat_lahir',
        'birthPlace',
      ]);

      final birthDate = getValue(profile, [
        'birth_date',
        'tanggal_lahir',
        'birthDate',
        'date_of_birth',
      ]);

      final photoValue = getValue(profile, [
        'photo',
        'profile_photo',
        'profile_image',
        'image',
        'foto',
        'foto_profil',
      ]);

      if (!mounted) return;

      setState(() {
        nameController.text = name;
        usernameController.text = username;
        emailController.text = email;
        phoneController.text = phone;
        gender = normalizeGender(genderValue);
        birthPlaceController.text = birthPlace;
        birthDateController.text = formatBirthDate(birthDate);
        photo = photoValue;
        isLoading = false;
      });

      debugPrint('======================================');
      debugPrint('FORM BERHASIL DIISI');
      debugPrint('NAMA       : $name');
      debugPrint('USERNAME   : $username');
      debugPrint('EMAIL      : $email');
      debugPrint('PHONE      : $phone');
      debugPrint('GENDER     : ${normalizeGender(genderValue)}');
      debugPrint('TEMPAT LAHIR: $birthPlace');
      debugPrint('TANGGAL LAHIR: ${formatBirthDate(birthDate)}');
      debugPrint('PHOTO      : $photoValue');
      debugPrint('======================================');
    } catch (e) {
      debugPrint('GET PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    }
  }

  // PICK IMAGE

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      showMessage('Gagal memilih foto: $e', Colors.red);
    }
  }

  // DATE PICKER

  Future<void> pickBirthDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    if (birthDateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(birthDateController.text);
      } catch (_) {}
    }

    final DateTime now = DateTime.now();

    if (initialDate.isAfter(now)) {
      initialDate = DateTime(2000, 1, 1);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked == null) return;

    final String date =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    if (!mounted) return;

    setState(() {
      birthDateController.text = date;
    });
  }

  // UPDATE PROFILE

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      showMessage('Nama tidak boleh kosong.', Colors.red);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage('Email tidak boleh kosong.', Colors.red);
      return;
    }

    if (gender.isEmpty) {
      showMessage('Jenis kelamin belum dipilih.', Colors.red);
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final token = await getToken();

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      final request = http.MultipartRequest('POST', Uri.parse(updateUrl));

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = nameController.text.trim();
      request.fields['username'] = usernameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['phone'] = phoneController.text.trim();
      request.fields['gender'] = gender;
      request.fields['birth_place'] = birthPlaceController.text.trim();
      request.fields['birth_date'] = birthDateController.text.trim();

      if (selectedImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImage!,
            filename: 'profile.jpg',
          ),
        );
      }

      debugPrint('======================================');
      debugPrint('UPDATE PROFILE');
      debugPrint('NAME: ${nameController.text}');
      debugPrint('USERNAME: ${usernameController.text}');
      debugPrint('EMAIL: ${emailController.text}');
      debugPrint('PHONE: ${phoneController.text}');
      debugPrint('GENDER: $gender');
      debugPrint('BIRTH PLACE: ${birthPlaceController.text}');
      debugPrint('BIRTH DATE: ${birthDateController.text}');
      debugPrint('ADA FOTO BARU: ${selectedImage != null}');
      debugPrint('======================================');

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UPDATE STATUS: ${response.statusCode}');
      debugPrint('UPDATE BODY: ${response.body}');

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        showMessage(
          data is Map
              ? data['message']?.toString() ?? 'Profile berhasil diperbarui.'
              : 'Profile berhasil diperbarui.',
          Colors.green,
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        String message = 'Gagal memperbarui profile.';

        if (data is Map) {
          if (data['message'] != null) {
            message = data['message'].toString();
          }

          if (data['errors'] != null) {
            message = '$message\n${data['errors']}';
          }
        }

        if (!mounted) return;

        showMessage(message, Colors.red);
      }
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');

      if (!mounted) return;

      showMessage('Terjadi kesalahan: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // GET OLD PHOTO
  // ============================================================

  Future<Uint8List?> getOldPhoto() async {
    if (photo.isEmpty || photo == 'null') {
      return null;
    }

    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$imageUrl/$photo'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
      );

      debugPrint('OLD PHOTO STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      debugPrint('OLD PHOTO ERROR: $e');

      return null;
    }
  }

  // ============================================================
  // PHOTO WIDGET
  // ============================================================

  Widget photoWidget() {
    if (selectedImage != null) {
      return ClipOval(
        child: Image.memory(
          selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (photo.isEmpty || photo == 'null') {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Color(0xFFE8F0FF),
        child: Icon(Icons.person, size: 60, color: Color(0xFF1E4BAF)),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: getOldPhoto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFFE8F0FF),
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1E4BAF),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          );
        }

        return const CircleAvatar(
          radius: 60,
          backgroundColor: Color(0xFFE8F0FF),
          child: Icon(Icons.person, size: 60, color: Color(0xFF1E4BAF)),
        );
      },
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1E4BAF)),
          filled: true,
          fillColor: enabled
              ? const Color(0xFFF8FAFC)
              : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E4BAF), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Widget genderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: gender.isEmpty ? null : gender,
        decoration: InputDecoration(
          labelText: 'Jenis Kelamin',
          prefixIcon: const Icon(Icons.wc_outlined, color: Color(0xFF1E4BAF)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E4BAF), width: 1.5),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
          DropdownMenuItem(value: 'P', child: Text('Perempuan')),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            gender = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 54, 139),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E4BAF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              child: Column(
                children: [
                  // ==================================================
                  // FOTO PROFILE
                  // ==================================================
                  Column(
                    children: [
                      photoWidget(),

                      const SizedBox(height: 10),

                      TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF1E4BAF),
                        ),
                        label: const Text(
                          'Ganti Foto',
                          style: TextStyle(
                            color: Color(0xFF1E4BAF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // DATA DIRI
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Color(0xFF1E4BAF),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Data Diri',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        inputField(
                          label: 'Nama',
                          controller: nameController,
                          icon: Icons.person_outline,
                        ),

                        inputField(
                          label: 'Username',
                          controller: usernameController,
                          icon: Icons.alternate_email,
                          enabled: false,
                        ),

                        inputField(
                          label: 'Email',
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        inputField(
                          label: 'Nomor HP',
                          controller: phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        genderDropdown(),

                        inputField(
                          label: 'Tempat Lahir',
                          controller: birthPlaceController,
                          icon: Icons.location_on_outlined,
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: TextField(
                            controller: birthDateController,
                            readOnly: true,
                            onTap: pickBirthDate,
                            decoration: InputDecoration(
                              labelText: 'Tanggal Lahir',
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF1E4BAF),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E4BAF),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // SIMPAN
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : updateProfile,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
