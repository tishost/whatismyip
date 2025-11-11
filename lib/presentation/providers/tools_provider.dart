import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tool_result.dart';
import '../../data/repositories/tools_repository.dart';

class ToolsState {
  final Map<ToolType, List<ToolResult>> toolHistory;
  final bool isLoading;

  ToolsState({
    required this.toolHistory,
    required this.isLoading,
  });

  ToolsState copyWith({
    Map<ToolType, List<ToolResult>>? toolHistory,
    bool? isLoading,
  }) {
    return ToolsState(
      toolHistory: toolHistory ?? this.toolHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ToolsNotifier extends StateNotifier<ToolsState> {
  final ToolsRepository _repository = ToolsRepository();

  ToolsNotifier() : super(ToolsState(toolHistory: {}, isLoading: true)) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true);
    final history = <ToolType, List<ToolResult>>{};
    for (final type in ToolType.values) {
      history[type] = await _repository.getToolHistory(type);
    }
    state = state.copyWith(toolHistory: history, isLoading: false);
  }

  Future<void> saveResult(ToolResult result) async {
    await _repository.saveToolResult(result);
    final updatedHistory = Map<ToolType, List<ToolResult>>.from(state.toolHistory);
    updatedHistory[result.type] = await _repository.getToolHistory(result.type);
    state = state.copyWith(toolHistory: updatedHistory);
  }

  Future<void> clearHistory() async {
    await _repository.clearToolHistory();
    state = state.copyWith(toolHistory: {});
  }
}

final toolsProvider = StateNotifierProvider<ToolsNotifier, ToolsState>((ref) {
  return ToolsNotifier();
});
