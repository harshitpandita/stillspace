// Learn article detail screen - renders parsed JSON blocks (paragraph/heading/bullet)
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/learn_content.dart';

class LearnArticleScreen extends StatelessWidget {
  final LearnArticle article;

  const LearnArticleScreen({super.key, required this.article});

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
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title, style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${article.readingTimeMinutes} min read',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...article.body.map(_buildBlock),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(LearnBlock block) {
    switch (block.type) {
      case LearnBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            block.text,
            style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
          ),
        );
      case LearnBlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 12),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: AppTextStyles.body1.copyWith(height: 1.6),
                ),
              ),
            ],
          ),
        );
      case LearnBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            block.text,
            style: AppTextStyles.body1.copyWith(height: 1.7),
          ),
        );
    }
  }
}
