import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool pageInitialised = false;

  final googleSignIn = GoogleSignIn();

  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    checkIfUserLoggedIn();
    super.initState();
  }

  checkIfUserLoggedIn() async {
//    await googleSignIn.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//    sharedPreferences.setString("id", '');
    bool userLoggedIn = (sharedPreferences.getString('id') ?? '').isNotEmpty;

    if (userLoggedIn) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => Home()));
    } else {
      setState(() {
        pageInitialised = true;
      });
    }
  }

  handleSignIn() async {
    final res = await googleSignIn.signIn();

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final auth = await res.authentication;

    final credentials = GoogleAuthProvider.getCredential(
        idToken: auth.idToken, accessToken: auth.accessToken);

    final firebaseUser =
        (await firebaseAuth.signInWithCredential(credentials)).user;

    if (firebaseUser != null) {
      final result = (await Firestore.instance
              .collection('users')
              .where('id', isEqualTo: firebaseUser.uid)
              .getDocuments())
          .documents;

      if (result.length == 0) {
        ///new user
        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({
          "id": firebaseUser.uid,
          "name": firebaseUser.displayName,
          "profile_pic": firebaseUser.photoUrl,
          "created_at": DateTime.now().millisecondsSinceEpoch,
        });

        sharedPreferences.setString("id", firebaseUser.uid);
        sharedPreferences.setString("name", firebaseUser.displayName);
        sharedPreferences.setString("profile_pic", firebaseUser.photoUrl);

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => Home()));
      } else {
        ///Old user
        sharedPreferences.setString("id", result[0]["id"]);
        sharedPreferences.setString("name", result[0]["name"]);
        sharedPreferences.setString("profile_pic", result[0]["profile_pic"]);

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => Home()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Container(
        child: Column(
          children: [
            Container(
              height: 465,
              width: 300,
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Image.asset(
                'assets/images/logo.png',
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                constraints: const BoxConstraints.expand(),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        primary: Colors.redAccent,
                        onPrimary: Colors.white,
                        onSurface: Colors.white,
                      ),
                      child: const Text('Sign in as Anonymous',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            fontSize: 25.0,
                          )),
                      onPressed: handleSignIn,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
