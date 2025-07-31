import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/GlobalComponents/button_global.dart';
import '../constant.dart';
import 'internet_connection_notifier.dart';

class GlobalPopup extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalPopup({super.key, required this.child});

  @override
  _GlobalPopupState createState() => _GlobalPopupState();
}

class _GlobalPopupState extends ConsumerState<GlobalPopup> {
  @override
  Widget build(BuildContext context) {
    final internetStatus = ref.watch(internetConnectionProvider);

    return Stack(
      children: [
        widget.child,
        if (!internetStatus.isConnected && internetStatus.appLifecycleState == AppLifecycleState.resumed)
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: kMainColor, size: 100),
                    const SizedBox(height: 20),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(color: kTitleColor, fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final notifier = ref.read(internetConnectionProvider);
                        await notifier.checkConnection();
                      },
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
