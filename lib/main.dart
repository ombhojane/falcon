import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'models/crypto_model.dart';
import 'services/crypto_service.dart';
import 'screens/search_screen.dart';
import 'screens/crypto_detail_screen.dart';
import 'theme/app_theme.dart';
import 'screens/alert_screen.dart';
import 'services/alert_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'services/wallet_service.dart';
import 'screens/wallet_import_screen.dart';
import 'models/wallet_model.dart';
import 'screens/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final alertService = AlertService();
  await alertService.initialize();
  
  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );
  
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
      routes: {
        '/alerts': (context) => const AlertScreen(),
      },
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
  final WalletService _walletService = WalletService();
  List<CryptoCurrency> _cryptos = [];
  bool _isLoading = true;
  Timer? _timer;
  WalletInfo? _wallet;
  bool _isLoadingWallet = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoadingWallet = true);
    try {
      final wallet = await _walletService.getStoredWallet();
      if (wallet != null) {
        final balances = await _walletService.getBalances(wallet);
        setState(() {
          _wallet = WalletInfo(
            address: wallet.address,
            privateKey: wallet.privateKey,
            balances: balances,
            walletType: wallet.walletType,
          );
        });
      }
    } finally {
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _importWallet() async {
    final result = await Navigator.push<WalletInfo>(
      context,
      MaterialPageRoute(builder: (context) => const WalletImportScreen()),
    );
    
    if (result != null) {
      setState(() => _wallet = result);
    }
  }

  Future<void> _checkConnectivityAndLoad() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      await _loadCryptos();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCryptos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final cryptos = await _cryptoService.getMainCryptos();
      if (mounted) {
        setState(() {
          _cryptos = cryptos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, ${_userName ?? "User"}',
              style: AppTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary,
            child: IconButton(
              icon: const Icon(Icons.person, color: AppTheme.textLight),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountScreen(
                      wallet: _wallet,
                      onBack: () => Navigator.pop(context),
                      onWalletImport: _importWallet,
                      onNameUpdate: (name) {
                        setState(() {
                          _userName = name;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Tooltip(
            message: 'Search cryptocurrencies',
            child: IconButton(
              icon: const Icon(Icons.search, size: 26, color: AppTheme.textLight),
              onPressed: _openSearch,
            ),
          ),
          Tooltip(
            message: 'Refresh data',
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 26, color: AppTheme.textLight),
              onPressed: _loadCryptos,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: AppTheme.textLight),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
        ],
        elevation: 0,
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

    if (_cryptos.isEmpty) {
      return const Center(child: Text('No cryptocurrencies available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _cryptos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Wallet balance card
          return Column(
            children: [
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Balance',
                        style: AppTheme.titleMedium.copyWith(color: AppTheme.textGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(_wallet?.balances['SOL'] ?? 0.0),
                        style: AppTheme.headlineLarge,
                      ),
                      if (_wallet == null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _importWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Import Wallet'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Cryptocurrencies',
                      style: AppTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return _buildCryptoCard(_cryptos[index - 1]);
      },
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
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crypto.symbol.toUpperCase(),
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceFormat.format(crypto.currentPrice),
                    style: AppTheme.titleMedium,
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