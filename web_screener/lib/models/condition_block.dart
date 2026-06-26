class ConfigurableIndicator {
  String name;
  String timeframe;
  int offset;
  Map<String, dynamic> parameters;
  String? outputLine; // e.g., 'upper', 'lower', 'histogram'

  ConfigurableIndicator({
    required this.name,
    this.timeframe = '1h',
    this.offset = -1,
    this.outputLine,
    Map<String, dynamic>? parameters,
  }) : parameters = parameters ?? {};

  String get friendlyOffset {
    if (offset == 0) return 'Current';
    if (offset == -1) return 'Last Closed';
    if (offset == -2) return '2nd Last';
    if (offset == -3) return '3rd Last';
    return '${offset.abs()} ago';
  }

  String getFriendlyLabel([String? baseTimeframe]) {
    final paramsString = parameters.isEmpty 
        ? '' 
        : '(${parameters.values.map((v) => v is double && v == v.toInt() ? v.toInt() : v).join(", ")})';
    
    final outputString = outputLine != null && outputLine != 'value' && outputLine != 'macd' && outputLine != 'k' && outputLine != 'basis'
        ? ' [$outputLine]' 
        : '';
        
    final tfString = (baseTimeframe != null && timeframe.toLowerCase() == baseTimeframe.toLowerCase())
        ? ''
        : ' $timeframe';
        
    return '$name$outputString$paramsString ($friendlyOffset)$tfString';
  }

  @override
  String toString() {
    return getFriendlyLabel();
  }

  ConfigurableIndicator copyWith({
    String? name,
    String? timeframe,
    int? offset,
    String? outputLine,
    Map<String, dynamic>? parameters,
  }) {
    return ConfigurableIndicator(
      name: name ?? this.name,
      timeframe: timeframe ?? this.timeframe,
      offset: offset ?? this.offset,
      outputLine: outputLine ?? this.outputLine,
      parameters: parameters ?? Map.from(this.parameters),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'timeframe': timeframe,
    'offset': offset,
    'outputLine': outputLine,
    'parameters': parameters,
  };

  static Map<String, dynamic> getDefaultParameters(String name) {
    switch (name) {
      // Price Action (no parameters)
      case 'Close': case 'Open': case 'High': case 'Low': case 'Volume':
        return {};

      // Trend & Overlap
      case 'SMA': return {'period': 20};
      case 'EMA': return {'period': 9};
      case 'WMA': return {'period': 9};
      case 'DEMA': return {'period': 9};
      case 'TEMA': return {'period': 9};
      case 'AVG_HIGH': return {'period': 14};
      case 'AVG_CLOSE': return {'period': 14};
      case 'AVG_VOL': return {'period': 14};
      case 'TRIMA': return {'period': 30};
      case 'KAMA': return {'period': 30};
      case 'ALMA': return {'period': 9, 'offset': 0.85, 'sigma': 6.0};
      case 'HMA': return {'period': 9};
      case 'ZLEMA': return {'period': 21};
      case 'VWMA': return {'period': 20};
      case 'VWAP': return {};
      case 'MACD': return {'fast_period': 12, 'slow_period': 26, 'signal_period': 9};
      case 'MACDEXT': return {'fast_period': 12, 'slow_period': 26, 'signal_period': 9};
      case 'BBANDS': return {'period': 20, 'std_dev': 2.0};
      case 'SAR': return {'acceleration': 0.02, 'maximum': 0.2};
      case 'SAREXT': return {'start_value': 0.0, 'offset_on_reverse': 0.0, 'acceleration_init_long': 0.02, 'acceleration_long': 0.02, 'acceleration_max_long': 0.2, 'acceleration_init_short': 0.02, 'acceleration_short': 0.02, 'acceleration_max_short': 0.2};
      case 'HT_TRENDLINE': return {};
      case 'SUPERTREND': return {'period': 10, 'multiplier': 3.0};
      case 'ICHIMOKU': return {'tenkan_period': 9, 'kijun_period': 26, 'senkou_b_period': 52};

      // Momentum & Oscillators
      case 'RSI': return {'period': 14};
      case 'STOCH': return {'k_period': 5, 'd_period': 3, 's_period': 3};
      case 'STOCHF': return {'k_period': 5, 'd_period': 3};
      case 'STOCHRSI': return {'period': 14, 'k_period': 3, 'd_period': 3};
      case 'MFI': return {'period': 14};
      case 'ADX': return {'period': 14};
      case 'ADXR': return {'period': 14};
      case 'APO': return {'fast_period': 12, 'slow_period': 26};
      case 'PPO': return {'fast_period': 12, 'slow_period': 26};
      case 'MOM': return {'period': 10};
      case 'CMO': return {'period': 14};
      case 'ROC': return {'period': 10};
      case 'ROCR': return {'period': 10};
      case 'TRIX': return {'period': 30};
      case 'ULTOSC': return {'period1': 7, 'period2': 14, 'period3': 28};
      case 'WILLR': return {'period': 14};
      case 'CCI': return {'period': 20};
      case 'BOP': return {};
      case 'AROON': return {'period': 25};
      case 'AROONOSC': return {'period': 25};
      case 'CHOP': return {'period': 14};
      case 'SQUEEZE': return {'bb_period': 20, 'bb_mult': 2.0, 'kc_period': 20, 'kc_mult': 1.5};
      case 'VORTEX': return {'period': 14};

      // Volatility
      case 'ATR': return {'period': 14};
      case 'NATR': return {'period': 14};
      case 'TRANGE': return {};
      case 'KC': return {'period': 20, 'multiplier': 2.0};
      case 'DC': return {'period': 20};
      case 'UI': return {'period': 14};

      // Volume
      case 'AD': return {};
      case 'ADOSC': return {'fast_period': 3, 'slow_period': 10};
      case 'OBV': return {};
      case 'CMF': return {'period': 20};
      case 'EFI': return {'period': 13};
      case 'PVT': return {};

      // Candlestick Patterns (no parameters)
      default: return {};
    }
  }

  factory ConfigurableIndicator.fromJson(Map<String, dynamic> json) => ConfigurableIndicator(
    name: json['name'],
    timeframe: json['timeframe'] ?? '1h',
    offset: json['offset'] ?? -1,
    outputLine: json['outputLine'],
    parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
  );
}

abstract class ExpressionNode {
  ExpressionNode();
  Map<String, dynamic> toJson();
  List<ConfigurableIndicator> getIndicators();
  factory ExpressionNode.fromJson(Map<String, dynamic> json) {
    if (json['nodeType'] == 'Indicator') return IndicatorNode.fromJson(json);
    if (json['nodeType'] == 'Value') return ValueNode.fromJson(json);
    if (json['nodeType'] == 'Math') return MathNode.fromJson(json);
    return ValueNode(0.0);
  }
}

class IndicatorNode extends ExpressionNode {
  ConfigurableIndicator indicator;
  IndicatorNode(this.indicator);
  @override
  Map<String, dynamic> toJson() => {'nodeType': 'Indicator', 'indicator': indicator.toJson()};
  @override
  List<ConfigurableIndicator> getIndicators() => [indicator];
  factory IndicatorNode.fromJson(Map<String, dynamic> json) => IndicatorNode(ConfigurableIndicator.fromJson(json['indicator']));
}

class ValueNode extends ExpressionNode {
  double value;
  ValueNode(this.value);
  @override
  Map<String, dynamic> toJson() => {'nodeType': 'Value', 'value': value};
  @override
  List<ConfigurableIndicator> getIndicators() => [];
  factory ValueNode.fromJson(Map<String, dynamic> json) => ValueNode(double.tryParse(json['value'].toString()) ?? 0.0);
}

class MathNode extends ExpressionNode {
  ExpressionNode left;
  String operator; // '+', '-', '*', '/'
  ExpressionNode right;
  MathNode({required this.left, required this.operator, required this.right});
  @override
  Map<String, dynamic> toJson() => {'nodeType': 'Math', 'left': left.toJson(), 'operator': operator, 'right': right.toJson()};
  @override
  List<ConfigurableIndicator> getIndicators() => [...left.getIndicators(), ...right.getIndicators()];
  factory MathNode.fromJson(Map<String, dynamic> json) => MathNode(
    left: ExpressionNode.fromJson(json['left']),
    operator: json['operator'] ?? '+',
    right: ExpressionNode.fromJson(json['right']),
  );
}

class ConditionBlock {
  String id;
  String type; // "IF", "AND", "OR"
  ExpressionNode leftNode;
  String operator;
  ExpressionNode rightNode;
  ExpressionNode? rightNode2; // For 'Between' operator


  ConditionBlock({
    required this.id,
    required this.type,
    required this.leftNode,
    required this.operator,
    required this.rightNode,
    this.rightNode2,
  });

  // Backward compatibility getters
  ConfigurableIndicator get subject => (leftNode is IndicatorNode) 
      ? (leftNode as IndicatorNode).indicator 
      : ConfigurableIndicator(name: 'Select...');
  
  set subject(ConfigurableIndicator s) {
    leftNode = IndicatorNode(s);
  }

  bool get isValueIndicator => rightNode is IndicatorNode;
  
  dynamic get value {
    if (rightNode is IndicatorNode) return (rightNode as IndicatorNode).indicator;
    if (rightNode is ValueNode) return (rightNode as ValueNode).value;
    return 0.0;
  }

  set value(dynamic val) {
    if (val is ConfigurableIndicator) {
      rightNode = IndicatorNode(val);
    } else {
      rightNode = ValueNode(double.tryParse(val.toString()) ?? 0.0);
    }
  }

  factory ConditionBlock.empty({String initialSubject = 'Select...'}) {
    return ConditionBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'IF',
      leftNode: IndicatorNode(ConfigurableIndicator(name: initialSubject)),
      operator: 'Select...',
      rightNode: ValueNode(0.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'leftNode': leftNode.toJson(),
    'operator': operator,
    'rightNode': rightNode.toJson(),
    'rightNode2': rightNode2?.toJson(),
  };

  factory ConditionBlock.fromJson(Map<String, dynamic> json) {
    ExpressionNode parseLegacyRight(dynamic val, bool isInd) {
      if (isInd && val is Map<String, dynamic>) {
        return IndicatorNode(ConfigurableIndicator.fromJson(val));
      } else {
        return ValueNode(double.tryParse(val.toString()) ?? 0.0);
      }
    }

    final leftNode = json['leftNode'] != null
        ? ExpressionNode.fromJson(json['leftNode'])
        : (json['subject'] != null ? IndicatorNode(ConfigurableIndicator.fromJson(json['subject'])) : IndicatorNode(ConfigurableIndicator(name: 'Select...')));

    final rightNode = json['rightNode'] != null
        ? ExpressionNode.fromJson(json['rightNode'])
        : parseLegacyRight(json['value'], json['isValueIndicator'] ?? false);

    ExpressionNode? rightNode2;
    if (json['rightNode2'] != null) {
      rightNode2 = ExpressionNode.fromJson(json['rightNode2']);
    } else if (json['value2'] != null && json['value2'].toString().isNotEmpty) {
      rightNode2 = parseLegacyRight(json['value2'], json['isValue2Indicator'] ?? false);
    }

    return ConditionBlock(
      id: json['id'],
      type: json['type'],
      leftNode: leftNode,
      operator: json['operator'] ?? 'Select...',
      rightNode: rightNode,
      rightNode2: rightNode2,
    );
  }
}

class StrategyRule {
  String id;
  String action; // "Long", "Short"
  List<ConditionBlock> conditions;

  StrategyRule({
    required this.id,
    this.action = 'Long',
    List<ConditionBlock>? conditions,
  }) : conditions = conditions ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'conditions': conditions.map((e) => e.toJson()).toList(),
  };

  factory StrategyRule.fromJson(Map<String, dynamic> json) => StrategyRule(
    id: json['id'],
    action: json['action'] ?? 'Long',
    conditions: (json['conditions'] as List).map((e) => ConditionBlock.fromJson(e)).toList(),
  );

  StrategyRule copyWith({String? action, List<ConditionBlock>? conditions}) {
    return StrategyRule(
      id: id,
      action: action ?? this.action,
      conditions: conditions ?? List.from(this.conditions),
    );
  }
}

enum TargetType { fixed, structural, indicator, riskReward }

class TargetConfig {
  TargetType type;
  String? value; // For fixed (percentage) or structural (lookback) or riskReward (multiplier)
  ConfigurableIndicator? indicator;

  TargetConfig({
    required this.type,
    this.value,
    this.indicator,
  });

  factory TargetConfig.defaultSL() => TargetConfig(type: TargetType.fixed, value: '2.0');
  factory TargetConfig.defaultTP() => TargetConfig(type: TargetType.fixed, value: '5.0');

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
    'indicator': indicator?.toJson(),
  };

  factory TargetConfig.fromJson(Map<String, dynamic> json) => TargetConfig(
    type: TargetType.values.firstWhere((e) => e.name == json['type'], orElse: () => TargetType.fixed),
    value: json['value'],
    indicator: json['indicator'] != null && json['indicator'] is Map<String, dynamic> 
        ? ConfigurableIndicator.fromJson(json['indicator']) 
        : null,
  );

  TargetConfig copyWith({TargetType? type, String? value, ConfigurableIndicator? indicator}) {
    return TargetConfig(
      type: type ?? this.type,
      value: value ?? this.value,
      indicator: indicator ?? this.indicator,
    );
  }

  @override
  String toString() {
    switch (type) {
      case TargetType.fixed: return '$value%';
      case TargetType.structural: return 'Pivot $value Candles';
      case TargetType.indicator: return indicator?.toString() ?? 'Select Indicator';
      case TargetType.riskReward: return '${value}x Risk';
    }
  }
}

