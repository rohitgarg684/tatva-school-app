import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> pages = [
    {
      'icon': Icons.assignment,
      'title': 'Get Worksheets Instantly',
      'subtitle':
          'Teachers upload homework and worksheets in seconds. Students access them anytime, anywhere.',
      'color': Color(0xFF2E7D32),
    },
    {
      'icon': Icons.grade,
      'title': 'Track Grades Easily',
      'subtitle':
          'Students and parents can view grades in real time. No more waiting for report cards.',
      'color': Color(0xFF388E3C),
    },
    {
      'icon': Icons.upload_file,
      'title': 'Teacher Uploads in Seconds',
      'subtitle':
          'Add grades, homework and worksheets for your class with just a few taps.',
      'color': Color(0xFF43A047),
    },
    {
      'icon': Icons.family_restroom,
      'title': 'Keep Families Connected',
      'subtitle':
          'Parents stay informed about their child\'s progress and assignments at all times.',
      'color': Color(0xFF1B5E20),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _goToWelcome();
    }
  }

  void _goToWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToWelcome,
                child: Text('Skip',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animController.reset();
                  _animController.forward();
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (page['color'] as Color).withOpacity(0.1),
                            ),
                            child: Icon(page['icon'] as IconData,
                                size: 80, color: page['color'] as Color),
                          ),
                          SizedBox(height: 40),
                          Text(page['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20))),
                          SizedBox(height: 16),
                          Text(page['subtitle'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                  height: 1.6)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Color(0xFF2E7D32)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Color(0xFF2E7D32).withOpacity(0.4),
                ),
                child: Text(
                  _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
