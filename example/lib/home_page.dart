import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';
import 'package:shimmer/shimmer.dart';

import 'home_controller.dart';
import 'todo.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.title});
  final String title;
  final controller = HomeController();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  void onPressedError() {
    widget.controller.getListTodosError();
  }

  void onPressed() {
    widget.controller.getListTodos();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.getListTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: onPressedError,
            child: Text('Make error request'),
          ),
          ElevatedButton(
            onPressed: onPressed,
            child: Text('Make request'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.controller.listTodos, widget.controller.checkedTodos]),
        builder: (context, child) {
          final todosResource = widget.controller.listTodos.value;
          final checkedTodos = widget.controller.checkedTodos.value;
          
          return ListViewResourceWidget<Todo>(
            resource: todosResource,
            loadingTileQuantity: 2,
            refresh: widget.controller.getListTodos,
            loadingTile: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: CheckboxListTile(
                title: Container(
                  width: double.infinity,
                  height: 8.0,
                  color: Colors.white,
                ),
                value: false,
                onChanged: (value) {},
              ),
            ),
            tileMapper: (data) => CheckboxListTile(
              title: Text(data.title),
              value: checkedTodos[data.id.toString()] ?? data.completed,
              onChanged: (value) => widget.controller.checkTodo(data.id.toString(), value ?? false),
            ),
          );
        },
      ),
    );
  }
}
