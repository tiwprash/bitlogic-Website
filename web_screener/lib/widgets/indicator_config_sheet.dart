import 'package:flutter/material.dart';
import '../models/condition_block.dart';
import '../utils/timeframe_config.dart';
import 'indicator_search_sheet.dart';

class IndicatorConfigSheet extends StatefulWidget {
  final ConfigurableIndicator indicator;
  final String exchange;
  final Function(ConfigurableIndicator) onSave;
  final VoidCallback? onChange;
  final VoidCallback? onReset;
  final bool isMultiTimeframe;

  const IndicatorConfigSheet({
    super.key,
    required this.indicator,
    required this.exchange,
    required this.onSave,
    this.onChange,
    this.onReset,
    this.isMultiTimeframe = false,
  });

  static void show(
    BuildContext context, 
    ConfigurableIndicator indicator, 
    String exchange,
    Function(ConfigurableIndicator) onSave, {
    VoidCallback? onChange,
    VoidCallback? onReset,
    bool isMultiTimeframe = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IndicatorConfigSheet(
        indicator: indicator, 
        exchange: exchange,
        onSave: onSave,
        onChange: onChange,
        onReset: onReset,
        isMultiTimeframe: isMultiTimeframe,
      ),
    );
  }

  /// Static helper â€” lets callers check if a config sheet is needed
  /// without instantiating the widget.
  static List<String> getAvailableLines(String name) {
    switch (name.toUpperCase()) {
      case 'BBANDS': return ['basis', 'upper', 'lower'];
      case 'MACD': case 'MACDEXT': return ['macd', 'signal', 'histogram'];
      case 'STOCH': case 'STOCHF': case 'STOCHRSI': return ['k', 'd'];
      case 'ICHIMOKU': return ['tenkan', 'kijun', 'senkou_a', 'senkou_b', 'chikou'];
      case 'SUPERTREND': return ['value', 'direction'];
      case 'AROON': return ['up', 'down'];
      case 'KC': case 'DC': return ['upper', 'middle', 'lower'];
      case 'VORTEX': return ['plus', 'minus'];
      default: return [];
    }
  }

  @override
  State<IndicatorConfigSheet> createState() => _IndicatorConfigSheetState();
}

class _IndicatorConfigSheetState extends State<IndicatorConfigSheet> {
  late ConfigurableIndicator _currentIndicator;
  final Map<String, TextEditingController> _controllers = {};
  late final List<String> _timeframes;

  final Map<int, String> _offsets = {
    0: 'Current (Unclosed)',
    -1: 'Last Closed',
    -2: '2nd Last',
    -3: '3rd Last',
    -4: '4th Last',
  };

  final Map<String, String> _lineLabels = {
    // Bands
    'basis': 'Basis (Middle Band)',
    'upper': 'Upper Band',
    'lower': 'Lower Band',
    'middle': 'Middle Line',
    // MACD
    'macd': 'MACD Line',
    'signal': 'Signal Line',
    'histogram': 'Histogram',
    // Stochastic
    'k': '%K Line',
    'd': '%D Line',
    // Ichimoku
    'tenkan': 'Tenkan-sen (Conversion)',
    'kijun': 'Kijun-sen (Base)',
    'senkou_a': 'Senkou Span A (Lead 1)',
    'senkou_b': 'Senkou Span B (Lead 2)',
    'chikou': 'Chikou Span (Lagging)',
    // Supertrend
    'value': 'Main Value',
    'direction': 'Trend Direction (1/-1)',
    // Aroon
    'up': 'Aroon Up',
    'down': 'Aroon Down',
    // Vortex
    'plus': 'VI+ (Positive)',
    'minus': 'VI- (Negative)',
    // APO / PPO
    'apo': 'APO Value',
    'ppo': 'PPO Value',
    // ADOSC
    'adosc': 'A/D Oscillator',
  };

