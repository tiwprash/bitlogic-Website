import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/access_config.dart';
import '../services/user_usage_service.dart';
import '../screens/auth/login_screen.dart';
import '../models/condition_block.dart';
import '../providers/strategy_provider.dart';
import '../widgets/condition_block_card.dart';
import '../widgets/indicator_search_sheet.dart';
import '../widgets/indicator_config_sheet.dart';
import '../widgets/trade_setup_card.dart';
import '../widgets/prebuilt_strategies_modal.dart';
import 'scan_results_screen.dart';
import 'scan_history_screen.dart';
import 'home_screen.dart';
import '../services/database_service.dart';
import '../widgets/app_toast.dart';
import '../services/rating_service.dart';

import '../widgets/indicator_config_sheet.dart';
import '../utils/timeframe_config.dart';

class StrategyTab extends StatefulWidget {
  const StrategyTab({super.key});

  @override
  State<StrategyTab> createState() => _StrategyTabState();
}

class _StrategyTabState extends State<StrategyTab> {
  final TextEditingController _nameController = TextEditingController();
  String? _currentStrategyId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncController(TradingStrategy strategy) {
    if (_currentStrategyId != strategy.id) {
      _currentStrategyId = strategy.id;
      _nameController.text = strategy.name;
    } else if (_nameController.text != strategy.name && !FocusScope.of(context).hasFocus) {
      _nameController.text = strategy.name;
    }
  }

