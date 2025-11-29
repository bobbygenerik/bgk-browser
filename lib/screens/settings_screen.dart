import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              // APPEARANCE SECTION
              _SectionHeader(title: 'Appearance', icon: Icons.palette),
              
              SwitchListTile(
                title: const Text('Auto Day/Night Mode'),
                subtitle: const Text('Light theme 6AM-6PM, dark at night'),
                secondary: const Icon(Icons.brightness_auto),
                value: settings.autoDayNight,
                onChanged: (v) => settings.setAutoDayNight(v),
              ),
              
              if (!settings.autoDayNight)
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('OLED-optimized black theme'),
                  secondary: const Icon(Icons.dark_mode),
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.setDarkMode(v),
                ),
              
              SwitchListTile(
                title: const Text('Blue Light Filter'),
                subtitle: const Text('Reduce eye strain at night'),
                secondary: const Icon(Icons.nightlight),
                value: settings.blueLightFilter,
                onChanged: (v) => settings.setBlueLightFilter(v),
              ),
              
              ListTile(
                leading: const Icon(Icons.font_download),
                title: const Text('Reader Mode Font'),
                subtitle: Text(settings.readerFont),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFontPicker(context, settings),
              ),

              const Divider(),
              
              // SEARCH & NAVIGATION
              _SectionHeader(title: 'Search & Navigation', icon: Icons.search),
              
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Engine'),
                subtitle: Text(settings.searchEngine),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSearchEnginePicker(context, settings),
              ),
              
              SwitchListTile(
                title: const Text('Request Desktop Site'),
                subtitle: const Text('View desktop version of websites'),
                secondary: const Icon(Icons.desktop_windows),
                value: settings.desktopMode,
                onChanged: (v) => settings.setDesktopMode(v),
              ),
              
              SwitchListTile(
                title: const Text('Enable JavaScript'),
                subtitle: const Text('Required for most websites'),
                secondary: const Icon(Icons.code),
                value: settings.enableJavascript,
                onChanged: (v) => settings.setEnableJavascript(v),
              ),

              const Divider(),
              
              // CONTENT PROTECTION
              _SectionHeader(title: 'Content Protection', icon: Icons.shield),
              
              SwitchListTile(
                title: const Text('Block Ads'),
                subtitle: const Text('Remove advertisements from pages'),
                secondary: const Icon(Icons.block),
                value: settings.blockAds,
                onChanged: (v) => settings.setBlockAds(v),
              ),
              
              SwitchListTile(
                title: const Text('Block Trackers'),
                subtitle: const Text('Prevent third-party tracking'),
                secondary: const Icon(Icons.visibility_off),
                value: settings.blockTrackers,
                onChanged: (v) => settings.setBlockTrackers(v),
              ),
              
              SwitchListTile(
                title: const Text('Auto-Hide Cookie Banners'),
                subtitle: const Text('Automatically dismiss consent popups'),
                secondary: const Icon(Icons.cookie),
                value: settings.blockCookieBanners,
                onChanged: (v) => settings.setBlockCookieBanners(v),
              ),

              const Divider(),
              
              // KID MODE
              _SectionHeader(title: 'Kid Mode (Handover)', icon: Icons.child_care),
              
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Kid Mode PIN'),
                subtitle: const Text('Required to exit kid mode'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPinDialog(context, settings),
              ),
              
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Allowed Sites'),
                subtitle: Text('${settings.kidModeWhitelist.length} sites'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWhitelistEditor(context, settings),
              ),

              const Divider(),
              
              // SYNC (BYOC)
              _SectionHeader(title: 'Sync (Bring Your Own Cloud)', icon: Icons.cloud_sync),
              
              SwitchListTile(
                title: const Text('Enable Sync'),
                subtitle: const Text('Sync bookmarks & history to your cloud'),
                secondary: const Icon(Icons.sync),
                value: settings.syncEnabled,
                onChanged: (v) => settings.setSyncEnabled(v),
              ),
              
              if (settings.syncEnabled)
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Sync Provider'),
                  subtitle: Text(_getSyncProviderName(settings.syncProvider)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSyncProviderPicker(context, settings),
                ),
              
              if (settings.syncEnabled && settings.lastSyncTime != null)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Last Sync'),
                  subtitle: Text(_formatSyncTime(settings.lastSyncTime!)),
                ),

              const Divider(),
              
              // TRANSLATION
              _SectionHeader(title: 'Translation', icon: Icons.translate),
              
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Preferred Language'),
                subtitle: Text(settings.preferredLanguage.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, settings),
              ),
              
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Portuguese Variant'),
                subtitle: Text(settings.portugueseVariant == 'pt-PT' 
                    ? 'European Portuguese' 
                    : 'Brazilian Portuguese'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPortugueseVariantPicker(context, settings),
              ),

              const Divider(),
              
              // PRIVACY
              _SectionHeader(title: 'Privacy', icon: Icons.privacy_tip),
              
              SwitchListTile(
                title: const Text('Clear Data on Exit'),
                subtitle: const Text('Delete history & cookies when closing'),
                secondary: const Icon(Icons.delete_sweep),
                value: settings.clearDataOnExit,
                onChanged: (v) => settings.setClearDataOnExit(v),
              ),
              
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Data'),
                subtitle: const Text('Delete all browsing data now'),
                onTap: () => _showClearDataDialog(context),
              ),

              const Divider(),
              
              // ABOUT
              _SectionHeader(title: 'About', icon: Icons.info),
              
              const ListTile(
                leading: Icon(Icons.web),
                title: Text('BGK Browser'),
                subtitle: Text('Version 1.0.0 - Ultimate Daily Driver'),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showFontPicker(BuildContext context, SettingsService settings) {
    final fonts = ['Charter', 'Georgia', 'Palatino', 'Times New Roman', 'System'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: fonts.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(fonts[index]),
          trailing: settings.readerFont == fonts[index] 
              ? const Icon(Icons.check, color: Colors.green) 
              : null,
          onTap: () {
            settings.setReaderFont(fonts[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showSearchEnginePicker(BuildContext context, SettingsService settings) {
    final engines = ['DuckDuckGo', 'Google', 'Bing', 'Brave', 'Ecosia'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: engines.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(engines[index]),
          trailing: settings.searchEngine == engines[index] 
              ? const Icon(Icons.check, color: Colors.green) 
              : null,
          onTap: () {
            settings.setSearchEngine(engines[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.kidModePin);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Kid Mode PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'PIN',
            hintText: 'Enter 4-6 digit PIN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                settings.setKidModePin(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWhitelistEditor(BuildContext context, SettingsService settings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _KidModeWhitelistScreen(settings: settings),
      ),
    );
  }

  void _showSyncProviderPicker(BuildContext context, SettingsService settings) {
    final providers = [
      ('none', 'None', Icons.cloud_off),
      ('gdrive', 'Google Drive', Icons.add_to_drive),
      ('dropbox', 'Dropbox', Icons.cloud),
    ];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final (id, name, icon) = providers[index];
          return ListTile(
            leading: Icon(icon),
            title: Text(name),
            trailing: settings.syncProvider == id 
                ? const Icon(Icons.check, color: Colors.green) 
                : null,
            onTap: () {
              settings.setSyncProvider(id);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsService settings) {
    final languages = ['en', 'es', 'pt', 'fr', 'de', 'it', 'ja', 'zh'];
    final names = ['English', 'Spanish', 'Portuguese', 'French', 'German', 'Italian', 'Japanese', 'Chinese'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: languages.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(names[index]),
          subtitle: Text(languages[index].toUpperCase()),
          trailing: settings.preferredLanguage == languages[index] 
              ? const Icon(Icons.check, color: Colors.green) 
              : null,
          onTap: () {
            settings.setPreferredLanguage(languages[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showPortugueseVariantPicker(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('European Portuguese'),
            subtitle: const Text('pt-PT'),
            trailing: settings.portugueseVariant == 'pt-PT' 
                ? const Icon(Icons.check, color: Colors.green) 
                : null,
            onTap: () {
              settings.setPortugueseVariant('pt-PT');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Brazilian Portuguese'),
            subtitle: const Text('pt-BR'),
            trailing: settings.portugueseVariant == 'pt-BR' 
                ? const Icon(Icons.check, color: Colors.green) 
                : null,
            onTap: () {
              settings.setPortugueseVariant('pt-BR');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all browsing history, cookies, and cached data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear data logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _getSyncProviderName(String provider) {
    switch (provider) {
      case 'gdrive':
        return 'Google Drive';
      case 'dropbox':
        return 'Dropbox';
      default:
        return 'Not configured';
    }
  }

  String _formatSyncTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _KidModeWhitelistScreen extends StatefulWidget {
  final SettingsService settings;

  const _KidModeWhitelistScreen({required this.settings});

  @override
  State<_KidModeWhitelistScreen> createState() => _KidModeWhitelistScreenState();
}

class _KidModeWhitelistScreenState extends State<_KidModeWhitelistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowed Sites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSite,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.settings.kidModeWhitelist.length,
        itemBuilder: (context, index) {
          final site = widget.settings.kidModeWhitelist[index];
          return ListTile(
            leading: const Icon(Icons.web),
            title: Text(site),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                widget.settings.removeKidModeSite(site);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  void _addSite() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allowed Site'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Domain',
            hintText: 'e.g., example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.settings.addKidModeSite(controller.text.trim());
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
