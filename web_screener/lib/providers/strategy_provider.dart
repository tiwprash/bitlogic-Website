import 'package:flutter/foundation.dart';
import '../models/condition_block.dart';
import '../services/strategy_storage.dart';
import '../utils/timeframe_config.dart';

class StrategyProvider with ChangeNotifier {
  Future<void> loadStrategies() async {}
  TradingStrategy _currentStrategy = TradingStrategy(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'Untitled Strategy',
    baseTimeframe: '1h',
    rules: [
      StrategyRule(id: 'r_long', action: 'Long'),
      StrategyRule(id: 'r_short', action: 'Short'),
    ],
  );
  
  String? _originalName; // Tracks the name this strategy was loaded with
  String? get originalName => _originalName;

  TradingStrategy get currentStrategy => _currentStrategy;
  List<StrategyRule> get rules => _currentStrategy.rules;
  TradeSetup get tradeSetup => _currentStrategy.globalSetup;

  // Rule Management
  void addRule(String action) {
    final count = _currentStrategy.rules.where((r) => r.action == action).length;
    if (count >= 2) return; // Hard limit of 2 per side

    _currentStrategy.rules.add(StrategyRule(
      id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
      action: action,
    ));
    notifyListeners();
  }

  void removeRule(String ruleId) {
    _currentStrategy.rules.removeWhere((r) => r.id == ruleId);
    notifyListeners();
  }

