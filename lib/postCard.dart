import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'main.dart';
import 'postPage.dart';

//이건 update되야 하는 My posts, accepted가 아닌 postcard들! --> 따로 active PostCard 정의할 것! --> 또한 state update할 때에는 함수를 parameter로 가져와서 그 함수 내부에서 updated 변수 update할것!
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post; //이미지도 고려할 것!

  /*
  bool shouldUpdate; //Accepted/My인지, 아닌지 --> delete/progress button의 여부!

  if (shouldUpdate){
  var user = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot> getUserData() async {
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('_userinfo')
          .doc(user.email)
          .get();
    }
    throw Exception('Not logged in');
  }
  }
  */

  //double userRating = 5.0;
  //bool updated = false;

  /*
  void retrieveUserRating() async {
    getUserData().then((snapshot) {
      if (snapshot.data() == null) {
        updated = true;
      }
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        userRating = data?['ratingAvg'];
        updated = true;
      }
    }).catchError((error) {
      userRating = 5.0;
      updated = true;
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    /*
    if (!updated) {
      retrieveUserRating();
    }
    */

    return SizedBox(
        width: 300.0,
        child: Card(
          //card를 제거하면 그냥 테두리 없는 글씨처럼 된다!
          child: ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostPage(
                            title: post.title,
                            contents: post.contents,
                            price: post.price,
                            userID: post.userID,
                            postID: post.postID,
                            rating: 5.0,
                            state: post.state,
                          ))); //postPage라는 파일 만들 것!
            },
            //leading:사진
            title: Text(post.title),
            titleAlignment: ListTileTitleAlignment.center,
            subtitle: Text(
              post.contents,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: Text(post.userID),
          ),
        ));
  }
}
