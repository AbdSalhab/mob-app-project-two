import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import '../baseUrl.dart';

class Student{
  String Username;
  int Id;
  String email;
  int Absent;
  bool isAbsent = false;
  Student({required this.Username,required this.Id,required this.email,required this.Absent});
}
List<Student> students = [];
Future<void> getStudents(Function(bool success) update,String courseId) async {
  try {
    SharedPreferences prefs;
    String userId;
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? "";
    final url = Uri.parse('https://$baseURL/Admin/GetStudentsWithCourse.php');

    final response = await http.post(url,
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8'
        },
        body: convert.jsonEncode(<String, String>{
          'UserId':userId,
          'CourseId':courseId,
          'Key': 'your_key'
        })
    ).timeout(const Duration(seconds: 20)); // max timeout 5 seconds
    students.clear(); // clear old products
    if (response.statusCode == 200) { // if successful call
      final jsonResponse = convert.jsonDecode(response.body); // create dart json object from json array
      for (var row in jsonResponse) { // iterate over all rows in the json array
        Student c = Student( // create a product object from JSON row object
            Username: row['Username'],
            Id: int.parse(row['ID']),
            email: row['Email'],
            Absent: int.parse(row['Absent'])
        );
        students.add(c); // add the product object to the _products list
      }
      update(true); // callback update method to inform that we completed retrieving data
    }
  }
  catch(e) {
    print(e);
    update(false); // inform through callback that we failed to get data
  }
}
class StudentCard extends StatefulWidget {
  const StudentCard({Key? key, required this.s}) : super(key: key);
  final Student s;
  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _switchValue = false;

  void update(String x){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));

    }
  @override
    Widget build(BuildContext context) {
      return Card(
        elevation: 3,
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student Name: ${widget.s.Username}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: widget.s.isAbsent,
                    onChanged: (value) {
                      setState(() {
                        widget.s.isAbsent = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Number of Absences: ${widget.s.Absent}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

  }
}

class ShowStudents extends StatefulWidget {
  const ShowStudents({Key? key, this.filteredItems}) : super(key: key);
  final filteredItems;
  @override
  State<ShowStudents> createState() => _ShowStudentsState();
}

class _ShowStudentsState extends State<ShowStudents> {

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.filteredItems.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 150,
          child: StudentCard(s: widget.filteredItems[index]),
        ),
      ),
    );
  }
}

class ViewStudents extends StatefulWidget {
  const ViewStudents({Key? key, this.courseId}) : super(key: key);
  final courseId;
  @override
  State<ViewStudents> createState() => _ViewStudentsState();
}

class _ViewStudentsState extends State<ViewStudents> {
  late SharedPreferences prefs;
  late String userId; // Declare userId as a variable
  bool _load = false; // used to show products list or progress bar

  @override
  void initState() {
    super.initState();
    getStudents(update,widget.courseId);
    _loadUserId(); // Load userId when the widget is initialized
  }
  void update(bool success) {
    setState(() {
      _load = true; // show product list
      if (!success) { // API request failed
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('failed to load data')));
      }
    });
  }
  Future<void> _loadUserId() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? ""; // Set a default value if userId is null
    setState(() {
      // Call setState to trigger a rebuild with the loaded userId
    });
  }
  List<Student>filteredItems = students;
  String filter = "";
  List<Student> searchForCourse(String search){
    return  students.where((x) => x.Username.toLowerCase().contains(search.toLowerCase())).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _load ? Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Attendance Form",style: TextStyle(fontSize: 20.0),),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                // Update the filtered list based on the search query
                setState(() {
                  filteredItems = searchForCourse(value);
                  print(filteredItems);
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Enter Student Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded (
            child:ShowStudents(filteredItems: filteredItems,),
          )
        ],
      ) : const Center(
          child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator())
      ),
    );
  }
}
