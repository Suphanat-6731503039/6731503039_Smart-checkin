
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class InstructorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Instructor Dashboard")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("checkins").snapshots(),
        builder: (context, snapshot) {

          if(!snapshot.hasData){
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          int total = docs.length;

          return Column(
            children: [
              Text("Total Attendance: $total"),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context,i){
                    final d = docs[i];
                    return ListTile(
                      title: Text(d["previousTopic"] ?? ""),
                      subtitle: Text("Mood: ${d["mood"]}"),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
