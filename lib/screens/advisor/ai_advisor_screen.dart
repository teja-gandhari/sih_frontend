import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/advisory_provider.dart';
import '../../models/advisory_model.dart';
import '../../providers/feasibility_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _speechAvailable = false;
  String _playingMessageId = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppStateProvider>();
      if (appState.applicationId != null) {
        context.read<AdvisoryProvider>().initialize(appState.applicationId!);
      }
    });

    _initTts();
  }

  Future<void> _initializeSpeech() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _initTts() async {
    final language = context.read<AppStateProvider>().selectedLanguage;
    await _flutterTts.setLanguage(_ttsLocaleForLanguage(language));
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _playingMessageId = '');
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
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

  Future<void> _listen() async {
    final language = context.read<AppStateProvider>().selectedLanguage;
    if (!_isListening) {
      if (!_speechAvailable) {
        await _initializeSpeech();
      }
      if (_speechAvailable) {
        setState(() => _isListening = true);
        await _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            localeId: _speechLocaleForLanguage(language),
          ),
          onResult: (val) {
            if (mounted) {
              setState(() => _textController.text = val.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  String? _speechLocaleForLanguage(String language) {
    switch (language) {
      case 'te':
        return 'te-IN';
      case 'hi':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }

  String _ttsLocaleForLanguage(String language) {
    switch (language) {
      case 'te':
        return 'te-IN';
      case 'hi':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }

  Future<void> _speak(String messageId, String text) async {
    if (_playingMessageId == messageId) {
      await _flutterTts.stop();
      setState(() => _playingMessageId = '');
    } else {
      await _flutterTts.stop();
      setState(() => _playingMessageId = messageId);
      await _flutterTts.speak(text);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final appState = context.read<AppStateProvider>();
    context.read<AdvisoryProvider>().sendMessage(
      text,
      appState.selectedLanguage,
    );

    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final advisoryState = context.watch<AdvisoryProvider>();
    final feasibilityState = context.watch<FeasibilityProvider>();

    final feasibilityScore =
        feasibilityState.feasibilityData?.overallScore.toString() ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('AI Business Advisor')),
      body: SafeArea(
        child: Column(
          children: [
            // Context Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏪 ${appState.businessCategory?.name ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('📍 ${appState.village ?? 'Unknown'}'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Feasibility: $feasibilityScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.yellow.shade100,
              width: double.infinity,
              child: const Text(
                'AI-generated advice is for business planning support. Verify details with officials.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: advisoryState.messages.length,
                itemBuilder: (context, index) {
                  final msg = advisoryState.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Status Indicator
            if (advisoryState.state == AdvisoryState.loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Analyzing your business information...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (advisoryState.state == AdvisoryState.error)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  advisoryState.errorMessage ?? 'Error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _listen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: advisoryState.state != AdvisoryState.loading,
                      decoration: const InputDecoration(
                        hintText: 'Ask your question...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: advisoryState.state == AdvisoryState.loading
                        ? null
                        : _sendMessage,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
                child: const Text('Continue to Final Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: !msg.isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            if (!msg.isUser) ...[
              const SizedBox(height: 8),
              if (msg.sources.isNotEmpty)
                Text(
                  'Sources: ${msg.sources.join(', ')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _playingMessageId == msg.id
                        ? Icons.stop_circle
                        : Icons.volume_up,
                    size: 20,
                    color: Colors.blue,
                  ),
                  onPressed: () => _speak(msg.id, msg.text),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
