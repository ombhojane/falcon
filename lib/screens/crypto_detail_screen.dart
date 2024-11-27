import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../services/alert_service.dart';
import '../models/alert_model.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoCurrency crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final CryptoService _cryptoService = CryptoService();
  final AlertService _alertService = AlertService();
  List<FlSpot> _pricePoints = [];
  bool _isLoading = false;
  String _selectedTimeframe = '1W'; // Default to 1 week
  final List<String> _timeframes = ['1H', '1W', '1M', 'ALL']; // Updated timeframes

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _cryptoService.getHistoricalData(
          widget.crypto.id, _selectedTimeframe);

      setState(() {
        _pricePoints = data
            .map((point) => FlSpot(
                  point[0],
                  point[1],
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching historical data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              try {
                await _alertService.showTestNotification(
                  widget.crypto.name,
                  widget.crypto.currentPrice,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send notification: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: _showAddAlertDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildPriceHeader(),
                const SizedBox(height: 40),
                _buildPriceChart(),
                const SizedBox(height: 16),
                _buildTimeframeSelector(),
                const SizedBox(height: 24),
                _buildStatistics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAlertDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAlertBottomSheet(),
    );
  }

  Widget _buildAlertBottomSheet() {
    final TextEditingController priceController = TextEditingController();
    bool isGreaterThan = true;

    return StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set Price Alert',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Alert when price is',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Greater'),
                    selected: isGreaterThan,
                    onSelected: (selected) {
                      setState(() => isGreaterThan = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Less'),
                    selected: !isGreaterThan,
                    onSelected: (selected) {
                      setState(() => isGreaterThan = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Target Price (\$)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  final price = double.tryParse(priceController.text);
                  if (price != null) {
                    final alert = PriceAlert(
                      cryptoId: widget.crypto.id,
                      targetPrice: price,
                      isGreaterThan: isGreaterThan,
                    );
                    _alertService.addAlert(alert);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Alert set for ${widget.crypto.name} at \$${price.toStringAsFixed(2)}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Set Alert',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    final priceFormat = NumberFormat.currency(symbol: '\$');
    final bool isPositive = widget.crypto.priceChangePercentage24h >= 0;
    final color = isPositive ? AppTheme.accentGreen : AppTheme.accentRed;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          priceFormat.format(widget.crypto.currentPrice),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${isPositive ? "+" : "-"}\$${widget.crypto.priceChangePercentage24h.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isPositive ? "+" : ""}${(widget.crypto.priceChangePercentage24h).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _timeframes.map((timeframe) {
          final isSelected = timeframe == _selectedTimeframe;
          final displayText = timeframe == '1H' ? '1D' : // Show as 1D instead of 1H
                            timeframe == '1W' ? '1W' :
                            timeframe == '1M' ? '1M' : 'ALL';
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = timeframe;
              });
              _loadHistoricalData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final color = widget.crypto.priceChangePercentage24h >= 0
        ? AppTheme.accentGreen
        : AppTheme.accentRed;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _pricePoints,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.8),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 0,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: color.withOpacity(0.2),
                    strokeWidth: 2,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final priceFormat = NumberFormat.currency(symbol: '\$');
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.crypto.marketCap > 0)
            _buildStatRow(
              'Market Cap',
              priceFormat.format(widget.crypto.marketCap),
            ),
          if (widget.crypto.totalVolume > 0)
            _buildStatRow(
              'Volume (24h)',
              priceFormat.format(widget.crypto.totalVolume),
            ),
          if (widget.crypto.high24h > 0)
            _buildStatRow(
              '24h High',
              priceFormat.format(widget.crypto.high24h),
            ),
          if (widget.crypto.low24h > 0)
            _buildStatRow(
              '24h Low',
              priceFormat.format(widget.crypto.low24h),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChange(double percentage) {
    final color = percentage >= 0 ? Colors.green : Colors.red;
    final percentageFormat =
        NumberFormat.decimalPercentPattern(decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${percentage >= 0 ? '+' : ''}${percentageFormat.format(percentage / 100)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
