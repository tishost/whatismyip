import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Interactive Terminal Widget - Allows typing commands directly like a real terminal
class InteractiveTerminal extends StatefulWidget {
  final Function(String command) onCommand;
  final List<String> outputLines;
  final String prompt;
  final bool isExecuting;
  final VoidCallback? onClear;

  const InteractiveTerminal({
    super.key,
    required this.onCommand,
    required this.outputLines,
    this.prompt = '\$ ',
    this.isExecuting = false,
    this.onClear,
  });

  @override
  State<InteractiveTerminal> createState() => _InteractiveTerminalState();
}

class _InteractiveTerminalState extends State<InteractiveTerminal> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _inputController = TextEditingController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentInput = '';
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void didUpdateWidget(InteractiveTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when output lines change
    if (widget.outputLines.length != oldWidget.outputLines.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _onInputChanged() {
    _currentInput = _inputController.text;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(1);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _executeCommand();
      }
    }
  }

  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      if (_historyIndex == -1) {
        // Save current input before navigating
        if (_currentInput.isNotEmpty) {
          _currentInput = _inputController.text;
        }
        _historyIndex = _commandHistory.length - 1;
      } else {
        _historyIndex += direction;
        if (_historyIndex < 0) {
          _historyIndex = -1;
          _inputController.text = _currentInput;
          return;
        }
        if (_historyIndex >= _commandHistory.length) {
          _historyIndex = _commandHistory.length - 1;
        }
      }

      if (_historyIndex >= 0 && _historyIndex < _commandHistory.length) {
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    });
  }

  void _executeCommand() {
    final command = _inputController.text.trim();
    if (command.isEmpty || widget.isExecuting) return;

    // Add to history
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
      if (_commandHistory.length > 100) {
        _commandHistory.removeAt(0);
      }
    }
    _historyIndex = -1;
    _currentInput = '';

    // Clear input
    _inputController.clear();

    // Execute command
    widget.onCommand(command);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyPress,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // Terminal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (widget.onClear != null)
                      TextButton(
                        onPressed: widget.onClear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Terminal Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.outputLines.length + 1, // +1 for input line
                    itemBuilder: (context, index) {
                      if (index < widget.outputLines.length) {
                        // Output lines
                        final line = widget.outputLines[index];
                        final isError = line.startsWith('✗') ||
                            line.startsWith('Error:') ||
                            line.toLowerCase().contains('error');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: SelectableText(
                            line.isEmpty ? ' ' : line, // Show space for empty lines
                            style: TextStyle(
                              color: isError
                                  ? Colors.red[300]
                                  : Colors.green[300],
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        );
                      } else {
                        // Input line with prompt
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.prompt,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  focusNode: _focusNode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _executeCommand(),
                                  enabled: !widget.isExecuting,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              if (widget.isExecuting)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                              else if (_showCursor)
                                Container(
                                  width: 8,
                                  height: 16,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

