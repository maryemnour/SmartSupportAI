import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final botCapabilitiesProvider = FutureProvider.family<Map<String, bool>, String>(
  (ref, companyId) async {
    final res = await Supabase.instance.client
        .from('companies')
        .select('bot_capabilities')
        .eq('id', companyId)
        .single();
    final raw = res['bot_capabilities'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, v == true));
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────
class BotControlsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const BotControlsScreen({super.key, required this.companyId});
  @override
  ConsumerState<BotControlsScreen> createState() => _BotControlsScreenState();
}

class _BotControlsScreenState extends ConsumerState<BotControlsScreen> {
  Map<String, bool> _caps = {};
  bool _loading  = false;
  bool _saved    = false;
  bool _initiated = false;

  // ── Capability definitions ────────────────────────────────────────────
  static const _sections = [
    _Section('Core Booking Actions', [
      _Cap('can_book_rooms',
           Icons.hotel_rounded,
           'Book Rooms',
           'Bot can guide guests through a full room reservation — collects dates, room type, name & email, and saves the booking.',
           AppColors.primary),
      _Cap('can_check_availability',
           Icons.event_available_rounded,
           'Check Availability',
           'Bot can answer availability questions and direct guests to your booking flow.',
           Color(0xFF0EA5E9)),
      _Cap('can_show_pricing',
           Icons.sell_rounded,
           'Show Pricing',
           'Bot can display room rates and pricing breakdowns to guests.',
           Color(0xFF10B981)),
      _Cap('can_cancel_booking',
           Icons.cancel_rounded,
           'Cancel Bookings',
           'Bot can accept cancellation requests and update booking status. Disable if you prefer guests to call for cancellations.',
           Color(0xFFEF4444)),
      _Cap('can_modify_booking',
           Icons.edit_calendar_rounded,
           'Modify Bookings',
           'Bot can handle date changes and room-type modifications on existing reservations.',
           Color(0xFFF59E0B)),
    ]),
    _Section('Guest Interaction', [
      _Cap('can_collect_contact_info',
           Icons.contact_mail_rounded,
           'Collect Contact Info',
           'Bot can ask for guest name, email, and phone number during a conversation.',
           Color(0xFF8B5CF6)),
      _Cap('can_handle_complaints',
           Icons.feedback_rounded,
           'Handle Complaints',
           'Bot can receive and log guest complaints. Disable to always route complaints to a human agent.',
           Color(0xFFEC4899)),
      _Cap('can_suggest_upsells',
           Icons.trending_up_rounded,
           'Suggest Upsells',
           'Bot can proactively suggest room upgrades, spa packages, or dining add-ons.',
           Color(0xFF14B8A6)),
    ]),
    _Section('Services', [
      _Cap('can_concierge_services',
           Icons.local_activity_rounded,
           'Concierge & Activities',
           'Bot can provide info and arrange tours, transfers, restaurant bookings, and other concierge services.',
           Color(0xFFF97316)),
      _Cap('ai_fallback_enabled',
           Icons.psychology_rounded,
           'AI Fallback (Claude)',
           'When no intent matches, bot uses Claude AI to answer. Disable to always show a human handoff message instead.',
           AppColors.primary),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(botCapabilitiesProvider(widget.companyId));

    return AdminScaffold(
      companyId: widget.companyId,
      currentRoute: AppRoutes.botControls,
      title: 'Bot Controls',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (caps) {
          if (!_initiated) { _caps = Map.from(caps); _initiated = true; }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      // Header card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(.25)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bot Actions Control', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900)),
            const SizedBox(height: 2),
            Text('Toggle which actions your chatbot is allowed to perform. Changes take effect instantly.',
                style: TextStyle(fontSize: 12, color: AppColors.grey600)),
          ])),
        ]),
      ),

      const SizedBox(height: 24),

      // Sections
      ..._sections.map((sec) => _buildSection(sec)),

      // Saved banner
      if (_saved) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6EE7B7)),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Bot controls saved successfully!', style: TextStyle(color: AppColors.success, fontSize: 13)),
          ]),
        ),
      ],

      const SizedBox(height: 20),

      // Save button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _save,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_loading ? 'Saving…' : 'Save Bot Controls'),
        ),
      ),

      const SizedBox(height: 32),

      // Bookings table
      _buildBookingsSection(),
    ],
  );

  Widget _buildSection(_Section sec) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(sec.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey400, letterSpacing: .4)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: sec.caps.asMap().entries.map((e) {
            final idx = e.key;
            final cap = e.value;
            final isLast = idx == sec.caps.length - 1;
            return _CapTile(
              cap: cap,
              value: _caps[cap.key] ?? false,
              isLast: isLast,
              onChanged: (v) => setState(() { _caps[cap.key] = v; _saved = false; }),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _buildBookingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Recent Bookings from Chat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey400, letterSpacing: .4)),
      const SizedBox(height: 10),
      _BookingsTable(companyId: widget.companyId),
    ],
  );

  Future<void> _save() async {
    setState(() { _loading = true; _saved = false; });
    try {
      await Supabase.instance.client
          .from('companies')
          .update({'bot_capabilities': _caps})
          .eq('id', widget.companyId);
      ref.invalidate(botCapabilitiesProvider(widget.companyId));
      setState(() { _loading = false; _saved = true; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

// ── Cap Tile ──────────────────────────────────────────────────────────────────
class _CapTile extends StatelessWidget {
  final _Cap cap;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;
  const _CapTile({required this.cap, required this.value, required this.isLast, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: cap.color.withOpacity(.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(cap.icon, color: cap.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cap.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey900)),
            const SizedBox(height: 2),
            Text(cap.description, style: const TextStyle(fontSize: 11, color: AppColors.grey400, height: 1.4)),
          ])),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cap.color,
          ),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 68),
    ],
  );
}

