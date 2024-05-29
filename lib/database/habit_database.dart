import 'package:flutter/material.dart';
import 'package:habit_tracker/models/app_settings.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  // database initialized
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar =
        await Isar.open([HabitSchema, AppSettingsSchema], directory: dir.path);
  }

  // save first date of app startup
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  //get first date of app startup
  Future<DateTime?> getFirstLaunchedDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  //CRUD

  final List<Habit> currentHabits = [];

  //create new habit
  Future<void> addHabit(String habitName) async {
    final newHabit = Habit()..name = habitName; //created new habit

    await isar.writeTxn(() => isar.habits.put(newHabit)); //save to database

    readHabits(); //read from database
  }

  //read habits
  Future<void> readHabits() async {
    //fetch all habits
    List<Habit> fetchHabits = await isar.habits.where().findAll();
    // give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchHabits);
    notifyListeners();
  }

  //update habits
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    final habit = await isar.habits.get(id);

    if (habit != null) {
      await isar.writeTxn(() async {
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          final today = DateTime.now();
          habit.completedDays.add(DateTime(today.year, today.month, today.day));
        }
      });
    } else {
      habit!.completedDays.removeWhere((date) =>
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day);
    }
    await isar.habits.put(habit);
  }

  //edit habit name
  Future<void> updateHabitName(int id, String newName) async {
    final habit = await isar.habits.get(id);

    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  // delete habits
  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    readHabits();
  }
}