
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../widgets/mood_selector.dart';

class CheckInScreen extends StatefulWidget {
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {

  final prev = TextEditingController();
  final expect = TextEditingController();
  int mood = 3;

  void submit() async {

    final pos = await LocationService.getLocation();

    await FirestoreService().saveCheckIn({
      "previousTopic": prev.text,
      "expectedTopic": expect.text,
      "mood": mood,
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
      appBar: AppBar(title: Text("Check-in")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: prev, decoration: InputDecoration(labelText: "Previous Topic")),
            TextField(controller: expect, decoration: InputDecoration(labelText: "Expected Topic")),
            SizedBox(height: 20),
            MoodSelector(selectedMood: mood, onSelected: (m){ setState((){ mood=m; }); }),
            SizedBox(height: 20),
            ElevatedButton(onPressed: submit, child: Text("Submit"))
          ],
        ),
      ),
    );
  }
}
