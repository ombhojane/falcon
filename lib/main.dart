import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/crypto_model.dart';
import 'services/crypto_service.dart';
import 'screens/search_screen.dart';
import 'screens/crypto_detail_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Falcon',
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CryptoService _cryptoService = CryptoService();
  List<CryptoCurrency> _cryptos = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCryptos();
    // Refresh every minute instead of 30 seconds
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) _loadCryptos();
    });
  }

  Future<void> _loadCryptos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final cryptos = await _cryptoService.getMainCryptos();
      setState(() {
        _cryptos = cryptos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Falcon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCryptos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _openSearch() async {
    final selected = await Navigator.push<CryptoCurrency>(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );

    if (selected != null && mounted) {
      // Check if the cryptocurrency is already in the list
      if (!_cryptos.any((crypto) => crypto.id == selected.id)) {
        setState(() {
          _cryptos.add(selected);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cryptocurrency already in list')),
          );
        }
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCryptos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCryptos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cryptos.length,
        itemBuilder: (context, index) {
          final crypto = _cryptos[index];
          return _buildCryptoCard(crypto);
        },
      ),
    );
  }

  Widget _buildCryptoCard(CryptoCurrency crypto) {
    final priceFormat = NumberFormat.currency(symbol: '\$');
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CryptoDetailScreen(crypto: crypto),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (crypto.image != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(crypto.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crypto.symbol.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceFormat.format(crypto.currentPrice),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  _buildPriceChange(crypto.priceChangePercentage24h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChange(double percentage) {
    final color = percentage >= 0 ? AppTheme.accentGreen : AppTheme.accentRed;
    final percentageFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          percentage >= 0 ? '+\$' : '-\$',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          '${percentage.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${percentage >= 0 ? '+' : ''}${percentageFormat.format(percentage / 100)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}