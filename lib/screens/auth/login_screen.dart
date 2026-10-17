import 'dart:convert';

import 'package:field_survey/screens/auth/register.dart';
import 'package:field_survey/screens/dashboard/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // CONTROLLER
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // STATE

  bool isLoading = false;
  bool obscurePassword = true;

  String? emailError;
  String? passwordError;

  // WARNA

  static const Color primaryColor = Color(0xFF1E4BAF);
  static const Color secondaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // DISPOSE

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // SHOW MESSAGE

  void showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // LOGIN

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email dan password harus diisi.');
      return;
    }

    setState(() {
      emailError = email.isEmpty ? 'Email wajib diisi.' : null;
      passwordError = password.isEmpty ? 'Password wajib diisi.' : null;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // REQUEST LOGIN

      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      debugPrint('================================');
      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN RESPONSE: ${response.body}');
      debugPrint('================================');

      // Decode response
      final dynamic data = jsonDecode(response.body);

      // LOGIN BERHASIL

      if (response.statusCode == 200 && data is Map && data['status'] == true) {
        final token = data['data']?['token'];

        if (token == null || token.toString().isEmpty) {
          throw Exception('Token tidak ditemukan dari server.');
        }

        // SIMPAN TOKEN

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token.toString());

        // Opsional: simpan data user
        if (data['data']?['user'] != null) {
          await prefs.setString('user', jsonEncode(data['data']['user']));
        }

        if (!mounted) return;

        // ======================================================
        // MASUK KE HOME
        // ======================================================

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(token: token.toString()),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // LOGIN GAGAL
      // ========================================================

      String message = 'Email atau password salah.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      showMessage(message);
    }
    // ==========================================================
    // ERROR
    // ==========================================================
    catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
    // ==========================================================
    // STOP LOADING
    // ==========================================================
    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // BACKGROUND BIRU BAGIAN ATAS
            // ==================================================
            Container(
              height: MediaQuery.of(context).size.height * 0.34,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
            ),

            // content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
              child: Column(
                children: [
                  // logo
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // title
                  const Text(
                    'Field Survey',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Masuk untuk melanjutkan',
                    style: TextStyle(fontSize: 15, color: Color(0xFFDCE8FF)),
                  ),

                  const SizedBox(height: 45),

                  // login card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE FORM
                        const Text(
                          'Selamat Datang ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Silakan masukkan akun kamu untuk melanjutkan.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // email
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
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
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'Masukkan email kamu',
                            errorText: emailError,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
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
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // password
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: passwordController,
                          onChanged: (value) {
                            if (passwordError != null) {
                              setState(() {
                                passwordError = null;
                              });
                            }
                          },
                          obscureText: obscurePassword,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!isLoading) {
                              login();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            errorText: passwordError,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                            ),
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
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
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // button login
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF93B4F5),
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
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),

                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
