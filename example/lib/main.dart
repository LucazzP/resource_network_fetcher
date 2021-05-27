import 'package:flutter/material.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

import 'error_mapper.dart';
import 'home_page.dart';

void main() {
  Resource.setErrorMapper(ErrorMapper.from);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
