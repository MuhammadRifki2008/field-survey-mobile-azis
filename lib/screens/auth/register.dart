import 'dart:convert';

import 'package:field_survey/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedGender;

  bool isLoading = false;

  String? namaError;
  String? jkError;
  String? emailError;
  String? hpError;

  static const Color primaryColor = Color(0xFF1E4BAF);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textColor = Color(0xFF0F172A);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color softBlueColor = Color(0xFFEFF6FF);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFDC2626) : primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    setState(() {
      namaError = name.isEmpty ? 'Nama wajib diisi.' : null;
      jkError = selectedGender == null ? 'Jenis kelamin wajib dipilih' : null;
      emailError = email.isEmpty ? 'Email wajib diisi.' : null;
      hpError = phone.isEmpty ? 'Nomer telepon harus diisi' : null;
    });

    if (namaError != null ||
        jkError != null ||
        emailError != null ||
        hpError != null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'gender': selectedGender,
          'email': email,
          'phone': phone,
        }),
      );

      debugPrint('================================');
      debugPrint('REGISTER');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      debugPrint('================================');

      if (!mounted) return;

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (e) {
        data = {};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage(
          data is Map
              ? data['message']?.toString() ?? 'Registrasi berhasil.'
              : 'Registrasi berhasil.',
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        return;
      }

      String message = 'Registrasi gagal. Silakan coba lagi.';

      if (data is Map) {
        message = data['message']?.toString() ?? message;

        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }
      }

      showMessage(message, isError: true);
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');

      if (!mounted) return;

      showMessage(
        'Terjadi kesalahan. Periksa koneksi internet kamu.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Buat Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: softBlueColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 45,
                    color: primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Daftar Akun',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Lengkapi data di bawah untuk membuat akun\nField Survey kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,
                      onChanged: (value) {
                        if (namaError != null) {
                          setState(() {
                            namaError = null;
                          });
                        }
                      },
                      textInputAction: TextInputAction.next,
                      decoration: inputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        icon: Icons.person_outline,
                        errorText: namaError,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Jenis Kelamin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      isExpanded: true,
                      decoration: inputDecoration(
                        hintText: 'Pilih jenis kelamin',
                        icon: Icons.wc_outlined,
                        errorText: jkError,
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'L',
                          child: Text('Laki-Laki'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'P',
                          child: Text('Perempuan'),
                        ),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                selectedGender = value;
                                jkError = null;
                              });
                            },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: emailController,
                      onChanged: (value) {
                        if (emailError != null) {
                          setState(() {
                            emailError = null;
                          });
                        }
                      },
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: inputDecoration(
                        hintText: 'Masukkan alamat email',
                        icon: Icons.email_outlined,
                        errorText: emailError,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Nomor Telepon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: phoneController,
                      onChanged: (value) {
                        if (hpError != null) {
                          setState(() {
                            hpError = null;
                          });
                        }
                      },
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isLoading) {
                          register();
                        }
                      },
                      decoration: inputDecoration(
                        hintText: 'Contoh: 081234567890',
                        icon: Icons.phone_outlined,
                        errorText: hpError,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93B4E8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1),
                            SizedBox(width: 10),
                            Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
