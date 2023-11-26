import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'login.dart';
import 'postCard.dart';
import 'messenger.dart';
//import 'createAccount.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simbureum',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: //AccountScreen(),
          LoginScreen(email: "", password: ""),
      //ListPage(),
    );
  }
}

class Post {
  Post(
      {required this.title,
      required this.contents,
      required this.userEmail,
      required this.userID,
      required this.price,
      required this.postID,
      required this.state,
      required this.otherID}); //image 파일도 추가!

  String title;
  String contents;
  String userEmail;
  String userID;
  int price; //원 단위
  String postID;
  String state;
  String otherID;
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final updated = useState<bool>(true); //정보 추가 시, reload, delete시마다 부를 state

    final TextEditingController _textFieldControllerT =
        TextEditingController(); //title
    final TextEditingController _textFieldControllerC =
        TextEditingController(); //contents
    final TextEditingController _textFieldControllerP =
        TextEditingController(); //price

    var user = FirebaseAuth.instance.currentUser;
    String userID = 'undefined';
    String? userEmail = 'undefined';

    List<Post> myPosts = [];
    List<Post> acceptedPosts = [];
    List<Post> newPosts = [];

    /*
    final documentStream = useMemoized(() => FirebaseFirestore.instance
        .collection('_userID')
        .doc(postID)
        .snapshots());
    final snapshot = useStream(documentStream);
    */

    Future<DocumentSnapshot> getUserData() async {
      if (user != null) {
        userEmail = user.email;
        return FirebaseFirestore.instance
            .collection('_userinfo')
            .doc(user.email)
            .get();
      }
      throw Exception('Not logged in');
    }

    Future<DocumentSnapshot> getOtherData(String email) async {
      return FirebaseFirestore.instance
          .collection('_userinfo')
          .doc(email)
          .get();
    }

    Future<List<dynamic>> getPostData() async {
      CollectionReference _collectionRef =
          FirebaseFirestore.instance.collection('_posts');
      QuerySnapshot querySnapshot = await _collectionRef.get();
      return querySnapshot.docs.map((doc) => (doc.id, doc.data())).toList();
    }

    Future _signOut() async {
      await FirebaseAuth.instance.signOut();
    }

    void retrieveUserID() async {
      getUserData().then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          userID = data?['userid'];
        } else {
          userID = 'undefined';
        }
      }).catchError((error) {
        userID = 'undefined';
        final snackBar = SnackBar(content: Text(error));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }

    Future<String?> retrieveUserIDof(String email) async {
      getOtherData(email).then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          return data?['userid'];
        } else {
          return 'undefined';
        }
      }).catchError((error) {
        return 'undefined';
      });
      return 'undefined';
    }

    void onLogOut() async {
      //로그아웃 버튼 누를 시
      try {
        _signOut();
        Navigator.pop(context);
      } catch (e) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    void _onDelete(String postID) async {
      //삭제 버튼 누를 시
      FirebaseFirestore.instance.collection('_posts').doc(postID).delete();
      updated.value = false;
    }

    void _addPost(String title, String contents, int price, String userID) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('_posts')
            .doc('$userID${DateTime.now().millisecondsSinceEpoch}')
            .set({
          'acceptedBy': '',
          'contents': contents,
          'email': user.email,
          'price': price,
          'state': 'New',
          'title': title,
          'userid': userID,
        });
      }
      updated.value = false;
    }

    void retrievePosts() async {
      List<dynamic> posts = getPostData() as List<dynamic>;
      posts.forEach((element) {
        if (element[1]['email'] == userEmail) {
          myPosts.add(Post(
              contents: element[1]['contents'],
              title: element[1]['title'],
              userEmail: element[1]['email'],
              userID: element[1]['userid'],
              price: element[1]['price'],
              postID: element[0],
              state: element[1]['state'],
              otherID: retrieveUserIDof(element[1]['acceptedBy']) as String));
        } else if (element[1]['acceptedBy'] == userEmail) {
          acceptedPosts.add(Post(
              contents: element[1]['contents'],
              title: element[1]['title'],
              userEmail: element[1]['email'],
              userID: element[1]['userid'],
              price: element[1]['price'],
              postID: element[0],
              state: element[1]['state'],
              otherID: userID));
        } else {
          newPosts.add(Post(
              contents: element[1]['contents'],
              title: element[1]['title'],
              userEmail: element[1]['email'],
              userID: element[1]['userid'],
              price: element[1]['price'],
              postID: element[0],
              state: element[1]['state'],
              otherID: 'undefined'));
        }
      });
    }

    Future<void> _displayDialog() async {
      return showDialog<void>(
        context: context,
        //T: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a Post'),
            content: Column(
              children: [
                TextField(
                  controller: _textFieldControllerT,
                  decoration: const InputDecoration(hintText: 'Type Title'),
                  autofocus: true,
                ),
                TextField(
                  controller: _textFieldControllerC,
                  decoration: const InputDecoration(hintText: "Type Contents"),
                  autofocus: true,
                ),
                TextField(
                  controller: _textFieldControllerP,
                  decoration: const InputDecoration(hintText: "Type Price"),
                  autofocus: true,
                )
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    _addPost(
                        _textFieldControllerT.text,
                        _textFieldControllerC.text,
                        int.parse(_textFieldControllerP.text),
                        userID);
                  } catch (e) {
                    final snackBar =
                        SnackBar(content: Text('Price must be Integer!'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    if (!updated.value) {
      myPosts = [];
      acceptedPosts = [];
      newPosts = [];
      retrievePosts();
      updated.value = true;
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("Simbureum"),
              IconButton(
                icon: Icon(Icons.person_2_rounded),
                onPressed: () => onLogOut(),
              ),
              if (user != null)
                Text(
                  "${user.email}",
                  style: TextStyle(fontSize: 10.0),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            ListView(
              children: myPosts
                  .map((Post post) => Row(children: [
                        PostCard(
                          post: post,
                        ),
                        if (post.state == 'New')
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _onDelete(post.postID),
                          ),
                        if (post.state == 'In Progress')
                          IconButton(
                            icon: Icon(Icons.history_rounded),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MessengerPage(
                                            myID: post.userID,
                                            postID: post.postID,
                                            otherID: post.otherID,
                                          ))); //postPage라는 파일 만들 것!
                            },
                          ),
                      ]))
                  .toList(),
            ),
            const Divider(
              thickness: 2,
              height: 1,
              color: Colors.black,
            ),
            ListView(
              children: acceptedPosts
                  .map((Post post) => Row(children: [
                        PostCard(
                          post: post,
                        ),
                        if (post.state == 'In Progress')
                          IconButton(
                            icon: Icon(Icons.history_rounded),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MessengerPage(
                                            myID: post.userID,
                                            postID: post.postID,
                                            otherID: post.otherID,
                                          ))); //postPage라는 파일 만들 것!
                            },
                          ),
                      ]))
                  .toList(),
            ),
            const Divider(
              thickness: 2,
              height: 1,
              color: Colors.black,
            ),
            ListView(
              children: newPosts
                  .map((Post post) => Row(children: [
                        PostCard(
                          post: post,
                        ),
                      ]))
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _displayDialog(),
          tooltip: 'Add new Post',
          child: const Icon(Icons.add),
        ));
  }
}
