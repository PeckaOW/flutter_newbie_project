import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_newbie_project/postPage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'login.dart';
import 'postCard.dart';
import 'messenger.dart';
import 'postPage.dart';

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
            LoginScreen(email: "", password: "")
        //ListPage(),
        //MessengerPage(
        //  myID: 'kingsj1130',
        //postID: 'kingsj11301701015736757',
        //otherID: 'thomaskim1130'));
        //PostPage(
        //   contents: 'Hello',
        //  title: 'nope',
        // userID: 'kingsj1130',
        //price: 10100,
        //rating: 5.0,
        //postID: 'kingsj11301701015997215'));
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
      required this.acceptedID,
      required this.acceptedEmail}); //image 파일도 추가!

  String title;
  String contents;
  String userEmail;
  String userID;
  int price; //원 단위
  String postID;
  String state;
  String acceptedID;
  String acceptedEmail;
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final updated = useState<bool>(false); //정보 추가 시, reload, delete시마다 부를 state

    final TextEditingController _textFieldControllerT =
        TextEditingController(); //title
    final TextEditingController _textFieldControllerC =
        TextEditingController(); //contents
    final TextEditingController _textFieldControllerP =
        TextEditingController(); //price

    XFile? pickedImage = null;

    final userID = useState<String>('undefined');
    final user = FirebaseAuth.instance.currentUser;

    List<Post> myPosts = [];
    List<Post> acceptedPosts = [];
    List<Post> newPosts = [];

    Future<String> retrieveUserID(String? myEmail) async {
      String myID = '';

      if (myEmail == 'undefined') return 'undefined';

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

    useEffect(() {
      if (userID.value == 'undefined' && user != null) {
        retrieveUserID(user.email).then((id) {
          userID.value = id;
        });
      }
      return null;
    }, [userID.value]);

    Future<List<Map<String, dynamic>>> getPostData() async {
      try {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection('_posts').get();

        // Map each document to a map of {id: <docId>, data: <docData>}
        return querySnapshot.docs.map((doc) {
          return {"id": doc.id, "data": doc.data()};
        }).toList();
      } catch (e) {
        // Handle exceptions
        print("Error fetching collection: $e");
        return [];
      }
    }

    Future _signOut() async {
      await FirebaseAuth.instance.signOut();
    }

    /*
    Future<String> retrieveUserIDof(String email) async {
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
    */

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
    }

    Future<XFile?> pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        return image;
      }
      return null;
    }

    void _addPost(
      String title,
      String contents,
      int price,
      String userID,
      /*XFile? image*/
    ) {
      if (user != null) {
        String docID = '$userID${DateTime.now().millisecondsSinceEpoch}';
        FirebaseFirestore.instance.collection('_posts').doc(docID).set({
          'acceptedBy': '',
          'acceptedID': '',
          'contents': contents,
          'email': user.email,
          'price': price,
          'state': 'New',
          'title': title,
          'userid': userID,
        });

        //if (image != null){
        //my
        //}
      }
    }

    Future<void> retrievePosts() async {
      List<Map<String, dynamic>> posts = await getPostData();
      if (user != null) {
        for (var element in posts) {
          if (element['data']['email'] == user.email) {
            myPosts.add(Post(
              contents: element['data']['contents'],
              title: element['data']['title'],
              userEmail: element['data']['email'],
              userID: element['data']['userid'],
              price: element['data']['price'],
              postID: element['id'],
              state: element['data']['state'],
              acceptedID: element['data']['acceptedID'],
              acceptedEmail: element['data']['acceptedBy'],
            ));
          } else if (element['data']['acceptedBy'] == user.email) {
            acceptedPosts.add(Post(
                contents: element['data']['contents'],
                title: element['data']['title'],
                userEmail: element['data']['email'],
                userID: element['data']['userid'],
                price: element['data']['price'],
                postID: element['id'],
                state: element['data']['state'],
                acceptedID: element['data']['acceptedID'],
                acceptedEmail: element['data']['acceptedBy']));
          } else {
            newPosts.add(Post(
                contents: element['data']['contents'],
                title: element['data']['title'],
                userEmail: element['data']['email'],
                userID: element['data']['userid'],
                price: element['data']['price'],
                postID: element['id'],
                state: element['data']['state'],
                acceptedID: element['data']['acceptedID'],
                acceptedEmail: element['data']['acceptedBy']));
          }
        }
      }
    }

    Future<void> retrieveMy() async {
      List<Map<String, dynamic>> posts = await getPostData();
      if (user != null) {
        for (var element in posts) {
          if (element['data']['email'] == user.email) {
            myPosts.add(Post(
              contents: element['data']['contents'],
              title: element['data']['title'],
              userEmail: element['data']['email'],
              userID: element['data']['userid'],
              price: element['data']['price'],
              postID: element['id'],
              state: element['data']['state'],
              acceptedID: element['data']['acceptedID'],
              acceptedEmail: element['data']['acceptedBy'],
            ));
          }
        }
      }
    }

    Future<void> retrieveAccepted() async {
      List<Map<String, dynamic>> posts = await getPostData();
      if (user != null) {
        for (var element in posts) {
          if (element['data']['acceptedBy'] == user.email) {
            acceptedPosts.add(Post(
                contents: element['data']['contents'],
                title: element['data']['title'],
                userEmail: element['data']['email'],
                userID: element['data']['userid'],
                price: element['data']['price'],
                postID: element['id'],
                state: element['data']['state'],
                acceptedID: element['data']['acceptedID'],
                acceptedEmail: element['data']['acceptedBy']));
          }
        }
      }
    }

    Future<void> retrieveNew() async {
      List<Map<String, dynamic>> posts = await getPostData();
      if (user != null) {
        for (var element in posts) {
          newPosts.add(Post(
              contents: element['data']['contents'],
              title: element['data']['title'],
              userEmail: element['data']['email'],
              userID: element['data']['userid'],
              price: element['data']['price'],
              postID: element['id'],
              state: element['data']['state'],
              acceptedID: element['data']['acceptedID'],
              acceptedEmail: element['data']['acceptedBy']));
        }
      }
    }

    Future<void> refresh() async {
      myPosts = [];
      acceptedPosts = [];
      newPosts = [];
      await retrievePosts();
      userID.value = 'undefined';
    }

    useEffect(() {
      if (!updated.value) {
        myPosts = [];
        acceptedPosts = [];
        newPosts = [];
        retrievePosts();
        updated.value = true;
      }
      return null;
    }, [updated.value]);

    Future<void> _displayDialog() async {
      return showDialog<void>(
        context: context,
        //T: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a Post'),
            content: Column(children: [
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
              ),
              //IconButton(onPressed:() { pickedImage = await pickImage();}
              //        ,icon: Icon(Icons.image))
            ]),
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
                        userID.value);
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => refresh(), icon: Icon(Icons.refresh)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'My Posts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          Expanded(
              child: FutureBuilder(
                  future: retrieveMy(),
                  builder: ((context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (myPosts == []) {
                      return Center(child: Text('No posts found'));
                    }

                    return ListView(
                      shrinkWrap: true,
                      children: myPosts
                          .map((Post post) => Row(children: [
                                PostCard(
                                  post: post,
                                ),
                                if (post.state != 'In Progress')
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
                                              builder: (context) =>
                                                  MessengerPage(
                                                    myID: post.userID,
                                                    postID: post.postID,
                                                    otherID: post.acceptedID,
                                                  ))); //postPage라는 파일 만들 것!
                                    },
                                  ),
                              ]))
                          .toList(),
                    );
                  }))),
          const Divider(
            thickness: 2,
            height: 1,
            color: Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Accepted Posts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          Expanded(
              child: FutureBuilder(
                  future: retrieveAccepted(),
                  builder: ((context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (acceptedPosts == []) {
                      return Center(child: Text('No posts found'));
                    }

                    return ListView(
                      shrinkWrap: true,
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
                                              builder: (context) =>
                                                  MessengerPage(
                                                    myID: post.acceptedID,
                                                    postID: post.postID,
                                                    otherID: post.userID,
                                                  ))); //postPage라는 파일 만들 것!
                                    },
                                  ),
                              ]))
                          .toList(),
                    );
                  }))),
          const Divider(
            thickness: 2,
            height: 1,
            color: Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "New Posts",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          Expanded(
              child: FutureBuilder(
                  future: retrieveNew(),
                  builder: ((context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (newPosts == []) {
                      return Center(child: Text('No posts found'));
                    }

                    return ListView(
                      shrinkWrap: true,
                      children: newPosts
                          .map((Post post) => Row(children: [
                                PostCard(
                                  post: post,
                                ),
                              ]))
                          .toList(),
                    );
                  }))),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        tooltip: 'Add new Post',
        child: const Icon(Icons.add),
        heroTag: 'btn1',
      ),
    );
  }
}
/*
class PostList extends StatelessWidget {
  PostList({super.key, required this.posts});

  final List<Post> posts;

  Stream<List<Map<String, dynamic>>> getPostData() {
    return FirebaseFirestore.instance.collection('_posts').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getPostData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return Text('No data available');
        }

        List<Map<String, dynamic>> documents = snapshot.data!;

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            var document = documents[index];
            var documentID = document['id'];
            var documentData = document['data'];
            // Build your widget with documentID and documentData
            return ListTile(
              title: Text(documentID),
              subtitle: Text(documentData.toString()),
            );
          },
        );
      },
    );
  }
}
*/