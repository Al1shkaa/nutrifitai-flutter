import 'package:flutter/material.dart';
import '../../models/message.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final List<Message> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
    });

    controller.clear();
    scrollToBottom();

    // имитация ответа ИИ (позже заменим на API)
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        messages.add(Message(
          text: _generateAiResponse(text),
          isUser: false,
        ));
      });

      scrollToBottom();
    });
  }

  String _generateAiResponse(String userText) {
    // временный ИИ-ответ (переделаем в API)
    if (userText.toLowerCase().contains("кал")) {
      return "Сегодня ты получил примерно 1850 ккал. Отличный баланс!";
    }

    if (userText.toLowerCase().contains("трен")) {
      return "Рекомендую: присед – 3×12, жим – 3×10, бег – 15 мин.";
    }

    return "Я понял тебя! Скоро добавим настоящий ИИ-ответ от NutriFit AI.";
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriFit AI Assistant"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final align = m.isUser ? Alignment.centerRight : Alignment.centerLeft;
                final color = m.isUser ? Colors.blue : Colors.grey.shade300;
                final textColor = m.isUser ? Colors.white : Colors.black;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  alignment: align,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),

          // input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(
                top: BorderSide(color: Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Введите запрос...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
