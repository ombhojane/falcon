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
import 'package:shared_preferences/shared_preferences.dart';

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
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
    _loadWallet();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
    });
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _checkConnectivityAndLoad();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with profile and actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AccountScreen(
                                        wallet: _wallet,
                                        onBack: () => Navigator.pop(context),
                                        onWalletImport: _importWallet,
                                        onNameUpdate: (name) => setState(() {
                                          _userName = name;
                                          if (_wallet != null) {
                                            _wallet!.name = name;
                                          }
                                        }),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.surfaceDark,
                                      radius: 20,
                                      child: Icon(Icons.account_circle, color: AppTheme.textLight),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _userName,
                                      style: AppTheme.titleLarge,
                                    ),
                                    Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.search, color: AppTheme.textLight),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.notifications_outlined, color: AppTheme.textLight),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/alerts');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Balance Section
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '\$${_wallet?.balances.values.fold(0.0, (prev, curr) => prev + curr).toStringAsFixed(2) ?? '0.00'}',
                                  style: AppTheme.headlineLarge.copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '+\$0.32',
                                      style: AppTheme.titleMedium.copyWith(
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+2.54%',
                                      style: AppTheme.titleMedium.copyWith(
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.send,
                                label: 'Send',
                                onTap: () {},
                              ),
                              _buildActionButton(
                                icon: Icons.swap_horiz,
                                label: 'Swap',
                                onTap: () {},
                              ),
                              _buildActionButton(
                                icon: Icons.account_balance_wallet,
                                label: 'Buy',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Crypto List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final crypto = _cryptos[index];
                        return _buildCryptoCard(crypto);
                      },
                      childCount: _cryptos.length,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoCard(CryptoCurrency crypto) {
    final isPositiveChange = crypto.priceChangePercentage24h >= 0;
    final changeColor = isPositiveChange ? AppTheme.accentGreen : AppTheme.accentRed;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CryptoDetailScreen(crypto: crypto),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(crypto.image ?? 'https://via.placeholder.com/40'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.name,
                    style: AppTheme.titleMedium,
                  ),
                  Text(
                    '${crypto.balance.toStringAsFixed(5)} ${crypto.symbol.toUpperCase()}',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${crypto.currentPrice.toStringAsFixed(2)}',
                  style: AppTheme.titleMedium,
                ),
                Text(
                  '${isPositiveChange ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: AppTheme.bodyMedium.copyWith(color: changeColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}