import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessengerPage extends HookWidget {
  MessengerPage(
      {super.key,
      required this.postID,
      required this.myID,
      required this.otherID});

  final String postID;
  final String myID;
  final String otherID;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final messageText = useState('');

    final documentStream = useMemoized(() => FirebaseFirestore.instance
        .collection('_messages')
        .doc(postID)
        .snapshots());
    final snapshot = useStream(documentStream);

    void sendMessage() async {
      if (messageText.value.isNotEmpty) {
        var messages =
            snapshot.data?.data()?['messages'] as List<dynamic>? ?? [];
        messages.add({
          'message': messageText.value,
          'user': myID,
        });

        await FirebaseFirestore.instance
            .collection('messages')
            .doc(postID)
            .set({'messages': messages}, SetOptions(merge: true));

        messageText.value = ''; // Clear the text field after sending
        textEditingController.clear();
      }
    }

    void completeDeal() async {
      String errorMessage = '';

      try {
        await FirebaseFirestore.instance.collection('_posts').doc(postID).set({
          "state": 'Complete',
        });
        errorMessage = 'Task Ended!';
      } catch (e) {
        errorMessage = e.toString();
      }

      final snackBar = SnackBar(content: Text(errorMessage));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: Text('Error: ${snapshot.error}')),
      );
    }

    final messages = snapshot.data?.data()?['messages'] as List<dynamic> ?? [];

    final acceptedID = snapshot.data?.data()?['acceptedBy'] as String ?? '';

    final requestedID = snapshot.data?.data()?['requestedBy'] as String ?? '';

    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop()),
            centerTitle: true,
            title: Text('Messages with $otherID')),
        body: Column(
          children: [
            if (requestedID == myID)
              Center(
                  child: IconButton(
                icon: const Icon(Icons.check),
                onPressed: completeDeal,
              )),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMine = message['user'] == myID;

                  return ListTile(
                    title: Align(
                      alignment:
                          isMine ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.orange : Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      onChanged: (value) => messageText.value = value,
                      decoration: InputDecoration(
                        hintText: 'Enter a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
