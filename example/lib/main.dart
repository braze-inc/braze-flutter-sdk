import 'package:flutter/material.dart';

import 'log_console.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() => runApp(const BrazeApp());

/// Root widget for the Braze Flutter sample app.
class BrazeApp extends StatefulWidget {
  const BrazeApp({super.key});

  @override
  State<BrazeApp> createState() => _BrazeAppState();
}

class _BrazeAppState extends State<BrazeApp> {
  final ValueNotifier<bool> _logConsoleVisible = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _logConsoleVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogConsoleVisibility(
      notifier: _logConsoleVisible,
      child: MaterialApp(
        title: 'Braze Flare',
        theme: BrazeAppTheme.light,
        home: const HomeScreen(),
        builder: (context, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: _logConsoleVisible,
            builder: (context, visible, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Visibility(
                    visible: visible,
                    maintainState: true,
                    maintainSize: false,
                    maintainAnimation: true,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LogConsole(height: 200),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: visible
                        ? MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: child ?? const SizedBox.shrink(),
                          )
                        : (child ?? const SizedBox.shrink()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
