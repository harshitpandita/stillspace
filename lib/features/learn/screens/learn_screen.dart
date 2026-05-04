// Learn Meditation screen - browse categories and articles loaded from local JSON
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/learn_service.dart';
import '../models/learn_content.dart';
import 'learn_article_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late Future<List<LearnCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = LearnService().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Learn', style: AppTextStyles.headline2),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<LearnCategory>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Could not load Learn content.',
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _buildList(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildList(List<LearnCategory> categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Short, practical reads about how meditation actually works.',
                    style: AppTextStyles.body2.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...categories.map(_buildCategorySection),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategorySection(LearnCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.title, style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...category.items.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildArticleCard(article),
              )),
        ],
      ),
    );
  }

  Widget _buildArticleCard(LearnArticle article) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LearnArticleScreen(article: article),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readingTimeMinutes} min read',
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
