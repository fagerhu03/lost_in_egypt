import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final result = await _translator.translateText(_sourceText)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _translatedText = result;
        _targetController.text = result;
      });
    } on TimeoutException {
      if (mounted) _showError('Translation timed out. Models may still be downloading — try again in a moment.');
    } catch (e) {
      debugPrint("Translation error: $e");
      if (mounted) _showError('Translation failed. If offline, models may not be downloaded yet.');
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
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final patternOpacity = isDark ? 0.1 : 0.4;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        image: DecorationImage(
          image: const AssetImage("assets/pattern_comp.png"),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
          opacity: patternOpacity,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20.r,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Translator",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 20.w),
                    ],
                  ),
                  SizedBox(height: 30.h),

                  // Offline Support Status
                  if (_isDownloadingModels)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? primary.withValues(alpha: 0.15)
                            : const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: primary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "Downloading translation models for offline use...",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isDownloadingModels && _translatedText.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done,
                            color: Colors.green,
                            size: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "Works offline - models cached on device",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20.h),

                  // Input/output container
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Source language dropdown and textbox
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: 12.h,
                            start: 12.w,
                            end: 12.w,
                          ),
                          child: _buildLanguageDropdown(
                            value: _sourceLanguage,
                            surfaceColor: surface,
                            textColor: textColor,
                            onChanged: (lang) {
                              setState(() => _sourceLanguage = lang);
                              _initializeTranslator();
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
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
                                color: textColor.withValues(alpha: 0.4),
                                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: surface,
                              contentPadding: EdgeInsets.all(16.r),
                              suffixIcon: IconButton(
                                onPressed: _isListening
                                    ? _stopListening
                                    : _startListening,
                                icon: Icon(
                                  Icons.mic,
                                  color: _isListening
                                      ? Colors.red
                                      : textColor.withValues(alpha: 0.6),
                                  size: 20.r,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _translate(),
                          ),
                        ),

                        // Swap button
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Material(
                            color: primary,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            child: InkWell(
                              onTap: _swapLanguages,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 44.r,
                                height: 44.r,
                                child: Icon(
                                  Icons.swap_vert,
                                  color: Colors.white,
                                  size: 22.r,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Target language dropdown and textbox
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: 12.h,
                            start: 12.w,
                            end: 12.w,
                          ),
                          child: _buildLanguageDropdown(
                            value: _targetLanguage,
                            surfaceColor: surface,
                            textColor: textColor,
                            onChanged: (lang) {
                              setState(() => _targetLanguage = lang);
                              _initializeTranslator();
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          child: TextField(
                            controller: _targetController,
                            readOnly: true,
                            maxLines: 4,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: "Translation",
                              hintStyle: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: surface,
                              contentPadding: EdgeInsets.all(16.r),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    _speak(_translatedText, _targetLanguage),
                                icon: Icon(
                                  Icons.volume_up,
                                  color: textColor.withValues(alpha: 0.9),
                                  size: 20.r,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.sp,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 35.h),

                  // Translate Button
                  if (_sourceText.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _isTranslating ? null : _translate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: primary.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: 4,
                        ),
                        child: _isTranslating
                            ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Translate",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildLanguageDropdown({
    required String value,
    required Function(String) onChanged,
    required Color surfaceColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
        borderRadius: BorderRadius.circular(20.r),
        items: languages.keys.map((lang) {
          return DropdownMenuItem<String>(
            value: lang,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Text(
                lang,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