class TradeSetup {
  String setupType; // "Fixed", "Conditional"
  TargetConfig longTP;
  TargetConfig longSL;
  TargetConfig shortTP;
  TargetConfig shortSL;

  TradeSetup({
    this.setupType = 'Fixed',
    TargetConfig? longTP,
    TargetConfig? longSL,
    TargetConfig? shortTP,
    TargetConfig? shortSL,
  }) : longTP = longTP ?? TargetConfig.defaultTP(),
       longSL = longSL ?? TargetConfig.defaultSL(),
       shortTP = shortTP ?? TargetConfig.defaultTP(),
       shortSL = shortSL ?? TargetConfig.defaultSL();

  Map<String, dynamic> toJson() => {
    'setupType': setupType,
    'longTP': longTP.toJson(),
    'longSL': longSL.toJson(),
    'shortTP': shortTP.toJson(),
    'shortSL': shortSL.toJson(),
  };

  factory TradeSetup.fromJson(Map<String, dynamic> json) => TradeSetup(
    setupType: json['setupType'] ?? 'Fixed',
    longTP: (json['longTP'] is Map<String, dynamic>) ? TargetConfig.fromJson(json['longTP'] as Map<String, dynamic>) : null,
    longSL: (json['longSL'] is Map<String, dynamic>) ? TargetConfig.fromJson(json['longSL'] as Map<String, dynamic>) : null,
    shortTP: (json['shortTP'] is Map<String, dynamic>) ? TargetConfig.fromJson(json['shortTP'] as Map<String, dynamic>) : null,
    shortSL: (json['shortSL'] is Map<String, dynamic>) ? TargetConfig.fromJson(json['shortSL'] as Map<String, dynamic>) : null,
  );
}


