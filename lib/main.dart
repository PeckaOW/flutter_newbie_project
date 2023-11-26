import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'login.dart';
import 'postCard.dart';
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
  Post({required this.title, required this.contents, required this.userEmail, required this.userID, required this.price}); //image 파일도 추가!

  String title;
  String contents;
  String userEmail;
  String userID;
  int price; //원 단위
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post; //이미지도 고려할 것!

  @override
  Widget build(BuildContext context){
    return Card(
      child: ListTile(onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PostPage(post : post)));
      },),
    );
  }
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {


    //List<Todo> list = [ex1];
    final updated = useState<bool>(true); //정보 추가 시, reload, delete시마다 부를 state

    final TextEditingController _textFieldController1 = TextEditingController();
    final TextEditingController _textFieldController2 = TextEditingController();

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

    Future _signOut() async {
      await FirebaseAuth.instance.signOut();
    }

    void onLogOut() async { //로그아웃 버튼 누를 시
      try {
        _signOut();
        Navigator.pop(context);
      } catch (e) {
        print(e.toString());
      }
    }

    void _onDelete(Todo todo) { //삭제 버튼 누를 시
      todos.value.remove(todo);
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .update({"${todo.title}": FieldValue.delete()});
      }
      updated = false;
      todos.notifyListeners();
    }

    void _addTodoItem(String title, String memo) {
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.email).set({
          title: {'memo': memo, 'done': false}
        }, SetOptions(merge: true));
      }
      updated = false;
      todos.notifyListeners();
    }

    void retrieveUserData() {
      getUserData().then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;
          userData.forEach((key, value) {
            todos.value.add(Todo(
                title: key.toString(),
                done: value['done'],
                memo: value['memo']));
          });
          todos.notifyListeners();
          print(todos.value);
          // Use your user data here, e.g., update the state or UI
        } else {
          todos.value = [ex1];
          // Handle the case where the user does not have data in the Firestore document
        }
      }).catchError((error) {
        // Handle errors here, e.g., show an error message
      });
    }

    Future<void> _displayDialog() async {
      return showDialog<void>(
        context: context,
        //T: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a todo'),
            content: Column(
              children: [
                TextField(
                  controller: _textFieldController1,
                  decoration: const InputDecoration(hintText: 'Type todo'),
                  autofocus: true,
                ),
                TextField(
                  controller: _textFieldController2,
                  decoration: const InputDecoration(hintText: "Type your memo"),
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
                  todos.notifyListeners();
                  _addTodoItem(
                      _textFieldController1.text, _textFieldController2.text);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    if (!updated) {
      todos.value = [];
      retrieveUserData();
      updated = true;
    } //only retrieve once

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("To-Do List"),
              IconButton(
                icon: Icon(Icons.person_2_rounded),
                onPressed: () => onLogin,
              ),
              if (user != null)
                Text(
                  "${user.email}",
                  style: TextStyle(fontSize: 10.0),
                ),
            ],
          ),
        ),
        body: ListView(
          children: 

              todos.value
                  .map((Todo todo) => TodoCard(
                        todo: todo,
                        onChecked: _onCheckbox,
                        onDeleted: _onDelete,
                      ))
                  .toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _displayDialog(),
          tooltip: 'Add new to-do',
          child: const Icon(Icons.add),
        ));
  }


class MemoPage extends StatelessWidget {
  const MemoPage({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(todo.title),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Text(
                "Completed : ${todo.done}",
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: Text(
                  "Your memo : ${todo.memo}",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
