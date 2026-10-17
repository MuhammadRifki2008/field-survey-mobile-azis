import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:field_survey/screens/survey/survey_form_page.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  // ============================================================
  // API
  // ============================================================

  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static const String imageUrl = 'https://sijala.biz.id/api/image';

  // ============================================================
  // WARNA
  // ============================================================

  static const Color primaryColor = Color(0xFF1E4BAF);

  static const Color lightBlueColor = Color(0xFFEFF6FF);

  static const Color backgroundColor = Color(0xFFF8FAFC);

  static const Color borderColor = Color(0xFFE2E8F0);

  static const Color textColor = Color(0xFF0F172A);

  static const Color secondaryTextColor = Color(0xFF64748B);

  // ============================================================
  // STATE
  // ============================================================

  Map<String, dynamic>? survey;

  bool isLoading = true;

  String? errorMessage;

  Uint8List? imageBytes;

  bool isLoadingImage = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    fetchDetail();
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ?? '';
  }

  // ============================================================
  // GET DETAIL
  // ============================================================

  Future<void> fetchDetail() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        imageBytes = null;
      });
    }

    try {
      final token = await getToken();

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/surveys/${widget.surveyId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('================================');
      debugPrint('STATUS DETAIL: ${response.statusCode}');
      debugPrint('RESPONSE DETAIL: ${response.body}');
      debugPrint('================================');

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.remove('token');
        await prefs.remove('user');

        throw Exception('Sesi login telah berakhir.');
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        Map<String, dynamic>? data;

        if (result is Map && result['data'] is Map) {
          data = Map<String, dynamic>.from(result['data']);
        } else if (result is Map && result['id'] != null) {
          data = Map<String, dynamic>.from(result);
        }

        if (data != null) {
          if (!mounted) return;

          setState(() {
            survey = data;
            isLoading = false;
          });

          final photoName =
              data['photo']?.toString() ?? data['image']?.toString() ?? '';

          if (photoName.isNotEmpty &&
              photoName != 'null' &&
              photoName != 'placeholder.jpg') {
            await fetchImage(photoName, token);
          }

          return;
        }
      }

      throw Exception('Survey tidak ditemukan.');
    } catch (e) {
      debugPrint('DETAIL ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // GET IMAGE
  // ============================================================

  Future<void> fetchImage(String photoName, String token) async {
    if (!mounted) return;

    setState(() {
      isLoadingImage = true;
    });

    try {
      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final response = await http.get(
        Uri.parse('$imageUrl/$fileName'),
        headers: {'Accept': 'image/*', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          imageBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
        });
      }
    }
  }

  // ============================================================
  // EDIT SURVEY
  // ============================================================

  Future<void> editSurvey() async {
    if (survey == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SurveyFormPage(survey: survey)),
    );

    if (result == true && mounted) {
      await fetchDetail();

      if (!mounted) return;

      showMessage('Data survey berhasil diperbarui', primaryColor);
    }
  }

  // ============================================================
  // DELETE SURVEY
  // ============================================================

  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Survey',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin menghapus survey ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final token = await getToken();

      if (token.isEmpty) {
        showMessage('Token tidak ditemukan.', Colors.red);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/surveys/${widget.surveyId}/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('DELETE STATUS: ${response.statusCode}');

      debugPrint('DELETE RESPONSE: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey berhasil dihapus'),
            backgroundColor: primaryColor,
          ),
        );

        Navigator.pop(context, true);
      } else if (response.statusCode == 401) {
        showMessage('Sesi login telah berakhir.', Colors.red);
      } else {
        String message = 'Gagal menghapus survey.';

        try {
          final data = jsonDecode(response.body);

          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}

        showMessage(message, Colors.red);
      }
    } catch (e) {
      debugPrint('DELETE ERROR: $e');

      if (!mounted) return;

      showMessage('Terjadi kesalahan saat menghapus survey.', Colors.red);
    }
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showMessage('Tidak dapat membuka Google Maps.', Colors.red);
      }
    } catch (e) {
      showMessage('Gagal membuka Google Maps.', Colors.red);
    }
  }

  // ============================================================
  // COPY KOORDINAT
  // ============================================================

  void copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));

    showMessage('Koordinat berhasil disalin!', primaryColor);
  }

  // ============================================================
  // FULL IMAGE
  // ============================================================

  void showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
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
  // FORMAT DATE
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Detail Survey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: buildBody(),
    );
  }

  // ============================================================
  // BODY
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
              'Memuat detail survey...',
              style: TextStyle(color: secondaryTextColor),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null || survey == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 70, color: Colors.red),

              const SizedBox(height: 16),

              const Text(
                'Gagal Memuat Survey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                errorMessage ?? 'Survey tidak ditemukan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: fetchDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // DATA SURVEY
    // ==========================================================

    final title =
        survey!['title']?.toString() ??
        survey!['name']?.toString() ??
        'Tanpa Judul';

    final description =
        survey!['description']?.toString() ??
        survey!['deskripsi']?.toString() ??
        '-';

    String category = 'Tanpa Kategori';

    if (survey!['category_name'] != null) {
      category = survey!['category_name'].toString();
    } else if (survey!['category'] is Map) {
      category = survey!['category']['name']?.toString() ?? 'Tanpa Kategori';
    }

    final date = formatDate(survey!['created_at']?.toString());

    final latitude = double.tryParse(survey!['latitude']?.toString() ?? '');

    final longitude = double.tryParse(survey!['longitude']?.toString() ?? '');

    final hasValidCoordinates = latitude != null && longitude != null;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchDetail,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(16),

        children: [
          // ====================================================
          // INFORMASI UTAMA
          // ====================================================
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderColor),
            ),

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: lightBlueColor,
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: Text(
                      category,

                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: secondaryTextColor,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        date,

                        style: const TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ====================================================
          // FOTO
          // ====================================================
          Card(
            elevation: 0,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderColor),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Padding(
                  padding: EdgeInsets.all(16),

                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, color: primaryColor),

                      SizedBox(width: 8),

                      Text(
                        'Foto Survey',

                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoadingImage)
                  const SizedBox(
                    height: 200,

                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                else if (imageBytes != null)
                  GestureDetector(
                    onTap: () {
                      showFullImageDialog(imageBytes!);
                    },

                    child: Image.memory(
                      imageBytes!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),

                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 45,
                          color: Color(0xFF94A3B8),
                        ),

                        SizedBox(height: 10),

                        Text(
                          'Tidak ada foto survey',

                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ====================================================
          // DESKRIPSI
          // ====================================================
          Card(
            elevation: 0,
            color: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderColor),
            ),

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined, color: primaryColor),

                      SizedBox(width: 8),

                      Text(
                        'Deskripsi',

                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Text(
                    description,

                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ====================================================
          // LOKASI
          // ====================================================
          Card(
            elevation: 0,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderColor),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: primaryColor),

                          SizedBox(width: 8),

                          Text(
                            'Lokasi Survey',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        hasValidCoordinates
                            ? 'Latitude: $latitude\nLongitude: $longitude'
                            : 'Koordinat tidak tersedia',

                        style: const TextStyle(
                          color: secondaryTextColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // MAP
                // ==================================================
                if (hasValidCoordinates)
                  SizedBox(
                    height: 250,
                    width: double.infinity,

                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude, longitude),

                        initialZoom: 15,
                      ),

                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                          userAgentPackageName: 'com.example.field_survey',
                        ),

                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude, longitude),

                              width: 50,
                              height: 50,

                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 160,
                    width: double.infinity,

                    color: const Color(0xFFF1F5F9),

                    child: const Center(
                      child: Text(
                        'Peta tidak tersedia',

                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                  ),

                // ==================================================
                // BUTTON MAP
                // ==================================================
                if (hasValidCoordinates)
                  Padding(
                    padding: const EdgeInsets.all(14),

                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              copyCoordinates(latitude, longitude);
                            },

                            icon: const Icon(Icons.copy),

                            label: const Text('Salin'),

                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,

                              side: const BorderSide(color: primaryColor),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              openGoogleMaps(latitude, longitude);
                            },

                            icon: const Icon(Icons.map),

                            label: const Text('Maps'),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,

                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // TOMBOL EDIT
          // ====================================================
          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: editSurvey,

              icon: const Icon(Icons.edit_outlined),

              label: const Text(
                'Edit Survey',

                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(vertical: 15),

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // TOMBOL HAPUS
          // ====================================================
          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: deleteSurvey,

              icon: const Icon(Icons.delete_outline),

              label: const Text(
                'Hapus Survey',

                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,

                side: const BorderSide(color: Colors.red),

                padding: const EdgeInsets.symmetric(vertical: 15),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
