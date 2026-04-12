// lib/features/dashboard/screens/chat_screen.dart
import 'package:chatbot_ai/chatbot_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_psych/features/activity_tracking/views/activity_tracking_screen.dart';
import 'package:smart_psych/features/phone_usage/views/phone_usage_screen.dart';
import 'package:smart_psych/features/statistics/views/statistics_screen.dart';
import '../../../core/database/models/nav_item_model.dart';
import '../../../shared/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  @override
  Widget build(BuildContext context) => const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatbotAi(
        isCvPending: false,
        title: "المحادثة",
        userData: {},
        language: "ar",
        name: "",
        id: "",
        url: "",
      ),
  );

}