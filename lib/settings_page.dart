import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onThemeToggle;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const SettingsPage({
    super.key,
    required this.isDarkTheme,
    required this.onThemeToggle,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool autoConnect = false;
  bool notificationsEnabled = false;
  late Color selectedColor;

  final List<Color> colorOptions = [
    Colors.indigo,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
    Colors.teal,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        // Geri dönme tuşu AppBar'da otomatik olarak gelir
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Koyu Tema"),
            value: widget.isDarkTheme,
            onChanged: (_) => widget.onThemeToggle(),
            secondary: Icon(
              widget.isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Otomatik Bağlan"),
            value: autoConnect,
            onChanged: (val) {
              setState(() {
                autoConnect = val;
              });
            },
            secondary: const Icon(Icons.bluetooth_connected),
          ),
          SwitchListTile(
            title: const Text("Bildirimleri Aç"),
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() {
                notificationsEnabled = val;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Tema Rengi"),
            subtitle: Row(
              children: colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                    widget.onColorChanged(color);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Hakkında"),
            subtitle: const Text("ESP32 Bluetooth LED Kontrol\nv1.0.0"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "ESP32 Bluetooth LED Kontrol",
                applicationVersion: "v1.0.0",
                applicationLegalese: "© 2025 Aybüke",
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text("Geri Bildirim Gönder"),
            onTap: () {
              // Buraya e-posta veya iletişim fonksiyonu ekleyebilirsin
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text("Ana Sayfaya Dön"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
