import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  Timer? _timer; 
  int step = 1;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding_1.jpeg",
      "title": "Catat Aktivitas",
      "desc": "Simpan setiap progres logbook harianmu dengan mudah.",
    },
    {
      "image": "assets/images/onboarding_2.jpeg",
      "title": "Keamanan Data",
      "desc": "Data tersimpan aman di perangkatmu.",
    },
    {
      "image": "assets/images/onboarding_3.jpeg",
      "title": "Pantau Progres",
      "desc": "Lihat riwayat aktivitas kapanpun kamu mau.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (step < onboardingData.length) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (step < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel(); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    step = index + 1;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        onboardingData[index]["image"]!,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        onboardingData[index]["title"]!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 158, 101, 140),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        onboardingData[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(221, 175, 133, 149),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),

          // Indicator Step
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer( 
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: step == (index + 1) ? 20 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: step == (index + 1)
                        ? const Color.fromARGB(255, 158, 101, 140)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),

            const SizedBox(
              height: 40,
            ),

            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color.fromARGB(255, 158, 101, 140),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    25,
                  ), // Sedikit lebih bulat agar estetik
                ),
              ),
              child: Text(step < 3 ? "Lanjut" : "Mulai Sekarang"),
            ),
          ],
        ),
      ),
    );
  }
}