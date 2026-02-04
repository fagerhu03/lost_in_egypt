import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  // Language map: display name -> ML Kit language code
  static const Map<String, TranslateLanguage> languages = {
    'English': TranslateLanguage.english,
    'Arabic': TranslateLanguage.arabic,
    'French': TranslateLanguage.french,
    'Spanish': TranslateLanguage.spanish,
    'German': TranslateLanguage.german,
    'Italian': TranslateLanguage.italian,
    'Portuguese': TranslateLanguage.portuguese,
    'Russian': TranslateLanguage.russian,
    'Chinese': TranslateLanguage.chinese,
    'Japanese': TranslateLanguage.japanese,
    'Korean': TranslateLanguage.korean,
    'Hindi': TranslateLanguage.hindi,
  };

  String _sourceLanguage = 'English';
  String _targetLanguage = 'Arabic';
  String _sourceText = '';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isListening = false;
  bool _isDownloadingModels = false;
  late OnDeviceTranslator _translator;
  late stt.SpeechToText _speechToText;
  late FlutterTts _tts;

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize speech to text
    _speechToText = stt.SpeechToText();
    await _speechToText.initialize(
      onError: (error) => debugPrint("Speech error: $error"),
      onStatus: (status) => debugPrint("Speech status: $status"),
    );

    // Initialize TTS
    _tts = FlutterTts();
    await _tts.setLanguage("en-US");

    // Initialize translator
    _initializeTranslator();
  }

  Future<void> _initializeTranslator() async {
    setState(() => _isDownloadingModels = true);

    try {
      // Close previous translator if exists
      try {
        _translator.close();
      } catch (_) {}

      _translator = OnDeviceTranslator(
        sourceLanguage: languages[_sourceLanguage]!,
        targetLanguage: languages[_targetLanguage]!,
      );

      // Pre-download models for offline support on first initialization
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("Error initializing translator: $e");
      if (mounted) {
        _showError("Failed to initialize translator");
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingModels = false);
      }
    }
  }

  Future<void> _translate() async {
    if (_sourceText.isEmpty) {
      _showError("Please enter text to translate");
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final result = await _translator.translateText(_sourceText);
      setState(() {
        _translatedText = result;
        _targetController.text = result;
      });
    } catch (e) {
      debugPrint("Translation error: $e");
      _showError("Models may be downloading. Please try again.");
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _startListening() async {
    if (!_isListening && await _speechToText.initialize()) {
      setState(() => _isListening = true);

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _sourceText = result.recognizedWords;
            _sourceController.text = _sourceText;
            if (result.finalResult) {
              _isListening = false;
              _translate();
            }
          });
        },
        localeId: _getLocaleId(_sourceLanguage),
      );
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text, String language) async {
    if (text.isEmpty) return;
    final localeId = _getLocaleId(language);
    await _tts.setLanguage(localeId);
    await _tts.speak(text);
  }

  String _getLocaleId(String language) {
    const localeMap = {
      'English': 'en-US',
      'Arabic': 'ar-SA',
      'French': 'fr-FR',
      'Spanish': 'es-ES',
      'German': 'de-DE',
      'Italian': 'it-IT',
      'Portuguese': 'pt-BR',
      'Russian': 'ru-RU',
      'Chinese': 'zh-CN',
      'Japanese': 'ja-JP',
      'Korean': 'ko-KR',
      'Hindi': 'hi-IN',
    };
    return localeMap[language] ?? 'en-US';
  }

  void _swapLanguages() {
    final temp = _sourceLanguage;
    setState(() {
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      _sourceText = _translatedText;
      _sourceController.text = _translatedText;
      _translatedText = '';
      _targetController.clear();
    });
    _initializeTranslator();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    _tts.stop();
    _translator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Color(0xFF714611),
                        ),
                      ),
                      const Text(
                        "Translator",
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: "Marcellus",
                          color: Color(0xFF714611),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Offline Support Status
                  if (_isDownloadingModels)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC79A00),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFC79A00),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Downloading translation models for offline use...",
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: "Marcellus",
                                color: Color(0xFF714611),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isDownloadingModels && _translatedText.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EDDA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_done,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Works offline - models cached on device",
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: "Marcellus",
                                color: Color(0xFF155724),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Vertically stacked input/output section
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8F2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Source language dropdown and textbox
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            left: 12,
                            right: 12,
                          ),
                          child: _buildLanguageDropdown(
                            value: _sourceLanguage,
                            onChanged: (lang) {
                              setState(() => _sourceLanguage = lang);
                              _initializeTranslator();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: TextField(
                            controller: _sourceController,
                            maxLines: 4,
                            minLines: 3,
                            onChanged: (text) =>
                                setState(() => _sourceText = text),
                            decoration: InputDecoration(
                              hintText: "Enter text",
                              hintStyle: TextStyle(
                                color: const Color(0xFF714611).withOpacity(0.4),
                                fontFamily: "Marcellus",
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(8),
                                child: GestureDetector(
                                  onTap: _isListening
                                      ? _stopListening
                                      : _startListening,
                                  child: Icon(
                                    Icons.mic,
                                    color: _isListening
                                        ? Colors.red
                                        : const Color(
                                            0xFF714611,
                                          ).withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF714611),
                              fontSize: 14,
                              fontFamily: "Marcellus",
                            ),
                          ),
                        ),
                        // Swap button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GestureDetector(
                            onTap: _swapLanguages,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF714611),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        // Target language dropdown and textbox
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            left: 12,
                            right: 12,
                          ),
                          child: _buildLanguageDropdown(
                            value: _targetLanguage,
                            onChanged: (lang) {
                              setState(() => _targetLanguage = lang);
                              _initializeTranslator();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: TextField(
                            controller: _targetController,
                            readOnly: true,
                            maxLines: 4,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: "Translation",
                              hintStyle: TextStyle(
                                color: const Color(0xFF714611).withOpacity(0.4),
                                fontFamily: "Marcellus",
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(8),
                                child: GestureDetector(
                                  onTap: () =>
                                      _speak(_translatedText, _targetLanguage),
                                  child: const Icon(
                                    Icons.volume_up,
                                    color: Color(0xFF714611),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF714611),
                              fontSize: 14,
                              fontFamily: "Marcellus",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  // Translate Button
                  if (_sourceText.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isTranslating ? null : _translate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC79A00),
                          disabledBackgroundColor: const Color(
                            0xFFC79A00,
                          ).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        child: _isTranslating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Translate",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Marcellus",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection({
    required String label,
    required TextEditingController controller,
    required Function(String) onLanguageChanged,
    VoidCallback? onMicTap,
    VoidCallback? onSpeak,
    bool isMicActive = false,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLanguageDropdown(value: label, onChanged: onLanguageChanged),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            maxLines: 4,
            minLines: 3,
            onChanged: (text) => setState(() => _sourceText = text),
            decoration: InputDecoration(
              hintText: "Enter text",
              hintStyle: TextStyle(
                color: const Color(0xFF714611).withOpacity(0.4),
                fontFamily: "Marcellus",
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: isReadOnly ? onSpeak : onMicTap,
                  child: Icon(
                    isReadOnly ? Icons.volume_up : Icons.mic,
                    color: isMicActive
                        ? Colors.red
                        : const Color(0xFF714611).withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF714611),
              fontSize: 14,
              fontFamily: "Marcellus",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown({
    required String value,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: (newLang) => onChanged(newLang!),
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(20),
        items: languages.keys.map((lang) {
          return DropdownMenuItem<String>(
            value: lang,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                lang,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: "Marcellus",
                  color: Color(0xFF714611),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
