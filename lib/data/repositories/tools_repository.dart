import '../models/tool_result.dart';

class ToolsRepository {
  final List<ToolResult> _toolHistory = [];

  Future<ToolResult> saveToolResult(ToolResult result) async {
    _toolHistory.add(result);
    return result;
  }

  Future<List<ToolResult>> getToolHistory(ToolType type) async {
    return _toolHistory.where((r) => r.type == type).toList();
  }

  Future<void> clearToolHistory() async {
    _toolHistory.clear();
  }
}

