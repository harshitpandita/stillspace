// Journal entry screen - create new journal entry with optional prompt and local images
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../services/journal_image_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/primary_action_button.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  late String _suggestedPrompt;
  late String _draftEntryId;
  bool _usePrompt = true;
  int? _selectedMood;
  bool _isSaving = false;
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _suggestedPrompt = _getRandomPrompt();
    _draftEntryId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _getRandomPrompt() {
    final random = Random();
    return AppConstants.defaultJournalPrompts[
        random.nextInt(AppConstants.defaultJournalPrompts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
        title: const Text('New Entry', style: AppTextStyles.headline3),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromptSection(),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _contentController,
                        style: AppTextStyles.body1,
                        maxLines: null,
                        minLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _usePrompt
                              ? 'Write your thoughts...'
                              : 'What\'s on your mind?',
                          hintStyle: AppTextStyles.body2,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Text('How are you feeling?', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final moodScore = index + 1;
                          final isSelected = _selectedMood == moodScore;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedMood = isSelected ? null : moodScore;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 52 : 44,
                              height: isSelected ? 52 : 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  AppConstants.moodEmojis[index],
                                  style: TextStyle(fontSize: isSelected ? 24 : 20),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      _buildImageSection(),
                      const Spacer(),
                      const SizedBox(height: 24),
                      PrimaryActionButton(
                        label: 'Save Entry',
                        onPressed: _contentController.text.trim().isNotEmpty ? _saveEntry : null,
                        isLoading: _isSaving,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Suggested prompt',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _usePrompt = !_usePrompt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _usePrompt ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _usePrompt ? 'On' : 'Off',
                  style: AppTextStyles.caption.copyWith(
                    color: _usePrompt ? AppColors.background : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_usePrompt) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _suggestedPrompt = _getRandomPrompt()),
            child: Container(
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
                      _suggestedPrompt,
                      style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shuffle, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final journalProvider = context.read<JournalProvider>();
      final streakProvider = context.read<StreakProvider>();

      await journalProvider.addEntry(
        prompt: _usePrompt ? _suggestedPrompt : 'Free write',
        content: _contentController.text.trim(),
        moodScore: _selectedMood,
        imagePaths: List.unmodifiable(_imagePaths),
      );

      await streakProvider.incrementStreak();

      // Cancel notifications in background - don't block navigation
      NotificationService().cancelFollowUpNotifications().catchError((_) {});
    } catch (e) {
      // Entry likely saved, continue
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos', style: AppTextStyles.label),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Local only',
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Images are saved locally and won't sync across devices.",
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              ..._imagePaths.map((path) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildImageThumbnail(path),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: 84,
              height: 84,
              color: AppColors.surface,
              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(path),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSourceTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _buildSourceTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take a photo',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.body1),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final path = await JournalImageService().pickAndSave(
        source: source,
        entryId: _draftEntryId,
      );
      if (path == null || !mounted) return;
      setState(() => _imagePaths.add(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load image. Please try again.'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeImage(String path) async {
    setState(() => _imagePaths.remove(path));
    await JournalImageService().deleteImage(path);
  }
}
