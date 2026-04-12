import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api_config.dart';
import 'clear_cache_dialog.dart';
import 'flutter_chat_ui.dart';
import 'src/extensions/context_extensions.dart';

class ChatbotAi extends StatefulWidget {
  final String language;
  final String name;
  final String title;
  final String url;
  final String id;
  final bool isCvPending;
  final Map<String, dynamic> userData;

  const ChatbotAi({
    super.key,
    required this.language,
    required this.title,
    required this.userData,
    required this.isCvPending,
    required this.id,
    required this.name,
    required this.url,
  });

  @override
  State<ChatbotAi> createState() => _ChatbotAiState();
}

class _ChatbotAiState extends State<ChatbotAi> {
  bool _isDisposed = false;
  StreamSubscription? _streamSubscription;
  final Map<String, ChatSession> sessions = {};
  Timer? _chatTimer;
  int _remainingSeconds = 600; // 10 minutes
  DateTime? _lastChatDate;
  bool _isTimerActive = false;

  String messages = '';
  List<types.Message> _messages = [];
  bool isSend = true;
  String sessionId = '';
  bool isNewLine = true;
  types.User? _user;
  bool _isWaitingForResponse = false;
  int _retryAttempts = 0;
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const int BASE_RETRY_DELAY = 2;

  // ✅ إضافة رابط واتساب
  static const String WHATSAPP_LINK = 'https://wa.me/96170123456';

