import 'condition_block.dart';

class PrebuiltStrategy {
  final String shortName;
  final String description;
  final String type; // e.g., "Trend", "Reversal", "Breakout"
  final String winRate; // e.g., "54%"
  final String riskReward; // e.g., "1:2.3"
  final TradingStrategy strategy;

  PrebuiltStrategy({
    required this.shortName,
    required this.description,
    required this.type,
    required this.winRate,
    required this.riskReward,
    required this.strategy,
  });

  Map<String, dynamic> toJson() => {
    'shortName': shortName,
    'description': description,
    'type': type,
    'winRate': winRate,
    'riskReward': riskReward,
    'strategy': strategy.toJson(),
  };

  factory PrebuiltStrategy.fromJson(Map<String, dynamic> json) => PrebuiltStrategy(
    shortName: json['shortName'] ?? '',
    description: json['description'] ?? '',
    type: json['type'] ?? '',
    winRate: json['winRate'] ?? '',
    riskReward: json['riskReward'] ?? '',
    strategy: TradingStrategy.fromJson(json['strategy']),
  );
}
