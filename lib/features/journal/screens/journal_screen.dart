// Journal screen - list of journal entries with FAB to add new entry
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final entries = journalProvider.recentEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Journal', style: AppTextStyles.headline2),
        centerTitle: false,
      ),
      body: entries.isEmpty ? _buildEmptyState(context) : _buildEntryList(context, entries),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewEntry(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text('No entries yet', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text(
              'Start journaling to track your thoughts and feelings',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _openNewEntry(context),
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: Text(
                'Write your first entry',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, List<JournalEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _JournalEntryCard(
          entry: entry,
          onTap: () => _openEntryDetail(context, entry),
        );
      },
    );
  }

  void _openNewEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const JournalEntryScreen()),
    );
  }

  void _openEntryDetail(BuildContext context, JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _JournalDetailScreen(entry: entry)),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const _JournalEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(entry.timestamp),
                    style: AppTextStyles.caption,
                  ),
                ),
                if (entry.moodScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getMoodEmoji(entry.moodScore!),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry.prompt != 'Free write')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entry.prompt,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            Text(
              entry.content,
              style: AppTextStyles.body1,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to read more',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMoodEmoji(int score) {
    const emojis = ['😔', '😕', '😐', '🙂', '😊'];
    return emojis[score - 1];
  }
}

class _JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const _JournalDetailScreen({required this.entry});

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
        title: Text(_formatDate(entry.timestamp), style: AppTextStyles.headline3),
        centerTitle: true,
        actions: [
          if (entry.moodScore != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _getMoodEmoji(entry.moodScore!),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.prompt != 'Free write') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.prompt,
                        style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              entry.content,
              style: AppTextStyles.body1.copyWith(height: 1.8),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                _formatFullDate(entry.timestamp),
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $time';
  }

  String _getMoodEmoji(int score) {
    const emojis = ['😔', '😕', '😐', '🙂', '😊'];
    return emojis[score - 1];
  }
}
