import 'package:flutter/material.dart';

import 'data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Data.init();
    return MaterialApp(
        title: '刷题',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: Builder(
            builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('刷题')),
                body: Center(
                    child: FractionallySizedBox(
                        widthFactor: 0.8,
                        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('请选择试卷', style: TextStyle(fontSize: 30)),
                          Container(
                              height: 100,
                              width: double.infinity,
                              child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                      return HomeWidget(id: 1);
                                    }));
                                  },
                                  child: const Text("1"))),
                          Container(
                              height: 100,
                              width: double.infinity,
                              child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                      return HomeWidget(id: 2);
                                    }));
                                  },
                                  child: const Text("2"))),
                          Container(
                              height: 100,
                              width: double.infinity,
                              child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                      return HomeWidget(id: 3);
                                    }));
                                  },
                                  child: const Text("3"))),
                        ]))))));
  }
}

class HomeWidget extends StatefulWidget {
  final int id;
  const HomeWidget({Key? key, required this.id}) : super(key: key);
  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  Problem p = Problem([]);
  void forceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    p = Data.problem[widget.id];
    return Scaffold(
        appBar: AppBar(
          title: Text("试卷" + widget.id.toString()),
        ),
        body: Center(
            child: FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("共 ${p.items.length} 道题目, 已经做了 ${p.doneProblems.length} 道，错题本中有 ${p.wrongProblems.length} 道",
                        style: TextStyle(fontSize: 20)),
                    Container(
                        height: 100,
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () {
                              int t = p.getFirstUndone();
                              if (t != -1) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return ProblemWidget(parent: this, id: widget.id, pid: t, mode: false);
                                }));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text("题都刷完了！"),
                                ));
                              }
                            },
                            child: const Text("开始做题"))),
                    Container(
                        height: 100,
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () {
                              int t = p.getFirstWrong();
                              if (t != -1) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return ProblemWidget(parent: this, id: widget.id, pid: t, mode: true);
                                }));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text("错题本中没有题目！"),
                                ));
                              }
                            },
                            child: const Text("开始做错题"))),
                    Container(
                        height: 100,
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                p.clearWrong();
                                Data.debounceSave();
                              });
                            },
                            child: const Text("清空错题本"))),
                    Container(
                        height: 100,
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                p.clear();
                                Data.debounceSave();
                              });
                            },
                            child: const Text("清空全部记录"))),
                  ],
                ))));
  }
}

class ProblemWidget extends StatefulWidget {
  final int id;
  final _HomeWidgetState parent;
  int pid;
  bool mode; // false： 做题模式； true： 错题本模式
  int state = 0; // 0: 未作答； 1：答案错误； 2：答案正确
  bool in_wrong_list = false;
  ProblemWidget({Key? key, required this.parent, required this.id, required this.pid, required this.mode})
      : in_wrong_list = Data.problem[id].wrongProblems.contains(pid),
        super(key: key);
  @override
  _ProblemWidgetState createState() => _ProblemWidgetState();
}

class _ProblemWidgetState extends State<ProblemWidget> {
  Problem p = Problem([]);
  void onAnswer(String ans) {
    if (widget.state == 0 || widget.state == 1) {
      setState(() {
        if (ans == p.items[widget.pid].answer) {
          widget.state = 2;
          if (!widget.mode) {
            p.doneProblems.add(widget.pid);
          }
        } else {
          widget.state = 1;
          if (!widget.mode) {
            updateWrongList(true);
          }
        }
        widget.parent.forceUpdate();
        Data.debounceSave();
      });
    }
  }

  void updateWrongList(bool new_state) {
    setState(() {
      widget.in_wrong_list = new_state;
      if (new_state) {
        p.wrongProblems.add(widget.pid);
      } else {
        p.wrongProblems.remove(widget.pid);
      }
      Data.debounceSave();
    });
  }

  @override
  Widget build(BuildContext context) {
    p = Data.problem[widget.id];
    const double height = 70;
    return Scaffold(
        appBar: AppBar(
          title: Text("试卷${widget.id} (${widget.mode ? "错题本" : "刷题"}模式)"),
        ),
        body: Center(
            child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                        height: 350,
                        child: Text(
                          p.items[widget.pid].problem,
                          style: const TextStyle(fontSize: 19),
                        )),
                    Row(
                      children: [
                        Container(
                          height: height,
                          width: 80,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                bool success = true;
                                if (widget.mode) {
                                  int t = p.getPrevWrong(widget.pid);
                                  if (t != -1) {
                                    widget.pid = t;
                                    widget.state = 0;
                                    widget.in_wrong_list = true;
                                  } else {
                                    success = false;
                                  }
                                } else {
                                  if (widget.pid > 0) {
                                    widget.pid--;
                                    widget.state = 0;
                                    widget.in_wrong_list = p.wrongProblems.contains(widget.pid);
                                  } else {
                                    success = false;
                                  }
                                }
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text("没有上一题了！"),
                                  ));
                                }
                              });
                            },
                            child: const Text("上一题"),
                          ),
                        ),
                        Expanded(
                            child: SizedBox(
                                child: Text(
                          (widget.state == 0 ? "" : (widget.state == 1 ? "答案错误" : "答案 ${p.items[widget.pid].answer}")),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: widget.state == 2 ? Colors.green : Colors.red),
                        ))),
                        Container(
                          height: height,
                          width: 80,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                bool success = true;
                                if (widget.mode) {
                                  int t = p.getNextWrong(widget.pid);
                                  if (t != -1) {
                                    widget.pid = t;
                                    widget.state = 0;
                                    widget.in_wrong_list = true;
                                  } else {
                                    success = false;
                                  }
                                } else {
                                  //print('${widget.pid}, ${p.items.length}');
                                  if (widget.pid < p.items.length - 1) {
                                    widget.pid++;
                                    widget.state = 0;
                                    widget.in_wrong_list = p.wrongProblems.contains(widget.pid);
                                  } else {
                                    success = false;
                                  }
                                }
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text("没有下一题了！"),
                                  ));
                                }
                              });
                            },
                            child: const Text("下一题"),
                          ),
                        ),
                      ],
                    ),
                    Row(children: [
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: height,
                            child: OutlinedButton(
                              onPressed: () {
                                onAnswer("A");
                              },
                              child: const Text("A(√)"),
                            ),
                          )),
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: height,
                            child: OutlinedButton(
                              onPressed: () {
                                onAnswer("B");
                              },
                              child: const Text("B(×)"),
                            ),
                          )),
                    ]),
                    Row(children: [
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: height,
                            child: OutlinedButton(
                              onPressed: () {
                                onAnswer("C");
                              },
                              child: const Text("C"),
                            ),
                          )),
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: height,
                            child: OutlinedButton(
                              onPressed: () {
                                onAnswer("D");
                              },
                              child: const Text("D"),
                            ),
                          )),
                    ]),
                    SizedBox(
                      height: height,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          updateWrongList(!widget.in_wrong_list);
                        },
                        child: Text(widget.in_wrong_list ? "移出错题本" : "加入错题本"),
                      ),
                    ),
                  ],
                ))));
  }
}
