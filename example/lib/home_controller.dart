import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';
import 'todo.dart';

class HomeController {
  final listTodos = ValueNotifier<Resource<List<Todo>>>(Resource.loading());
  Future<Resource<List<Todo>>> getListTodos() async {
    listTodos.value = Resource.loading(data: listTodos.value.data);
    final result = await NetworkBoundResources.asFuture<List<Todo>, Response<List>>(
      createCall: () => Dio().get('https://jsonplaceholder.typicode.com/todos'),
      processResponse: (result) => compute(parseTodos, result?.data),
    );
    listTodos.value = result.transformData((data) => data ?? listTodos.value.data ?? []);
    return listTodos.value;
  }

  Future<Resource<List<Todo>>> getListTodosError() async {
    listTodos.value = Resource.loading(data: listTodos.value.data);
    final result = await NetworkBoundResources.asFuture<List<Todo>, Response<List>>(
      // PUT Doesnt exists, so will throw a 404
      createCall: () => Dio().put('https://jsonplaceholder.typicode.com/todos'),
      processResponse: (result) => compute(parseTodos, result?.data),
    );
    listTodos.value = result.transformData((data) => data ?? listTodos.value.data ?? []);
    return listTodos.value;
  }

  final checkedTodos = ValueNotifier<Map<String, bool>>({});

  void checkTodo(String id, bool value) {
    checkedTodos.value = {
      ...checkedTodos.value,
      id: value,
    };
  }
}

List<Todo> parseTodos(List? todos) {
  if (todos != null) {
    return todos.map<Todo>((todo) => Todo.fromMap(Map.from(todo))).toList();
  }
  throw 'The list is not a List of Maps';
}
