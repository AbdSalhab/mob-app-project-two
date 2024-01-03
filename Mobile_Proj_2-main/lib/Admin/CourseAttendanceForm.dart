import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import '../baseUrl.dart';
import 'CourseAttendanceForm.dart';
import 'Student.dart';
class CourseForm extends StatefulWidget {
  const CourseForm({Key? key,required this.club}) : super(key: key);
  final club;
  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  bool _load = false;
  void updateLoad(bool x){
    setState(() {
      _load = x;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.Name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Call the function to submit the form when the icon is pressed
              submitForm(updateLoad, widget.club.Id);
            },
          ),
        ],
      ),
      body: !_load ? ViewStudents(courseId: widget.club.Id) :  const Center(
    child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator()))
    );
  }

}
Future<void> submitForm(Function(bool)updateLoad,String courseId) async {
  try {
    updateLoad(true);
    List<Map<String, dynamic>> modifiedStudents = students.map((student) {
      return {
        'Id': student.Id,
        'isAbsent': student.isAbsent,
        'courseId': courseId,
      };
    }).toList();
    final url = Uri.parse('https://$baseURL/Admin/UpdateAttendance.php');

    final response = await http.post(url,
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8'
        },
      body: convert.jsonEncode({
        'students': modifiedStudents,
      }),
    ).timeout(const Duration(seconds: 20)); // max timeout 5 seconds
    if (response.statusCode == 200) {
      String responseValue = response.body;
    }
    updateLoad(false);
  }
  catch(e) {
    updateLoad(false);
    print(e);
  }
}