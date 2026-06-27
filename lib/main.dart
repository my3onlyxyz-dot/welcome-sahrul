import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    runApp(const WelcomeSahrulApp());
  }, (error, stack) {
    debugPrint('Error: $error');
  });
}

// ============================================================
// TEMA & WARNA GLOBAL
// ============================================================
final isNightNotifier = ValueNotifier<bool>(true);
bool get _night => isNightNotifier.value;

const kCyan   = Color(0xFF00E5FF);
const kGreen  = Color(0xFF34C759);
const kYellow = Color(0xFFE6A700);
const kRed    = Color(0xFFFF4747);
const kOrange = Color(0xFFFF6B47);
const kPurple = Color(0xFFB47FFF);
const kTeal   = Color(0xFF13B5A6);
const kPink   = Color(0xFFFF2D78);
const kBlue   = Color(0xFF3D8EFF);

Color get kBg     => _night ? const Color(0xFF070710) : const Color(0xFFF0F2F8);
Color get kPanel  => _night ? const Color(0xFF0F0F1E) : const Color(0xFFFFFFFF);
Color get kPanel2 => _night ? const Color(0xFF14142A) : const Color(0xFFE8EAF2);
Color get kBorder => _night ? const Color(0xFF1E1E3A) : const Color(0xFFDDE0EC);
Color get kWhite  => _night ? Colors.white : const Color(0xFF0A0A1A);

Color mut(double o) => _night
    ? Colors.white.withOpacity(o)
    : const Color(0xFF0A0A1A).withOpacity(o.clamp(0.05, 0.9));
Color glow(Color c, double o) => c.withOpacity(o);

