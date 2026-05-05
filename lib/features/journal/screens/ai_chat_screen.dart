// AI Chat Screen - conversational AI interface for journal reflection
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/recommendation_engine.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/ai_chat_service.dart';
import '../../../services/chat_mood_service.dart';
import '../../session/data/breathing_sessions.dart';
import '../../session/screens/breathing_session_screen.dart';
import '../../session/screens/session_screen.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiChatService _aiChatService = AiChatService();
  final ChatMoodService _chatMoodService = ChatMoodService();
  bool _isLoading = false;
  ChatMoodSnapshot? _detectedMood;
  Recommendation? _recommendation;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _aiChatService.close();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(Message(
      text: 'Hello! I\'m here to listen and help you reflect on your thoughts. How are you feeling today?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await _aiChatService.sendMessage(text);
      if (mounted) {
        await _updateMoodAndRecommendation();
        setState(() {
          _messages.add(Message(text: aiResponse, isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(Message(
            text: 'Sorry, I\'m having trouble connecting right now. Let\'s try again later.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _updateMoodAndRecommendation() async {
    final userMessages = _messages
        .where((message) => message.isUser)
        .map((message) => message.text)
        .toList();
    final detectedMood = _chatMoodService.analyzeUserMessages(userMessages);
    if (detectedMood == null) return;

    await context.read<MoodProvider>().upsertAiChatMood(detectedMood.score);
    final streakProvider = context.read<StreakProvider>();
    final recommendation = RecommendationEngine.getRecommendation(
      moodScore: detectedMood.score,
      currentStreak: streakProvider.currentStreak,
      daysLeftToGoal: streakProvider.daysLeftToGoal,
      missedYesterday: streakProvider.missedYesterday,
    );

    _detectedMood = detectedMood;
    _recommendation = recommendation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('AI Chat', style: AppTextStyles.headline2),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_detectedMood != null && _recommendation != null)
            _buildRecommendationCard(_detectedMood!, _recommendation!),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.body1.copyWith(
            color: message.isUser ? AppColors.background : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI is typing', style: AppTextStyles.caption),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    ChatMoodSnapshot mood,
    Recommendation recommendation,
  ) {
    final sessionLabel = RecommendationEngine.getSessionTypeLabel(
      recommendation.sessionType,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood detected: ${mood.label}',
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.promptMessage,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$sessionLabel • ${recommendation.sessionDuration} min',
                  style: AppTextStyles.body1,
                ),
              ),
              GestureDetector(
                onTap: () => _startRecommendedSession(recommendation),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startRecommendedSession(Recommendation recommendation) {
    if (recommendation.sessionType == SessionType.wimHof) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BreathingSessionScreen(
            session: BreathingSessions.wimHof,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(
          duration: recommendation.sessionDuration,
          sound: MeditationSound.none,
          meditationType: RecommendationEngine.getSessionTypeLabel(
            recommendation.sessionType,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surface, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTextStyles.body1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: AppTextStyles.body2,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: AppColors.background,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
