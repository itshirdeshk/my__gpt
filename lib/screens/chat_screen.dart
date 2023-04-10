import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my__gpt/constants.dart';
import 'package:my__gpt/providers/chat_provider.dart';
import 'package:my__gpt/services/assests_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my__gpt/widgets/chat_widget.dart';
import 'package:my__gpt/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../models/models_provider.dart';
import '../services/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTying = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  @override
  void initState() {
    textEditingController = TextEditingController();
    _listScrollController = ScrollController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // List<ChatModel> chatList = [];

  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatsProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
          elevation: 2,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(AssetsManger.openaiImage),
          ),
          title: const Text('My GPT'),
          actions: [
            IconButton(
              onPressed: () async {
                await Services.showModalSheet(context: context);
              },
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
              ),
            )
          ]),
      body: SafeArea(
        child: Column(children: [
          Flexible(
            child: ListView.builder(
                controller: _listScrollController,
                itemCount: chatsProvider.getChatList.length,
                itemBuilder: (context, index) {
                  return ChatWidget(
                    msg: chatsProvider.getChatList[index].msg,
                    chatIndex: chatsProvider.getChatList[index].chatIndex,
                  );
                }),
          ),
          if (_isTying) ...[
            const SpinKitThreeBounce(
              color: Colors.white,
              size: 18,
            ),
          ],
          const SizedBox(height: 15),
          Material(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      controller: textEditingController,
                      onSubmitted: (value) async {
                        await sendMessage(
                          modelsProvider: modelsProvider,
                          chatProvider: ChatProvider(),
                        );
                      },
                      decoration: const InputDecoration.collapsed(
                          hintText: "How can i help you",
                          hintStyle: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await sendMessage(
                        modelsProvider: modelsProvider,
                        chatProvider: chatsProvider,
                      );
                    },
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
      _listScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
    );
  }

  Future<void> sendMessage(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTying) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: TextWidget(
          label: "You can't send multiple messages at a time",
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: TextWidget(
          label: "Please type a message",
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTying = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTying = false;
      });
    }
  }
}
