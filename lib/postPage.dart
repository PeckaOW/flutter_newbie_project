import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostPage extends StatelessWidget {
  PostPage(
      {super.key,
      required this.title,
      required this.contents,
      required this.userID,
      required this.price,
      required this.rating,
      required this.postID});

  final String title; // Title
  final String contents; // Contents
  final String userID; // User ID
  final int price; // Product price
  final double rating; //Rating of User
  final String postID; //Special ID of this post

  String formatNum(int num) {
    if (num >= 1000000) {
      return '${num ~/ 1000000},${(num ~/ 1000) % 1000},${num % 1000}';
    } else if (num >= 1000) {
      return '${num ~/ 1000},${num % 1000}';
    } else {
      return num.toString();
    }
  }
  //가격에 comma표시 해주는 함수 (1억원까지만 가능)

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    final imageUrl = postID; // URL of the image in Firebase storage

    Future<String> getUserID(String? myEmail) async {
      String myID = '';

      try {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('_userinfo')
            .doc(myEmail)
            .get();

        if (documentSnapshot.exists) {
          Map<String, dynamic> data =
              documentSnapshot.data() as Map<String, dynamic>; // Corrected line
          myID = data['userid'] ?? '';
        } else {
          // Handle the case where the document does not exist
          print("Document not found");
        }
      } catch (e) {
        // Handle any errors here
        print("Error fetching document: $e");
      }

      return myID;
    }

    Future<void> makeAcceptedRequest() async {
      String errorMessage = '';

      if (user == null) {
        errorMessage = 'Not Logged In for Some Reason!';
      } else {
        try {
          await FirebaseFirestore.instance
              .collection('_posts')
              .doc(postID)
              .set({
            "acceptedBy": user.email,
            "acceptedID": await getUserID(user.email),
            "state": 'In Progress',
          }, SetOptions(merge: true));
          errorMessage = 'Task Accepted!';
        } catch (e) {
          errorMessage = e.toString();
        }
      }

      final snackBar = SnackBar(content: Text(errorMessage));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop()),
        title: Text(
            '$userID (Rating : ${rating.toStringAsFixed(1)})'), //Rating only to 1st decimal
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FutureBuilder<String>(
              future: _loadImage(imageUrl),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading image');
                } else if (snapshot.hasData) {
                  return Image.network(snapshot.data!);
                } else {
                  return const Text('No data available');
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                contents,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            /*
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('User ID: $userID'),
            ),
            */
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Price : ₩ ${formatNum(price)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      //아래에 showModalBottomSheet에서 accept 확정!
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: 200,
                            color: Colors.orange,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Text(
                                      'Are you sure you want to continue?'),
                                  ElevatedButton(
                                    child: const Text('Accept Request'),
                                    onPressed: () => makeAcceptedRequest(),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Accept Simbureum'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _loadImage(String imageUrl) async {
    final ref = FirebaseStorage.instance.ref().child(imageUrl);
    return await ref.getDownloadURL();
  }
}
