import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import 'MyCourses.dart';
import 'ViewCourses.dart';
class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _selectedIndex = 0;
  List<Widget> manageOption = <Widget>[];
  @override
  void initState() {
    super.initState();
    // Initialize manageOption in initState where widget is accessible
    manageOption = [
      MyCourses(),
      ViewCourses(),

    ];
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liu'),
      ),

      body: Center(
        child: manageOption[_selectedIndex],
      ),
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('LIU'),
            ),
            ListTile(
              title: const Text('My Courses'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('All Courses'),
              onTap: () {
                _onItemTapped(1);

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