// ============================================================
// APP ROOT
// ============================================================
class WelcomeSahrulApp extends StatelessWidget {
  const WelcomeSahrulApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, night, __) => MaterialApp(
        title: 'Command Center',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: kBg,
          fontFamily: 'sans-serif',
          colorScheme: ColorScheme.fromSeed(
            seedColor: kCyan,
            brightness: night ? Brightness.dark : Brightness.light,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    _scale = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _c, curve: const Interval(0.4, 0.9, curve: Curves.easeOut));
    _ring  = CurvedAnimation(parent: _c, curve: const Interval(0.2, 0.8, curve: Curves.easeOut));

    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, a, __) =>
                FadeTransition(opacity: a, child: const RootShell()),
          ),
        );
      }
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070710),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo animasi berlapis
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  // Ring luar
                  Opacity(
                    opacity: _ring.value,
                    child: Container(
                      width: 120 + (30 * _ring.value),
                      height: 120 + (30 * _ring.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kCyan.withOpacity(0.15 * _ring.value), width: 1),
                      ),
                    ),
                  ),
                  // Ring tengah
                  Opacity(
                    opacity: _ring.value * 0.6,
                    child: Container(
                      width: 100 + (20 * _ring.value),
                      height: 100 + (20 * _ring.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kCyan.withOpacity(0.3), width: 1),
                      ),
                    ),
                  ),
                  // Ikon utama
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00E5FF), Color(0xFF006080)],
                        ),
                        boxShadow: [
                          BoxShadow(color: kCyan.withOpacity(.5), blurRadius: 40, spreadRadius: 4),
                          BoxShadow(color: kCyan.withOpacity(.2), blurRadius: 80, spreadRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.memory_rounded, color: Colors.black, size: 44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                Text('SAHRUL', style: TextStyle(
                  color: kCyan,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                )),
                const SizedBox(height: 6),
                Text('COMMAND CENTER', style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                )),
                const SizedBox(height: 20),
                // Loading bar
                SizedBox(
                  width: 120,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _c.value,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation(kCyan),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 2,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROOT SHELL — bottom nav
// ============================================================
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _idx = 0;
  final _pages = const [DashboardTab(), CommandTab(), ToolsTab(), AboutTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(bottom: false, child: _pages[_idx]),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: isNightNotifier,
        builder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: kPanel,
            border: Border(top: BorderSide(color: kBorder, width: 1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.dashboard_rounded, 'Dashboard', kCyan),
                  _navItem(1, Icons.account_tree_rounded, 'Command', kPurple),
                  _navItem(2, Icons.construction_rounded, 'Tools', kOrange),
                  _navItem(3, Icons.person_rounded, 'Tentang', kGreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label, Color accent) {
    final on = _idx == i;
    return GestureDetector(
      onTap: () => setState(() => _idx = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: on ? glow(accent, .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? glow(accent, .35) : Colors.transparent, width: 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: on ? accent : mut(.35)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: on ? FontWeight.w800 : FontWeight.w500,
            color: on ? accent : mut(.35),
            letterSpacing: .5,
          )),
        ]),
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB
// ============================================================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Simulasi nilai sensor
  double _cpuTemp  = 38.5;
  double _cpuLoad  = 42.0;
  double _ramUsed  = 68.0;
  double _battery  = 72.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {
        _cpuTemp  = 36 + ((_cpuTemp  - 36 + 1) % 12);
        _cpuLoad  = 30 + ((_cpuLoad  - 30 + 3) % 50);
        _ramUsed  = 55 + ((_ramUsed  - 55 + 2) % 35);
        _battery  = (_battery - 0.1).clamp(0, 100);
      });
    });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  Color _tempColor(double t) => t < 45 ? kGreen : t < 60 ? kYellow : kRed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          _pageHeader('Dashboard', 'System Overview', Icons.dashboard_rounded, kCyan),
          const SizedBox(height: 24),

          // Status banner
          _statusBanner(),
          const SizedBox(height: 20),

          // Grid metrik utama
          _sectionLabel('LIVE METRICS', kCyan),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _metricCard('CPU Temp', '${_cpuTemp.toStringAsFixed(1)}°C',
                  Icons.thermostat_rounded, _tempColor(_cpuTemp), _cpuTemp / 100),
              _metricCard('CPU Load', '${_cpuLoad.toStringAsFixed(0)}%',
                  Icons.speed_rounded, kBlue, _cpuLoad / 100),
              _metricCard('RAM Used', '${_ramUsed.toStringAsFixed(0)}%',
                  Icons.memory_rounded, kPurple, _ramUsed / 100),
              _metricCard('Battery', '${_battery.toStringAsFixed(0)}%',
                  Icons.battery_charging_full_rounded, kGreen, _battery / 100),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          _sectionLabel('QUICK ACCESS', kOrange),
          const SizedBox(height: 12),
          _quickActions(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kCyan.withOpacity(.12), kPurple.withOpacity(.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCyan.withOpacity(.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kGreen.withOpacity(.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: kGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('System Normal', style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('KernelSU Active · All sensors OK', style: TextStyle(color: mut(.45), fontSize: 11.5)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGreen.withOpacity(.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGreen.withOpacity(.4)),
          ),
          child: Text('ONLINE', style: TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ]),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, double pct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(.06), blurRadius: 20, spreadRadius: -2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: mut(.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ]),
        const Spacer(),
        Text(value, style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: mut(.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .8)),
      ]),
    );
  }

  Widget _quickActions() {
    final items = [
      _QuickItem('Clear Cache', Icons.cleaning_services_rounded, kTeal),
      _QuickItem('CPU Boost', Icons.bolt_rounded, kYellow),
      _QuickItem('Kill Apps', Icons.close_rounded, kRed),
      _QuickItem('Force Stop', Icons.stop_circle_rounded, kOrange),
    ];
    return Row(
      children: items.map((e) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: e == items.last ? 0 : 10),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: e.color.withOpacity(.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: e.color.withOpacity(.25)),
              ),
              child: Column(children: [
                Icon(e.icon, color: e.color, size: 22),
                const SizedBox(height: 6),
                Text(e.label, style: TextStyle(color: e.color, fontSize: 9.5, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _QuickItem {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickItem(this.label, this.icon, this.color);
}

// ============================================================
// COMMAND TAB — Nested Cascading Menu utama
// ============================================================
class CommandTab extends StatelessWidget {
  const CommandTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _pageHeader('Command', 'Device Control Hub', Icons.account_tree_rounded, kPurple),
          const SizedBox(height: 8),

          // Banner info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kYellow.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kYellow.withOpacity(.3)),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: kYellow, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Sebagian fitur memerlukan akses Root.',
                  style: TextStyle(color: kYellow, fontSize: 11.5))),
            ]),
          ),
          const SizedBox(height: 20),

          // ── CPU CONTROL ──
          _CommandGroup(
            icon: Icons.developer_board_rounded,
            label: 'CPU Control',
            accent: kCyan,
            subtitle: 'Governor · Frekuensi · Core',
            children: [
              _CommandSubGroup(
                icon: Icons.tune_rounded,
                label: 'Governor',
                accent: kCyan,
                children: [
                  _CommandLeaf('Performance', Icons.flash_on_rounded, kCyan, 'Semua core full speed'),
                  _CommandLeaf('Powersave', Icons.battery_saver_rounded, kGreen, 'Hemat baterai maksimal'),
                  _CommandLeaf('Schedutil', Icons.schedule_rounded, kBlue, 'Adaptif berdasarkan load'),
                  _CommandLeaf('Interactive', Icons.touch_app_rounded, kPurple, 'Responsif untuk gaming'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.speed_rounded,
                label: 'Frekuensi Max',
                accent: kTeal,
                children: [
                  _CommandLeaf('2.4 GHz', Icons.bolt_rounded, kRed, 'Overdrive — panas tinggi'),
                  _CommandLeaf('2.0 GHz', Icons.offline_bolt_rounded, kOrange, 'Performa tinggi'),
                  _CommandLeaf('1.6 GHz', Icons.electric_bolt_rounded, kYellow, 'Seimbang'),
                  _CommandLeaf('1.0 GHz', Icons.battery_charging_full_rounded, kGreen, 'Hemat daya'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.memory_rounded,
                label: 'Core Management',
                accent: kBlue,
                children: [
                  _CommandLeaf('Aktifkan Semua Core', Icons.power_rounded, kGreen, '8 core aktif'),
                  _CommandLeaf('Mode 4 Core', Icons.grid_view_rounded, kYellow, 'Hemat daya'),
                  _CommandLeaf('Mode 2 Core', Icons.crop_square_rounded, kOrange, 'Ultra hemat'),
                ],
              ),
            ],
          ),

          // ── GPU CONTROL ──
          _CommandGroup(
            icon: Icons.videogame_asset_rounded,
            label: 'GPU Control',
            accent: kPurple,
            subtitle: 'Governor · Frekuensi · Render',
            children: [
              _CommandSubGroup(
                icon: Icons.tune_rounded,
                label: 'GPU Governor',
                accent: kPurple,
                children: [
                  _CommandLeaf('Performance', Icons.flash_on_rounded, kPurple, 'GPU full speed'),
                  _CommandLeaf('Simple', Icons.linear_scale_rounded, kBlue, 'Stabil & efisien'),
                  _CommandLeaf('Powersave', Icons.battery_saver_rounded, kGreen, 'Minimal load GPU'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.graphic_eq_rounded,
                label: 'Frekuensi GPU',
                accent: kPink,
                children: [
                  _CommandLeaf('900 MHz', Icons.rocket_launch_rounded, kRed, 'Gaming mode'),
                  _CommandLeaf('650 MHz', Icons.sports_esports_rounded, kOrange, 'Balanced gaming'),
                  _CommandLeaf('400 MHz', Icons.movie_rounded, kYellow, 'Video & UI'),
                  _CommandLeaf('200 MHz', Icons.eco_rounded, kGreen, 'Ultra hemat'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.layers_rounded,
                label: 'Render Mode',
                accent: kTeal,
                children: [
                  _CommandLeaf('Hardware Overlay', Icons.monitor_rounded, kCyan, 'Compositing GPU'),
                  _CommandLeaf('Software Render', Icons.code_rounded, kBlue, 'CPU rendering'),
                ],
              ),
            ],
          ),

          // ── RAM & SWAP ──
          _CommandGroup(
            icon: Icons.storage_rounded,
            label: 'RAM & Swap',
            accent: kGreen,
            subtitle: 'Cache · Swap · ZRAM',
            children: [
              _CommandSubGroup(
                icon: Icons.cleaning_services_rounded,
                label: 'Cache Manager',
                accent: kGreen,
                children: [
                  _CommandLeaf('Clear Pagecache', Icons.clear_all_rounded, kGreen, 'Bersihkan cache halaman'),
                  _CommandLeaf('Clear Dentries', Icons.folder_delete_rounded, kTeal, 'Bersihkan direktori cache'),
                  _CommandLeaf('Clear Inodes', Icons.delete_sweep_rounded, kCyan, 'Bersihkan inode cache'),
                  _CommandLeaf('Clear All', Icons.cleaning_services_rounded, kRed, 'Bersihkan semua cache'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.swap_horiz_rounded,
                label: 'Swap Manager',
                accent: kBlue,
                children: [
                  _CommandLeaf('Aktifkan Swap 1GB', Icons.add_circle_rounded, kGreen, 'Tambah virtual RAM'),
                  _CommandLeaf('Aktifkan Swap 2GB', Icons.add_circle_outline_rounded, kCyan, 'Virtual RAM besar'),
                  _CommandLeaf('Nonaktifkan Swap', Icons.remove_circle_rounded, kRed, 'Matikan swap'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.compress_rounded,
                label: 'ZRAM',
                accent: kPurple,
                children: [
                  _CommandLeaf('ZRAM 512MB', Icons.memory_rounded, kPurple, 'Kompresi RAM kecil'),
                  _CommandLeaf('ZRAM 1GB', Icons.memory_rounded, kBlue, 'Kompresi RAM standar'),
                  _CommandLeaf('Reset ZRAM', Icons.restart_alt_rounded, kOrange, 'Reset konfigurasi'),
                ],
              ),
            ],
          ),

          // ── THERMAL ──
          _CommandGroup(
            icon: Icons.thermostat_rounded,
            label: 'Thermal Control',
            accent: kOrange,
            subtitle: 'Mode · Throttle · Fan',
            children: [
              _CommandSubGroup(
                icon: Icons.ac_unit_rounded,
                label: 'Thermal Mode',
                accent: kOrange,
                children: [
                  _CommandLeaf('Normal', Icons.thermostat_rounded, kGreen, 'Throttle standar'),
                  _CommandLeaf('Gaming', Icons.sports_esports_rounded, kOrange, 'Throttle lebih longgar'),
                  _CommandLeaf('Silent', Icons.volume_off_rounded, kBlue, 'Prioritas dingin'),
                  _CommandLeaf('Disable Thermal', Icons.warning_rounded, kRed, 'Matikan throttle — berbahaya!'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.device_thermostat_rounded,
                label: 'Throttle Threshold',
                accent: kRed,
                children: [
                  _CommandLeaf('60°C Throttle', Icons.thermostat_auto_rounded, kGreen, 'Aman & dingin'),
                  _CommandLeaf('70°C Throttle', Icons.thermostat_auto_rounded, kYellow, 'Standar pabrik'),
                  _CommandLeaf('80°C Throttle', Icons.local_fire_department_rounded, kOrange, 'Gaming aggressive'),
                ],
              ),
            ],
          ),

          // ── NETWORK ──
          _CommandGroup(
            icon: Icons.wifi_rounded,
            label: 'Network Control',
            accent: kBlue,
            subtitle: 'DNS · TCP · Hotspot',
            children: [
              _CommandSubGroup(
                icon: Icons.dns_rounded,
                label: 'DNS Changer',
                accent: kBlue,
                children: [
                  _CommandLeaf('Google DNS', Icons.g_mobiledata_rounded, kBlue, '8.8.8.8 / 8.8.4.4'),
                  _CommandLeaf('Cloudflare DNS', Icons.cloud_rounded, kOrange, '1.1.1.1 / 1.0.0.1'),
                  _CommandLeaf('OpenDNS', Icons.lock_rounded, kGreen, '208.67.222.222'),
                  _CommandLeaf('Reset DNS', Icons.restore_rounded, kRed, 'Kembali default'),
                ],
              ),
              _CommandSubGroup(
                icon: Icons.network_check_rounded,
                label: 'TCP Optimization',
                accent: kTeal,
                children: [
                  _CommandLeaf('BBR Congestion', Icons.compress_rounded, kTeal, 'Algoritma Google BBR'),
                  _CommandLeaf('Cubic (Default)', Icons.show_chart_rounded, kBlue, 'Standar Linux'),
                  _CommandLeaf('Westwood+', Icons.trending_up_rounded, kPurple, 'Optimal wireless'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ============================================================
// COMMAND GROUP — Level 1 (kategori utama)
// ============================================================
class _CommandGroup extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final List<Widget> children;

  const _CommandGroup({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.children,
  });

  @override
  State<_CommandGroup> createState() => _CommandGroupState();
}

class _CommandGroupState extends State<_CommandGroup>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _c;
  late Animation<double> _expand;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expand = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(_expand);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _c.forward() : _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _open ? widget.accent.withOpacity(.4) : kBorder),
          boxShadow: _open ? [BoxShadow(color: widget.accent.withOpacity(.08), blurRadius: 24, spreadRadius: -2)] : [],
        ),
        child: Column(children: [
          // Header klik
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Ikon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.accent.withOpacity(.25)),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.label, style: TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: TextStyle(color: mut(.4), fontSize: 11.5)),
                ])),
                // Jumlah sub menu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${widget.children.length}', style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                // Arrow animasi
                RotationTransition(
                  turns: _rotate,
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: mut(.4), size: 22),
                ),
              ]),
            ),
          ),

          // Konten animasi
          SizeTransition(
            sizeFactor: _expand,
            child: Column(children: [
              Divider(height: 1, color: kBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(children: widget.children),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// COMMAND SUB GROUP — Level 2
// ============================================================
class _CommandSubGroup extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final List<_CommandLeaf> children;

  const _CommandSubGroup({
    required this.icon,
    required this.label,
    required this.accent,
    required this.children,
  });

  @override
  State<_CommandSubGroup> createState() => _CommandSubGroupState();
}

class _CommandSubGroupState extends State<_CommandSubGroup>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _c;
  late Animation<double> _expand;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expand = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(_expand);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _c.forward() : _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: kPanel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _open ? widget.accent.withOpacity(.3) : kBorder.withOpacity(.5)),
        ),
        child: Column(children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.label, style: TextStyle(color: kWhite, fontSize: 13.5, fontWeight: FontWeight.w600))),
                // Badge jumlah opsi
                Text('${widget.children.length} opsi', style: TextStyle(color: mut(.35), fontSize: 10.5)),
                const SizedBox(width: 6),
                RotationTransition(
                  turns: _rotate,
                  child: Icon(Icons.chevron_right_rounded, color: widget.accent.withOpacity(.6), size: 20),
                ),
              ]),
            ),
          ),

          // Leaf items
          SizeTransition(
            sizeFactor: _expand,
            child: Column(children: [
              Divider(height: 1, color: kBorder.withOpacity(.5)),
              ...widget.children.asMap().entries.map((e) => _AnimatedLeaf(
                leaf: e.value,
                index: e.key,
                total: widget.children.length,
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// COMMAND LEAF — Level 3 (aksi akhir)
// ============================================================
class _CommandLeaf extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String desc;

  const _CommandLeaf(this.label, this.icon, this.color, this.desc);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // Dirender oleh _AnimatedLeaf
}

class _AnimatedLeaf extends StatefulWidget {
  final _CommandLeaf leaf;
  final int index;
  final int total;

  const _AnimatedLeaf({required this.leaf, required this.index, required this.total});

  @override
  State<_AnimatedLeaf> createState() => _AnimatedLeafState();
}

class _AnimatedLeafState extends State<_AnimatedLeaf> {
  bool _pressed = false;
  bool _active  = false;

  @override
  Widget build(BuildContext context) {
    final isLast = widget.index == widget.total - 1;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() { _pressed = false; _active = !_active; });
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_active ? '✓ ${widget.leaf.label} diaktifkan' : '✗ ${widget.leaf.label} dinonaktifkan'),
          backgroundColor: _active ? widget.leaf.color.withOpacity(.85) : kPanel2,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.leaf.color.withOpacity(.15)
              : _active
                  ? widget.leaf.color.withOpacity(.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.only(
            bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Row(children: [
          // Indent visual
          Container(width: 2, height: 32, color: widget.leaf.color.withOpacity(_active ? .8 : .3),
              margin: const EdgeInsets.only(right: 14)),
          Icon(widget.leaf.icon, color: widget.leaf.color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.leaf.label, style: TextStyle(
              color: _active ? widget.leaf.color : kWhite,
              fontSize: 13,
              fontWeight: _active ? FontWeight.w700 : FontWeight.w500,
            )),
            Text(widget.leaf.desc, style: TextStyle(color: mut(.35), fontSize: 10.5)),
          ])),
          // Toggle indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              color: _active ? widget.leaf.color.withOpacity(.25) : mut(.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _active ? widget.leaf.color.withOpacity(.6) : mut(.12)),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _active ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _active ? widget.leaf.color : mut(.3),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// TOOLS TAB
// ============================================================
class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Tools', 'System Utilities', Icons.construction_rounded, kOrange),
          const SizedBox(height: 20),

          _sectionLabel('DIAGNOSTIK', kCyan),
          const SizedBox(height: 12),
          _toolCard('CPU Info', 'Detail prosesor & arsitektur', Icons.developer_board_rounded, kCyan),
          _toolCard('Battery Info', 'Kapasitas, suhu & kesehatan baterai', Icons.battery_full_rounded, kGreen),
          _toolCard('Sensor Monitor', 'Pantau semua sensor real-time', Icons.sensors_rounded, kPurple),
          _toolCard('Memory Map', 'Peta penggunaan RAM detail', Icons.map_rounded, kBlue),

          const SizedBox(height: 20),
          _sectionLabel('SISTEM', kOrange),
          const SizedBox(height: 12),
          _toolCard('Root Explorer', 'Jelajahi sistem file root', Icons.folder_special_rounded, kOrange),
          _toolCard('Log Viewer', 'Lihat logcat & kernel log', Icons.article_rounded, kYellow),
          _toolCard('Build.prop Editor', 'Edit properti sistem', Icons.edit_note_rounded, kRed),

          const SizedBox(height: 20),
          _sectionLabel('JARINGAN', kTeal),
          const SizedBox(height: 12),
          _toolCard('IP & Network Info', 'Alamat IP & info koneksi', Icons.wifi_find_rounded, kTeal),
          _toolCard('Ping Test', 'Test latensi ke server', Icons.network_ping_rounded, kBlue),
          _toolCard('DNS Lookup', 'Resolusi DNS manual', Icons.dns_rounded, kCyan),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _toolCard(String title, String sub, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: mut(.4), fontSize: 11.5)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: mut(.25), size: 14),
        ]),
      ),
    );
  }
}

// ============================================================
// AVATAR ILUSTRASI — CustomPainter geometric
// ============================================================
class AvatarIllustration extends CustomPainter {
  final double pulse;
  final double rotate;

  AvatarIllustration({required this.pulse, required this.rotate});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // -- Background circle gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1A1A3A), Color(0xFF070710)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // -- Ring pulse luar
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = kCyan.withOpacity(0.15 + 0.1 * pulse);
    canvas.drawCircle(Offset(cx, cy), r * (0.92 + 0.05 * pulse), ringPaint);
    canvas.drawCircle(Offset(cx, cy), r * (0.78 + 0.04 * pulse), ringPaint..color = kPurple.withOpacity(0.12 + 0.08 * pulse));

    // -- Hex grid background (6 titik)
    final dotPaint = Paint()..color = kCyan.withOpacity(0.18);
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + rotate * 360) * 3.14159 / 180;
      final dx = cx + r * 0.62 * _cos(angle);
      final dy = cy + r * 0.62 * _sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }

    // -- Badan (torso trapezoid)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF1E1E4A), kCyan.withOpacity(.25)],
      ).createShader(Rect.fromLTWH(cx - r * 0.4, cy + r * 0.18, r * 0.8, r * 0.55));
    final bodyPath = Path()
      ..moveTo(cx - r * 0.28, cy + r * 0.22)
      ..lineTo(cx + r * 0.28, cy + r * 0.22)
      ..lineTo(cx + r * 0.42, cy + r * 0.72)
      ..lineTo(cx - r * 0.42, cy + r * 0.72)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // -- Kerah baju (accent cyan)
    final collarPaint = Paint()..color = kCyan.withOpacity(.5)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final collarPath = Path()
      ..moveTo(cx - r * 0.12, cy + r * 0.22)
      ..lineTo(cx, cy + r * 0.36)
      ..lineTo(cx + r * 0.12, cy + r * 0.22);
    canvas.drawPath(collarPath, collarPaint);

    // -- Kepala (circle)
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [const Color(0xFF2A2A5A), const Color(0xFF0F0F2A)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - r * 0.18), radius: r * 0.28));
    canvas.drawCircle(Offset(cx, cy - r * 0.18), r * 0.28, headPaint);

    // -- Outline kepala cyan
    canvas.drawCircle(
      Offset(cx, cy - r * 0.18), r * 0.28,
      Paint()..style = PaintingStyle.stroke..color = kCyan.withOpacity(.35)..strokeWidth = 1.5,
    );

    // -- Mata kiri
    final eyePaint = Paint()..color = kCyan..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx - r * 0.1, cy - r * 0.2), 3.5, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.1, cy - r * 0.2), 3.5, eyePaint);
    // pupil
    canvas.drawCircle(Offset(cx - r * 0.1, cy - r * 0.2), 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.1, cy - r * 0.2), 1.5, Paint()..color = Colors.white);

    // -- Senyum kecil
    final smilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = kCyan.withOpacity(.6)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.1), width: r * 0.22, height: r * 0.14),
      0.3, 2.5, false, smilePaint,
    );

    // -- Rambut (arc atas kepala)
    final hairPaint = Paint()
      ..color = const Color(0xFF6040FF)
      ..style = PaintingStyle.fill;
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy - r * 0.18), radius: r * 0.28),
        3.14159 + 0.3, 2.58,
      )
      ..lineTo(cx, cy - r * 0.18)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // -- Highlight rambut
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r * 0.06, cy - r * 0.38), radius: r * 0.09),
      3.9, 1.2, false,
      Paint()..style = PaintingStyle.stroke..color = kPurple.withOpacity(.5)..strokeWidth = 2,
    );

    // -- Badge "DEV" di dada
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.38), width: r * 0.52, height: r * 0.18),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, Paint()..color = kCyan.withOpacity(.15));
    canvas.drawRRect(badgeRect, Paint()..style = PaintingStyle.stroke..color = kCyan.withOpacity(.5)..strokeWidth = 1);

    // -- Glow bawah
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [kCyan.withOpacity(0.18 * pulse), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy + r * 0.6), radius: r * 0.5));
    canvas.drawCircle(Offset(cx, cy + r * 0.6), r * 0.5, glowPaint);
  }

  double _cos(double rad) => rad == 0 ? 1 : (rad == 3.14159 ? -1 : (1 - rad * rad / 2 + rad * rad * rad * rad / 24));
  double _sin(double rad) => rad - rad * rad * rad / 6 + rad * rad * rad * rad * rad / 120;

  @override
  bool shouldRepaint(AvatarIllustration old) => old.pulse != pulse || old.rotate != rotate;
}

