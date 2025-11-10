import 'package:flutter/foundation.dart';
import '../../data/models/tool_result.dart';
import '../../data/repositories/tools_repository.dart';

class ToolsProvider with ChangeNotifier {
  final ToolsRepository _repository = ToolsRepository();
  
  Map<ToolType, List<ToolResult>> _toolHistory = {};
  bool _isLoading = false;

  ToolsProvider() {
    _loadHistory();
  }

  Map<ToolType, List<ToolResult>> get toolHistory => _toolHistory;
  bool get isLoading => _isLoading;

  Future<void> _loadHistory() async {
    for (final type in ToolType.values) {
      _toolHistory[type] = await _repository.getToolHistory(type);
    }
    notifyListeners();
  }

  Future<void> saveResult(ToolResult result) async {
    await _repository.saveToolResult(result);
    _toolHistory[result.type] = await _repository.getToolHistory(result.type);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repository.clearToolHistory();
    _toolHistory.clear();
    notifyListeners();
  }
}

