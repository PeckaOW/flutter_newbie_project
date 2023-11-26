import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_newbie_project/login.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final idController = useTextEditingController();
    final passwordController = useTextEditingController();
    final accountNumberController = useTextEditingController();

    final authError = useState<String?>(null);
    final idError =
        useState<String?>(null); // 아이디 생성 관련 관여, 중복 확인도 포함. 영문+숫자 4글자 이상
    // 비번 생성 관련, 8자 이상 + 영문과 숫자 섞음

    Future<DocumentSnapshot> getUserData() async {
      return FirebaseFirestore.instance
          .collection('_userid')
          .doc('users')
          .get();
    }

    void _checkIDValid() async {
      String id = idController.text;

      if ((id.length < 4)) {
        idError.value = 'Your ID must be at least 4 characters.';
      } else if (!id.contains(RegExp(r'[0-9]'))) {
        idError.value = 'Your ID must contain numbers.';
      } else if (!id.contains(RegExp(r'[a-z]'))) {
        idError.value = 'Your ID must contain alphabet letters.';
      } else if (!RegExp(r'^[a-z0-9]+$').hasMatch(id)) {
        idError.value =
            'Your ID must ONLY contain lower case alphabets and numbers.';
      } else {
        idError.value = 'true';
      } //id 문제 없음

      if (idError.value == 'true') {
        await getUserData().then((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> users =
                snapshot.data() as Map<String, dynamic>;
            users['users'].forEach((value) {
              if (id == value.toString()) {
                idError.value = 'Please choose a different id.';
              }
            });
            print(idError.value);
          }
        });
      }

      final snackBar = SnackBar(
          content: Text(
              idError.value ?? 'An error has occured during the procedure.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Future<void> _create() async {
      String pass = passwordController.text;
      final bool emailValid = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailController.text);

      if (idError.value != 'true') {
        final snackBar =
            SnackBar(content: Text('Please check if your ID is valid'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else if (!((pass.contains(RegExp(r'[A-Za-z]'))) &&
          (pass.contains(RegExp(r'[0-9]'))) &&
          (pass.length >= 8))) {
        final snackBar = SnackBar(
            content: Text(
                'Your password must be at least 8 letters with alphabets and numbers.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else if (!emailValid) {
        final snackBar = SnackBar(content: Text('Your email must be valid.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else if (accountNumberController.text == '') {
        final snackBar =
            SnackBar(content: Text('Your account number must be valid.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text); //fireauth에 등록

          FirebaseFirestore.instance.collection('_userid').doc('users').update({
            "users": FieldValue.arrayUnion([idController.text])
          }); //_userid 추가하기

          //이하는 _userinfo
          FirebaseFirestore.instance
              .collection('_userinfo')
              .doc(emailController.text)
              .set({
            'accepted': [],
            'accountNumber': accountNumberController.text,
            'message': [],
            'ratings': [],
            'ratingAvg': 0,
            'requested': [],
            'securityCode': 12341234,
            'userid': idController.text,
          });

          authError.value = 'Registration Complete!';
        } on FirebaseAuthException catch (e) {
          if (e.code == 'weak-password') {
            authError.value = 'The password provided is too weak.';
          } else if (e.code == 'email-already-in-use') {
            authError.value = 'The account already exists for that email.';
          }
        } catch (e) {
          authError.value = e.toString();
        }

        final snackBar = SnackBar(
            content: Text(authError.value ??
                'An error has occured during the procedure.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => LoginScreen(
                        email: emailController.text,
                        password: passwordController.text,
                      )),
              (Route<dynamic> route) => false),
        ),
        title: Text("Register"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            Row(
              children: [
                SizedBox(
                    width: 200.0,
                    child: TextField(
                      controller: idController,
                      decoration: InputDecoration(labelText: 'ID'),
                    )),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                    onPressed: _checkIDValid,
                    child: Text('Check ID'),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 189, 106),
                    ))
              ],
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: accountNumberController,
              decoration: InputDecoration(labelText: 'Account Number'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _create,
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
