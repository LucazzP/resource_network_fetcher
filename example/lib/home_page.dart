import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';
import 'package:shimmer/shimmer.dart';

import 'home_controller.dart';
import 'todo.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);
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
      body: ValueListenableBuilder(
        valueListenable: widget.controller.listTodos,
        builder: (context, Resource<List<Todo>> value, child) {
          return ListViewResourceWidget<Todo>(
            resource: value,
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
              value: data.completed,
              onChanged: (value) {},
            ),
          );
        },
      ),
    );
  }
}
