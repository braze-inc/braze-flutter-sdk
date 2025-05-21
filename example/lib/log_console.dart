import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display Braze SDK logs in a console-like view.
class LogConsole extends StatefulWidget {
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
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    // Initialize the method channel handler.
    MethodChannel('brazeLogChannel')
        .setMethodCallHandler((MethodCall call) async {
      setState(() {
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        String? logString = argumentsMap['logString'];
        String? logLevel = argumentsMap['level'];
        if (logString != null) {
          _logs.add(LogEntry(content: logString));

          if (logLevel == 'error') {
            ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
              content: new Text(logString),
            ));
          }
        }

        // Keep only the latest maxLines logs.
        if (_logs.length > widget.maxLines) {
          _logs.removeAt(0);
        }
      });

      // Always scroll to bottom on new log.
      _scrollToBottom();

      return null;
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withOpacity(0.8),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Braze Logger Console (${_logs.length})',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                                      ? Colors.grey.withOpacity(0.2)
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
    );
  }
}

class LogEntry {
  final String content;
  bool isExpanded;

  LogEntry({required this.content, this.isExpanded = false});
}
