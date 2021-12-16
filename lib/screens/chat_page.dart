import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final docs;

  const ChatPage({Key key, this.docs}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String groupChatId;
  String userID;

  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    getGroupChatId();
    super.initState();
  }

  getGroupChatId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    userID = sharedPreferences.getString('id');

    String anotherUserId = widget.docs['id'];

    if (userID.compareTo(anotherUserId) > 0) {
      groupChatId = '$userID - $anotherUserId';
    } else {
      groupChatId = '$anotherUserId - $userID';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.redAccent),
        title: const Text(
          "ChatPage",
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.redAccent,
            fontSize: 25.0,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Column(
              children: <Widget>[
                Expanded(
                    child: ListView.builder(
                  controller: scrollController,
                  itemBuilder: (listContext, index) =>
                      buildItem(snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                  reverse: true,
                )),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.redAccent,
                        decoration: const InputDecoration(
                          hintText: 'Type something...',
                          focusColor: Colors.redAccent,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                        ),
                        controller: textEditingController,
                      ),
                    ),
                    IconButton(
                      highlightColor: Colors.white,
                      hoverColor: Colors.white,
                      focusColor: Colors.white,
                      splashColor: Colors.redAccent,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => sendMsg(),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return const Center(
                child: SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ));
          }
        },
      ),
    );
  }

  sendMsg() {
    String msg = textEditingController.text.trim();

    if (msg.isNotEmpty) {
      textEditingController.clear();
      print('thisiscalled $msg');
      var ref = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(ref, {
          "senderId": userID,
          "anotherUserId": widget.docs['id'],
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          'content': msg,
          "type": 'text',
        });
      });
      scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 100), curve: Curves.bounceInOut);
    } else {
      print('Please enter some text to send');
    }
  }

  buildItem(doc) {
    return Padding(
      padding: EdgeInsets.only(
          top: 4.0,
          left: ((doc['senderId'] == userID) ? 120 : 5),
          right: ((doc['senderId'] == userID) ? 5 : 120)),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: ((doc['senderId'] == userID)
                ? const Color(0xFFF1EEEE)
                : const Color(0xFFFDA9A9) ),
            borderRadius: BorderRadius.circular(10.0),

        ),
        child: (doc['type'] == 'text')
            ? Text(
                '${doc['content']}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              )
            : Image.network(doc['content']),
      ),
    );
  }
}
