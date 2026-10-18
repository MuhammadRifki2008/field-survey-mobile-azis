import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:field_survey/screens/survey/survey_screen.dart';
import 'package:field_survey/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF1E4BAF);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  final GlobalKey<_DashboardStatsState> _statsKey =
      GlobalKey<_DashboardStatsState>();
  final GlobalKey<_LatestSurveysState> _latestSurveysKey =
      GlobalKey<_LatestSurveysState>();

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _statsKey.currentState?.refresh() ?? Future<void>.value(),
      _latestSurveysKey.currentState?.refresh() ?? Future<void>.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: primaryColor, size: 28),
            SizedBox(width: 8),
            Text(
              'Field Survey',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada notifikasi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo, Selamat Datang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kelola dan pantau kegiatan survei lapangan dengan lebih mudah.',
                          style: TextStyle(
                            color: Color(0xFFDCE7FF),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SurveyScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text(
                            'Lihat Semua Survey',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Ringkasan Dashboard',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 14),
              DashboardStats(key: _statsKey, token: widget.token),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Survey Terbaru',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SurveyScreen(),
                        ),
                      );
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LatestSurveys(key: _latestSurveysKey, token: widget.token),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SurveyScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(token: widget.token),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Survey',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardStats extends StatefulWidget {
  final String token;

  const DashboardStats({super.key, required this.token});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  int jumlahSurvey = 0;
  int jumlahKategori = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    ambilData();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    await ambilData();
  }

  Future<void> ambilData() async {
    try {
      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal mengambil survey');
      }

      final json = jsonDecode(response.body);
      final surveys = extractList(json);

      final kategori = <String>{};

      for (final survey in surveys) {
        if (survey is! Map) continue;

        final category =
            survey['category'] ?? survey['kategori'] ?? survey['category_name'];

        String? nama;

        if (category is Map) {
          nama =
              (category['name'] ??
                      category['nama'] ??
                      category['category_name'])
                  ?.toString();
        } else if (category is String) {
          nama = category;
        }

        if (nama != null && nama.trim().isNotEmpty) {
          kategori.add(nama.trim());
        }
      }

      if (!mounted) return;

      setState(() {
        jumlahSurvey = cariTotal(json, surveys.length);
        jumlahKategori = kategori.length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Gagal memuat statistik';
        loading = false;
      });
    }
  }

  List<dynamic> extractList(dynamic json) {
    if (json is List) return json;

    if (json is Map) {
      if (json['data'] is List) return json['data'];
      if (json['surveys'] is List) return json['surveys'];

      if (json['data'] is Map) {
        return extractList(json['data']);
      }
    }

    return [];
  }

  int cariTotal(dynamic json, int fallback) {
    if (json is Map) {
      for (final key in ['total', 'total_surveys', 'surveys_count']) {
        final value = json[key];
        if (value is num) return value.toInt();
        if (value is String && int.tryParse(value) != null) {
          return int.parse(value);
        }
      }

      if (json['meta'] is Map && json['meta']['total'] is num) {
        return (json['meta']['total'] as num).toInt();
      }

      if (json['data'] is Map) {
        return cariTotal(json['data'], fallback);
      }
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              loading = true;
              error = null;
            });
            ambilData();
          },
          child: const Text('Coba Lagi'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: statCard(
            'Jumlah Survey',
            jumlahSurvey,
            Icons.assignment_outlined,
            const Color(0xFF1E4BAF),
            const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: statCard(
            'Kategori Survey',
            jumlahKategori,
            Icons.category_outlined,
            const Color(0xFF059669),
            const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  Widget statCard(
    String title,
    int jumlah,
    IconData icon,
    Color warna,
    Color latar,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: latar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: warna, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            '$jumlah',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class LatestSurveys extends StatefulWidget {
  final String token;

  const LatestSurveys({super.key, required this.token});

  @override
  State<LatestSurveys> createState() => _LatestSurveysState();
}

class _LatestSurveysState extends State<LatestSurveys> {
  List<dynamic> surveys = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    ambilSurvey();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    await ambilSurvey();
  }

  Future<void> ambilSurvey() async {
    try {
      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal mengambil survey');
      }

      final json = jsonDecode(response.body);
      final data = extractList(json);

      String tanggal(dynamic item) {
        if (item is! Map) return '';
        return (item['created_at'] ??
                item['createdAt'] ??
                item['tanggal'] ??
                item['survey_date'] ??
                '')
            .toString();
      }

      data.sort((a, b) => tanggal(b).compareTo(tanggal(a)));

      if (!mounted) return;

      setState(() {
        surveys = data.take(5).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Gagal memuat survey terbaru';
        loading = false;
      });
    }
  }

  List<dynamic> extractList(dynamic json) {
    if (json is List) return json;

    if (json is Map) {
      if (json['data'] is List) return json['data'];
      if (json['surveys'] is List) return json['surveys'];

      if (json['data'] is Map) {
        return extractList(json['data']);
      }
    }

    return [];
  }

  String nilai(dynamic item, List<String> keys) {
    if (item is! Map) return '-';

    for (final key in keys) {
      final value = item[key];

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }

      if (value is num) return value.toString();

      if (value is Map) {
        final nested = value['name'] ?? value['nama'] ?? value['category_name'];
        if (nested != null) return nested.toString();
      }
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(error!),
            TextButton(
              onPressed: () {
                setState(() {
                  loading = true;
                  error = null;
                });
                ambilSurvey();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (surveys.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 10),
            Text(
              'Belum ada data survey',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: surveys.map((survey) {
        final judul = nilai(survey, [
          'title',
          'judul',
          'nama',
          'name',
          'survey_name',
        ]);

        final kategori = nilai(survey, [
          'category',
          'kategori',
          'category_name',
        ]);

        final tanggal = nilai(survey, [
          'created_at',
          'createdAt',
          'tanggal',
          'survey_date',
        ]);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF1E4BAF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Kategori: $kategori',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (tanggal != '-')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          tanggal,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