// Widget avatar dengan animasi pulse + rotate
class AnimatedAvatar extends StatefulWidget {
  const AnimatedAvatar({super.key});
  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _rotate;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _rotate = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() { _pulse.dispose(); _rotate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _rotate]),
      builder: (_, __) => CustomPaint(
        size: const Size(120, 120),
        painter: AvatarIllustration(
          pulse: _pulse.value,
          rotate: _rotate.value,
        ),
      ),
    );
  }
}

// ============================================================
// ABOUT TAB
// ============================================================
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Tentang', 'About This App', Icons.person_rounded, kGreen),
          const SizedBox(height: 24),

          // Kartu profil dengan avatar animasi
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kCyan.withOpacity(.1), kPurple.withOpacity(.07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kCyan.withOpacity(.2)),
            ),
            child: Column(children: [
              // Avatar ilustrasi animasi
              Stack(alignment: Alignment.bottomRight, children: [
                const AnimatedAvatar(),
                // Badge online
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kPanel, width: 2.5),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                ),
              ]),
              const SizedBox(height: 16),
              Text('Sahrul', style: TextStyle(
                color: kWhite, fontSize: 24,
                fontWeight: FontWeight.w900, letterSpacing: -.5,
              )),
              const SizedBox(height: 4),
              Text('Android Developer & Enthusiast', style: TextStyle(color: mut(.45), fontSize: 13)),
              const SizedBox(height: 16),
              // Stats row
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statChip('KernelSU', Icons.security_rounded, kGreen),
                const SizedBox(width: 8),
                _statChip('Root', Icons.lock_open_rounded, kOrange),
                const SizedBox(width: 8),
                _statChip('v2.0', Icons.rocket_launch_rounded, kCyan),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          _sectionLabel('FITUR UTAMA', kCyan),
          const SizedBox(height: 12),
          _aboutCard(Icons.account_tree_rounded, kPurple, 'Nested Command Menu', 'Kontrol berlapis 3 tingkat — kategori, sub-kategori, dan aksi.'),
          _aboutCard(Icons.dashboard_rounded, kCyan, 'Live Dashboard', 'Pantau CPU, RAM, suhu, dan baterai secara real-time.'),
          _aboutCard(Icons.dark_mode_rounded, kYellow, 'Night / Light Mode', 'Ganti tema kapan saja dengan satu ketukan.'),
          _aboutCard(Icons.security_rounded, kGreen, 'KernelSU Support', 'Optimasi penuh dengan akses root KernelSU.'),
          _aboutCard(Icons.devices_rounded, kOrange, 'Infinix GT 20 Pro', 'Dirancang dan dioptimasi khusus untuk perangkat ini.'),

          const SizedBox(height: 28),
          Center(child: Text('Dibuat dengan ❤️ oleh Sahrul', style: TextStyle(color: mut(.35), fontSize: 12))),
          const SizedBox(height: 8),
          Center(child: Text('Command Center © 2026', style: TextStyle(color: mut(.25), fontSize: 11))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _statChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _aboutCard(IconData ic, Color c, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(ic, color: c, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: mut(.45), fontSize: 12, height: 1.4)),
          ])),
        ]),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================
Widget _pageHeader(String title, String subtitle, IconData icon, Color accent) {
  return ValueListenableBuilder<bool>(
    valueListenable: isNightNotifier,
    builder: (_, night, __) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kWhite, letterSpacing: -.5)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: mut(.4), letterSpacing: .3)),
        ])),
        // Theme toggle
        GestureDetector(
          onTap: () => isNightNotifier.value = !isNightNotifier.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: (night ? kPurple : kYellow).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (night ? kPurple : kYellow).withOpacity(.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(night ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 16, color: night ? kPurple : kYellow),
              const SizedBox(width: 6),
              Text(night ? 'Night' : 'Light', style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: night ? kPurple : kYellow,
              )),
            ]),
          ),
        ),
      ],
    ),
  );
}

Widget _sectionLabel(String text, Color accent) {
  return Row(children: [
    Container(width: 3, height: 13, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
  ]);
}
