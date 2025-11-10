enum ToolType {
  whois,
  dns,
  ping,
  speedTest,
  portScanner,
  traceroute,
  networkScan,
}

class NetworkTool {
  final ToolType type;
  final String name;
  final String icon;
  final String description;
  final bool isPro;

  NetworkTool({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    this.isPro = false,
  });

  static List<NetworkTool> get allTools => [
    NetworkTool(
      type: ToolType.whois,
      name: 'WHOIS Lookup',
      icon: '🔍',
      description: 'Lookup domain registration info',
    ),
    NetworkTool(
      type: ToolType.dns,
      name: 'DNS Lookup',
      icon: '🌐',
      description: 'Query DNS records (A, MX, NS, TXT)',
    ),
    NetworkTool(
      type: ToolType.ping,
      name: 'Ping Test',
      icon: '📡',
      description: 'Test network latency',
    ),
    NetworkTool(
      type: ToolType.speedTest,
      name: 'Speed Test',
      icon: '⚡',
      description: 'Test download/upload speed',
      isPro: true,
    ),
    NetworkTool(
      type: ToolType.portScanner,
      name: 'Port Scanner',
      icon: '🔒',
      description: 'Scan open ports',
      isPro: true,
    ),
    NetworkTool(
      type: ToolType.traceroute,
      name: 'Traceroute',
      icon: '🗺️',
      description: 'Trace network path',
      isPro: true,
    ),
  ];
}

class ToolResult {
  final ToolType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool success;
  final String? error;

  ToolResult({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.success = true,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();
}

