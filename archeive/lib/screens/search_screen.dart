import 'package:flutter/material.dart';
import 'dart:async';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CryptoService _cryptoService = CryptoService();
  final _searchController = TextEditingController();
  List<CryptoCurrency> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _cryptoService.searchCryptos(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search cryptocurrencies...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppTheme.textGrey),
            prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
          ),
          style: TextStyle(color: AppTheme.textLight),
          autofocus: true,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final crypto = _searchResults[index];
        return _buildSearchResultItem(crypto);
      },
    );
  }

  Widget _buildSearchResultItem(CryptoCurrency crypto) {
    return ListTile(
      title: Text(crypto.name),
      subtitle: Text(crypto.symbol.toUpperCase()),
      trailing: Text(
        '\$${crypto.currentPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.pop(context, crypto);
      },
    );
  }
}
