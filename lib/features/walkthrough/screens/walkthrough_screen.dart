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
      icon: Icons.wb_sunny_outlined,
      title: 'Daily Check-In',
      description:
          'Start with your mood, then get gentle suggestions that fit your day.',
      features: [
        'Mood check-ins every few hours',
        'Personal session recommendations',
        'Daily wisdom on Home',
      ],
    ),
    _WalkthroughPage(
      icon: Icons.self_improvement,
      title: 'Meditate and Breathe',
      description:
          'Use silent timers, ambient sound, or guided breathwork when you need a reset.',
      features: [
        '5 to 30 minute sessions',
        'Focus tones and brown noise',
        'Guided Wim Hof breathing',
      ],
    ),
    _WalkthroughPage(
      icon: Icons.graphic_eq,
      title: 'Music for Focus',
      description:
          'Play calm soundscapes in the background with a timer and quick controls.',
      features: [
        'Ambient and frequency tracks',
        '15, 30, or 60 minute sessions',
        'Mini player from any tab',
      ],
    ),
    _WalkthroughPage(
      icon: Icons.edit_note,
      title: 'Journal and Learn',
      description:
          'Reflect, attach local images, and build a practical understanding of meditation.',
      features: [
        'Guided prompts and mood tags',
        'Private local journal images',
        'Offline Learn articles',
      ],
    ),
    _WalkthroughPage(
      icon: Icons.insights,
      title: 'Progress That Sticks',
      description:
          'Stay consistent with streaks, reminders, progress charts, and backup.',
      features: [
        'Streak calendar and mood chart',
        'Daily reminders and follow-ups',
        'Google backup with daily sync',
      ],
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
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
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
            child: Icon(page.icon, color: AppColors.primary, size: 56),
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
          ...page.features.map(
            (feature) => Padding(
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
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.surface,
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
