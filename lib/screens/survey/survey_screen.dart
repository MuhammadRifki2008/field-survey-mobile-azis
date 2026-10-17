import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'survey_detail_page.dart';
import 'survey_form_page.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // ============================================================
  // API
  // ============================================================

  static const String apiUrl = 'https://sijala.biz.id/api/v1/surveys';

  // ============================================================
  // WARNA
  // ============================================================

  static const Color primaryColor = Color(0xFF1E4BAF);

  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> surveys = [];

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  List<Map<String, dynamic>> get filteredSurveys {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return surveys;

    return surveys.where((survey) {
      final title = survey['title']?.toString().toLowerCase() ?? '';
      final category = survey['category_name']?.toString().toLowerCase() ?? '';

      return title.contains(query) || category.contains(query);
    }).toList();
  }

  bool isLoading = true;

  String? errorMessage;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    fetchSurveys();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // AMBIL DATA SURVEY
  // ============================================================

  Future<void> fetchSurveys() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================================');
      debugPrint('GET SURVEYS');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      debugPrint('================================');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        throw Exception('Sesi login telah berakhir.');
      }

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        List<dynamic> rawData = [];

        if (data is Map && data['status'] == true && data['data'] is List) {
          rawData = data['data'];
        } else if (data is List) {
          rawData = data;
        }

        if (!mounted) return;

        setState(() {
          surveys = rawData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          isLoading = false;
        });

        debugPrint('TOTAL DATA SURVEY: ${surveys.length}');

        return;
      }

      throw Exception(
        'Gagal mengambil data survey. Kode: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('ERROR GET SURVEY: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // TAMBAH SURVEY
  // ============================================================

  Future<void> openAddSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SurveyFormPage()),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // ============================================================
  // BUKA DETAIL SURVEY
  // ============================================================

  Future<void> openDetail(int surveyId) async {
    if (surveyId <= 0) {
      showMessage('ID survey tidak valid.', Colors.red);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyDetailPage(surveyId: surveyId),
      ),
    );

    // Refresh setelah kembali dari detail
    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(dateString.replaceFirst(' ', 'T'));

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // ============================================================
  // PESAN
  // ============================================================

  void showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ========================================================
      // APPBAR
      // ========================================================
      appBar: AppBar(
        title: const Text('Daftar Survey'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchSurveys,
        child: buildBody(),
      ),

      // ========================================================
      // BUTTON TAMBAH
      // ========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddSurvey,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Survey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD BODY
  // ============================================================

  Widget buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat data survey...',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null && surveys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 70,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Gagal Memuat Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: fetchSurveys,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // DATA KOSONG
    // ==========================================================

    // ==========================================================
    // LIST SURVEY
    // ==========================================================

    final filtered = filteredSurveys;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari judul atau kategori survey...',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          );
        }

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 12),
                Text(
                  'Survey tidak ditemukan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Coba gunakan kata kunci lain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        final survey = filtered[index - 1];

        // ======================================================
        // DATA API
        // ======================================================

        final int id = int.tryParse(survey['id']?.toString() ?? '') ?? 0;

        final String title = survey['title']?.toString() ?? 'Tanpa Judul';

        final String description = survey['description']?.toString() ?? '';

        final String categoryName =
            survey['category_name']?.toString() ?? 'Tanpa Kategori';

        final String latitude = survey['latitude']?.toString() ?? '';

        final String longitude = survey['longitude']?.toString() ?? '';

        final String date = formatDate(survey['created_at']?.toString());

        // ======================================================
        // CARD
        // ======================================================

        return Card(
          elevation: 0,

          margin: const EdgeInsets.only(bottom: 14),

          color: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),

          child: InkWell(
            borderRadius: BorderRadius.circular(16),

            onTap: () {
              openDetail(id);
            },

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ============================================
                  // HEADER CARD
                  // ============================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ICON
                      Container(
                        width: 50,
                        height: 50,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.assignment_outlined,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // INFORMASI
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              title,

                              maxLines: 2,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Text(
                                categoryName,

                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ============================================
                  // DESKRIPSI
                  // ============================================
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 14),

                    Text(
                      description,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  const Divider(color: Color(0xFFE2E8F0)),

                  const SizedBox(height: 8),

                  // ============================================
                  // LOKASI
                  // ============================================
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: primaryColor,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          latitude.isNotEmpty && longitude.isNotEmpty
                              ? '$latitude, $longitude'
                              : 'Lokasi tidak tersedia',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ============================================
                  // TANGGAL
                  // ============================================
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        date,

                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
