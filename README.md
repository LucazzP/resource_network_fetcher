# Resource Network Fetcher! 🧰

<p>
  <a href="https://pub.dev/packages/resource_network_fetcher" target="_blank">
    <img alt="Pub" src="https://img.shields.io/pub/v/resource_network_fetcher?color=orange" />
  </a>
  <a href="https://opensource.org/licenses/BSD-3-Clause" target="_blank">
    <img alt="License: BSD-3-Clause" src="https://img.shields.io/badge/BSD-3-Clause" />
  </a>
</p>

### 🧰 A package that provides you a way to track your request and avoid any errors.

We use the `NetworkBoundResources` to make a request, **process the response** using then and **centralize all errors**
of the application to a unique function that you inject and provide a **friendly message** to your users.

<br>

## 📄 Table of Contents

- **[Why should I use](#-why-should-i-use)**
- **[Examples](#-examples)**
- **[Install](#-install)**
- **[Usage](#-usage)**
  - [Setup](#-setup)
  - [AppException](#-appexception)
  - [NetworkBoundResources](#-network-bound-resources)
    - [asFuture](#-asfuture)
    - [asSimpleStream](#-assimplestream)
    - [asResourceStream](#-asresourcestream)
    - [asStream](#-asstream)
  - [Resource](#-resource)
    - [Executing a function with resource](#-executing-a-function-with-resource)
    - [States](#-states)
    - [Loading state](#-loading-state)
    - [Success state](#-success-state)
    - [Failed state](#-failed-state)
  - [ResourceMetaData](#-resource-metadata)
  - [Widgets](#-widgets)
    - [ListViewResourceWidget](#-listviewresourcewidget)
    - [ResourceWidget](#-resourceWidget)
- **[Author](#-author)**
- **[Contributing](#-contributing)**
- **[Show your support](#-show-your-support)**
- **[License](#-license)**

## ❓ Why should I use

Resource Network Fetcher **standardize** your flutter project, making all your functions that can occur **errors**
return a same value, that is the `Resource<T>`. This object helps you to pass the error for the view, making a default
way to know what message to display to the user. Other thing that it does is centralize the errors with the function
called `AppException errorMapper(e)`, that receives all errors of the application and map how you want to make the error
readable.

Other thing that it provides is the `Status`, that can be: <span style="color:#008000">Status.success<span/>,
<span style="color:#FFA500">Status.loading<span/> and <span style="color:#ff0000">
Status.error<span/>

## 📦 Examples

Examples of to-do apps that used resource_network_fetcher as base:

- [Example](https://github.com/LucazzP/resource_network_fetcher/tree/main/example)
- [Daily Nasa photo](https://github.com/LucazzP/daily_nasa_photo)
- [Todo clean](https://gitlab.com/snowman-labs/flutter-devs/project_sample_base)
- [Todo modular](https://gitlab.com/snowman-labs/flutter-devs/todo-app-example-modular)
- [Example clean](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/tree/master/example_clean)
- [Example clean complete](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/tree/master/example_clean_complete)
- [Example MVC modular](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/tree/master/example_mvc_modular)
- [Example MVC modular complete](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/tree/master/example_mvc_modular_complete)

## 🔧 Install

Follow this tutorial: [Installation tab](#-installing-tab-)

Add `resource_network_fetcher` to your pubspec.yaml file:

```yaml
dependencies:
  resource_network_fetcher:
```

Import get in files that it will be used:

```dart
import 'package:resource_network_fetcher/resource_network_fetcher.dart';
```

## 🎉 Usage

### Setup

### main.dart file

```dart
import 'package:flutter/material.dart';
import 'error_mapper.dart';

void main() {
  Resource.setErrorMapper(ErrorMapper.from);
  runApp(MyApp());
}
```

### error_mapper.dart

This is an example of minimum configuration to use, you can add other parameters to map better.

```dart
import 'package:dio/dio.dart';
import 'package:resource_network_fetcher/resource_network_fetcher.dart';

abstract class ErrorMapper {
  static AppException from(dynamic e) {
    switch (e.runtimeType) {
      case AppException:
        return e;
      case DioError:
        return AppException(
          exception: e,
          message: _dioError(e),
        );
      default:
        return AppException(
          exception: e,
          message: e.toString(),
        );
    }
  }

  static String _dioError(DioError error) {
    switch (error.type) {
      case DioErrorType.sendTimeout:
      case DioErrorType.connectTimeout:
      case DioErrorType.receiveTimeout:
        return "Connection failure, verify your internet";
      case DioErrorType.cancel:
        return "Canceled request";
      case DioErrorType.response:
      case DioErrorType.other:
      default:
    }
    if (error.response?.statusCode != null) {
      switch (error.response!.statusCode) {
        case 401:
          return "Authorization denied, check your login";
        case 403:
          return "There was an error in your request, check the data and try again";
        case 404:
          return "Not found";
        case 500:
          return "Internal server error";
        case 503:
          return "The server is currently unavailable, please try again later";
        default:
      }
    }
    return "Request error, please try again later";
  }
}
```

## ❌ AppException

We use this exception to standardize the exceptions to the app
```dart
throw AppException(
    message: "Error message",
    exception: Exception("Error message"),
    data: null,
);
```

## ↕️ Network Bound Resources

Is a conjunction of rules that run with the `Resource.asFuture` and transforms the response of the fetch to the model
specified in the `processResponse` param.
Another use for this is using for offline-first or only to cache your requests. For that you need to use the other params
of the method.

We have other options of methods, that returns a **stream** or a **Future**.
Here is an example of how to use in a simple way:

### asFuture

```dart
Future<Resource<UserEntity>> getUser() {
  return NetworkBoundResources.asFuture<UserEntity, Map<String, dynamic>>(
    createCall: _getUserFromNetwork,
    processResponse: UserEntity.fromMap,
  );
}

Future<Map<String, dynamic>> _getUserFromNetwork() async {
  return {}; /// Fetch the api
}
```

### asSimpleStream

```dart
Stream<Resource<UserEntity>> streamUser() {
  return NetworkBoundResources.asSimpleStream<UserEntity, Map<String, dynamic>>(
    createCall: _streamUserFromNetwork,
    processResponse: UserEntity.fromMap,
  );
}

Stream<Map<String, dynamic>> _streamUserFromNetwork() async* {
  yield {}; /// Fetch the api
}
```

### asResourceStream

The difference of this and the `asStream` is that with this you can return your own `Resource` in `createCall` param.

```dart
Stream<Resource<UserEntity>> streamUser() {
  return NetworkBoundResources.asResourceStream<UserEntity, Map<String, dynamic>>(
    createCall: _streamUserFromNetwork,
    processResponse: UserEntity.fromMap,
  );
}

Stream<Resource<Map<String, dynamic>>> _streamUserFromNetwork() async* {
  yield Resource.loading();
  yield Resource.success(data: {}); /// Fetch the api
}
```

### asStream

```dart
Stream<Resource<UserEntity>> streamUser() {
  return NetworkBoundResources.asStream<UserEntity, Map<String, dynamic>>(
    createCall: _streamUserFromNetwork,
    processResponse: UserEntity.fromMap,
  );
}

Stream<Map<String, dynamic>> _streamUserFromNetwork() async* {
  yield {}; /// Fetch the api
}
```


## 📜 Resource

### ⏯‍️ Executing a function with resource

Here is an example of how to run a function with the `Resource`, because with that, any error that occur inside will
be mapped with the `ErrorMapper` setted.
```dart
final result = await Resource.asFuture(() async {
  /// Here you execute wherever you want and returns the result.
  return ["one"];
});
print(result.isSuccess); /// Prints true
print(result.isFailed); /// Prints false
print(result.isLoading); /// Prints false
print(result.data); /// Prints the result: ["one"]
```

###  States

We have 3 basic states, the success, loading and failed state. But each state can storage an error
so, in the total can have 6 states, that includes having or not the data.

### Loading state

```dart
final resource = Resource.loading<T>({T data});
```

#### Loading without data state

```dart
final resource = Resource.loading<List<String>>();
```

#### Loading with data state

```dart
final resource = Resource.loading<List<String>>(data: ["one"]);
```

### Success state

```dart
final resource = Resource.success<T>({T data});
```

#### Success without data state

```dart
final resource = Resource.success<List<String>>();
```

#### Success with data state

```dart
final resource = Resource.success<List<String>>(data: ["one"]);
```

### Failed state

```dart
final resource = Resource.failed<T>({dynamic error, T data});
```

#### Failed without data state

```dart
final resource = Resource.failed<List<String>>(error: AppException());
```

#### Failed with data state

```dart
final resource = Resource.failed<List<String>>(error: AppException(), data: ["one"]);
```

### 📑 Resource MetaData

Is an information about the last returns of the `Resource`, can be very useful in streams, when you need to know the last
result that was returned. If you use the `NetworkBoundResources.asSimpleStream()`,
`NetworkBoundResources.asResourceStream()` or `NetworkBoundResources.asStream()`, the add to the `Resource.metaData` is
automatic!

Here is an example that show how you can get the `MetaData` of a `Resource`.
```dart
var resource = Resource.success(data: <String>[]);
resource = resource.addData(Status.success, ["newData"]);

// Prints the metadata of the resource
print(resource.metaData);

// Prints the last data returned by this resource
print(resource.metaData.data); /// ["newData"]

// Prints the list of the lasts 2 returns of the resource
print(resource.metaData.results); /// [ ["newData"], [] ]
```

## ❇️️ Widgets

We created widgets that helps you to summarize your code and work better with `Resource<T>` object, treating all the
states at your way!

### 🔹 ListViewResourceWidget

```dart
Widget build(BuildContext) {
  return ListViewResourceWidget(
    resource: Resource.success(data: []),
    loadingTile: ListTile(),
    tileMapper: (data) => ListTile(),
    loadingTileQuantity: 2,
    refresh: () async {},
    emptyWidget: Container(),
  );
}
```

### 🔸 ResourceWidget

```dart
Widget build(BuildContext) {
  return ResourceWidget(
    resource: Resource.success(),
    loadingWidget: CircularProgressIndicator(),
    doneWidget: (data) => Container(),
    refresh: () async {},
    errorWithDataWidget: (e, data) => Container(),
    loadingWithDataWidget: (data) => Container(),
  );
}
```

## 👤 Author

### Lucas Henrique Polazzo

- Github: [@LucazzP](https://github.com/LucazzP)
- Gitlab: [@LucazzP](https://gitlab.com/LucazzP)
- LinkedIn: [@LucazzP](https://www.linkedin.com/in/lucazzp/?locale=en_US)

## 🤝 Contributing

Contributions, issues and feature requests are welcome!<br />
Feel free to check [issues page](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/issues). You can also
take a look at
the [contributing guide](https://gitlab.com/snowman-labs/flutter-devs/snow_cli_flutter/-/blob/master/CHANGELOG.md).

## 💚 Show your support

Give a ⭐ and a like in [Pub.dev](https://pub.dev/packages/resource_network_fetcher)️ if this project helped you!

## 📝 License

Copyright © 2021 [Lucas Henrique Polazzo](https://github.com/LucazzP).<br />
This project is [BSD-3 Clause](https://opensource.org/licenses/BSD-3-Clause) licensed.

