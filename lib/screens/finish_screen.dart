
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class FinishScreen extends StatefulWidget {
  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {

  final learn = TextEditingController();
  final feedback = TextEditingController();

  void submit() async {

    final pos = await LocationService.getLocation();

    await FirestoreService().saveCheckOut({
      "learnedToday": learn.text,
      "feedback": feedback.text,
      "latitude": pos.latitude,
      "longitude": pos.longitude,
      "timestamp": DateTime.now()
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Finish Class")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: learn, decoration: InputDecoration(labelText: "What did you learn")),
            TextField(controller: feedback, decoration: InputDecoration(labelText: "Feedback")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: submit, child: Text("Submit"))
          ],
        ),
      ),
    );
  }
}
