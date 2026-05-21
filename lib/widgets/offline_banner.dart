import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _verificar();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _offline = results.contains(ConnectivityResult.none));
      }
    });
  }

  Future<void> _verificar() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _offline = r.contains(ConnectivityResult.none));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();
    return Material(
      color: Colors.orange.shade700,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sem conexão — dados salvos localmente',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
