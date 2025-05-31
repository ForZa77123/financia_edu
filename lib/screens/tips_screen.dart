import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Bank soal quiz
  final List<Map<String, dynamic>> _quizBank = [
    {
      'type': 'multiple',
      'question': 'Apa tujuan utama menabung?',
      'options': [
        'Membeli barang mewah',
        'Mengamankan masa depan',
        'Menghabiskan uang',
        'Berfoya-foya',
      ],
      'answer': 1,
    },
    {
      'type': 'truefalse',
      'question': 'Belanja tanpa membuat daftar belanja adalah kebiasaan baik.',
      'answer': false,
    },
    {
      'type': 'case',
      'question':
          'Andi menerima uang saku Rp20.000/hari. Ia ingin membeli buku seharga Rp100.000. Apa yang sebaiknya Andi lakukan?',
      'options': [
        'Langsung membeli dengan uang saku hari itu',
        'Menabung sebagian uang sakunya hingga cukup',
        'Meminjam uang ke teman',
        'Mengabaikan kebutuhan buku',
      ],
      'answer': 1,
    },
    {
      'type': 'multiple',
      'question': 'Apa yang sebaiknya dilakukan sebelum membeli barang?',
      'options': [
        'Membandingkan harga dan kebutuhan',
        'Langsung beli saja',
        'Meminjam uang',
        'Membeli yang paling mahal',
      ],
      'answer': 0,
    },
    {
      'type': 'truefalse',
      'question': 'Menabung hanya penting untuk orang dewasa.',
      'answer': false,
    },
    {
      'type': 'multiple',
      'question':
          'Jika kamu mendapat uang lebih, apa yang sebaiknya dilakukan?',
      'options': [
        'Menghabiskan semuanya',
        'Menabung sebagian',
        'Membelikan teman jajan',
        'Menyembunyikan dari orang tua',
      ],
      'answer': 1,
    },
    {
      'type': 'case',
      'question':
          'Siti ingin membeli sepatu baru, tapi uangnya belum cukup. Apa langkah terbaik?',
      'options': [
        'Meminjam uang ke teman',
        'Menabung hingga cukup',
        'Membeli sepatu bekas',
        'Mengambil uang orang tua tanpa izin',
      ],
      'answer': 1,
    },
    {
      'type': 'truefalse',
      'question': 'Membuat anggaran bulanan bisa membantu mengatur keuangan.',
      'answer': true,
    },
    {
      'type': 'multiple',
      'question': 'Apa manfaat mencatat pengeluaran?',
      'options': [
        'Agar tahu ke mana uang pergi',
        'Agar bisa boros',
        'Agar bisa minta uang lebih',
        'Agar lupa pengeluaran',
      ],
      'answer': 0,
    },
    {
      'type': 'case',
      'question':
          'Budi sering membeli jajanan setiap hari hingga uang sakunya habis. Apa saran terbaik?',
      'options': [
        'Kurangi jajan dan sisihkan untuk ditabung',
        'Minta uang saku lebih banyak',
        'Pinjam uang ke teman',
        'Abaikan saja',
      ],
      'answer': 0,
    },
  ];

  // Bank tips harian
  final List<Map<String, String>> _tipsBank = [
    {
      'title': 'Menabung itu Keren!',
      'message':
          'Sisihkan minimal 10% uang sakumu setiap hari untuk masa depan yang lebih baik.',
      'image': 'assets/images/save_money.png',
    },
    {
      'title': 'Belanja Cerdas',
      'message': 'Buat daftar belanja sebelum ke toko agar tidak boros.',
      'image': 'assets/images/shopping_list.png',
    },
    {
      'title': 'Hemat Pangkal Kaya',
      'message': 'Utamakan kebutuhan daripada keinginan.',
      'image': 'assets/images/smart_spend.png',
    },
    {
      'title': 'Catat Pengeluaran',
      'message':
          'Selalu catat setiap pengeluaran agar tahu ke mana uangmu pergi.',
      'image': 'assets/images/notes.png',
    },
    {
      'title': 'Bandingkan Harga',
      'message': 'Sebelum membeli, bandingkan harga di beberapa tempat.',
      'image': 'assets/images/compare.png',
    },
    {
      'title': 'Bawa Bekal Sendiri',
      'message': 'Membawa bekal dari rumah bisa menghemat pengeluaran jajan.',
      'image': 'assets/images/lunchbox.png',
    },
    {
      'title': 'Jangan Mudah Tergoda Diskon',
      'message': 'Beli barang karena butuh, bukan karena diskon.',
      'image': 'assets/images/discount.png',
    },
    {
      'title': 'Tentukan Tujuan Menabung',
      'message': 'Menabung dengan tujuan membuatmu lebih semangat.',
      'image': 'assets/images/goal.png',
    },
    {
      'title': 'Gunakan Uang Secukupnya',
      'message': 'Belanjakan uang sesuai kebutuhan, bukan keinginan.',
      'image': 'assets/images/wallet.png',
    },
    {
      'title': 'Jangan Lupa Berbagi',
      'message': 'Sisihkan sebagian uang untuk membantu sesama.',
      'image': 'assets/images/share.png',
    },
  ];

  // Quiz & tips state
  int _quizIndex = 0;
  int _score = 0;
  bool _showResult = false;
  late List<Map<String, dynamic>> _quizQuestions;
  late List<Map<String, String>> _dailyTips;

  // Carousel state
  late final PageController _pageController;
  int _currentTip = 0;
  Timer? _tipTimer;

  // Daftar berita & video edukasi dari internet
  final String _defaultEduLinksJson = jsonEncode([
    {
      'title': '5 tips MENABUNG (no4 sering keskip...)',
      'subtitle': 'YouTube: cclaracl',
      'url': 'https://www.youtube.com/watch?v=JfjevexbVVI',
      'icon': 'video',
    },
    {
      'title': 'Tips Menabung untuk Pelajar, Orangtua Harus Tahu!',
      'subtitle': 'hokibank.co.id',
      'url':
          'https://hokibank.co.id/tips-menabung-untuk-pelajar-orangtua-harus-tahu/',
      'icon': 'article',
    },
  ]);

  List<Map<String, String>> _eduLinks = [];
  bool _loadingEduLinks = true;

  Future<void> _fetchEduLinks() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      // Set in-app default
      await remoteConfig.setDefaults({'edu_links': _defaultEduLinksJson});
      await remoteConfig.fetchAndActivate();
      final jsonString = remoteConfig.getString('edu_links');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _eduLinks =
            jsonList.map((e) => Map<String, String>.from(e as Map)).toList();
        _loadingEduLinks = false;
      });
    } catch (e) {
      // On error, use the in-app default
      final List<dynamic> jsonList = json.decode(_defaultEduLinksJson);
      setState(() {
        _eduLinks =
            jsonList.map((e) => Map<String, String>.from(e as Map)).toList();
        _loadingEduLinks = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _randomizeQuizAndTips();
    _pageController = PageController(initialPage: _currentTip);
    _startTipTimer();
    _fetchEduLinks();
  }

  void _randomizeQuizAndTips() {
    final rand = Random();
    // Ambil 5 soal random unik
    final quizBankCopy = List<Map<String, dynamic>>.from(_quizBank);
    quizBankCopy.shuffle(rand);
    _quizQuestions = quizBankCopy.take(5).toList();

    // Ambil 3 tips random unik
    final tipsBankCopy = List<Map<String, String>>.from(_tipsBank);
    tipsBankCopy.shuffle(rand);
    _dailyTips = tipsBankCopy.take(3).toList();

    _quizIndex = 0;
    _score = 0;
    _showResult = false;
    _currentTip = 0;
  }

  void _startTipTimer() {
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentTip + 1) % _dailyTips.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onTipPageChanged(int index) {
    setState(() {
      _currentTip = index;
    });
  }

  void _answerQuiz(int selected) {
    final q = _quizQuestions[_quizIndex];
    bool correct = false;
    if (q['type'] == 'multiple' || q['type'] == 'case') {
      correct = selected == q['answer'];
    } else if (q['type'] == 'truefalse') {
      correct = (selected == 1) == q['answer'];
    }
    if (correct) _score++;
    setState(() {
      if (_quizIndex < _quizQuestions.length - 1) {
        _quizIndex++;
      } else {
        _showResult = true;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _randomizeQuizAndTips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Background gradient sesuai tema
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDark
                      ? [
                        const Color(0xFF23272F),
                        const Color(0xFF181A20),
                        const Color(0xFF23272F),
                      ]
                      : [
                        const Color(0xFF1976D2),
                        const Color(0xFF64B5F6),
                        const Color(0xFFFFFDE4),
                      ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                // Tips Harian Carousel
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onTipPageChanged,
                          itemCount: _dailyTips.length,
                          itemBuilder: (context, idx) {
                            final tip = _dailyTips[idx];
                            return Card(
                              elevation: 5,
                              color:
                                  isDark
                                      ? Colors.grey[900]?.withOpacity(0.13)
                                      : Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading:
                                    tip['image'] != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                          child: Image.asset(
                                            tip['image']!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.lightbulb,
                                                      size: 48,
                                                    ),
                                          ),
                                        )
                                        : const Icon(Icons.lightbulb, size: 48),
                                title: Text(
                                  tip['title']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(tip['message']!),
                              ),
                            );
                          },
                        ),
                        // Dots indicator
                        Positioned(
                          bottom: 15,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_dailyTips.length, (idx) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _currentTip == idx ? 14 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _currentTip == idx
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                          : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Kuis Finansial
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          _showResult
                              ? Column(
                                children: [
                                  Text(
                                    'Skor Anda: $_score / ${_quizQuestions.length}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _resetQuiz,
                                    child: const Text(
                                      'Ulangi Kuis (Soal & Tips Baru)',
                                    ),
                                  ),
                                ],
                              )
                              : _buildQuizQuestion(_quizQuestions[_quizIndex]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Berita & Video Edukasi Keuangan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berita & Video Edukasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _loadingEduLinks
                              ? const Center(child: CircularProgressIndicator())
                              : (_eduLinks.isEmpty
                                  ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Tidak ada berita atau video edukasi.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                  : Column(
                                    children:
                                        _eduLinks
                                            .map(
                                              (item) => Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                color:
                                                    isDark
                                                        ? Colors.grey[850]
                                                        : Colors.white,
                                                child: ListTile(
                                                  leading:
                                                      item['icon'] == 'video'
                                                          ? const Icon(
                                                            Icons
                                                                .play_circle_fill,
                                                            color: Colors.red,
                                                          )
                                                          : const Icon(
                                                            Icons.article,
                                                            color: Colors.blue,
                                                          ),
                                                  title: Text(
                                                    item['title'] ?? '',
                                                  ),
                                                  subtitle: Text(
                                                    item['subtitle'] ?? '',
                                                  ),
                                                  onTap: () async {
                                                    String? url = item['url'];
                                                    if (url != null &&
                                                        url.isNotEmpty) {
                                                      // Ensure the URL starts with http/https
                                                      if (!url.startsWith(
                                                            'http://',
                                                          ) &&
                                                          !url.startsWith(
                                                            'https://',
                                                          )) {
                                                        url = 'https://$url';
                                                      }
                                                      final uri = Uri.parse(
                                                        url,
                                                      );
                                                      if (await canLaunchUrl(
                                                        uri,
                                                      )) {
                                                        await launchUrl(
                                                          uri,
                                                          mode:
                                                              LaunchMode
                                                                  .externalApplication,
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Tidak dapat membuka link',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  trailing: const Icon(
                                                    Icons.open_in_new,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizQuestion(Map<String, dynamic> q) {
    if (q['type'] == 'multiple' || q['type'] == 'case') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q['question'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(q['options'].length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: () => _answerQuiz(i),
                child: Text(q['options'][i]),
              ),
            );
          }),
        ],
      );
    } else if (q['type'] == 'truefalse') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q['question'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _answerQuiz(1),
                  child: const Text('Benar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _answerQuiz(0),
                  child: const Text('Salah'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
