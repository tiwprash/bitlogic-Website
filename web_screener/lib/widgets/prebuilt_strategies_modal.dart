import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/prebuilt_strategy.dart';
import '../providers/strategy_provider.dart';
import '../widgets/app_toast.dart';

class PrebuiltStrategiesModal extends StatefulWidget {
  const PrebuiltStrategiesModal({super.key});

  @override
  State<PrebuiltStrategiesModal> createState() => _PrebuiltStrategiesModalState();
}

class _PrebuiltStrategiesModalState extends State<PrebuiltStrategiesModal> {
  List<PrebuiltStrategy> _strategies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    try {
      final jsonString = await rootBundle.loadString('assets/prebuilt_strategies.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _strategies = jsonList.map((e) => PrebuiltStrategy.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading prebuilt strategies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectStrategy(PrebuiltStrategy prebuilt) {
    final provider = context.read<StrategyProvider>();
    provider.loadStrategyFromModel(prebuilt.strategy);
    AppToast.show(context, 'Strategy "${prebuilt.shortName}" loaded successfully!');
    Navigator.pop(context, prebuilt.strategy);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prebuilt Strategies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    'These strategies are based on backtested historical data and are provided for educational purposes only. Past performance does not guarantee future results.',
                    style: TextStyle(color: Colors.amber, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _strategies.isEmpty
                    ? const Center(child: Text('No strategies found.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: _strategies.length,
                        itemBuilder: (context, index) {
                          final s = _strategies[index];
                          return _buildStrategyCard(s);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(PrebuiltStrategy s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectStrategy(s),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.type,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Win Rate', s.winRate, Colors.greenAccent),
                    _buildStat('R:R', s.riskReward, Colors.amberAccent),
                    _buildStat('Timeframe', s.strategy.baseTimeframe.toUpperCase(), Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