  @override
  void initState() {
    super.initState();
    getInit();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chatTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> getInit() async {
    if (_isDisposed) return;
    await _initializeWithFirstTimeClear().then((_) {
      // ✅ تعديل: استخدام _sendWelcomeMessage بدل _sendInitialResumeMessage
      if (!_isDisposed && widget.isCvPending == false) {
        _sendWelcomeMessage();
      }
    });
    if (!_isDisposed) {
      await initializeTimer();
    }
  }

  // ✅ دالة جديدة: رسالة ترحيب بسيطة
  Future<void> _sendWelcomeMessage() async {
    if (_isDisposed) return;
    if (_messages.isEmpty) {
      final String welcomeMessage = widget.language == 'ar'
          ? 'مرحباً! أنا Smart Psych Companion، مرافقك اليومي للدعم النفسي. كيف يمكنني مساعدتك اليوم؟'
          : 'Hello! I\'m Smart Psych Companion, your daily mental health support companion. How can I help you today?';

      if (!_isDisposed) {
        final botMessage = types.TextMessage(
          author: types.User(
            id: '1',
            firstName: 'Smart Psych',
            lastName: '',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: welcomeMessage,
        );
        _addMessage(botMessage, true);
        await saveFullConversation();
      }
    }
  }

  Future<void> clearCache() async {
    if (_isDisposed) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();
      final String currentDate = '${now.year}-${now.month}-${now.day}';

      await prefs.remove('messages_$currentDate');
      await prefs.remove('session_$currentDate');
      await prefs.remove(currentDate);

      sessions.clear();
      sessionId = _generateSessionId();

      if (mounted && !_isDisposed) {
        setState(() {
          _messages = [];
        });
      }

      // ✅ تعديل: استخدام _sendWelcomeMessage
      if (!_isDisposed) {
        await _sendWelcomeMessage();
      }
    } catch (e) {
      if (!_isDisposed) {
        _showErrorMessage(
            'خطأ في مسح الذاكرة المؤقتة',
            'Error clearing cache'
        );
      }
    }
  }

  Future<void> initializeTimer() async {
    if (_isDisposed) return;
    final prefs = await SharedPreferences.getInstance();
    final lastChatDateStr = prefs.getString('last_chat_date');
    final remainingTime = prefs.getInt('remaining_time') ?? 600;

    if (lastChatDateStr != null) {
      _lastChatDate = DateTime.parse(lastChatDateStr);
      final now = DateTime.now();

      if (_lastChatDate!.day != now.day ||
          _lastChatDate!.month != now.month ||
          _lastChatDate!.year != now.year) {
        _remainingSeconds = 600;
        _lastChatDate = now;
        await prefs.setInt('remaining_time', _remainingSeconds);
        await prefs.setString('last_chat_date', now.toIso8601String());
      } else {
        _remainingSeconds = remainingTime;
      }
    } else {
      _lastChatDate = DateTime.now();
      await prefs.setString('last_chat_date', _lastChatDate!.toIso8601String());
      await prefs.setInt('remaining_time', _remainingSeconds);
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void startTimer() {
    if (_remainingSeconds <= 0 || _isTimerActive || _isDisposed) return;

    _isTimerActive = true;
    _chatTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isTimerActive = false;
        isSend = false;
        _showTimeUpMessage();
        return;
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _remainingSeconds--;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('remaining_time', _remainingSeconds);
    });
  }

  void _showTimeUpMessage() {
    if (_isDisposed) return;
    _showErrorMessage(
        'انتهى وقت المحادثة اليومي (10 دقائق). يمكنك المحاولة غداً',
        'Daily chat time limit reached (10 minutes). Try again tomorrow'
    );
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadMessagesFromPreferences() async {
    if (_isDisposed) return;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String currentDate = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

      final List<String>? messageList = prefs.getStringList('messages_$currentDate');
      if (messageList != null && messageList.isNotEmpty) {
        _messages = messageList.map((msgStr) {
          try {
            return types.Message.fromJson(jsonDecode(msgStr));
          } catch (e) {
            print('Error parsing message: $e');
            return null;
          }
        }).whereType<types.Message>().toList();
      }

      final String? sessionStr = prefs.getString('session_$currentDate');
      if (sessionStr != null) {
        final sessionData = jsonDecode(sessionStr);
        sessionId = sessionData['sessionId'];
        final ChatSession session = ChatSession(sessionId);
        session.messages = List<Map<String, String>>.from(
            sessionData['messages'].map((m) => Map<String, String>.from(m))
        );
        session.currentLanguage = sessionData['currentLanguage'];
        sessions[sessionId] = session;
      } else {
        sessionId = _generateSessionId();
      }

      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading conversation: $e');
      if (!_isDisposed) {
        sessionId = _generateSessionId();
      }
    }
  }

  Future<void> _initializeWithFirstTimeClear() async {
    if (_isDisposed) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (isFirstTime && !_isDisposed) {
        await clearCache();
        await prefs.setBool('is_first_time', false);
      }

      if (!_isDisposed) {
        await loadMessagesFromPreferences();
        if (sessionId.isEmpty) {
          sessionId = _generateSessionId();
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        _showErrorMessage(
            'حدث خطأ في تهيئة التطبيق',
            'Error initializing the app'
        );
      }
    }
  }

  Future<void> saveFullConversation() async {
    if (_isDisposed) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String currentDate = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

      final List<String> messageList = _messages.map((msg) => jsonEncode(msg.toJson())).toList();
      await prefs.setStringList('messages_$currentDate', messageList);

      final ChatSession currentSession = sessions[sessionId]!;
      final Map<String, dynamic> sessionData = {
        'sessionId': sessionId,
        'messages': currentSession.messages,
        'currentLanguage': currentSession.currentLanguage,
      };
      await prefs.setString('session_$currentDate', jsonEncode(sessionData));
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (!isSend || _isWaitingForResponse || _remainingSeconds <= 0 || _isDisposed) return;

    if (!_isTimerActive) {
      startTimer();
    }

    final textMessage = types.TextMessage(
      author: _user!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
      remoteId: sessionId,
    );

    if (mounted && !_isDisposed) {
      setState(() {
        isSend = false;
        _isWaitingForResponse = true;
      });
    }

    try {
      messages = '';
      await sendMessage(message.text);
    } catch (e) {
      if (!_isDisposed) {
        _showErrorMessage(
            'حدث خطأ في إرسال الرسالة',
            'Error sending message'
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          isSend = true;
          _isWaitingForResponse = false;
        });
      }
    }
  }

  void _addMessage(types.Message? message, bool isNewLine) {
    if (message != null && mounted && !_isDisposed) {
      setState(() {
        if (isNewLine) {
          _messages = [message, ..._messages];
        } else {
          if (_messages.isNotEmpty) {
            _messages = [message, ..._messages.sublist(1)];
          } else {
            _messages = [message];
          }
        }
      });
    }
  }

