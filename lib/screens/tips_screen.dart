import 'dart:async';
import 'package:flutter/material.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Quiz state
  int _quizIndex = 0;
  int _score = 0;
  bool _showResult = false;

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'type': 'multiple',
      'question': 'Apa tujuan utama menabung?',
      'options': [
        'Membeli barang mewah',
        'Mengamankan masa depan',
        'Menghabiskan uang',
        'Berfoya-foya'
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
      'question': 'Andi menerima uang saku Rp20.000/hari. Ia ingin membeli buku seharga Rp100.000. Apa yang sebaiknya Andi lakukan?',
      'options': [
        'Langsung membeli dengan uang saku hari itu',
        'Menabung sebagian uang sakunya hingga cukup',
        'Meminjam uang ke teman',
        'Mengabaikan kebutuhan buku'
      ],
      'answer': 1,
    },
  ];

  // Daily tips
  final List<Map<String, String>> _dailyTips = [
    {
      'title': 'Menabung itu Keren!',
      'message': 'Sisihkan minimal 10% uang sakumu setiap hari untuk masa depan yang lebih baik.',
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
  ];

  // Carousel state
  late final PageController _pageController;
  int _currentTip = 0;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTip);
    _startTipTimer();
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
      _quizIndex = 0;
      _score = 0;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24), // beri padding bawah agar tidak mentok
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // Tips Harian Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: tip['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      tip['image']!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.lightbulb, size: 48),
                                    ),
                                  )
                                : const Icon(Icons.lightbulb, size: 48),
                            title: Text(tip['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tip['message']!),
                          ),
                        );
                      },
                    ),
                    // Dots indicator
                    Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_dailyTips.length, (idx) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentTip == idx ? 14 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentTip == idx
                                  ? Theme.of(context).colorScheme.secondary
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _showResult
                      ? Column(
                          children: [
                            Text('Skor Anda: $_score / ${_quizQuestions.length}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _resetQuiz,
                              child: const Text('Ulangi Kuis'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berita & Video Edukasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: const Text('5 Cara Sederhana Mengatur Uang Saku'),
                      subtitle: const Text('kumparan.com'),
                      onTap: () {
                        // Ganti dengan url_launcher jika ingin membuka link
                        // launchUrl(Uri.parse('https://kumparan.com/...'));
                      },
                      trailing: const Icon(Icons.open_in_new),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                      title: const Text('Tips Mengelola Uang Jajan - YouTube'),
                      subtitle: const Text('YouTube: Finansialku.com'),
                      onTap: () {
                        // launchUrl(Uri.parse('https://www.youtube.com/watch?v=6b4gQyKqk2w'));
                      },
                      trailing: const Icon(Icons.open_in_new),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: const Text('Kenali Pentingnya Menabung Sejak Dini'),
                      subtitle: const Text('detik.com'),
                      onTap: () {
                        // launchUrl(Uri.parse('https://finance.detik.com/perencanaan-keuangan/d-6561047/kenali-pentingnya-menabung-sejak-dini'));
                      },
                      trailing: const Icon(Icons.open_in_new),
                    ),
                  ),
                  // Tambahan berita/video edukasi
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                      title: const Text('Cara Mengatur Keuangan untuk Pelajar'),
                      subtitle: const Text('YouTube: Zenius'),
                      onTap: () {
                        // launchUrl(Uri.parse('https://www.youtube.com/watch?v=5wQF6QyJv9g'));
                      },
                      trailing: const Icon(Icons.open_in_new),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: const Text('Tips Menabung Efektif untuk Remaja'),
                      subtitle: const Text('kompas.com'),
                      onTap: () {
                        // launchUrl(Uri.parse('https://www.kompas.com/edu/read/2021/10/25/180000171/tips-menabung-efektif-untuk-remaja'));
                      },
                      trailing: const Icon(Icons.open_in_new),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizQuestion(Map<String, dynamic> q) {
    if (q['type'] == 'multiple' || q['type'] == 'case') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          Text(q['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
