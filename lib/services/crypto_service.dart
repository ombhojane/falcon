import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class CryptoService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  // List of supported cryptocurrencies
  static const List<String> supportedCryptos = [
    'bitcoin',
    'ethereum',
    'solana',
    'matic-network', // Polygon
  ];

  Future<List<CryptoCurrency>> getMainCryptos() async {
    try {
      final ids = supportedCryptos.join(',');
      final response = await http.get(Uri.parse(
          '$baseUrl/coins/markets?vs_currency=usd&ids=$ids&order=market_cap_desc&sparkline=false'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoCurrency.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load crypto data');
      }
    } catch (e) {
      throw Exception('Error fetching crypto data: $e');
    }
  }

  Future<List<List<double>>> getHistoricalData(String id, String timeframe) async {
    try {
      // Convert timeframe to API parameters
      final Map<String, String> timeframeParams = {
        '1H': '1', // 1 hour data points for last day
        '1W': '7',  // 7 days
        '1M': '30', // 30 days
        'ALL': 'max' // Maximum available data
      };

      final String days = timeframeParams[timeframe] ?? '7'; // Default to 7 days
      final String interval = timeframe == '1H' ? 'hourly' : 'daily';
      
      final response = await http.get(Uri.parse(
          '$baseUrl/coins/$id/market_chart?vs_currency=usd&days=$days&interval=$interval'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<List<dynamic>> prices = List<List<dynamic>>.from(data['prices']);
        
        return prices.map((price) => [
          (price[0] as int).toDouble(),
          (price[1] as num).toDouble(),
        ]).toList();
      } else {
        throw Exception('Failed to load historical data');
      }
    } catch (e) {
      throw Exception('Error fetching historical data: $e');
    }
  }

  Future<List<CryptoCurrency>> searchCryptos(String query) async {
    final response = await http.get(
        Uri.parse('$baseUrl/search?query=$query'));
    
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return (data['coins'] as List)
          .map((coin) => CryptoCurrency.fromJson(coin))
          .toList();
    } else {
      throw Exception('Failed to search cryptos');
    }
  }
}