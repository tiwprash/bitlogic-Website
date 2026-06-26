import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/condition_block.dart';
import '../providers/strategy_provider.dart';

class TradeSetupCard extends StatefulWidget {
  const TradeSetupCard({super.key});

  @override
  State<TradeSetupCard> createState() => _TradeSetupCardState();
}

class _TradeSetupCardState extends State<TradeSetupCard> {
  int _activeTab = 0; // 0 = LONG SETUP, 1 = SHORT SETUP

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StrategyProvider>(context);
    final setup = provider.tradeSetup;

    const accentColor = Color(0xFF828DF8); // Indigo/Purple Accent

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A25), // Deep trading theme color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.12), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Fixed vs Conditional Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk & Profit Exits',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Global exit configurations',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Custom Pill Toggle: Fixed vs Conditional
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F121C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildModeToggleButton(
                      title: 'Fixed',
                      isSelected: setup.setupType == 'Fixed',
                      onTap: () {
                        provider.updateTradeSetup(
                          TradeSetup(
                            setupType: 'Fixed',
                            longTP: setup.longTP,
                            longSL: setup.longSL,
                            shortTP: setup.shortTP,
                            shortSL: setup.shortSL,
                          ),
                        );
                      },
                    ),
                    _buildModeToggleButton(
                      title: 'Conditional',
                      isSelected: setup.setupType == 'Conditional',
                      onTap: () {
                        TargetConfig ensureConditional(TargetConfig c) {
                          if (c.type == TargetType.fixed || c.type == TargetType.indicator) {
                            return c.copyWith(type: TargetType.structural, value: '5');
                          }
                          return c;
                        }

                        provider.updateTradeSetup(
                          TradeSetup(
                            setupType: 'Conditional',
                            longTP: ensureConditional(setup.longTP),
                            longSL: ensureConditional(setup.longSL),
                            shortTP: ensureConditional(setup.shortTP),
                            shortSL: ensureConditional(setup.shortSL),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Content Area
          if (setup.setupType == 'Fixed') ...[
            // Fixed Mode UI
            Row(
              children: [
                Expanded(
                  child: _buildFixedTargetCard(
                    title: 'TAKE PROFIT',
                    value: setup.longTP.value ?? '5.0',
                    accentColor: const Color(0xFF05C270),
                    icon: Icons.flag_rounded,
                    onChanged: (val) {
                      provider.updateTarget('longTP', setup.longTP.copyWith(value: val, type: TargetType.fixed));
                      provider.updateTarget('shortTP', setup.shortTP.copyWith(value: val, type: TargetType.fixed));
                    },
                    description: 'Closes target trade in profit',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFixedTargetCard(
                    title: 'STOP LOSS',
                    value: setup.longSL.value ?? '2.0',
                    accentColor: const Color(0xFFFF3B30),
                    icon: Icons.gpp_bad_rounded,
                    onChanged: (val) {
                      provider.updateTarget('longSL', setup.longSL.copyWith(value: val, type: TargetType.fixed));
                      provider.updateTarget('shortSL', setup.shortSL.copyWith(value: val, type: TargetType.fixed));
                    },
                    description: 'Closes target trade to limit loss',
                  ),
                ),
              ],
            ),
          ] else ...[
            // Conditional Mode UI with Segment Tab Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Sliding Tabs
                Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'LONG STRATEGY EXITS',
                          isSelected: _activeTab == 0,
                          activeColor: const Color(0xFF05C270),
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          title: 'SHORT STRATEGY EXITS',
                          isSelected: _activeTab == 1,
                          activeColor: const Color(0xFFFF3B30),
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Active Tab Content
                _activeTab == 0
                    ? _buildConditionalSetup(
                        tpConfig: setup.longTP,
                        slConfig: setup.longSL,
                        onTPUpdate: (val) => provider.updateTarget('longTP', val),
                        onSLUpdate: (val) => provider.updateTarget('longSL', val),
                        isLong: true,
                      )
                    : _buildConditionalSetup(
                        tpConfig: setup.shortTP,
                        slConfig: setup.shortSL,
                        onTPUpdate: (val) => provider.updateTarget('shortTP', val),
                        onSLUpdate: (val) => provider.updateTarget('shortSL', val),
                        isLong: false,
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeToggleButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF828DF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: activeColor.withOpacity(0.3), width: 1) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white30,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedTargetCard({
    required String title,
    required String value,
    required Color accentColor,
    required IconData icon,
    required Function(String) onChanged,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 12),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  color: accentColor.withOpacity(0.85),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatefulTargetValueInput(
            initialValue: value,
            suffixText: '%',
            step: 0.5,
            minVal: 0.1,
            maxVal: 50.0,
            onChanged: onChanged,
            accentColor: accentColor,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 9, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionalSetup({
    required TargetConfig tpConfig,
    required TargetConfig slConfig,
    required Function(TargetConfig) onTPUpdate,
    required Function(TargetConfig) onSLUpdate,
    required bool isLong,
  }) {
    return Column(
      children: [
        _buildConditionalTargetCard(
          title: 'TAKE PROFIT',
          config: tpConfig,
          onUpdate: onTPUpdate,
          accentColor: const Color(0xFF05C270),
          isLong: isLong,
          isStopLoss: false,
        ),
        const SizedBox(height: 12),
        _buildConditionalTargetCard(
          title: 'STOP LOSS',
          config: slConfig,
          onUpdate: onSLUpdate,
          accentColor: const Color(0xFFFF3B30),
          isLong: isLong,
          isStopLoss: true,
        ),
      ],
    );
  }

  Widget _buildConditionalTargetCard({
    required String title,
    required TargetConfig config,
    required Function(TargetConfig) onUpdate,
    required Color accentColor,
    required bool isLong,
    required bool isStopLoss,
  }) {
    final isStructural = config.type == TargetType.structural;
    
    // Generate helpful explanation text dynamically
    String explanation = '';
    if (isStructural) {
      final candles = config.value ?? '5';
      if (isLong) {
        explanation = isStopLoss
            ? 'Exit point set at the LOWEST LOW of the last $candles candles.'
            : 'Exit point set at the HIGHEST HIGH of the last $candles candles.';
      } else {
        explanation = isStopLoss
            ? 'Exit point set at the HIGHEST HIGH of the last $candles candles.'
            : 'Exit point set at the LOWEST LOW of the last $candles candles.';
      }
    } else {
      final mult = config.value ?? '2.0';
      explanation = 'Exit point set at $mult times the distance of your stop loss safety.';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Label & Dropdown Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: accentColor.withOpacity(0.85),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              
              // Custom mini Selector
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TargetType>(
                    value: config.type,
                    icon: const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white38),
                    dropdownColor: const Color(0xFF161A25),
                    style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                    items: [TargetType.structural, TargetType.riskReward].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type == TargetType.structural ? 'Pivot High/Low' : 'Risk/Reward'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        onUpdate(config.copyWith(
                          type: val,
                          value: val == TargetType.structural ? '5' : '2.0',
                        ));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Value controller
          StatefulTargetValueInput(
            initialValue: config.value ?? (isStructural ? '5' : '2.0'),
            suffixText: isStructural ? 'Candles' : 'x Risk',
            step: isStructural ? 1.0 : 0.5,
            minVal: isStructural ? 1.0 : 0.5,
            maxVal: isStructural ? 100.0 : 10.0,
            onChanged: (val) => onUpdate(config.copyWith(value: val)),
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),

          // Real-time calculation description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.08)),
            ),
            child: Text(
              explanation,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.55),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatefulTargetValueInput extends StatefulWidget {
  final String initialValue;
  final String suffixText;
  final double step;
  final double minVal;
  final double maxVal;
  final Function(String) onChanged;
  final Color accentColor;

  const StatefulTargetValueInput({
    super.key,
    required this.initialValue,
    required this.suffixText,
    required this.step,
    required this.minVal,
    required this.maxVal,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<StatefulTargetValueInput> createState() => _StatefulTargetValueInputState();
}

class _StatefulTargetValueInputState extends State<StatefulTargetValueInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant StatefulTargetValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustValue(double delta) {
    final currentVal = double.tryParse(_controller.text.replaceAll(',', '.')) ?? widget.minVal;
    double newVal = currentVal + delta;
    if (newVal < widget.minVal) newVal = widget.minVal;
    if (newVal > widget.maxVal) newVal = widget.maxVal;

    // Keep integer format if the step is an integer
    final formatted = widget.step == 1.0 ? newVal.toInt().toString() : newVal.toStringAsFixed(1);
    
    setState(() {
      _controller.text = formatted;
    });
    widget.onChanged(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrease button
        _buildStepButton(icon: Icons.remove, onTap: () => _adjustValue(-widget.step)),
        const SizedBox(width: 6),
        
        // Input text field
        Expanded(
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onChanged: (val) {
                // Propagate value changes as typed
                widget.onChanged(val);
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: InputBorder.none,
                suffixText: widget.suffixText,
                suffixStyle: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.normal),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 6),
        // Increase button
        _buildStepButton(icon: Icons.add, onTap: () => _adjustValue(widget.step)),
      ],
    );
  }

  Widget _buildStepButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: Colors.white70),
      ),
    );
  }
}
