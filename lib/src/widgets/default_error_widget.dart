import 'package:flutter/material.dart';

class DefaultErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onTryAgain;
  final String? textTryAgain;

  const DefaultErrorWidget(
    this.error, {
    Key? key,
    this.onTryAgain,
    this.textTryAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.error,
            size: 45,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            error,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            height: 10,
          ),
          if (onTryAgain != null)
            ElevatedButton(
              onPressed: onTryAgain,
              child: Text(
                textTryAgain ?? 'Try again',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
