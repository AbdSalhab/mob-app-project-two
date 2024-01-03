import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';
import '../baseUrl.dart';

class Course{
  String Name;
  int MaxNb;
  String Id;
  Course({required this.Name, required this.MaxNb, required this.Id});
  @override
  String toString() {
    // TODO: implement toString
    return this.Name;
  }
}

List<Course> courses = [];
Future<void> getCourses(Function(bool success) update) async {
  try {
    final url = Uri.parse('https://$baseURL/User/ViewCourses.php');

    final response = await http.post(url,
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8'
        },
        body: convert.jsonEncode(<String, String>{
          'Key': 'your_key'
        })
    ).timeout(const Duration(seconds: 20)); // max timeout 5 seconds
    courses.clear(); // clear old products
    if (response.statusCode == 200) { // if successful call
      final jsonResponse = convert.jsonDecode(response.body); // create dart json object from json array
      for (var row in jsonResponse) { // iterate over all rows in the json array
        Course c = Course( // create a product object from JSON row object
          Name: row['Name'],
          MaxNb: int.parse(row['MaxStudents']),
          Id: (row['ID']).toString(),
        );
        courses.add(c); // add the product object to the _products list


      }
      update(true); // callback update method to inform that we completed retrieving data
    }
  }
  catch(e) {
    print(e);
    update(false); // inform through callback that we failed to get data
  }
}
Future<void> joinCourse(Function(bool,String)update, String courseId) async {
  try {
    SharedPreferences prefs;
    String userId;
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? "";
    final url = Uri.parse('https://$baseURL/Student/JoinCourse.php');

    final response = await http.post(url,
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8'
        },
        body: convert.jsonEncode(<String, String>{
          'UserId': userId,
          'CourseId':courseId,
          'Key': 'your_key'
        })
    ).timeout(const Duration(seconds: 20)); // max timeout 5 seconds
    courses.clear(); // clear old products
    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> responseData = convert.jsonDecode(response.body);
        String responseValue = responseData['response'];
        print('Decoded Response: $responseValue');
        update(true,responseValue); // callback update method for JSON response

      } catch (e) {
        // Handle the case where the response is not a JSON object (e.g., a string)
        String responseValue = response.body;
        update(true,responseValue); // callback update method for non-JSON response
      }
    }
  }
  catch(e) {
    print(e);
    update(false,"failed to join course"); // inform through callback that we failed to get data
  }
}
class CourseCard extends StatefulWidget {
  const CourseCard({Key? key,required this.c}) : super(key: key);
  final Course c;
  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool joining = false;

  void response(bool x,String y){
    if(x){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(y)));
    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(y)));
    }
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
            Text(
              'Course Name: ${widget.c.Name}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Course Size: ${widget.c.MaxNb}',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: () {
                  if(!joining){
                    joinCourse(response,widget.c.Id);
                  }else{
                    return;
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                ),
                child: Text(
                  'Join',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ShowCourses extends StatefulWidget {
  const ShowCourses({Key? key,required this.filteredItems}) : super(key: key);
  final List<Course> filteredItems;
  @override
  State<ShowCourses> createState() => _ShowCoursesState();
}

class _ShowCoursesState extends State<ShowCourses> {

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
          child: CourseCard(c: widget.filteredItems[index]),
        ),
      ),
    );
  }
}

class ViewCourses extends StatefulWidget {
  const ViewCourses({Key? key}) : super(key: key);

  @override
  State<ViewCourses> createState() => _ViewCoursesState();
}

class _ViewCoursesState extends State<ViewCourses> {
  late SharedPreferences prefs;
  late String userId; // Declare userId as a variable
  bool _load = false; // used to show products list or progress bar

  @override
  void initState() {
    super.initState();
    getCourses(update);
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
  List<Course>filteredItems = courses;
  String filter = "";
  List<Course> searchForCourse(String search){
    return  courses.where((x) => x.Name.toLowerCase().contains(search.toLowerCase())).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _load ? Column(
        children: [
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
                hintText: 'Enter Course Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded (
            child:ShowCourses(filteredItems: filteredItems,),
          )
        ],
      ) : const Center(
          child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator())
      ),
    );
  }
}
