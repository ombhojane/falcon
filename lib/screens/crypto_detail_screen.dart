import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoCurrency crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final CryptoService _cryptoService = CryptoService();
  List<FlSpot> _pricePoints = [];
  bool _isLoading = false;
  String _selectedTimeframe = '7'; // Default to 7 days
  final List<String> _timeframes = ['1', '7', '30', '365'];
  
  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _cryptoService.getHistoricalData(
        widget.crypto.id, 
        _selectedTimeframe
      );
      
      setState(() {
        _pricePoints = data.map((point) => FlSpot(
          point[0],
          point[1],
        )).toList();
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
    final priceFormat = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.crypto.image?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network(
                  widget.crypto.image!,
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 24,
                      width: 24,
                      child: Icon(Icons.currency_bitcoin),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
              ),
            Expanded(
              child: Text(
                widget.crypto.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceHeader(),
                const SizedBox(height: 24),
                _buildTimeframeSelector(),
                const SizedBox(height: 24),
                ErrorBoundary(
                  child: _buildPriceChart(),
                  onError: (error, stack) {
                    return const Center(
                      child: Text('Unable to load chart'),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildStatistics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    final priceFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceFormat.format(widget.crypto.currentPrice),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPriceChange(widget.crypto.priceChangePercentage24h),
            const Text(' in the last 24h'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _timeframes.map((timeframe) {
        final isSelected = timeframe == _selectedTimeframe;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeframe = timeframe;
            });
            _loadHistoricalData();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.textGrey,
              ),
            ),
            child: Text(
              '${timeframe}D',
              style: TextStyle(
                color: isSelected ? AppTheme.textLight : AppTheme.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _pricePoints,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.1),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    AppTheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.cardDark.withOpacity(0.8),
              tooltipRoundedRadius: 8,
              tooltipMargin: 0,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: AppTheme.primary.withOpacity(0.4),
                    strokeWidth: 2,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: AppTheme.primary,
                        strokeWidth: 2,
                        strokeColor: AppTheme.textLight,
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
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
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
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChange(double percentage) {
    final color = percentage >= 0 ? Colors.green : Colors.red;
    final percentageFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    
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