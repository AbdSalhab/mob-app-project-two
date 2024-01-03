import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import './Student/HomeStudent.dart';
import './Admin/HomeAdmin.dart';
import 'baseUrl.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String role = "";
  void updateRole(String x){
    role = x;
  }
  @override
  Widget build(BuildContext context) {
    void update(String x){
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(role)));
      if(role == "Admin"){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminHome()),
        );
      }else if(role == "student"){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentHome()),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                //login
                loading = true;
                String email = emailController.text;
                String password = passwordController.text;
                LoginUser(email,password,update,updateRole);
              },
              child: !loading ? const Text('Login') : CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
void LoginUser(String email, String password,Function(String) update,Function(String) updateRole) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = Uri.parse('https://$baseURL/User/Login.php');

  try {
    //final url = Uri.https(baseURL, '/User/login.php');
    final response = await http
        .post(url,
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8'
        },
        body: convert.jsonEncode(<String, String>{
          'Email': email,
          'Password':password,
          'Key': 'your_key'
        }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {

      Map<String, dynamic> responseData = convert.jsonDecode(response.body);
      String userId = responseData['userID'].toString();
      String Role = responseData['Role'].toString();
      prefs.setString('userId', userId);
      if(Role == "Admin"){
        updateRole("Admin");
      }else{
        updateRole("student");
      }
      update("logged in");
    }
  } catch (e) {
    print(e.toString());
    update(e.toString());
  }
}