  List<String> _getAvailableLines(String name) {
    switch (name.toUpperCase()) {
      // Bollinger Bands
      case 'BBANDS':
        return ['basis', 'upper', 'lower'];
      // MACD variants
      case 'MACD':
      case 'MACDEXT':
        return ['macd', 'signal', 'histogram'];
      // Stochastic variants
      case 'STOCH':
      case 'STOCHF':
      case 'STOCHRSI':
        return ['k', 'd'];
      // Ichimoku
      case 'ICHIMOKU':
        return ['tenkan', 'kijun', 'senkou_a', 'senkou_b', 'chikou'];
      // Supertrend
      case 'SUPERTREND':
        return ['value', 'direction'];
      // Aroon
      case 'AROON':
        return ['up', 'down'];
      // Keltner & Donchian Channels
      case 'KC':
      case 'DC':
        return ['upper', 'middle', 'lower'];
      // Vortex
      case 'VORTEX':
        return ['plus', 'minus'];
      // All single-output indicators fall through to default
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _timeframes = TimeframeConfig.getSupportedTimeframes(widget.exchange);
    _currentIndicator = widget.indicator.copyWith();

    // Normalize timeframe to lowercase to match _timeframes list
    _currentIndicator.timeframe = _currentIndicator.timeframe.toLowerCase();
    if (!_timeframes.contains(_currentIndicator.timeframe)) {
      _currentIndicator.timeframe = '1h';
    }
    
    // Initialize default parameters if empty
    if (_currentIndicator.parameters.isEmpty) {
      _initDefaultParameters();
    }

    // Initialize default output line if multi-output indicator
    if (_currentIndicator.outputLine == null) {
      final available = _getAvailableLines(_currentIndicator.name);
      if (available.isNotEmpty) {
        _currentIndicator.outputLine = available.first;
      }
    }
  }

  void _initDefaultParameters() {
    final name = _currentIndicator.name;
    _currentIndicator.parameters = ConfigurableIndicator.getDefaultParameters(name);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
        start: 20,
        end: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure ${_currentIndicator.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (widget.onChange != null || widget.onReset != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 4.0),
                      child: Row(
                        children: [
                          if (widget.onChange != null)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onChange!();
                              },
                              icon: const Icon(Icons.swap_horiz, size: 14, color: Color(0xFF4361EE)),
                              label: const Text('Change', style: TextStyle(color: Color(0xFF4361EE), fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          if (widget.onChange != null && widget.onReset != null)
                            const Text('  â€¢  ', style: TextStyle(color: Colors.white24, fontSize: 12)),
                          if (widget.onReset != null)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onReset!();
                              },
                              icon: const Icon(Icons.delete_outline, size: 14, color: const Color(0xFFFF3B30)),
                              label: const Text('Reset', style: TextStyle(color: const Color(0xFFFF3B30), fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white12),
          
          // Timeframe
          if (widget.isMultiTimeframe) ...[
            const Text('Timeframe', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _currentIndicator.timeframe,
              items: _timeframes,
              itemLabel: (val) => val == '1m' ? '1 min' : 
                                 val == '5m' ? '5 min' :
                                 val == '15m' ? '15 min' :
                                 val == '30m' ? '30 min' :
                                 val!.toUpperCase(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currentIndicator.timeframe = val);
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // Offset
          const Text('Candle Offset', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          _buildDropdown<int>(
            value: _currentIndicator.offset,
            items: _offsets.keys.toList(),
            itemLabel: (val) => _offsets[val!]!,
            onChanged: (val) {
              if (val != null) {
                setState(() => _currentIndicator.offset = val);
              }
            },
          ),
          const SizedBox(height: 16),

          // Indicator Output Line (Attributes)
          if (_getAvailableLines(_currentIndicator.name).isNotEmpty) ...[
            const Text('Indicator Attribute', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _currentIndicator.outputLine ?? _getAvailableLines(_currentIndicator.name).first,
              items: _getAvailableLines(_currentIndicator.name),
              itemLabel: (val) => _lineLabels[val] ?? val!,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currentIndicator.outputLine = val);
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // Dynamic Parameters
          if (_currentIndicator.parameters.isNotEmpty) ...[
            const Text('Parameters', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._currentIndicator.parameters.entries.map((entry) {
              return _buildParameterInput(entry.key, entry.value);
            }),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_currentIndicator);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A67D8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 60), // Extra padding to prevent hiding behind taskbar
        ],
      ),
      ),
    );
  }

  Widget _buildParameterInput(String key, dynamic value) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value.toString());
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2, 
            child: Text(
              key.replaceAll('_', ' ').split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' '),
              style: const TextStyle(fontSize: 13, color: Colors.white60)
            )
          ),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 38,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), 
                    borderSide: const BorderSide(color: Colors.white10)
                  ),
                ),
                controller: _controllers[key],
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                onChanged: (val) {
                  final numValue = double.tryParse(val.replaceAll(',', '.'));
                  if (numValue != null) {
                    _currentIndicator.parameters[key] = numValue;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF2C2C2E),
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
      ),
    );
  }
}
