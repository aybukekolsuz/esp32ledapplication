import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart'; // en üste ekle

import 'led_switch_widget.dart'; // LedSwitchWidget
import 'settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkTheme = false;
  Color primaryColor = Colors.indigo; // <-- Bunu ekle

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  void changePrimaryColor(Color color) {
    setState(() {
      primaryColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Bluetooth Control',
      debugShowCheckedModeBanner: false,
      theme: isDarkTheme
          ? ThemeData.dark().copyWith(
              primaryColor: primaryColor,
              colorScheme: ColorScheme.dark(
                primary: primaryColor,
                secondary: Colors.indigoAccent,
              ),
            )
          : ThemeData(
              primaryColor: primaryColor,
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                secondary: Colors.indigoAccent,
              ),
              fontFamily: 'Arial',
            ),
      home: BluetoothControl(
        isDarkTheme: isDarkTheme,
        onThemeToggle: toggleTheme,
        primaryColor: primaryColor,
        onColorChanged: changePrimaryColor,
      ),
    );
  }
}

class BluetoothControl extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onThemeToggle;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;

  const BluetoothControl({
    super.key,
    required this.isDarkTheme,
    required this.onThemeToggle,
    required this.primaryColor,
    required this.onColorChanged,
  });

  @override
  State<BluetoothControl> createState() => _BluetoothControlState();
}

class _BluetoothControlState extends State<BluetoothControl> {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  bool isConnecting = false;
  bool isConnected = false;
  String? errorMessage;

  final String targetDeviceName = "ESP32_BLE_LED";
  final String serviceUuid = "4FAFC201-1FB5-459E-8FCC-C5C9C331914B";
  final String characteristicUuid = "BEB5483E-36E1-4688-B7F5-EA07361B26A8";

  StreamSubscription<List<ScanResult>>? subscription;

  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  void scanAndConnect() async {
    setState(() {
      isConnecting = true;
      isConnected = false;
      errorMessage = null;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == targetDeviceName ||
            r.device.name == targetDeviceName) {
          device = r.device;
          await FlutterBluePlus.stopScan();

          try {
            await device!.connect();
            await discoverServices();
            setState(() {
              isConnected = true;
              isConnecting = false;
              errorMessage = null;
            });
          } catch (e) {
            setState(() {
              isConnected = false;
              isConnecting = false;
              errorMessage = "Bağlantı hatası: $e";
            });
          }

          await subscription?.cancel();
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 6));

    if (!isConnected) {
      await FlutterBluePlus.stopScan();
      setState(() {
        isConnecting = false;
        errorMessage ??= "Cihaz bulunamadı veya bağlanılamadı.";
      });
    }
  }

  Future<void> discoverServices() async {
    if (device == null) return;

    List<BluetoothService> services = await device!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUuid) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString().toUpperCase() == characteristicUuid) {
            characteristic = c;
            return;
          }
        }
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (characteristic == null) return;
    try {
      await characteristic!.write(utf8.encode(command), withoutResponse: true);
    } catch (e) {
      // hata sessizce yutuluyor
    }
  }

  Widget connectionStatusIndicator() {
    Color color;
    if (isConnected) {
      color = Colors.greenAccent;
    } else if (isConnecting) {
      color = Colors.amberAccent;
    } else {
      color = Colors.redAccent; // bağlantı yoksa kırmızı
    }

    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isConnecting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Bağlanıyor..."),
          actions: [
            IconButton(
              icon: Icon(
                widget.isDarkTheme ? Icons.wb_sunny : Icons.nights_stay,
              ),
              onPressed: widget.onThemeToggle,
              tooltip: 'Tema değiştir',
            ),
            connectionStatusIndicator(),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!isConnected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Cihaz bulunamadı"),
          actions: [
            IconButton(
              icon: Icon(
                widget.isDarkTheme ? Icons.wb_sunny : Icons.nights_stay,
              ),
              onPressed: widget.onThemeToggle,
              tooltip: 'Tema değiştir',
            ),
            connectionStatusIndicator(),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: widget.isDarkTheme
                ? const LinearGradient(
                    colors: [Colors.black, Colors.grey],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFCE4EC), Color(0xFFE1F5FE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: widget.isDarkTheme
                            ? Colors.red[300]
                            : Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: scanAndConnect,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tekrar Tara"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ESP32 Bluetooth Kontrol"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkTheme: widget.isDarkTheme,
                    onThemeToggle: widget.onThemeToggle,
                    selectedColor: widget.primaryColor,
                    onColorChanged: widget.onColorChanged,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: widget.onThemeToggle,
            tooltip: 'Tema değiştir',
          ),
          connectionStatusIndicator(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkTheme
              ? const LinearGradient(
                  colors: [Colors.black, Colors.grey],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter, // gradient for dark theme
                )
              : const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter, // gradient for light theme
                ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "LED Kontrol",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              LedSwitchWidget(
                initialValue: false,
                onChanged: (bool value) {
                  sendCommand(value ? '1' : '0');
                  HapticFeedback.mediumImpact(); // Haptic feedback burada!
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Dokunarak LED'i aç/kapat",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}
