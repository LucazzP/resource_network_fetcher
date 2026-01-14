import 'package:flutter/material.dart';

/// A default error display widget used when no custom error widget is provided.
///
/// [DefaultErrorWidget] displays an error icon, message, and an optional
/// "Try Again" button. It's used internally by [ResourceWidget] and
/// [ListViewResourceWidget] when an error occurs and no custom error
/// widget is specified.
///
/// ## Customization
///
/// While this widget provides a simple default error UI, you should typically
/// provide your own error widget for a better user experience that matches
/// your app's design.
///
/// ## Example
///
/// ```dart
/// DefaultErrorWidget(
///   "Failed to load data",
///   onTryAgain: () => controller.refresh(),
///   textTryAgain: "Retry",
/// )
/// ```
class DefaultErrorWidget extends StatelessWidget {
  /// The error message to display to the user.
  ///
  /// This should be a user-friendly message that explains what went wrong.
  final String error;

  /// Callback function executed when the user taps the "Try Again" button.
  ///
  /// If null, the "Try Again" button will not be shown.
  final VoidCallback? onTryAgain;

  /// Custom text for the "Try Again" button.
  ///
  /// Defaults to "Try again" if not specified.
  final String? textTryAgain;

  /// Creates a [DefaultErrorWidget].
  ///
  /// The [error] parameter is required and should contain a user-friendly
  /// error message.
  ///
  /// [onTryAgain] is an optional callback that, when provided, displays
  /// a button allowing the user to retry the failed operation.
  ///
  /// [textTryAgain] allows customizing the retry button text.
  const DefaultErrorWidget(
    this.error, {
    super.key,
    this.onTryAgain,
    this.textTryAgain,
  });

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
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