  Future<void> sendMessage(String message, {bool showUserMessage = true}) async {
    if (_isDisposed) return;
    if (message.isEmpty || _remainingSeconds <= 0) {
      _showTimeUpMessage();
      return;
    }

    final String idUUID = const Uuid().v4();
    String fullResponse = '';
    bool responseReceived = false;

    if (showUserMessage && !_isDisposed) {
      final userMessage = types.TextMessage(
        author: _user!,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: message,
        remoteId: sessionId,
      );
      _addMessage(userMessage, true);

      if (!_isDisposed) {
        final ChatSession currentSession = getSession(sessionId);
        currentSession.addUserMessage(message);
        await saveFullConversation();
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // ✅ تعديل: تغيير اسم البوت
    if (!_isDisposed) {
      final textMessage = types.TextMessage(
        author: types.User(
          id: '1',
          firstName: 'Smart Psych',
          lastName: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: idUUID,
        text: '',
      );
      _addMessage(textMessage, true);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      final String detectedLanguage = await detectMessageLanguage(message);
      if (_isDisposed) return;

      final Stream<String> responseStream = await getMessageFromChatGPT(
        message,
        detectedLanguage,
        widget.userData,
        sessionId,
      );

      _streamSubscription?.cancel();
      _streamSubscription = responseStream.listen(
            (response) async {
          if (_isDisposed) {
            _streamSubscription?.cancel();
            return;
          }

          if (_remainingSeconds <= 0) {
            _streamSubscription?.cancel();
            _showTimeUpMessage();
            return;
          }

          if (response.startsWith('ERROR:')) {
            _streamSubscription?.cancel();
            _showErrorMessage(response.substring(6), response.substring(6));
            return;
          }

          fullResponse += response;

          if (!_isDisposed) {
            // ✅ تعديل: تغيير اسم البوت
            final updatedMessage = types.TextMessage(
              author: types.User(
                id: '1',
                firstName: 'Smart Psych',
                lastName: '',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
              id: idUUID,
              text: fullResponse,
            );

            _addMessage(updatedMessage, false);
            await Future.delayed(const Duration(milliseconds: 50));
            responseReceived = true;
            _retryAttempts = 0;
          }
        },
        onError: (error) async {
          if (_isDisposed) return;

          if (_retryAttempts < MAX_RETRY_ATTEMPTS && _remainingSeconds > 0) {
            _retryAttempts++;
            _showErrorMessage(
                'حدث خطأ، جاري إعادة المحاولة...',
                'Error occurred, retrying...'
            );
            await Future.delayed(Duration(seconds: BASE_RETRY_DELAY * pow(2, _retryAttempts - 1).toInt()));
            if (_remainingSeconds > 0 && !_isDisposed) {
              await sendMessage(message, showUserMessage: showUserMessage);
            }
          } else {
            _showErrorMessage(
                'تعذر الاتصال بالخادم. الرجاء المحاولة لاحقاً',
                'Could not connect to server. Please try again later'
            );
          }
        },
        onDone: () async {
          if (_isDisposed) return;

          if (!responseReceived && !_isDisposed) {
            _showErrorMessage(
                'لم نتلق استجابة. الرجاء المحاولة مرة أخرى',
                'No response received. Please try again'
            );
          } else if (fullResponse.isNotEmpty && !_isDisposed) {
            final ChatSession currentSession = getSession(sessionId);
            currentSession.addAssistantMessage(fullResponse);
            await saveFullConversation();
          }

          if (mounted && !_isDisposed) {
            setState(() {
              messages = '';
              isSend = _remainingSeconds > 0;
              _isWaitingForResponse = false;
            });
          }
          _streamSubscription?.cancel();
        },
      );
    } catch (e) {
      if (_isDisposed) return;

      _showErrorMessage(
          'تعذر الاتصال بالخادم. الرجاء المحاولة لاحقاً',
          'Could not connect to server. Please try again later'
      );
    }
  }
  Future<Stream<String>> getMessageFromChatGPT(
      String message1,
      String language,
      Map<String, dynamic> resume,
      String sessionId,
      ) async {
    if (_isDisposed) return Stream.value('');

    int retryCount = 0;
    const maxRetries = 3;

    Future<http.StreamedResponse> makeRequest() async {
      final ChatSession session = getSession(sessionId);

      if (session.currentLanguage != language) {
        if (session.messages.isNotEmpty && session.messages[0]['role'] == 'system') {
          session.messages[0] = {
            'role': 'system',
            'content': getSystemPrompt(language),
          };
        } else {
          session.messages.insert(0, {
            'role': 'system',
            'content': getSystemPrompt(language),
          });
        }
        session.currentLanguage = language;
      }

      session.addUserMessage(message1);

      if (session.messages.length > 12) {
        final systemMessage = session.messages.first;
        session.messages = [
          systemMessage,
          ...session.messages.sublist(session.messages.length - 6)
        ];
      }

      final request = http.Request(
        'POST',
        Uri.parse('https://api.openai.com/v1/chat/completions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${AiConfig.apiKey}',
        'Content-Type': 'application/json; charset=UTF-8',
      });

      request.body = jsonEncode({
        'model': 'gpt-4',
        'messages': session.messages,
        'temperature': 0.7,
        'max_tokens': 1000, // ✅ تعديل: من 800 إلى 1000
        'top_p': 1,
        'frequency_penalty': 0,
        'presence_penalty': 0,
        'stream': true,
      });

      return await request.send();
    }

    while (retryCount < maxRetries && !_isDisposed) {
      try {
        final response = await makeRequest();

        if (response.statusCode == 429) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw HttpException('Rate limit exceeded. Please try again later.');
          }

          final waitSeconds = BASE_RETRY_DELAY * pow(2, retryCount - 1);
          await Future.delayed(Duration(seconds: waitSeconds.toInt()));
          continue;
        }

        if (response.statusCode != 200) {
          throw HttpException('Server returned ${response.statusCode}');
        }

        return response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .where((line) => line.startsWith('data: '))
            .map<String>((line) {
          if (_isDisposed) return '';
          if (line.startsWith('data: [DONE]')) return '';

          try {
            final data = jsonDecode(line.substring(6));
            final content = data['choices']?[0]?['delta']?['content'] ?? '';

            if (!_isDisposed) {
              getSession(sessionId).lastResponseContent =
                  (getSession(sessionId).lastResponseContent ?? '') + content;
            }
            return content;
          } catch (e) {
            print('Error parsing response: $e');
            return '';
          }
        });

      } catch (e, stackTrace) {
        if (_isDisposed) return Stream.value('');

        if (retryCount >= maxRetries - 1) {
          final errorDetails = '''
Error Type: ${e.runtimeType}
Error Details: ${e.toString()}
Stack Trace:
${stackTrace.toString()}
''';

          String errorMessage;
          if (e is TimeoutException) {
            errorMessage = language == 'ar'
                ? 'انتهت مهلة الاتصال. الرجاء المحاولة مرة أخرى'
                : 'Connection timed out. Please try again';
          } else if (e is HttpException && e.toString().contains('429')) {
            errorMessage = language == 'ar'
                ? 'تم تجاوز حد الطلبات المسموح به. الرجاء المحاولة بعد قليل'
                : 'Rate limit exceeded. Please try again later';
          } else {
            errorMessage = language == 'ar'
                ? 'حدث خطأ في الاتصال. الرجاء المحاولة بعد قليل'
                : 'Connection error. Please try again later';
          }

          return Stream.value('ERROR:$errorMessage\n$errorDetails');
        }

        retryCount++;
        final waitSeconds = BASE_RETRY_DELAY * pow(2, retryCount - 1);
        await Future.delayed(Duration(seconds: waitSeconds.toInt()));
      }
    }

    return Stream.value('ERROR:Unexpected error occurred');
  }

  // ✅ البرومبت الجديد الكامل للصحة النفسية
  String getSystemPrompt(String language) {
    if (language == 'ar') {
      return '''أنت "Smart Psych Companion" مرافق يومي داعم للصحة النفسية داخل تطبيق Smart Psych.
مهمتك تقديم دعم نفسي أولي وتثقيف بسيط وتمارين خفيفة تساعد المستخدم على تهدئة نفسه وفهم مشاعره.
أنت لست طبيباً ولا معالجاً بديلاً ولا تقدم تشخيصاً ولا أدوية ولا تعد بنتائج علاجية.

أسلوبك
تكلم بالعربية المبسطة القريبة من لهجة المستخدم. إذا كان المستخدم يكتب فصحى استخدم فصحى مبسطة، وإذا كان يكتب بلهجة استخدم لهجة محترمة وخفيفة.
كن إنسانياً ودوداً وقريباً، لكن بنبرة أقرب لمختص نفسي من حيث الهدوء والاحتواء.
تجنب اللغة الآلية أو العبارات العامة الفارغة.
لا تقدم أكثر من فكرة أو تمرين واحد في الرد الواحد.
طول الرد ديناميكي حسب الحاجة لكن لا يتجاوز 5 جمل كحد أقصى.
إذا احتاج المستخدم تفاصيل إضافية، قسمها على رسائل قصيرة متتابعة.
اسأل سؤالاً واحداً واضحاً في نهاية الرد فقط عند الحاجة.

قواعد أمان وحدود واضحة
ممنوع التشخيص: لا تقل "أنت مكتئب" أو "عندك اضطراب". استخدم صيغاً مثل "من كلامك يبدو أنك تمر بضيق" أو "قد يكون هذا شعور تعب".
ممنوع الأدوية: لا تقترح أدوية أو جرعات أو بدائل طبية. إذا سأل المستخدم عن دواء، وضّح أن هذا يحتاج مختصاً طبياً ووجّهه للمتابعة المناسبة.
الخصوصية: لا تطلب معلومات شخصية حساسة. إذا ذكرها المستخدم، تعامل معها بحذر وركز فقط على الدعم النفسي.
تجنب الحكم أو اللوم أو التقليل من المشاعر. لا تستخدم التخويف أو التهويل.

طريقة المحادثة العلاجية المختصرة
1) اعكس المشاعر باحتواء مع تسمية إحساس واحد فقط مثل: "واضح إنك حاسس بتعب وضغط".
2) عند وجود مؤشرات خطر، تحقق من الأمان بسؤال واحد مباشر ولطيف.
3) قدم خطوة واحدة قابلة للتطبيق الآن فقط.
4) عزز الإحساس بالقدرة والدعم مثل: "مو لازم تمر بهالشي لحالك".
5) اختم بسؤال واحد بسيط عند الحاجة مثل: "متى بدأ هذا الشعور؟" أو "كيف كان نومك آخر يومين؟"

تمارين مسموحة ومقترحة
تنفس 4-6: شهيق 4 ثواني وزفير 6 ثواني لمدة دقيقة.
Box Breathing: شهيق 4 ثواني، حبس 4، زفير 4، حبس 4. كرر 4 إلى 5 مرات.
Progressive Muscle Relaxation (PMR): شد عضلة 5 ثواني ثم إرخاؤها 10 ثواني، من القدم للرأس.
Grounding 5-4-3-2-1: 
5 أشياء تراها، 4 تسمعها، 3 تحسها بجسمك، 2 تشمها، 1 تتذوقها.
Self-Compassion Break: ترديد جملة داخلية مثل "هذا وقت صعب، طبيعي أحس بهالمشاعر، وأنا أستحق التعاطف".
Behavioral Activation: اختيار خطوة بسيطة جداً خلال 15 دقيقة مثل شرب ماء، مشي 5 دقائق، أو مكالمة قصيرة.
تفريغ كتابي دقيقتين: ماذا أشعر الآن؟ ماذا أحتاج في هذه اللحظة؟

إرشادات استخدام التمارين
اختر تمريناً واحداً فقط في الرد الواحد.
اربط التمرين مباشرة بما يشعر به المستخدم.
لا تفرض التمرين، قدّمه كاقتراح لطيف.
اسأل بعد التمرين سؤالاً قصيراً مثل: "كيف حاسس الآن؟"

بروتوكول الحالات الخطرة والتصعيد التدريجي
اعتبر الحالة خطرة إذا ظهر أي مما يلي:
نية لإيذاء النفس أو الانتحار، وجود خطة أو وسيلة، وداع أو يأس شديد، إيذاء للآخرين، فقدان واضح للاتصال بالواقع، عنف مباشر، أو خطر فوري.

عند الاشتباه بالخطر:
أ) احتوِ المستخدم فوراً بجملتين هادئتين.
ب) اسأل سؤال أمان واحد فقط:
"هل عندك نية الآن تؤذي نفسك أو عندك خطة أو وسيلة؟"

إذا كان الخطر فوري أو المستخدم أجاب بنعم:
اطلب منه فوراً التواصل مع خدمات الطوارئ المحلية أو شخص قريب منه الآن.
بعدها مباشرة، وجّهه للتواصل مع فريق Smart Psych دون انتظار.

إذا كان الخطر غير فوري أو غير واضح:
قدّم تهدئة قصيرة أو تمرين بسيط.
شجّعه على التواصل مع الفريق كخطوة دعم إضافية.
اطلب منه تأكيد أنه الآن في مكان آمن.

قنوات تحويل المستخدم للفريق البشري
عند الحالات الخطرة، أو طلب مساعدة متخصصة، أو استمرار أعراض شديدة:
وجّه المستخدم للتواصل مع فريق Smart Psych عبر:
Email: mbmabadie@gmail.com
WhatsApp: استخدم رابط واتساب من متغير WHATSAPP_LINK في إعدادات التطبيق.

قالب رد جاهز للحالات الخطرة
"أنا سامعك، وواضح إنك بتمر بضغط قوي ومؤلم. قبل أي شيء، هل عندك نية الآن تؤذي نفسك أو عندك خطة أو وسيلة؟
إذا حاسس إن الخطر قريب، تواصل فوراً مع الطوارئ في بلدك أو شخص قريب منك الآن.
وبنفس الوقت، راسل فريقنا حالاً على البريد أو الواتساب عشان نوصلّك بمختص."''';
    } else {
      // النسخة الإنجليزية
      return '''You are "Smart Psych Companion," a daily supportive mental health companion within the Smart Psych app.
Your mission is to provide initial psychological support, simple education, and light exercises to help users calm themselves and understand their feelings.
You are not a doctor, therapist replacement, and do not provide diagnoses, medications, or promise therapeutic outcomes.

Your Style
Speak in simple English that feels natural and approachable. Be human, friendly, and close, with a tone closer to a mental health professional in terms of calmness and containment.
Avoid robotic language or empty generic phrases.
Provide no more than one idea or exercise per response.
Response length is dynamic based on need but should not exceed 5 sentences maximum.
If the user needs additional details, break them into short sequential messages.
Ask only one clear question at the end of the response when needed.

Safety Rules and Clear Boundaries
No diagnosis: Don't say "You're depressed" or "You have a disorder." Use phrases like "From what you're saying, it seems you're going through distress" or "This might be a feeling of fatigue."
No medications: Don't suggest medications, dosages, or medical alternatives. If the user asks about medication, clarify that this requires a medical professional and direct them to appropriate follow-up.
Privacy: Don't request sensitive personal information. If the user mentions it, handle it carefully and focus only on psychological support.
Avoid judgment, blame, or minimizing feelings. Don't use fear or exaggeration.

Brief Therapeutic Conversation Method
1) Reflect feelings with containment, naming only one emotion like: "It's clear you're feeling tired and stressed."
2) When there are risk indicators, check for safety with one direct, gentle question.
3) Provide one actionable step that can be applied right now only.
4) Reinforce the sense of capability and support like: "You don't have to go through this alone."
5) End with one simple question when needed like: "When did this feeling start?" or "How has your sleep been the last two days?"

Allowed and Suggested Exercises
4-6 Breathing: Inhale 4 seconds, exhale 6 seconds for one minute.
Box Breathing: Inhale 4 seconds, hold 4, exhale 4, hold 4. Repeat 4-5 times.
Progressive Muscle Relaxation (PMR): Tense a muscle for 5 seconds then relax it for 10 seconds, from feet to head.
5-4-3-2-1 Grounding: 
5 things you see, 4 you hear, 3 you feel in your body, 2 you smell, 1 you taste.
Self-Compassion Break: Repeat an internal phrase like "This is a difficult time, it's normal to feel these emotions, and I deserve compassion."
Behavioral Activation: Choose a very simple step within 15 minutes like drinking water, walking 5 minutes, or a short call.
Two-minute writing release: What do I feel now? What do I need at this moment?

Exercise Usage Guidelines
Choose only one exercise per response.
Link the exercise directly to what the user is feeling.
Don't impose the exercise; present it as a gentle suggestion.
Ask a short question after the exercise like: "How are you feeling now?"

Crisis and Escalation Protocol
Consider the situation critical if any of the following appears:
Intent to harm self or suicide, having a plan or means, farewell or severe hopelessness, harm to others, clear loss of contact with reality, direct violence, or immediate danger.

When suspecting danger:
a) Contain the user immediately with two calm sentences.
b) Ask one safety question only:
"Do you currently have an intention to harm yourself or do you have a plan or means?"

If danger is immediate or user answered yes:
Immediately ask them to contact local emergency services or someone close to them now.
Right after that, direct them to contact the Smart Psych team without waiting.

If danger is not immediate or unclear:
Provide short calming or a simple exercise.
Encourage them to contact the team as an additional support step.
Ask them to confirm they are currently in a safe place.

Referral Channels to Human Team
In critical cases, request for specialized help, or persistent severe symptoms:
Direct the user to contact the Smart Psych team via:
Email: mbmabadie@gmail.com
WhatsApp: Use the WhatsApp link from the WHATSAPP_LINK variable in the app settings.

Ready Response Template for Critical Cases
"I hear you, and it's clear you're going through intense and painful pressure. First, do you currently have an intention to harm yourself or do you have a plan or means?
If you feel danger is near, immediately contact emergency services in your country or someone close to you now.
At the same time, message our team right away via email or WhatsApp so we can connect you with a specialist."''';
    }
  }

  Future<String> detectMessageLanguage(String message) async {
    final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegExp.hasMatch(message)) {
      return 'ar';
    }
    return 'en';
  }

  // ✅ تعديل: تغيير اسم البوت
  void _showErrorMessage(String arMessage, String enMessage) {
    if (_isDisposed) return;
    _addMessage(
      types.TextMessage(
        author: types.User(
          id: '1',
          firstName: 'Smart Psych',
          lastName: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: widget.language == 'ar' ? arMessage : enMessage,
      ),
      true,
    );
  }

  String _generateSessionId() {
    final random = Random();
    return String.fromCharCodes(List.generate(10, (index) => random.nextInt(33) + 89));
  }

  ChatSession getSession(String sessionId) {
    return sessions.putIfAbsent(sessionId, () => ChatSession(sessionId));
  }

  @override
  Widget build(BuildContext context) {
    _user ??= types.User(
      id: widget.id,
      firstName: widget.name,
      imageUrl: widget.url,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                formatTime(_remainingSeconds),
                style: TextStyle(
                  color: _remainingSeconds <= 60 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.black),
            onPressed: () async {
              if (_isDisposed) return;
              await showDialog(
                context: context,
                builder: (context) => ClearCacheDialog(
                  title: widget.language == 'ar'?"حذف المحادثات":"Delete conversations",
                  subTitle: widget.language == 'ar'?"هل أنت متأكد؟":"Are you sure?",
                  confirmText: widget.language == 'ar'?"موافق":"Ok",
                  cancelText: widget.language == 'ar'?"إلغاء الأمر":"Cancel",
                  onConfirm: () async {
                    if (_isDisposed) return;
                    context.pop();
                    await clearCache();
                    if (mounted && !_isDisposed) {
                      setState(() {});
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_remainingSeconds <= 60 && _remainingSeconds > 0)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.1),
              child: Text(
                widget.language == 'ar'
                    ? 'تحذير: باقي أقل من دقيقة على انتهاء وقت المحادثة'
                    : 'Warning: Less than a minute remaining',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Chat(
              l10n: widget.language == 'en' ? const ChatL10nEn() : const ChatL10nAr(),
              messages: _messages,
              isSend: isSend && _remainingSeconds > 0,
              onAttachmentPressed: () {},
              onMessageTap: (_, __) {},
              onPreviewDataFetched: (_, __) {},
              onSendPressed: _handleSendPressed,
              showUserAvatars: true,
              showUserNames: true,
              user: _user!,
            ),
          ),

          SizedBox(
            height: 150.h,)
        ],
      ),
    );
  }
}

class ChatSession {
  final String sessionId;
  List<Map<String, String>> messages;
  String? currentLanguage;
  String? lastResponseContent;

  ChatSession(this.sessionId) : messages = [];

  void updateLanguage(String language) {
    currentLanguage = language;
  }

  void clearMessages() {
    messages.clear();
    lastResponseContent = null;
  }

  void addSystemMessage(String content) {
    messages.add({
      'role': 'system',
      'content': content,
    });
  }

  void addUserMessage(String content) {
    messages.add({
      'role': 'user',
      'content': content,
    });
  }

  void addAssistantMessage(String content) {
    messages.add({
      'role': 'assistant',
      'content': content,
    });
  }
}