
import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {

  final int selectedMood;
  final Function(int) onSelected;

  MoodSelector({required this.selectedMood, required this.onSelected});

  final moods = ["😡","🙁","😐","🙂","😄"];

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(moods.length, (i){

        int value = i+1;
        bool selected = value == selectedMood;

        return GestureDetector(
          onTap: ()=>onSelected(value),
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? Colors.blue.shade100 : null,
              borderRadius: BorderRadius.circular(10)
            ),
            child: Text(moods[i], style: TextStyle(fontSize:30)),
          ),
        );
      }),
    );

  }

}
