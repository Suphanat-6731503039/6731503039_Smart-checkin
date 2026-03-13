
import 'package:flutter/material.dart';
import 'checkin_screen.dart';
import 'finish_screen.dart';
import 'instructor_dashboard.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Class")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              child: Text("Check-in"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CheckInScreen()));
              },
            ),
            ElevatedButton(
              child: Text("Finish Class"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => FinishScreen()));
              },
            ),
            ElevatedButton(
              child: Text("Instructor Dashboard"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => InstructorDashboard()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
