import 'package:flutter/material.dart';

class IndicatorSearchSheet extends StatefulWidget {
  const IndicatorSearchSheet({super.key});

  /// Returns the selected indicator name, or null if dismissed.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const FractionallySizedBox(
          heightFactor: 0.8,
          child: IndicatorSearchSheet(),
        ),
      ),
    );
  }

  @override
  State<IndicatorSearchSheet> createState() => _IndicatorSearchSheetState();
}

class _IndicatorSearchSheetState extends State<IndicatorSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  
  final Map<String, List<String>> _allData = {
    'Price Action': ['Close', 'Open', 'High', 'Low', 'Volume', 'AVG_HIGH', 'AVG_CLOSE', 'AVG_VOL'],
    'Trend & Overlap': [
      'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'VWAP', 'ALMA', 'HMA', 
      'ZLEMA', 'MACD', 'MACDEXT', 'BBANDS', 'SAR', 'SAREXT', 'HT_TRENDLINE', 'SUPERTREND', 'ICHIMOKU'
    ],
    'Momentum & Oscillators': [
      'RSI', 'STOCH', 'STOCHF', 'STOCHRSI', 'MFI', 'ADX', 'ADXR', 'APO', 'PPO', 'MOM', 
      'CMO', 'ROC', 'ROCR', 'TRIX', 'ULTOSC', 'WILLR', 'CCI', 'BOP', 'AROON', 'AROONOSC', 
      'CHOP', 'SQUEEZE', 'VORTEX'
    ],
    'Volatility': ['ATR', 'NATR', 'TRANGE', 'KC', 'DC', 'UI'],
    'Volume': ['AD', 'ADOSC', 'OBV', 'CMF', 'EFI', 'PVT', 'VWMA'],
    'Candlestick Patterns': [
      'CDL2CROWS', 'CDL3BLACKCROWS', 'CDL3INSIDE', 'CDL3LINESTRIKE', 'CDL3OUTSIDE', 
      'CDL3STARSINSOUTH', 'CDL3WHITESOLDIERS', 'CDLABANDONEDBABY', 'CDLADVANCEBLOCK', 
      'CDLBELTHOLD', 'CDLBREAKAWAY', 'CDLCLOSINGMARUBOZU', 'CDLCONCEALBABYSWALL', 
      'CDLCOUNTERATTACK', 'CDLDARKCLOUDCOVER', 'CDLDOJI', 'CDLDOJISTAR', 'CDLDRAGONFLYDOJI', 
      'CDLENGULFING', 'CDLEVENINGDOJISTAR', 'CDLEVENINGSTAR', 'CDLGAPSIDESIDEWHITE', 
      'CDLGRAVESTONEDOJI', 'CDLHAMMER', 'CDLHANGINGMAN', 'CDLHARAMI', 'CDLHARAMICROSS', 
      'CDLHIGHWAVE', 'CDLHIKKAKE', 'CDLHIKKAKEMOD', 'CDLHOMINGPIGEON', 'CDLIDENTICAL3CROWS', 
      'CDLINNECK', 'CDLINVERTEDHAMMER', 'CDLKICKING', 'CDLKICKINGBYLENGTH', 'CDLLADDERBOTTOM', 
      'CDLLONGLEGGEDDOJI', 'CDLLONGLINE', 'CDLMARUBOZU', 'CDLMATCHINGLOW', 'CDLMATHOLD', 
      'CDLMORNINGDOJISTAR', 'CDLMORNINGSTAR', 'CDLONNECK', 'CDLPIERCING', 'CDLRICKSHAWMAN', 
      'CDLRISEFALL3METHODS', 'CDLSEPARATINGLINES', 'CDLSHOOTINGSTAR', 'CDLSHORTLINE', 
      'CDLSPINNINGTOP', 'CDLSTALLEDPATTERN', 'CDLSTICKSANDWICH', 'CDLTAKURI', 'CDLTASUKIGAP', 
      'CDLTHRUSTING', 'CDLTRISTAR', 'CDLUNIQUE3RIVER', 'CDLUPSIDEGAP2CROWS', 'CDLXSIDEGAP3METHODS',
      'CDLINSIDEBAR', 'CDLPINBAR', 'CDLTWEEZERS'
    ],
  };

  final Map<String, String> _friendlyNames = {
    'SMA': 'Simple Moving Average',
    'EMA': 'Exponential Moving Average',
    'WMA': 'Weighted Moving Average',
    'DEMA': 'Double Exponential Moving Average',
    'TEMA': 'Triple Exponential Moving Average',
    'TRIMA': 'Triangular Moving Average',
    'KAMA': 'Kaufman Adaptive Moving Average',
    'VWAP': 'Volume Weighted Average Price',
    'ALMA': 'Arnaud Legoux Moving Average',
    'HMA': 'Hull Moving Average',
    'ZLEMA': 'Zero Lag Exponential Moving Average',
    'MACD': 'Moving Average Convergence divergence',
    'MACDEXT': 'MACD with controllable MA type',
    'BBANDS': 'Bollinger Bands',
    'SAR': 'Parabolic SAR',
    'SAREXT': 'Parabolic SAR - Extended',
    'HT_TRENDLINE': 'Hilbert Transform - Instantaneous Trendline',
    'SUPERTREND': 'Supertrend',
    'ICHIMOKU': 'Ichimoku Cloud',
    'RSI': 'Relative Strength Index',
    'STOCH': 'Stochastic Oscillator',
    'STOCHF': 'Stochastic Fast',
    'STOCHRSI': 'Stochastic RSI',
    'MFI': 'Money Flow Index',
    'ADX': 'Average Directional Movement Index',
    'ADXR': 'ADX Rating',
    'APO': 'Absolute Price Oscillator',
    'PPO': 'Percentage Price Oscillator',
    'MOM': 'Momentum Indicator',
    'CMO': 'Chande Momentum Oscillator',
    'ROC': 'Rate of Change',
    'ROCR': 'Rate of Change Ratio',
    'TRIX': '1-day ROC of Triple Smooth EMA',
    'ULTOSC': 'Ultimate Oscillator',
    'WILLR': 'Williams %R',
    'AVG_HIGH': 'Average High',
    'AVG_CLOSE': 'Average Close',
    'AVG_VOL': 'Average Volume',
    'CCI': 'Commodity Channel Index',
    'BOP': 'Balance Of Power',
    'AROON': 'Aroon indicator',
    'AROONOSC': 'Aroon Oscillator',
    'CHOP': 'Choppiness Index',
    'SQUEEZE': 'Squeeze Index',
    'VORTEX': 'Vortex Indicator',
    'ATR': 'Average True Range',
    'NATR': 'Normalized ATR',
    'TRANGE': 'True Range',
    'KC': 'Keltner Channels',
    'DC': 'Donchian Channels',
    'UI': 'Ulcer Index',
    'AD': 'Chaikin A/D Line',
    'ADOSC': 'Chaikin A/D Oscillator',
    'OBV': 'On Balance Volume',
    'CMF': 'Chaikin Money Flow',
    'EFI': 'Elder Force Index',
    'PVT': 'Price Volume Trend',
    'VWMA': 'Volume Weighted Moving Average',
    'CDL2CROWS': 'Two Crows',
    'CDL3BLACKCROWS': 'Three Black Crows',
    'CDL3INSIDE': 'Three Inside Up/Down',
    'CDL3LINESTRIKE': 'Three-Line Strike',
    'CDL3OUTSIDE': 'Three Outside Up/Down',
    'CDL3STARSINSOUTH': 'Three Stars In The South',
    'CDL3WHITESOLDIERS': 'Three Advancing White Soldiers',
    'CDLABANDONEDBABY': 'Abandoned Baby',
    'CDLADVANCEBLOCK': 'Advance Block',
    'CDLBELTHOLD': 'Belt-hold',
    'CDLBREAKAWAY': 'Breakaway',
    'CDLCLOSINGMARUBOZU': 'Closing Marubozu',
    'CDLCONCEALBABYSWALL': 'Concealing Baby Swallow',
    'CDLCOUNTERATTACK': 'Counterattack',
    'CDLDARKCLOUDCOVER': 'Dark Cloud Cover',
    'CDLDOJI': 'Doji',
    'CDLDOJISTAR': 'Doji Star',
    'CDLDRAGONFLYDOJI': 'Dragonfly Doji',
    'CDLENGULFING': 'Engulfing Pattern',
    'CDLEVENINGDOJISTAR': 'Evening Doji Star',
    'CDLEVENINGSTAR': 'Evening Star',
    'CDLGAPSIDESIDEWHITE': 'Up/Down-gap side-by-side white lines',
    'CDLGRAVESTONEDOJI': 'Gravestone Doji',
    'CDLHAMMER': 'Hammer Pattern',
    'CDLHANGINGMAN': 'Hanging Man',
    'CDLHARAMI': 'Harami Pattern',
    'CDLHARAMICROSS': 'Harami Cross Pattern',
    'CDLHIGHWAVE': 'High-Wave Candle',
    'CDLHIKKAKE': 'Hikkake Pattern',
    'CDLHIKKAKEMOD': 'Modified Hikkake Pattern',
    'CDLHOMINGPIGEON': 'Homing Pigeon',
    'CDLIDENTICAL3CROWS': 'Identical Three Crows',
    'CDLINNECK': 'In-Neck Pattern',
    'CDLINVERTEDHAMMER': 'Inverted Hammer',
    'CDLKICKING': 'Kicking Pattern',
    'CDLKICKINGBYLENGTH': 'Kicking (Long Marubozu)',
    'CDLLADDERBOTTOM': 'Ladder Bottom',
    'CDLLONGLEGGEDDOJI': 'Long Legged Doji',
    'CDLLONGLINE': 'Long Line Candle',
    'CDLMARUBOZU': 'Marubozu Indicator',
    'CDLMATCHINGLOW': 'Matching Low',
    'CDLMATHOLD': 'Mat Hold',
    'CDLMORNINGDOJISTAR': 'Morning Doji Star',
    'CDLMORNINGSTAR': 'Morning Star',
    'CDLONNECK': 'On-Neck Pattern',
    'CDLPIERCING': 'Piercing Pattern',
    'CDLRICKSHAWMAN': 'Rickshaw Man',
    'CDLRISEFALL3METHODS': 'Rising/Falling Three Methods',
    'CDLSEPARATINGLINES': 'Separating Lines',
    'CDLSHOOTINGSTAR': 'Shooting Star',
    'CDLSHORTLINE': 'Short Line Candle',
    'CDLSPINNINGTOP': 'Spinning Top',
    'CDLSTALLEDPATTERN': 'Stalled Pattern',
    'CDLSTICKSANDWICH': 'Stick Sandwich',
    'CDLTAKURI': 'Takuri Line',
    'CDLTASUKIGAP': 'Tasuki Gap',
    'CDLTHRUSTING': 'Thrusting Pattern',
    'CDLTRISTAR': 'Tristar Pattern',
    'CDLUNIQUE3RIVER': 'Unique 3 River',
    'CDLUPSIDEGAP2CROWS': 'Upside Gap Two Crows',
    'CDLXSIDEGAP3METHODS': 'Gap Three Methods',
    'CDLINSIDEBAR': 'Inside Bar Pattern',
    'CDLPINBAR': 'Pin Bar Reversal',
    'CDLTWEEZERS': 'Tweezer Tops/Bottoms'
  };

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Indicator / Pattern',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                 _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: _allData.keys.map((category) {
              final filteredIds = _allData[category]!.where((id) {
                final friendlyName = _friendlyNames[id] ?? '';
                return id.toLowerCase().contains(_searchQuery) ||
                       friendlyName.toLowerCase().contains(_searchQuery);
              }).toList();
                  
              if (filteredIds.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  ...filteredIds.map((id) {
                    final friendlyName = _friendlyNames[id] ?? id;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 4),
                      child: ListTile(
                        title: Text(friendlyName),
                        subtitle: Text(id, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: Theme.of(context).scaffoldBackgroundColor,
                        onTap: () => Navigator.pop(context, id),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

