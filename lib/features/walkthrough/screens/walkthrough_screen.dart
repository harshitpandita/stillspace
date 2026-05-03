// Walkthrough screen - introduces app features to new users
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/primary_action_button.dart';

class WalkthroughScreen extends StatefulWidget {
  final bool showSkip;
  final VoidCallback? onComplete;

  const WalkthroughScreen({super.key, this.showSkip = true, this.onComplete});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_WalkthroughPage> _pages = [
    _WalkthroughPage(
      icon: Icons.self_improvement,
      title: 'Meditation Sessions',
      description: 'Choose your duration and ambient sound. A gentle bell marks the start and end of each session.',
      features: ['5 to 30 minute sessions', '2.5 Hz binaural beats for focus', 'Brown noise for relaxation'],
    ),
    _WalkthroughPage(
      icon: Icons.local_fire_department,
      title: 'Build Your Streak',
      description: 'Stay consistent and watch your streak grow. Complete a session or write a journal entry each day.',
      features: ['Streak freeze protects missed days', 'Set 7, 14, 21, or 30 day goals', 'Track your journey visually'],
    ),
    _WalkthroughPage(
      icon: Icons.edit_note,
      title: 'Reflective Journaling',
      description: 'Capture your thoughts with guided prompts or free writing. Journaling counts toward your streak too.',
      features: ['Thoughtful daily prompts', 'Tag entries with your mood', 'Private and stored locally'],
    ),
    _WalkthroughPage(
      icon: Icons.insights,
      title: 'Track Your Progress',
      description: 'See your consistency at a glance with the streak calendar and mood trends over time.',
      features: ['30-day streak calendar', '7-day mood chart', 'Total meditation time'],
    ),
    _WalkthroughPage(
      icon: Icons.cloud_done,
      title: 'Cloud Backup',
      description: 'Sign in with Google to securely backup your data. Your progress is safe and syncs across devices.',
      features: ['One-tap Google sign in', 'Automatic cloud sync', 'Restore anytime'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    widget.onComplete?.call();
    if (widget.onComplete == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: !widget.showSkip
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                '${_currentPage + 1}/${_pages.length}',
                style: AppTextStyles.caption,
              ),
            ),
          ),
          if (widget.showSkip)
            TextButton(
              onPressed: _finish,
              child: Text(
                'Skip',
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildPageIndicator(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryActionButton(
                label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _nextPage,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_WalkthroughPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              color: AppColors.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: AppTextStyles.headline1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...page.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _WalkthroughPage {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  _WalkthroughPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });
}
