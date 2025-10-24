import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/ui/widgets/add_channel_sheet.dart';
import 'package:omada/core/data/utils/channel_launcher.dart';
import 'package:omada/core/controllers/profile_controller.dart';
import 'profile/channel_grid.dart';
import 'profile/cta_panel.dart';
import 'profile/about_section.dart';
import 'profile/avatar.dart';
import 'package:omada/core/theme/design_tokens.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late Future<ProfileData> _future;
  final Set<String> _selectedChannelIds = <String>{};
  final ChannelLauncher _launcher = const ChannelLauncher();

  @override
  void initState() {
    super.initState();
    _future = ProfileController(Supabase.instance.client).load();
  }

  void _refresh() {
    setState(() {
      _future = ProfileController(Supabase.instance.client).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorPill = const Color(0xFF1d4ed8); // Blue-700
    final colorPillActive = const Color(0xFF93c5fd); // Blue-300
    final colorText = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top section with gradient (60% of screen)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.1),
                  radius: 1.2,
                  colors: [
                    Color(0xFF7dd3fc), // Sky-300
                    Color(0xFF60a5fa), // Blue-400
                    Color(0xFF3b82f6), // Blue-500
                    Color(0xFF2563eb), // Blue-600
                    Color(0xFF1d4ed8), // Blue-700
                    Color(0xFF1e40af), // Blue-800
                    Color(0xFF3730a3), // Indigo-700
                  ],
                  stops: [0.0, 0.2, 0.4, 0.6, 0.78, 0.9, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OmadaTokens.space16,
                        vertical: OmadaTokens.space12,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, size: 22, color: colorText),
                              const SizedBox(width: OmadaTokens.space8),
                              Text(
                                'Omada',
                                style: TextStyle(
                                  color: colorText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: OmadaTokens.fontLg,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              tooltip: 'Account',
                              icon: const Icon(Icons.account_circle, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context).pushNamed('/account');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Data-driven content for gradient section
                    Expanded(
                      child: FutureBuilder<ProfileData>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Failed to load profile. ${snapshot.error ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          final data = snapshot.data!;
                          final displayName =
                              data.profile?.username ?? data.contact.displayName;
                          final notes = data.contact.notes;
                          final about = _aboutText(data);

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OmadaTokens.space16,
                                ),
                                child: Column(
                                  children: [
                                    Avatar(
                                      displayName: displayName,
                                      colorText: colorText,
                                    ),
                                    const SizedBox(height: OmadaTokens.space4),
                                    if (notes?.isNotEmpty == true)
                                      Text(
                                        notes!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorText.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    const SizedBox(height: OmadaTokens.space12),
                                    AboutSection(title: about, textColor: colorText),
                                  ],
                                ),
                              ),
                              const SizedBox(height: OmadaTokens.space16),

                              // Channel chips grid in gradient section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OmadaTokens.space16,
                                ),
                                // Match the search box styling used on Contacts screen
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: ChannelGrid(
                                    colorPill: colorPill,
                                    colorPillActive: colorPillActive,
                                    colorText: colorText,
                                    channels: data.channels,
                                    selectedIds: _selectedChannelIds,
                                    onOpen: (id) {
                                      final ch = data.channels.firstWhere(
                                        (c) => c.id == id,
                                      );
                                      _launcher.openChannel(context, ch);
                                    },
                                    onLongPress: (id) =>
                                        _onChannelLongPress(context, data, id),
                                  ),
                                ),
                              ),

                              const SizedBox(height: OmadaTokens.space12),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom section with white background (40% of screen)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: FutureBuilder<ProfileData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load profile. ${snapshot.error ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;

                  return Column(
                    children: [
                      const SizedBox(height: OmadaTokens.space16),

                      // CTA / actions panel
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OmadaTokens.space16,
                        ),
                        child: CtaPanel(
                          centerValue: _selectedChannelIds.isEmpty
                              ? 'Request'
                              : '${_selectedChannelIds.length} selected',
                          onAdd: () => _openAddChannel(context, data),
                          onShare: () => _openShare(context, data),
                          onQuickCall: () => _quickCall(context, data),
                        ),
                      ),

                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.profile),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedChannelIds.contains(id)) {
        _selectedChannelIds.remove(id);
      } else {
        _selectedChannelIds.add(id);
      }
    });
  }

  Future<void> _onChannelLongPress(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    _toggleSelection(id);
    await _showChannelActions(context, data, id);
  }

  Future<void> _showChannelActions(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    final ch = data.channels.firstWhere((c) => c.id == id);
    final repo = ContactChannelRepository(Supabase.instance.client);

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_labelForChannel(ch)),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'open'),
            child: const Text('Open'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (selected) {
      case 'open':
        _launcher.openChannel(context, ch);
        break;
      case 'edit':
        await _openEditChannel(context, data, ch);
        break;
      case 'delete':
        await _deleteChannel(context, data, ch, repo);
        break;
    }
  }

  Future<void> _openEditChannel(
    BuildContext context,
    ProfileData data,
    ContactChannelModel channel,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddChannelSheet(contactId: data.contact.id),
    );
    if (result == true) _refresh();
  }

  Future<void> _deleteChannel(
    BuildContext context,
    ProfileData data,
    ContactChannelModel channel,
    ContactChannelRepository repo,
  ) async {
    try {
      await repo.deleteChannel(channel.id);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _quickCall(BuildContext context, ProfileData data) async {
    final mobileChannels = data.channels.where(
      (c) => c.kind.toLowerCase() == 'mobile' || c.kind.toLowerCase() == 'phone',
    );

    if (mobileChannels.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number found')),
      );
      return;
    }

    final channel = mobileChannels.first;
    final number = channel.value;
    if (number == null || number.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number found')),
      );
      return;
    }

    final telUri = Uri.parse('tel:$number');
    if (!await launchUrl(telUri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open dialer')));
    }
  }

  Future<void> _openAddChannel(BuildContext context, ProfileData data) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddChannelSheet(contactId: data.contact.id),
    );
    if (result == true) _refresh();
  }

  Future<void> _openShare(BuildContext context, ProfileData data) async {
    final sharing = SharingService(Supabase.instance.client);
    final usernameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Share channels'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter recipient username'),
              const SizedBox(height: 8),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'username'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await sharing.sendShareRequest(
        recipientUsername: usernameCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Share request sent')));
    }
  }
}

// Data aggregation
// Helpers for mapping and display
String _labelForChannel(ContactChannelModel c) {
  if (c.label?.isNotEmpty == true) return c.label!;
  switch (c.kind.toLowerCase()) {
    case 'mobile':
    case 'phone':
      return 'Mobile';
    case 'email':
      return 'Email';
    case 'instagram':
      return 'Instagram';
    case 'linkedin':
      return 'LinkedIn';
    case 'whatsapp':
      return 'WhatsApp';
    case 'website':
      return 'Website';
    case 'telegram':
      return 'Telegram';
    case 'address':
      return 'Address';
    default:
      return c.kind;
  }
}

String _aboutText(ProfileData data) {
  if (data.contact.notes?.isNotEmpty == true) return data.contact.notes!;
  if (data.channels.isNotEmpty) {
    final kinds = data.channels
        .map((c) => _labelForChannel(c))
        .toSet()
        .join(' · ');
    return 'Channels: $kinds';
  }
  return 'Set up your preferred contact channels and profile details.';
}