// ── Bookings Table ────────────────────────────────────────────────────────────
class _BookingsTable extends StatefulWidget {
  final String companyId;
  const _BookingsTable({required this.companyId});
  @override
  State<_BookingsTable> createState() => _BookingsTableState();
}

class _BookingsTableState extends State<_BookingsTable> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select('*')
          .eq('company_id', widget.companyId)
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) setState(() { _bookings = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (_bookings.isEmpty) return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
      child: Column(children: [
        Icon(Icons.hotel_rounded, size: 36, color: AppColors.grey200),
        const SizedBox(height: 10),
        const Text('No bookings yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey400)),
        const SizedBox(height: 4),
        const Text('Bookings made through the chatbot will appear here.', style: TextStyle(fontSize: 12, color: AppColors.grey400), textAlign: TextAlign.center),
      ]),
    );

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
      child: Column(
        children: _bookings.asMap().entries.map((e) {
          final b   = e.value;
          final idx = e.key;
          final isLast = idx == _bookings.length - 1;
          final status = b['status'] as String? ?? 'pending';
          final statusColor = {
            'pending':   const Color(0xFFF59E0B),
            'confirmed': const Color(0xFF10B981),
            'cancelled': const Color(0xFFEF4444),
            'completed': AppColors.primary,
          }[status] ?? AppColors.grey400;

          return Column(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text((b['guest_name'] as String? ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
              ),
              title: Row(children: [
                Expanded(child: Text(b['guest_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(.1), borderRadius: BorderRadius.circular(100)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: .5)),
                ),
              ]),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 2),
                Text('${b['room_type'] ?? ''} · ${b['check_in_date'] ?? ''} → ${b['check_out_date'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                Text(b['guest_email'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
              ]),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.grey400),
                onSelected: (val) => _updateStatus(b['id'] as String, val),
                itemBuilder: (_) => ['confirmed', 'cancelled', 'completed']
                    .map((s) => PopupMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                    .toList(),
              ),
            ),
            if (!isLast) const Divider(height: 1, indent: 68),
          ]);
        }).toList(),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    await Supabase.instance.client.from('bookings').update({'status': status}).eq('id', id);
    _load();
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _Section {
  final String title;
  final List<_Cap> caps;
  const _Section(this.title, this.caps);
}

class _Cap {
  final String key, label, description;
  final IconData icon;
  final Color color;
  const _Cap(this.key, this.icon, this.label, this.description, this.color);
}
