import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../models/condition_block.dart';
import '../services/scan_coordinator.dart';
import '../services/sharing_service.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';


class ScanResultsScreen extends StatefulWidget {
  final TradingStrategy strategy;

  const ScanResultsScreen({super.key, required this.strategy});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  static int _scanSessionCount = 0;
  final ScanCoordinator _coordinator = ScanCoordinator();
  late Stream<ScanProgress> _scanStream;
  bool _resultsSaved = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _scanSessionCount++;
    _scanStream = _coordinator.runScan(widget.strategy);
  }

  Future<void> _saveResultsToDatabase(List<SymbolMatch> matches) async {
    if (_resultsSaved || matches.isEmpty) return;
    _resultsSaved = true;
    
    final db = LocalDatabaseService();
    final String scanId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    
    for (var match in matches) {
      await db.saveBackgroundSignal({
        'symbol': match.symbol,
        'direction': match.direction,
        'entryPrice': match.entryPrice,
        'tp': match.tp,
        'sl': match.sl,
        'strategyName': widget.strategy.name,
        'scan_id': scanId,
      });
    }
    debugPrint('Saved ${matches.length} manual scan results to history.');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => html.window.location.href = '../index.html',
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 24),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
              Text('Scanning: ${widget.strategy.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            tooltip: 'Download App',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text('Download Free ▾', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'android',
                child: Text('Android App', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<String>(
                value: 'windows',
                child: Text('Windows App', style: TextStyle(color: Colors.white)),
              ),
            ],
            onSelected: (String result) {
              if (result == 'android') {
                html.window.open('https://play.google.com/store/apps/details?id=com.bitlogic.screener.pro', '_blank');
              } else if (result == 'windows') {
                html.window.open('https://apps.microsoft.com/detail/9PGBXSLTP4DS?hl=en-us&gl=IN&ocid=pdpshare', '_blank');
              }
            },
          ),
          const SizedBox(width: 24),
        ],
        ),
        body: SafeArea(
        child: Column(
          children: [

          Expanded(
            child: StreamBuilder<ScanProgress>(
              stream: _scanStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData) {
             return Center(
               child: Shimmer.fromColors(
                 baseColor: Colors.white.withOpacity(0.05),
                 highlightColor: Colors.white.withOpacity(0.1),
                 child: Image.asset('assets/images/logo.png', width: 80, height: 80),
               ),
             );
          }

          final progress = snapshot.data!;
          final isComplete = progress.progress >= 1.0;

          if (isComplete && progress.currentMatches.isNotEmpty) {
            _saveResultsToDatabase(progress.currentMatches);
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
                // Animated Progress Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isComplete ? const Color(0xFF05C270) : const Color(0xFF828DF8).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isComplete ? 'Analysis Complete' : 'Finding Opportunities',
                        style: TextStyle(
                           fontSize: 20, 
                           fontWeight: FontWeight.bold,
                           color: isComplete ? const Color(0xFF05C270) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress.progress,
                        backgroundColor: Colors.white12,
                        color: isComplete ? const Color(0xFF05C270) : const Color(0xFF828DF8),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        progress.statusText,
                        style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      if (isComplete) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progress.currentMatches.length} Matches Found',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            if (progress.currentMatches.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => SharingService.shareBulkSignals(
                                  progress.currentMatches, 
                                  widget.strategy.name, 
                                  context.read<AuthProvider>().user
                                ),
                                icon: const Icon(Icons.share, size: 16, color: const Color(0xFF05C270)),
                                label: const Text('Share All', style: TextStyle(color: const Color(0xFF05C270), fontSize: 12, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF05C270).withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Static List of Matches
                const Text('LIVE OPPORTUNITIES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                
                if (progress.currentMatches.isEmpty)
                  Center(
                    child: Text(
                      isComplete ? 'No symbols matched your strategy.' : 'Waiting for matches...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              mainAxisExtent: 170,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: progress.currentMatches.length,
                            itemBuilder: (context, index) {
                              final match = progress.currentMatches[index];
                              final isLong = match.direction == 'Long';
                              final accentColor = isLong ? const Color(0xFF05C270) : const Color(0xFFFF3B30);

                              // Calculate R:R Ratio
                              double? rr;
                              if (match.tp != null && match.sl != null) {
                                final risk = (match.entryPrice - match.sl!).abs();
                                final reward = (match.tp! - match.entryPrice).abs();
                                if (risk > 0) rr = reward / risk;
                              }

                              return Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Theme.of(context).cardColor,
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
                                   boxShadow: [
                                     BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                   ],
                                 ),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     // Symbol & Badges
                                     Row(
                                       children: [
                                         Expanded(
                                           child: Text(
                                             match.symbol, 
                                             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                         const SizedBox(width: 8),
                                         if (rr != null)
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                             decoration: BoxDecoration(
                                               color: const Color(0xFF828DF8).withOpacity(0.1),
                                               borderRadius: BorderRadius.circular(6),
                                               border: Border.all(color: const Color(0xFF828DF8).withOpacity(0.6)),
                                             ),
                                             child: Row(
                                               mainAxisSize: MainAxisSize.min,
                                               children: [
                                                 const Icon(Icons.analytics, color: const Color(0xFF828DF8), size: 10),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   'R:R ${rr.toStringAsFixed(2)}',
                                                   style: const TextStyle(color: const Color(0xFF828DF8), fontSize: 10, fontWeight: FontWeight.bold),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         const SizedBox(width: 4),
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                           decoration: BoxDecoration(
                                             color: accentColor.withOpacity(0.15),
                                             borderRadius: BorderRadius.circular(6),
                                           ),
                                           child: Text(
                                             isLong ? 'BUY' : 'SELL',
                                             style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                                           ),
                                         ),
                                         const SizedBox(width: 4),
                                         IconButton(
                                           onPressed: () => SharingService.shareSignal(
                                             match, 
                                             widget.strategy.exchange, 
                                             widget.strategy.marketType, 
                                             context.read<AuthProvider>().user
                                           ),
                                           icon: const Icon(Icons.share_rounded, color: Color(0xFF05C270), size: 20),
                                           tooltip: 'Share Signal',
                                           padding: EdgeInsets.zero,
                                           constraints: const BoxConstraints(),
                                         ),
                                       ],
                                     ),
                                     
                                     const SizedBox(height: 16),
                                     
                                     // Trade Zone Block
                                     Container(
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(
                                         color: Theme.of(context).scaffoldBackgroundColor,
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           _buildTargetInfo(
                                             'ENTRY', 
                                             match.entryPrice, 
                                             Colors.white, 
                                             Icons.login
                                           ),
                                           if (match.tp != null)
                                             _buildTargetInfo(
                                               'TARGET (TP)', 
                                               match.tp!, 
                                               const Color(0xFF05C270), 
                                               Icons.flag_rounded
                                             ),
                                           if (match.sl != null)
                                             _buildTargetInfo(
                                               'SAFETY (SL)', 
                                               match.sl!, 
                                               const Color(0xFFFF3B30), 
                                               Icons.shield_rounded
                                             ),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                              );
                            },
                          ),
                

              ],
          );
        },
      ),
    ),

  ],
), // closes Column
      ), // closes SafeArea
    ), // closes Scaffold
  ); // closes WillPopScope
}

  Widget _buildShimmerScanner() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }

  Widget _buildTargetInfo(String label, double price, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withOpacity(0.5), size: 10),
            const SizedBox(width: 4),
            Text(
              label, 
              style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          price.toStringAsFixed(4), 
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}

