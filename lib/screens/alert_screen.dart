import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final AlertService _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
      ),
      body: StreamBuilder<List<PriceAlert>>(
        stream: _alertService.alertsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No active alerts',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final alert = snapshot.data![index];
              return Dismissible(
                key: Key(alert.hashCode.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _alertService.removeAlert(alert);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert removed')),
                  );
                },
                child: ListTile(
                  title: Text(
                    alert.cryptoId.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Target: \$${alert.targetPrice.toStringAsFixed(2)} '
                    '(${alert.isGreaterThan ? 'Above' : 'Below'})',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  trailing: const Icon(Icons.notifications_active),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