  bool _isStrategyEmpty(TradingStrategy strategy) {
    // Check if there are any entry conditions
    bool anyEntries = strategy.rules.any((rule) => rule.conditions.isNotEmpty);
    
    // Check if there are any conditional exit targets configured (not in Fixed mode)
    bool anyExits = strategy.globalSetup.setupType == 'Conditional';
                    
    return !anyEntries && !anyExits;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StrategyProvider>(context);
    final strategy = provider.currentStrategy;
    
    _syncController(strategy);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 10),
            const Text('Strategy Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => html.window.location.href = '../index.html#features',
            child: const Text('Features', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => html.window.location.href = '../index.html#indicators',
            child: const Text('Indicators', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => html.window.location.href = '../index.html#exchanges',
            child: const Text('Exchanges', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => html.window.location.href = '../strategies/index.html',
            child: const Text('Strategies', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strategy Toolbar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          key: HomeScreen.newStrategyButtonKey,
                          onPressed: () => provider.createNewStrategy(),
                          icon: const Icon(Icons.add_box_outlined),
                          label: const Text('New Strategy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF828DF8).withOpacity(0.15),
                            foregroundColor: const Color(0xFF828DF8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PrebuiltStrategiesModal(),
                            ).then((strategy) {
                              if (strategy != null) {
                                // Strategy is loaded inside the modal via provider
                              }
                            });
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Use Prebuilt Strategies'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF828DF8).withOpacity(0.15),
                            foregroundColor: const Color(0xFF828DF8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          key: HomeScreen.marketConfigKey,
                          child: _buildMarketSelection(context, strategy, provider),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          key: HomeScreen.timeframeConfigKey,
                          child: _buildTimeframeModeSelection(context, strategy, provider),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVolumeFilterSelection(context, strategy, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Section Title: Entry Rules
                  Container(
                    key: HomeScreen.rulesListKey,
                    child: const Text('SIGNAL RULES (ENTRY POINTS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 12),

                  // Rules Sections
                  ...strategy.rules.map((rule) => _buildRuleSection(context, rule, provider)),

                  const SizedBox(height: 8),
                  Container(
                    key: HomeScreen.addRuleButtonsKey,
                    child: _buildAddRuleButtons(provider),
                  ),

                  const SizedBox(height: 48),
                  
                  // Section Title: Global Setup
                  const Text('RISK & PROFIT MANAGEMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    key: HomeScreen.riskConfigKey,
                    child: const TradeSetupCard(),
                  ),
                  const SizedBox(height: 48),

                  // Run Button
                  Center(
                    child: Container(
                      key: HomeScreen.scanButtonKey,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF05C270).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          final isGuest = auth.user!.role == UserRole.guest;
                          
                          // Check Scan Limit for Guest
                          if (isGuest) {
                            final canScan = await UserUsageService.trackScanAttempt(true);
                            if (!canScan) {
                              final nextSlot = await UserUsageService.getNextAvailableScanTime();
                              if (mounted) {
                                _showRestrictedDialog(
                                  context, 
                                  'You reached your daily limit of 3 scans. Register for free to unlock unlimited scanning!',
                                  extraText: nextSlot != null ? 'Next scan available at: ${nextSlot.hour}:${nextSlot.minute.toString().padLeft(2, '0')}' : null,
                                );
                              }
                              return;
                            }
                          }

                          if (_isStrategyEmpty(strategy)) {
                             AppToast.show(context, 'Cannot run an empty strategy. Add some conditions first.', isError: true);
                             return;
                          }
                          RatingService.incrementScanCount(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ScanResultsScreen(strategy: strategy)),
                          );
                        },
                        icon: const Icon(Icons.play_circle_filled, size: 28),
                        label: const Text('SCAN MARKET NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF05C270),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStrategyHeader(TradingStrategy strategy, StrategyProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Strategy Name (e.g., EMA Cross)',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.edit_note, color: const Color(0xFF828DF8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        onChanged: (val) => provider.updateStrategyName(val),
      ),
    );
  }

  Widget _buildMarketSelection(BuildContext context, TradingStrategy strategy, StrategyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXCHANGE & MARKET TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              // Exchange Dropdown
              Expanded(
                child: _buildCompactDropdown(
                  label: 'EXCHANGE',
                  options: ['Binance', 'Bybit', 'OKX', 'Bitstamp', 'Upbit'],
                  selectedValue: strategy.exchange,
                  onSelected: (val) => provider.setExchange(val),
                  activeColor: const Color(0xFF828DF8),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 35, color: Colors.white10),
              const SizedBox(width: 16),
              // Market Dropdown
              Expanded(
                child: _buildCompactDropdown(
                  label: 'MARKET',
                  options: (strategy.exchange == 'Bitstamp' || strategy.exchange == 'Upbit') 
                      ? ['Spot'] 
                      : ['Spot', 'Futures'],
                  selectedValue: strategy.marketType,
                  onSelected: (val) => provider.setMarketType(val),
                  activeColor: const Color(0xFF05C270),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelected,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        DropdownButtonHideUnderline(
          child: SizedBox(
            height: 32,
            child: DropdownButton<String>(
              value: options.contains(selectedValue) ? selectedValue : options.first,
              isExpanded: true,
              dropdownColor: Theme.of(context).scaffoldBackgroundColor,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: activeColor.withOpacity(0.7)),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              onChanged: (val) { if (val != null) onSelected(val); },
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeModeSelection(BuildContext context, TradingStrategy strategy, StrategyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TIMEFRAME SETUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCompactDropdown(
                      label: 'STRATEGY MODE',
                      options: ['Single Timeframe', 'Multi-Timeframe'],
                      selectedValue: strategy.isMultiTimeframe ? 'Multi-Timeframe' : 'Single Timeframe',
                      onSelected: (val) => provider.setIsMultiTimeframe(val == 'Multi-Timeframe'),
                      activeColor: const Color(0xFF828DF8),
                    ),
                  ),
                  if (!strategy.isMultiTimeframe) ...[
                    const SizedBox(width: 16),
                    Container(width: 1, height: 35, color: Colors.white10),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildCompactDropdown(
                        label: 'CANDLES',
                        options: TimeframeConfig.getSupportedTimeframes(strategy.exchange),
                        selectedValue: strategy.baseTimeframe,
                        onSelected: (val) => provider.setBaseTimeframe(val),
                        activeColor: const Color(0xFF828DF8),
                      ),
                    ),
                  ],
                ],
              ),
              if (strategy.isMultiTimeframe)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Timeframes are configured individually inside each indicator.', style: TextStyle(color: Colors.amber, fontSize: 12))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeFilterSelection(BuildContext context, TradingStrategy strategy, StrategyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VOLUME FILTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MINIMUM VOLUME (MILLIONS)', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    SizedBox(
                      height: 32,
                      child: TextFormField(
                        key: ValueKey('volume_filter_${strategy.id}'),
                        initialValue: strategy.volumeFilterMillions != null ? strategy.volumeFilterMillions!.toInt().toString() : '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 5 (Leave empty to disable)',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsetsDirectional.only(bottom: 14), // Adjust alignment
                        ),
                        onChanged: (val) {
                          if (val.trim().isEmpty) {
                            provider.setVolumeFilterMillions(null);
                            provider.setVolumeFilterTimeframe(null);
                          } else {
                            final parsed = double.tryParse(val.replaceAll(',', '.'));
                            if (parsed != null) {
                              provider.setVolumeFilterMillions(parsed);
                            if (strategy.volumeFilterTimeframe == null) {
                              provider.setVolumeFilterTimeframe('1d');
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (strategy.volumeFilterMillions != null) ...[
                const SizedBox(width: 16),
                Container(width: 1, height: 35, color: Colors.white10),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildCompactDropdown(
                    label: 'TIMEFRAME',
                    options: TimeframeConfig.getSupportedTimeframes(strategy.exchange),
                    selectedValue: strategy.volumeFilterTimeframe ?? '1d',
                    onSelected: (val) => provider.setVolumeFilterTimeframe(val),
                    activeColor: Colors.orangeAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleSection(BuildContext context, StrategyRule rule, StrategyProvider provider) {
    final isLong = rule.action == 'Long';
    final accentColor = isLong ? const Color(0xFF05C270) : const Color(0xFFFF3B30);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.12))),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isLong ? Icons.trending_up : Icons.trending_down, color: accentColor, size: 14),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLong ? 'LONG POSITION' : 'SHORT POSITION',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                    ),
                    Text(
                      isLong ? 'Buy conditions' : 'Sell conditions',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white12, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => provider.removeRule(rule.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [

                ...rule.conditions.map((block) {
                  final isFirst = rule.conditions.indexOf(block) == 0;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 10),
                    child: ConditionBlockCard(
                      block: block,
                      onRemove: () => provider.removeBlockFromRule(rule.id, block.id),
                      onUpdate: (updatedBlock) => provider.updateBlockInRule(rule.id, block.id, updatedBlock),
                      isFirst: isFirst,
                      accentColor: accentColor,
                    ),
                  );
                }),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: TextButton.icon(
                    onPressed: () async {
                      final selectedName = await IndicatorSearchSheet.show(context);
                      if (selectedName == null) return;
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (!context.mounted) return;

                      final newIndicator = ConfigurableIndicator(
                        name: selectedName,
                        parameters: ConfigurableIndicator.getDefaultParameters(selectedName),
                      );

                      final hasParams = newIndicator.parameters.isNotEmpty;
                      final hasLines = IndicatorConfigSheet.getAvailableLines(selectedName).isNotEmpty;

                      if (!hasParams && !hasLines) {
                        provider.addBlockToRule(rule.id, selectedName);
                      } else {
                        if (!context.mounted) return;
                        IndicatorConfigSheet.show(
                          context,
                          newIndicator,
                          provider.currentStrategy.exchange,
                          (configured) => provider.addBlockToRule(rule.id, configured.name, indicator: configured),
                          isMultiTimeframe: provider.currentStrategy.isMultiTimeframe,
                        );
                      }
                    },
                     icon: Icon(Icons.add_circle_outline, size: 16, color: accentColor),
                     label: Text('ADD INDICATOR/CONDITION', style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                    style: TextButton.styleFrom(
                      backgroundColor: accentColor.withOpacity(0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRuleButtons(StrategyProvider provider) {
    final longCount = provider.rules.where((r) => r.action == 'Long').length;
    final shortCount = provider.rules.where((r) => r.action == 'Short').length;

    return Row(
      children: [
        Expanded(
          child: _buildMiniAddButton(
            label: 'Add Long Rule',
            color: const Color(0xFF05C270),
            onTap: longCount < 2 ? () => provider.addRule('Long') : null,
            isDisabled: longCount >= 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniAddButton(
            label: 'Add Short Rule',
            color: const Color(0xFFFF3B30),
            onTap: shortCount < 2 ? () => provider.addRule('Short') : null,
            isDisabled: shortCount >= 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAddButton({required String label, required Color color, required VoidCallback? onTap, bool isDisabled = false}) {
    final displayColor = isDisabled ? Colors.white10 : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: displayColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDisabled ? Icons.lock_outline : Icons.add_circle_outline, size: 16, color: displayColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: displayColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }



  void _showSaveDialog(BuildContext context, StrategyProvider provider) async {
    final strategy = provider.currentStrategy;
    final originalName = provider.originalName;
    
    if (strategy.name.trim().isEmpty || strategy.name == 'Untitled Strategy') {
      AppToast.show(context, 'Please provide a name for your strategy.', isError: true);
      return;
    }

    if (_isStrategyEmpty(strategy)) {
      AppToast.show(context, 'Cannot save an empty strategy. Please add at least one condition.', isError: true);
      return;
    }

    // Check if it already exists to show a different prompt
    final alreadyExists = await provider.checkIfStrategyExists(strategy.name);
    
    // It's a pure update if the name hasn't changed from what we loaded
    final isUpdate = alreadyExists && originalName == strategy.name;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUpdate ? 'Update Saved Strategy?' : (alreadyExists ? 'Overwrite Strategy?' : 'Save to Library?')),
        content: Text(isUpdate
          ? 'Save changes to "${strategy.name}"?'
          : (alreadyExists 
              ? 'A strategy named "${strategy.name}" already exists. Do you want to replace it?' 
              : 'Save "${strategy.name}" to your library for future use?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.saveCurrentStrategy(overwrite: true);
                if (context.mounted) {
                  Navigator.pop(context);
                  AppToast.show(
                    context,
                    isUpdate
                      ? 'Updated: "${strategy.name}" changes saved.'
                      : (alreadyExists 
                          ? 'Overwritten: "${strategy.name}" has been replaced.' 
                          : 'Success: "${strategy.name}" saved to library.')
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(context, 'Error: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isUpdate ? const Color(0xFF05C270) : (alreadyExists ? Colors.orangeAccent : const Color(0xFF05C270)), 
              foregroundColor: Colors.white
            ),
            child: Text(isUpdate ? 'Update Strategy' : (alreadyExists ? 'Yes, Overwrite' : 'Yes, Save')),
          ),
        ],
      ),
    );
  }

  void _showLibrary(BuildContext context, StrategyProvider provider) async {
    final strategies = await provider.getSavedStrategies();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Saved Strategies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            if (strategies.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_motion, size: 64, color: Colors.white10),
                      SizedBox(height: 16),
                      Text('No strategies saved yet.', style: TextStyle(color: Colors.white24)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: strategies.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (context, index) {
                    final name = strategies[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF828DF8).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.description_outlined, color: const Color(0xFF828DF8)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: const Color(0xFFFF3B30), size: 20),
                        onPressed: () async {
                          await provider.deleteSavedStrategy(name);
                          if (context.mounted) Navigator.pop(context);
                          _showLibrary(context, provider);
                        },
                      ),
                      onTap: () async {
                        await provider.loadStrategy(name);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRestrictedDialog(BuildContext context, String message, {String? extraText}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text('Login Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (extraText != null) ...[
              const SizedBox(height: 12),
              Text(extraText, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF828DF8), foregroundColor: Colors.white),
            child: const Text('Login / Sign Up'),
          ),
        ],
      ),
    );
  }
}

