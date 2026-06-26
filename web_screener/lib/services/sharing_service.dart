import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import 'scan_coordinator.dart';

class SharingService {
  static const String appName = "BitLogic";
  static const String appLink = "https://bitlogic.info";

  static Future<void> shareSignal(SymbolMatch match, String exchange, String market, UserModel user) async {
    final direction = match.direction == 'Long' ? '📈 BUY (Long)' : '📉 SELL (Short)';
    final price = match.entryPrice.toStringAsFixed(4);
    final time = DateFormat('HH:mm').format(DateTime.now());
    
    final tpText = (match.tp != null && match.tp != 0) ? "\n🎯 Target: \$${match.tp!.toStringAsFixed(4)}" : "";
    final slText = (match.sl != null && match.sl != 0) ? "\n🛡️ Stop Loss: \$${match.sl!.toStringAsFixed(4)}" : "";

    final text = """
🔥 $direction Signal on $appName
💰 ${match.symbol} at \$$price$tpText$slText
🏦 Exchange: $exchange ($market)
🕒 Time: $time (UTC)

Join me on $appName to build and automate your own crypto strategies!
🔗 Check it out:
$appLink
""";

    await Share.share(text, subject: '${match.symbol} $direction Signal');
  }

  static Future<void> shareBulkSignals(List<SymbolMatch> signals, String strategyName, UserModel user) async {
    if (signals.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("🎯 ${signals.length} New Signals from $strategyName");
    buffer.writeln("Powered by $appName\n");

    for (var i = 0; i < signals.length; i++) {
      final match = signals[i];
      final direction = match.direction == 'Long' ? '📈 LONG' : '📉 SHORT';
      final price = match.entryPrice.toStringAsFixed(2);
      final targets = (match.tp != null && match.sl != null) 
          ? " (TP: ${match.tp!.toStringAsFixed(2)}, SL: ${match.sl!.toStringAsFixed(2)})" 
          : "";
      
      buffer.writeln("${i + 1}. ${match.symbol} - $direction @ \$$price$targets");
    }

    buffer.writeln("\nGet real-time alerts for your strategies on $appName!");
    buffer.writeln("🔗 Check it out here:");
    buffer.writeln(appLink);

    await Share.share(buffer.toString(), subject: 'New Trading Signals from $appName');
  }

  static Future<void> shareScanResult(String symbol, String timeframe, String action, double entryPrice, double targetPrice, double stopLoss) async {
    // Legacy support if needed
  }
  
  static Future<void> shareStrategy(String strategyName, int rulesCount, String timeframe) async {
    // Legacy support if needed
  }
}
