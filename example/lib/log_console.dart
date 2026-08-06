import 'dart:async';

import 'package:flutter/material.dart';

/// Widget to display Braze SDK logs in a console-like view.
class LogConsole extends StatefulWidget {
  static final _controller =
      StreamController<Map<String, String>>.broadcast();

  /// Feed a log entry to all mounted [LogConsole] instances.
  static void addLog(String message, String level) {
    _controller.add({'logString': message, 'level': level});
  }

  final double height;
  final int maxLines;
  final TextStyle logTextStyle;
  final Color backgroundColor;

  const LogConsole({
    Key? key,
    this.height = 200,
    this.maxLines = 100,
    this.logTextStyle = const TextStyle(color: Colors.white, fontSize: 12),
    this.backgroundColor = const Color(0xFF1A1A1A),
  }) : super(key: key);

  @override
  _LogConsoleState createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  /// Alpha channel values (0-255) for the console's translucent surfaces:
  /// 204 is 80% opaque, 51 is 20%.
  static const int _headerAlpha = 204;
  static const int _expandedRowAlpha = 51;

  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  StreamSubscription<Map<String, String>>? _logSubscription;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    _logSubscription = LogConsole._controller.stream.listen((data) {
      final String? logString = data['logString'];
      final String? logLevel = data['level'];
      if (logString == null) return;

      setState(() {
        _logs.add(LogEntry(content: logString));
        if (logLevel == 'error') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(logString)),
          );
        }
        if (_logs.length > widget.maxLines) {
          _logs.removeAt(0);
        }
      });

      _scrollToBottom();
    });
  }

  void _scrollListener() {
    // Show button if not at bottom of console.
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >=
          (_scrollController.position.maxScrollExtent - 50);

      setState(() {
        _showScrollToBottomButton = !isAtBottom;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getFirstLine(String text) {
    final newlineIndex = text.indexOf('\n');
    if (newlineIndex > 0) {
      return text.substring(0, newlineIndex);
    }
    return text;
  }

  bool _hasMultipleLines(String text) {
    return text.contains('\n');
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Material(
        color: widget.backgroundColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor.withAlpha(_headerAlpha),
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Braze Logger Console (${_logs.length})',
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () {
                          setState(() => _logs.clear());
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final hasMultipleLines =
                              _hasMultipleLines(log.content);

                          return GestureDetector(
                            onTap: hasMultipleLines
                                ? () {
                                    setState(() {
                                      log.isExpanded = !log.isExpanded;
                                    });
                                  }
                                : null,
                            child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 3, horizontal: 5),
                                decoration: BoxDecoration(
                                  color: log.isExpanded
                                      ? Colors.grey.withAlpha(_expandedRowAlpha)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasMultipleLines)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 6, top: 3),
                                        child: Icon(
                                          log.isExpanded
                                              ? Icons.keyboard_arrow_down
                                              : Icons.keyboard_arrow_right,
                                          size: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        log.isExpanded
                                            ? log.content
                                            : _getFirstLine(log.content),
                                        style: widget.logTextStyle,
                                        softWrap: true,
                                        maxLines: log.isExpanded ? null : 1,
                                        overflow: log.isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_showScrollToBottomButton)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white24,
                onPressed: () {
                  _scrollToBottom();
                },
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class LogEntry {
  final String content;
  bool isExpanded;

  LogEntry({required this.content, this.isExpanded = false});
}

/// Provides the shared [ValueNotifier] for log console visibility (wrap [MaterialApp]).
class LogConsoleVisibility extends InheritedNotifier<ValueNotifier<bool>> {
  const LogConsoleVisibility({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<bool> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LogConsoleVisibility>();
    assert(scope != null, 'LogConsoleVisibility must wrap MaterialApp');
    return scope!.notifier!;
  }
}

/// App bar action to show or hide the sample app's log console.
class LogConsoleToggleButton extends StatelessWidget {
  const LogConsoleToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final visible = LogConsoleVisibility.of(context);
    return ListenableBuilder(
      listenable: visible,
      builder: (context, _) {
        return IconButton(
          icon: Icon(
            visible.value ? Icons.terminal : Icons.terminal_outlined,
            color: Colors.white,
          ),
          tooltip: 'Toggle Log Console',
          onPressed: () => visible.value = !visible.value,
        );
      },
    );
  }
}
