import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:habit_tracker/components/heat_map.dart';
import 'package:habit_tracker/database/habit_database.dart';
import 'package:habit_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import '../components/mhy_habit_tile.dart';
import '../components/my_drawer.dart';
import '../models/habit.dart';
import '../util/habit_util.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController textEditingController = TextEditingController();
  @override
  void initState() {
    Provider.of<HabitDatabase>(context, listen: false).readHabits();

    super.initState();
  }

  void checkHabitOnOff(bool? value, Habit habit) {
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  void createNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textEditingController,
          decoration: InputDecoration(hintText: "Create new habit"),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              String newHabitName = textEditingController.text;
              context.read<HabitDatabase>().addHabit(newHabitName);
              Navigator.pop(context);
              textEditingController.clear();
            },
            child: const Text('Save'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
              textEditingController.clear();
            },
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  void editHabitBox(Habit habit) {
    textEditingController.text = habit.name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textEditingController,
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              String newHabitName = textEditingController.text;
              context
                  .read<HabitDatabase>()
                  .updateHabitName(habit.id, newHabitName);
              Navigator.pop(context);
              textEditingController.clear();
            },
            child: const Text('Save'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
              textEditingController.clear();
            },
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  //delete habit
  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure you want to delete?"),
        actions: [
          MaterialButton(
            onPressed: () {
              context.read<HabitDatabase>().deleteHabit(
                    habit.id,
                  );
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        shape: CircleBorder(),
        child: Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
      body: ListView(
        children: [_buildHeatMap(), _buildHabitList()],
      ),
    );
  }

  Widget _buildHeatMap() {
    final habitDataBase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDataBase.currentHabits;

    return FutureBuilder<DateTime?>(
      future: habitDataBase.getFirstLaunchedDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MyHeatMap(
              startDate: snapshot.data!,
              datasets: prepHeatMapDataset(currentHabits));
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildHabitList() {
    final habitDatabase = context.watch<HabitDatabase>();

    List<Habit> currentHabits = habitDatabase.currentHabits;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentHabits.length,
      itemBuilder: (context, index) {
        final habit = currentHabits[index];

        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);
        return MyHabitTile(
          text: habit.name,
          isCompleted: isCompletedToday,
          onChanged: (value) => checkHabitOnOff(value, habit),
          editHabit: (context) => editHabitBox(habit),
          deleteHabit: (context) => deleteHabitBox(habit),
        );
      },
    );
  }
}
