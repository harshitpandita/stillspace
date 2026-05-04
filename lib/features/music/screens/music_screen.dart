// Music screen - background music player with track selection and timed sessions
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/music_service.dart';
import '../data/music_tracks.dart';
import '../models/music_track.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final MusicService _music = MusicService();
  Duration? _selectedDuration; // null = until stopped

  static const _durationOptions = [
    _DurationOption('15 min', Duration(minutes: 15)),
    _DurationOption('30 min', Duration(minutes: 30)),
    _DurationOption('60 min', Duration(minutes: 60)),
    _DurationOption('Until I stop', null),
  ];

  @override
  void initState() {
    super.initState();
    _music.addListener(_onMusicChange);
  }

  @override
  void dispose() {
    _music.removeListener(_onMusicChange);
    super.dispose();
  }

  void _onMusicChange() {
    if (mounted) setState(() {});
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
        title: const Text('Music', style: AppTextStyles.headline2),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_music.currentTrack != null) ...[
                _buildNowPlayingCard(),
                const SizedBox(height: 24),
              ],
              const Text('Session Length', style: AppTextStyles.headline3),
              const SizedBox(height: 12),
              _buildDurationSelector(),
              const SizedBox(height: 32),
              ...MusicTracks.categories.map(_buildCategorySection),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.primary, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Plays in the background and when your phone is locked. Control from the notification shade.',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _durationOptions.map((opt) {
        final isSelected = _selectedDuration == opt.duration;
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = opt.duration),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              opt.label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(String category) {
    final tracks = MusicTracks.byCategory(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          ...tracks.map((track) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTrackCard(track),
              )),
        ],
      ),
    );
  }

  Widget _buildTrackCard(MusicTrack track) {
    final isCurrent = _music.currentTrack?.id == track.id;
    final isPlaying = isCurrent && _music.isPlaying;

    return GestureDetector(
      onTap: () => _onTrackTap(track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(track.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(track.description, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isCurrent ? AppColors.background : AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayingCard() {
    final track = _music.currentTrack!;
    final remaining = _music.sessionRemaining;
    final progress = _music.sessionProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Now Playing',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(track.title, style: AppTextStyles.headline2, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildCountdownRing(track, remaining, progress),
          const SizedBox(height: 24),
          _buildVolumeSlider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _music.isPlaying ? () => _music.pause() : () => _music.resume(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _music.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.background,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _music.isPlaying ? 'Pause' : 'Resume',
                            style: const TextStyle(
                              color: AppColors.background,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _music.stop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stop, color: AppColors.error, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownRing(MusicTrack track, Duration? remaining, double? progress) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              // For "Until I stop" sessions there's no fixed end — show full ring
              value: progress != null ? (1.0 - progress) : 1.0,
              strokeWidth: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(track.icon, color: AppColors.primary, size: 32),
                const SizedBox(height: 8),
                if (remaining != null) ...[
                  Text(
                    _formatRemaining(remaining),
                    style: AppTextStyles.headline1.copyWith(
                      color: AppColors.primary,
                      fontSize: 28,
                    ),
                  ),
                  Text('remaining', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ] else ...[
                  Text(
                    'Playing',
                    style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
                  ),
                  Text('Until you stop', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: AppColors.textSecondary, size: 18),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _music.volume,
              onChanged: (v) => _music.setVolume(v),
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: AppColors.textSecondary, size: 18),
      ],
    );
  }

  void _onTrackTap(MusicTrack track) {
    final isCurrent = _music.currentTrack?.id == track.id;
    if (isCurrent) {
      _music.isPlaying ? _music.pause() : _music.resume();
    } else {
      _music.play(track, duration: _selectedDuration);
    }
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    return '${seconds}s';
  }
}

class _DurationOption {
  final String label;
  final Duration? duration;
  const _DurationOption(this.label, this.duration);
}