class TradingStrategy {
  String id;
  String name;
  String baseTimeframe;
  String exchange; // 'Binance', 'Bybit', 'CoinDCX', 'OKX', 'Kraken', 'KuCoin', 'VALR', 'Bitstamp', 'Upbit'
  String marketType; // 'Spot', 'Futures'
  bool isMultiTimeframe;
  double? volumeFilterMillions;
  String? volumeFilterTimeframe;
  List<StrategyRule> rules;
  TradeSetup globalSetup;

  TradingStrategy({
    required this.id,
    required this.name,
    this.baseTimeframe = '1h',
    this.exchange = 'Binance',
    this.marketType = 'Futures',
    this.isMultiTimeframe = false,
    this.volumeFilterMillions,
    this.volumeFilterTimeframe,
    List<StrategyRule>? rules,
    TradeSetup? globalSetup,
  }) : rules = rules ?? [],
       globalSetup = globalSetup ?? TradeSetup();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseTimeframe': baseTimeframe,
    'exchange': exchange,
    'marketType': marketType,
    'isMultiTimeframe': isMultiTimeframe,
    'volumeFilterMillions': volumeFilterMillions,
    'volumeFilterTimeframe': volumeFilterTimeframe,
    'rules': rules.map((e) => e.toJson()).toList(),
    'globalSetup': globalSetup.toJson(),
  };

  factory TradingStrategy.fromJson(Map<String, dynamic> json) => TradingStrategy(
    id: json['id'],
    name: json['name'],
    baseTimeframe: json['baseTimeframe'] ?? '1h',
    exchange: json['exchange'] ?? 'Binance',
    marketType: json['marketType'] ?? 'Futures',
    isMultiTimeframe: json['isMultiTimeframe'] ?? false,
    volumeFilterMillions: json['volumeFilterMillions'] != null ? double.tryParse(json['volumeFilterMillions'].toString().replaceAll(',', '.')) : null,
    volumeFilterTimeframe: json['volumeFilterTimeframe'],
    rules: (json['rules'] as List).map((e) => StrategyRule.fromJson(e)).toList(),
    globalSetup: TradeSetup.fromJson(json['globalSetup']),
  );
}