  void updateRuleAction(String ruleId, String action) {
    final index = _currentStrategy.rules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      _currentStrategy.rules[index].action = action;
      notifyListeners();
    }
  }

  // Block Management per Rule (Entry)
  void addBlockToRule(String ruleId, String subject, {ConfigurableIndicator? indicator}) {
    final ruleIndex = _currentStrategy.rules.indexWhere((r) => r.id == ruleId);
    if (ruleIndex != -1) {
      final conditions = _currentStrategy.rules[ruleIndex].conditions;
      final newBlock = ConditionBlock.empty(initialSubject: subject);

      // If a fully configured indicator was provided, use it directly
      if (indicator != null) {
        newBlock.subject = indicator;
      }

      // Inherit master timeframe (unless already set by config sheet)
      if (indicator == null) {
        newBlock.subject.timeframe = _currentStrategy.baseTimeframe;
      }
      if (newBlock.isValueIndicator && newBlock.value is ConfigurableIndicator) {
        (newBlock.value as ConfigurableIndicator).timeframe = _currentStrategy.baseTimeframe;
      }

      if (conditions.isEmpty) {
        newBlock.type = 'IF';
      } else {
        newBlock.type = 'AND';
      }

      conditions.add(newBlock);
      notifyListeners();
    }
  }

  void setBaseTimeframe(String tf) {
    _currentStrategy.baseTimeframe = tf;
    // Bulk update all existing indicators
    for (final rule in _currentStrategy.rules) {
      for (final block in rule.conditions) {
        for (final ind in block.leftNode.getIndicators()) {
          ind.timeframe = tf;
        }
        for (final ind in block.rightNode.getIndicators()) {
          ind.timeframe = tf;
        }
        if (block.rightNode2 != null) {
          for (final ind in block.rightNode2!.getIndicators()) {
            ind.timeframe = tf;
          }
        }
      }
    }
    
    // Also update exit targets if they use indicators
    if (_currentStrategy.globalSetup.longTP.indicator != null) {
      _currentStrategy.globalSetup.longTP.indicator!.timeframe = tf;
    }
    if (_currentStrategy.globalSetup.longSL.indicator != null) {
      _currentStrategy.globalSetup.longSL.indicator!.timeframe = tf;
    }
    if (_currentStrategy.globalSetup.shortTP.indicator != null) {
      _currentStrategy.globalSetup.shortTP.indicator!.timeframe = tf;
    }
    if (_currentStrategy.globalSetup.shortSL.indicator != null) {
      _currentStrategy.globalSetup.shortSL.indicator!.timeframe = tf;
    }
    
    notifyListeners();
  }

  void setIsMultiTimeframe(bool isMulti) {
    _currentStrategy.isMultiTimeframe = isMulti;
    if (!isMulti) {
      // If switching to single timeframe, override all indicators with baseTimeframe
      setBaseTimeframe(_currentStrategy.baseTimeframe);
    }
    notifyListeners();
  }

  void removeBlockFromRule(String ruleId, String blockId) {
    final ruleIndex = _currentStrategy.rules.indexWhere((r) => r.id == ruleId);
    if (ruleIndex != -1) {
      final conditions = _currentStrategy.rules[ruleIndex].conditions;
      conditions.removeWhere((b) => b.id == blockId);
      if (conditions.isNotEmpty) {
        conditions.first.type = 'IF';
      }
      notifyListeners();
    }
  }

  void updateBlockInRule(String ruleId, String blockId, ConditionBlock newBlock) {
    final ruleIndex = _currentStrategy.rules.indexWhere((r) => r.id == ruleId);
    if (ruleIndex != -1) {
      final conditions = _currentStrategy.rules[ruleIndex].conditions;
      final blockIndex = conditions.indexWhere((b) => b.id == blockId);
      if (blockIndex != -1) {
        conditions[blockIndex] = newBlock;
        notifyListeners();
      }
    }
  }

  // Strategy Management
  void updateStrategyName(String name) {
    _currentStrategy.name = name;
    notifyListeners();
  }

  void updateTradeSetup(TradeSetup newSetup) {
    _currentStrategy.globalSetup = newSetup;
    notifyListeners();
  }

  void setExchange(String exchange) {
    _currentStrategy.exchange = exchange;
    if (exchange == 'Bitstamp' || exchange == 'Upbit') {
      _currentStrategy.marketType = 'Spot';
    }
    
    // Fallback timeframes if current ones are unsupported
    _currentStrategy.baseTimeframe = TimeframeConfig.getFallbackTimeframe(exchange, _currentStrategy.baseTimeframe);
    
    if (_currentStrategy.volumeFilterTimeframe != null) {
      _currentStrategy.volumeFilterTimeframe = TimeframeConfig.getFallbackTimeframe(exchange, _currentStrategy.volumeFilterTimeframe!);
    }
    
    for (var rule in _currentStrategy.rules) {
      for (var block in rule.conditions) {
        final indicators = [
          ...block.leftNode.getIndicators(),
          ...block.rightNode.getIndicators(),
          if (block.rightNode2 != null) ...block.rightNode2!.getIndicators(),
        ];
        for (var ind in indicators) {
          ind.timeframe = TimeframeConfig.getFallbackTimeframe(exchange, ind.timeframe);
        }
      }
    }
    
    notifyListeners();
  }

  void setMarketType(String type) {
    _currentStrategy.marketType = type;
    notifyListeners();
  }

  void setVolumeFilterTimeframe(String? tf) {
    _currentStrategy.volumeFilterTimeframe = tf;
    notifyListeners();
  }

  void setVolumeFilterMillions(double? millions) {
    _currentStrategy.volumeFilterMillions = millions;
    notifyListeners();
  }

  // Granular Target Management
  void updateTarget(String category, TargetConfig newConfig) {
    switch (category) {
      case 'longTP': _currentStrategy.globalSetup.longTP = newConfig; break;
      case 'longSL': _currentStrategy.globalSetup.longSL = newConfig; break;
      case 'shortTP': _currentStrategy.globalSetup.shortTP = newConfig; break;
      case 'shortSL': _currentStrategy.globalSetup.shortSL = newConfig; break;
    }
    notifyListeners();
  }


  // Persistence
  Future<void> saveCurrentStrategy({bool overwrite = true}) async {
    await StrategyStorageService.saveStrategy(_currentStrategy, overwrite: overwrite);
    _originalName = _currentStrategy.name; // Update original name after successful save
    notifyListeners();
  }

  Future<bool> checkIfStrategyExists(String name) async {
    return await StrategyStorageService.strategyExists(name);
  }

  Future<void> loadStrategy(String name) async {
    final loaded = await StrategyStorageService.loadStrategy(name);
    if (loaded != null) {
      _currentStrategy = loaded;
      _originalName = name; // Set original name on load
      
      // Auto-sync timeframes if it's single timeframe mode
      if (!_currentStrategy.isMultiTimeframe) {
        setBaseTimeframe(_currentStrategy.baseTimeframe);
      }
      
      notifyListeners();
    }
  }

  void loadStrategyFromModel(TradingStrategy strategy) {
    // Generate a new ID so it doesn't conflict if they save it
    _currentStrategy = TradingStrategy.fromJson(strategy.toJson());
    _currentStrategy.id = DateTime.now().millisecondsSinceEpoch.toString();
    _originalName = null; // Treat as a new unsaved strategy to avoid overwriting prebuilt source directly (unless they name it same, but we want them to save it to DB)
    
    // Auto-sync timeframes if it's single timeframe mode
    if (!_currentStrategy.isMultiTimeframe) {
      setBaseTimeframe(_currentStrategy.baseTimeframe);
    }
    
    notifyListeners();
  }

  Future<List<String>> getSavedStrategies() async {
    return await StrategyStorageService.listSavedStrategies();
  }

  Future<void> deleteSavedStrategy(String name) async {
    await StrategyStorageService.deleteStrategy(name);
  }

  void createNewStrategy() {
    _currentStrategy = TradingStrategy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Untitled Strategy',
      baseTimeframe: '1h',
      rules: [
        StrategyRule(id: 'rule_l', action: 'Long'),
        StrategyRule(id: 'rule_s', action: 'Short'),
      ],
    );
    _originalName = null; // Clear original name for new strategies
    notifyListeners();
  }
}

