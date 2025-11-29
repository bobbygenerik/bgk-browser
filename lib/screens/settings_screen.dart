import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.isDarkMode,
            onChanged: settings.setDarkMode,
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Slider(
              value: settings.textScale,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              label: '${(settings.textScale * 100).round()}%',
              onChanged: settings.setTextScale,
            ),
          ),

          // Search
          const _SectionHeader('Search'),
          ListTile(
            title: const Text('Search Engine'),
            subtitle: Text(_getSearchEngineName(settings.searchEngine)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSearchEngineDialog(context, settings),
          ),
          ListTile(
            title: const Text('Homepage'),
            subtitle: Text(settings.homepage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHomepageDialog(context, settings),
          ),

          // Privacy
          const _SectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Block Pop-ups'),
            value: settings.blockPopups,
            onChanged: settings.setBlockPopups,
          ),
          SwitchListTile(
            title: const Text('Do Not Track'),
            subtitle: const Text('Request websites not to track you'),
            value: settings.doNotTrack,
            onChanged: settings.setDoNotTrack,
          ),
          SwitchListTile(
            title: const Text('Save Passwords'),
            value: settings.savePasswords,
            onChanged: settings.setSavePasswords,
          ),
          ListTile(
            title: const Text('Clear Browsing Data'),
            leading: const Icon(Icons.delete_outline),
            onTap: () => _showClearDataDialog(context),
          ),

          // Advanced
          const _SectionHeader('Advanced'),
          SwitchListTile(
            title: const Text('JavaScript'),
            subtitle: const Text('Enable JavaScript on websites'),
            value: settings.enableJavascript,
            onChanged: settings.setEnableJavascript,
          ),
          SwitchListTile(
            title: const Text('Desktop Mode'),
            subtitle: const Text('Request desktop version of sites'),
            value: settings.desktopMode,
            onChanged: settings.setDesktopMode,
          ),

          // About
          const _SectionHeader('About'),
          const ListTile(
            title: Text('BGK Browser'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getSearchEngineName(SearchEngine engine) {
    switch (engine) {
      case SearchEngine.google: return 'Google';
      case SearchEngine.duckduckgo: return 'DuckDuckGo';
      case SearchEngine.bing: return 'Bing';
      case SearchEngine.yahoo: return 'Yahoo';
    }
  }

  void _showSearchEngineDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Search Engine'),
        children: SearchEngine.values.map((engine) {
          return RadioListTile<SearchEngine>(
            title: Text(_getSearchEngineName(engine)),
            value: engine,
            groupValue: settings.searchEngine,
            onChanged: (value) {
              if (value != null) {
                settings.setSearchEngine(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showHomepageDialog(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.homepage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Homepage'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://www.google.com',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setHomepage(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Browsing Data'),
        content: const Text('This will clear your browsing history. Bookmarks will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryService>().clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Browsing data cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
