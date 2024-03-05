import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// For the testing purposes, you should probably use https://pub.dev/packages/uuid.
String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .evnから環境変数を読み込む
  await dotenv.load(fileName: '.env');
  OpenAI.apiKey = dotenv.get('OPEN_AI_API_KEY');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  final _agent = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac2');
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          // 認識した単語が最終的なものであればリスニングを停止します。
          if (val.finalResult) {
            _handleSendPressed(types.PartialText(text: val.recognizedWords));
            _stopListening();
          }
        }),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<String> sendMessage(String message) async {
    // メッセージをuserロールでモデル化
    final newUserMessage = OpenAIChatCompletionChoiceMessageModel(
      content: message,
      role: OpenAIChatMessageRole.user,
    );

    // ChatGPTに聞く
    final chatCompletion = await OpenAI.instance.chat
        .create(model: 'gpt-3.5-turbo', messages: [newUserMessage]);

    return Future<String>.value(chatCompletion.choices.first.message.content);
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );

    _addMessage(userMessage);

    final response = await sendMessage(message.text);

    final chatgptMessage = types.TextMessage(
      author: _agent,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: response,
    );

    _addMessage(chatgptMessage);
  }
}
