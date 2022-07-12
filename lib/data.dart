import 'dart:convert';
import 'dart:io';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' show window;

class ProblemItem {
  String answer;
  String problem;
  ProblemItem(this.answer, this.problem);
}

class Problem {
  List<ProblemItem> items;
  Set<int> doneProblems;
  Set<int> wrongProblems;
  Problem(this.items)
      : doneProblems = <int>{},
        wrongProblems = <int>{};
  int getFirstUndone() {
    for (int i = 0; i < items.length; i++) {
      if (!doneProblems.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  int getFirstWrong() {
    for (int i = 0; i < items.length; i++) {
      if (wrongProblems.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  int getNextWrong(int id) {
    for (int i = id + 1; i < items.length; i++) {
      if (wrongProblems.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  int getPrevWrong(int id) {
    for (int i = id - 1; i >= 0; i--) {
      if (wrongProblems.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  void clear() {
    doneProblems.clear();
    wrongProblems.clear();
  }

  void clearWrong() {
    wrongProblems.clear();
  }
}

class Data {
  static const N = 3;
  static List<Problem> problem = [];
  static String dir = "";
  static Future<void> init() async {
    problem.clear();
    for (int i = 0; i <= N; i++) {
      problem.add(Problem([]));
    }
    if (!kIsWeb) {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    for (int i = 1; i <= N; i++) {
      var t = await rootBundle.loadString('data/${i}_problem.json');
      var a = jsonDecode(t);
      for (var e in a) {
        problem[i].items.add(ProblemItem(e['answer'], e['problem']));
      }
      //print('problem: ${i}, ${problem[i].items.length}');
    }
    await load();
  }

  static Future<void> load() async {
    try {
      for (int i = 1; i <= N; i++) {
        String tData="";
        if (kIsWeb) {
          tData = window.localStorage['${i}_save.json']!;
        } else {
          tData =  await File(p.join(dir, 'shuati', '${i}_save.json')).readAsString();
        }
        var t = jsonDecode(tData);
        for (var j in t['done']) {
          problem[i].doneProblems.add(j);
        }
        for (var j in t['wrong']) {
          problem[i].wrongProblems.add(j);
        }
      }
    } catch (e) {
      print(e);
      createEmptyData();
    }
  }

  static void debounceSave() {
    EasyDebounce.debounce('save', const Duration(seconds: 3), () {
      _save();
    });
  }

  static void _save() async {
    for (int i = 1; i <= N; i++) {
      var t = {
        'done': problem[i].doneProblems.toList(),
        'wrong': problem[i].wrongProblems.toList(),
      };
      if (kIsWeb) {
        window.localStorage['${i}_save.json'] = jsonEncode(t);
      } else {
        await File(p.join(dir, 'shuati', '${i}_save.json')).create(recursive: true);
        await File(p.join(dir, 'shuati', '${i}_save.json')).writeAsString(jsonEncode(t));
      }
    }
  }

  static void createEmptyData() {}
}
