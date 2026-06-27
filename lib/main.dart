import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    runApp(const SahrulApp());
  }, (e, s) => debugPrint('ERR: $e'));
}

// TEMA GLOBAL
final isNightNotifier = ValueNotifier<bool>(true);
final isRootNotifier  = ValueNotifier<bool>(false);
bool get _night => isNightNotifier.value;
bool get _root  => isRootNotifier.value;

const kCyan   = Color(0xFF00E5FF);
const kGreen  = Color(0xFF34C759);
const kYellow = Color(0xFFE6A700);
const kRed    = Color(0xFFFF4747);
const kOrange = Color(0xFFFF6B47);
const kPurple = Color(0xFFB47FFF);
const kTeal   = Color(0xFF13B5A6);
const kBlue   = Color(0xFF3D8EFF);

Color get kBg     => _night ? const Color(0xFF060612) : const Color(0xFFF0F2F8);
Color get kPanel  => _night ? const Color(0xFF0D0D20) : const Color(0xFFFFFFFF);
Color get kPanel2 => _night ? const Color(0xFF12122A) : const Color(0xFFE8EAF2);
Color get kBorder => _night ? const Color(0xFF1A1A38) : const Color(0xFFDDE0EC);
Color get kWhite  => _night ? Colors.white : const Color(0xFF080818);
Color mut(double o) => _night
    ? Colors.white.withOpacity(o)
    : const Color(0xFF080818).withOpacity(o.clamp(0.05, 0.9));
Color glow(Color c, double o) => c.withOpacity(o);

// ROOT HELPERS
Future<bool> checkRoot() async {
  try {
    final r = await Process.run('su', ['-c', 'id']);
    return r.stdout.toString().contains('uid=0');
  } catch (_) { return false; }
}

Future<String> runRoot(String cmd) async {
  if (!_root) return 'NO_ROOT';
  try {
    final r = await Process.run('su', ['-c', cmd]);
    return r.stdout.toString().trim();
  } catch (e) { return 'ERROR: $e'; }
}

// APP
class SahrulApp extends StatelessWidget {
  const SahrulApp({super.key});
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
          colorScheme: ColorScheme.fromSeed(seedColor: kCyan,
              brightness: night ? Brightness.dark : Brightness.light),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// SPLASH
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _main, _orbit;
  late Animation<double> _scale, _fade, _progress;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _main  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..forward();
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _scale    = CurvedAnimation(parent: _main, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    _fade     = CurvedAnimation(parent: _main, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _progress = CurvedAnimation(parent: _main, curve: Curves.easeInOut);
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _status = 'Checking root...');
    final hasRoot = await checkRoot();
    isRootNotifier.value = hasRoot;
    if (mounted) setState(() => _status = hasRoot ? 'Root detected ✓' : 'Non-root mode');
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _status = 'Loading modules...');
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const RootShell()),
      ));
    }
  }

  @override
  void dispose() { _main.dispose(); _orbit.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060612),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: Listenable.merge([_main, _orbit]),
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            Transform.rotate(
              angle: _orbit.value * 6.28318,
              child: SizedBox(width: 160, height: 160,
                  child: CustomPaint(painter: _OrbitPainter(_orbit.value))),
            ),
            Opacity(opacity: _scale.value,
              child: Container(width: 118 + 6 * (_orbit.value % 1), height: 118 + 6 * (_orbit.value % 1),
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: kCyan.withOpacity(0.1), width: 1)))),
            ScaleTransition(scale: _scale, child: _AppIcon(size: 92)),
          ]),
        ),
        const SizedBox(height: 36),
        FadeTransition(opacity: _fade, child: Column(children: [
          Text('SAHRUL', style: TextStyle(color: kCyan, fontSize: 28,
              fontWeight: FontWeight.w900, letterSpacing: 8)),
          const SizedBox(height: 4),
          Text('COMMAND CENTER', style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 10,
              fontWeight: FontWeight.w600, letterSpacing: 5)),
          const SizedBox(height: 28),
          SizedBox(width: 160, child: AnimatedBuilder(
            animation: _progress,
            builder: (_, __) => Column(children: [
              LinearProgressIndicator(value: _progress.value, minHeight: 2,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation(kCyan),
                borderRadius: BorderRadius.circular(2)),
              const SizedBox(height: 10),
              Text(_status, style: TextStyle(color: Colors.white.withOpacity(0.35),
                  fontSize: 11, fontFamily: 'monospace')),
            ]),
          )),
        ])),
      ])),
    );
  }
}

// APP ICON elegan — huruf S circuit
class _AppIcon extends StatelessWidget {
  final double size;
  const _AppIcon({required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A40), Color(0xFF060612)]),
      border: Border.all(color: kCyan.withOpacity(.35), width: 1.5),
      boxShadow: [
        BoxShadow(color: kCyan.withOpacity(.4), blurRadius: 28, spreadRadius: 1),
        BoxShadow(color: kPurple.withOpacity(.15), blurRadius: 48, spreadRadius: -4),
      ],
    ),
    child: CustomPaint(painter: _IconPainter(), size: Size(size, size)),
  );
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final p = Paint()..color = kCyan..style = PaintingStyle.stroke
      ..strokeWidth = 3.2..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final path = Path();
    path.moveTo(cx + s.width*.18, cy - s.height*.22);
    path.cubicTo(cx + s.width*.18, cy - s.height*.28,
        cx - s.width*.20, cy - s.height*.28, cx - s.width*.20, cy - s.height*.12);
    path.cubicTo(cx - s.width*.20, cy + s.height*.02,
        cx + s.width*.20, cy - s.height*.02, cx + s.width*.20, cy + s.height*.12);
    path.cubicTo(cx + s.width*.20, cy + s.height*.28,
        cx - s.width*.18, cy + s.height*.28, cx - s.width*.18, cy + s.height*.22);
    canvas.drawPath(path, p);
    final dot = Paint()..color = kCyan..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx + s.width*.18, cy - s.height*.22), 2.5, dot);
    canvas.drawCircle(Offset(cx - s.width*.18, cy + s.height*.22), 2.5, dot);
    final line = Paint()..color = kCyan.withOpacity(.35)..strokeWidth = 1..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + s.width*.18, cy - s.height*.22),
        Offset(cx + s.width*.3, cy - s.height*.22), line);
    canvas.drawLine(Offset(cx - s.width*.18, cy + s.height*.22),
        Offset(cx - s.width*.3, cy + s.height*.22), line);
  }
  @override
  bool shouldRepaint(_) => false;
}

class _OrbitPainter extends CustomPainter {
  final double v;
  _OrbitPainter(this.v);
  double _c(double a) => 1 - a*a/2 + a*a*a*a/24;
  double _s(double a) => a - a*a*a/6 + a*a*a*a*a/120;
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width/2, cy = s.height/2, r = s.width/2 - 4;
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 6.28318;
      canvas.drawCircle(Offset(cx + r*_c(a), cy + r*_s(a)), i%3==0 ? 2.2 : 1.2,
        Paint()..color = kCyan.withOpacity(i%3==0 ? .45 : .18));
    }
    final ma = v * 6.28318;
    canvas.drawCircle(Offset(cx + r*_c(ma), cy + r*_s(ma)), 4,
      Paint()..color = kCyan..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }
  @override
  bool shouldRepaint(_OrbitPainter o) => o.v != v;
}

// ROOT SHELL
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
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => Scaffold(
        backgroundColor: kBg,
        body: SafeArea(bottom: false, child: _pages[_idx]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: kPanel,
            border: Border(top: BorderSide(color: kBorder, width: .5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 20, offset: const Offset(0,-4))]),
          child: SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _nav(0, Icons.dashboard_rounded,    'Dashboard', kCyan),
              _nav(1, Icons.account_tree_rounded, 'Command',   kPurple),
              _nav(2, Icons.construction_rounded, 'Tools',     kOrange),
              _nav(3, Icons.person_rounded,       'Tentang',   kGreen),
            ]),
          )),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label, Color accent) {
    final on = _idx == i;
    return GestureDetector(
      onTap: () { setState(() => _idx = i); HapticFeedback.selectionClick(); },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: on ? accent.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? accent.withOpacity(.3) : Colors.transparent)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 21, color: on ? accent : mut(.3)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: on ? FontWeight.w800 : FontWeight.w500,
              color: on ? accent : mut(.3), letterSpacing: .3)),
        ]),
      ),
    );
  }
}

// DASHBOARD
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _freq = '---', _gov = '---', _temp = '---';
  String _memTotal = '---', _memFree = '---';
  String _bat = '---', _batTemp = '---', _uptime = '---';
  bool _loading = true;
  late Timer _timer;

  @override
  void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch()); }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  Future<String> _r(String p) async { try { return (await File(p).readAsString()).trim(); } catch (_) { return ''; } }
  Future<String> _rf(String p) async { try { return await File(p).readAsString(); } catch (_) { return ''; } }
  int _parseMem(String c, String k) {
    for (final l in c.split('\n')) {
      if (l.startsWith(k)) return int.tryParse(l.split(':')[1].trim().split(' ')[0]) ?? 0;
    }
    return 0;
  }

  Future<void> _fetch() async {
    try {
      final freq = await _r('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq');
      final gov  = await _r('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor');
      String temp = '---';
      for (int i = 0; i < 15; i++) {
        final t = await _r('/sys/class/thermal/thermal_zone$i/temp');
        final n = int.tryParse(t) ?? 0;
        if (n > 30000 && n < 90000) { temp = '${(n/1000).toStringAsFixed(1)}°C'; break; }
      }
      final mem = await _rf('/proc/meminfo');
      final mt = _parseMem(mem, 'MemTotal'), mf = _parseMem(mem, 'MemAvailable');
      String bat = '---', bt = '---';
      try {
        bat = await _r('/sys/class/power_supply/battery/capacity');
        final rawBt = await _r('/sys/class/power_supply/battery/temp');
        final bti = int.tryParse(rawBt) ?? 0;
        bt = '${(bti/10).toStringAsFixed(1)}°C';
        if (bat.isNotEmpty) bat = '$bat%';
      } catch (_) {}
      final up = await _rf('/proc/uptime');
      final sec = double.tryParse(up.split(' ')[0]) ?? 0;
      final upStr = '${sec~/3600}h ${((sec%3600)~/60)}m';
      final freqMhz = int.tryParse(freq) ?? 0;
      if (mounted) setState(() {
        _freq = freqMhz > 0 ? '${(freqMhz/1000).round()} MHz' : '---';
        _gov = gov.isEmpty ? '---' : gov;
        _temp = temp;
        _memTotal = mt > 0 ? '${(mt/1024).round()} MB' : '---';
        _memFree  = mf > 0 ? '${(mf/1024).round()} MB' : '---';
        _bat = bat.isEmpty ? '---' : bat;
        _batTemp = bt;
        _uptime = upStr;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => RefreshIndicator(
        onRefresh: _fetch, color: kCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader('Dashboard', 'Live System Monitor', kCyan),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isRootNotifier,
              builder: (_, root, __) => _banner(root),
            ),
            const SizedBox(height: 18),
            _sectionLabel('PROCESSOR', kCyan),
            const SizedBox(height: 10),
            _loading ? _skel() : GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15,
              children: [
                _tile('CPU Freq', _freq, Icons.speed_rounded, kCyan),
                _tile('Governor', _gov, Icons.tune_rounded, kPurple),
                _tile('CPU Temp', _temp, Icons.thermostat_rounded,
                    _temp == '---' ? kBlue : (double.tryParse(_temp.replaceAll('°C',''))??0) > 55 ? kRed : kGreen),
                _tile('Uptime', _uptime, Icons.timer_rounded, kTeal),
              ],
            ),
            const SizedBox(height: 18),
            _sectionLabel('MEMORY', kPurple),
            const SizedBox(height: 10),
            _loading ? _skel() : _memCard(),
            const SizedBox(height: 18),
            _sectionLabel('BATTERY', kGreen),
            const SizedBox(height: 10),
            _loading ? _skel() : Row(children: [
              Expanded(child: _tile('Kapasitas', _bat, Icons.battery_full_rounded, kGreen)),
              const SizedBox(width: 10),
              Expanded(child: _tile('Suhu', _batTemp, Icons.device_thermostat_rounded, kOrange)),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _banner(bool root) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: root ? kGreen.withOpacity(.07) : kYellow.withOpacity(.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: root ? kGreen.withOpacity(.25) : kYellow.withOpacity(.25))),
    child: Row(children: [
      Icon(root ? Icons.verified_rounded : Icons.info_rounded,
          color: root ? kGreen : kYellow, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(root ? 'Root Aktif — MT6895' : 'Mode Non-Root',
            style: TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(root ? 'KernelSU · Semua fitur tersedia' : 'Mode aman — fitur terbatas',
            style: TextStyle(color: mut(.4), fontSize: 11)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: root ? kGreen.withOpacity(.15) : kYellow.withOpacity(.15),
            borderRadius: BorderRadius.circular(8)),
        child: Text(root ? 'ROOT' : 'SAFE',
            style: TextStyle(color: root ? kGreen : kYellow,
                fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1))),
    ]),
  );

  Widget _memCard() {
    final t = int.tryParse(_memTotal.replaceAll(' MB','')) ?? 1;
    final f = int.tryParse(_memFree.replaceAll(' MB',''))  ?? 0;
    final u = t - f; final pct = (u/t).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.memory_rounded, color: kPurple, size: 18),
          const SizedBox(width: 8),
          Text('RAM Usage', style: TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$u / $t MB', style: TextStyle(color: kPurple, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
          value: pct, minHeight: 8, backgroundColor: mut(.06),
          valueColor: AlwaysStoppedAnimation(pct > .85 ? kRed : pct > .65 ? kYellow : kPurple))),
        const SizedBox(height: 8),
        Row(children: [
          Text('Free: $_memFree', style: TextStyle(color: mut(.4), fontSize: 11)),
          const Spacer(),
          Text('${(pct*100).toStringAsFixed(0)}% used', style: TextStyle(color: mut(.4), fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _tile(String label, String val, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 16)),
      const Spacer(),
      Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: mut(.38), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: .8)),
    ]),
  );

  Widget _skel() => Container(height: 80, decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18)),
    child: Center(child: SizedBox(width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: kCyan.withOpacity(.5)))));
}

// COMMAND TAB
class CommandTab extends StatelessWidget {
  const CommandTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Command', 'Device Control Hub', kPurple),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: isRootNotifier,
            builder: (_, root, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: root ? kGreen.withOpacity(.07) : kRed.withOpacity(.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: root ? kGreen.withOpacity(.25) : kRed.withOpacity(.25))),
              child: Row(children: [
                Icon(root ? Icons.check_circle_rounded : Icons.lock_rounded,
                    color: root ? kGreen : kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  root ? 'Root aktif — semua perintah dapat dieksekusi'
                       : 'Non-root — hanya info, tidak bisa ubah sistem',
                  style: TextStyle(color: root ? kGreen : kRed, fontSize: 11.5))),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          _CmdGroup(icon: Icons.developer_board_rounded, label: 'CPU Governor', accent: kCyan,
            subtitle: 'sugov_ext · conservative · powersave · performance · schedutil',
            children: [
              _CmdLeaf('performance',  Icons.flash_on_rounded,          kRed,    'Semua core max — gaming/benchmark',        cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > \$f; done'),
              _CmdLeaf('schedutil',    Icons.schedule_rounded,          kCyan,   'Adaptif load-based — rekomendasi harian',  cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo schedutil > \$f; done'),
              _CmdLeaf('conservative', Icons.trending_down_rounded,     kBlue,   'Naik pelan turun cepat — hemat daya',      cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo conservative > \$f; done'),
              _CmdLeaf('powersave',    Icons.battery_saver_rounded,     kGreen,  'Kunci di frekuensi minimum',               cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo powersave > \$f; done'),
              _CmdLeaf('sugov_ext',    Icons.auto_awesome_rounded,      kPurple, 'Governor extended MediaTek',               cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo sugov_ext > \$f; done'),
            ]),

          _CmdGroup(icon: Icons.speed_rounded, label: 'CPU Frekuensi Max', accent: kOrange,
            subtitle: 'MT6895 · 450 MHz – 2000 MHz',
            children: [
              _CmdLeaf('2000 MHz', Icons.rocket_launch_rounded,         kRed,    'Full speed — panas tinggi',   cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 2000000 > \$f; done'),
              _CmdLeaf('1800 MHz', Icons.bolt_rounded,                  kOrange, 'High performance',            cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 1800000 > \$f; done'),
              _CmdLeaf('1500 MHz', Icons.electric_bolt_rounded,         kYellow, 'Balanced — rekomendasi',      cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 1500000 > \$f; done'),
              _CmdLeaf('1200 MHz', Icons.eco_rounded,                   kGreen,  'Hemat daya ringan',           cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 1200000 > \$f; done'),
              _CmdLeaf('900 MHz',  Icons.battery_charging_full_rounded, kTeal,   'Ultra hemat — kerja ringan',  cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 900000 > \$f; done'),
              _CmdLeaf('450 MHz',  Icons.battery_saver_rounded,         kBlue,   'Minimum — idle only',         cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 450000 > \$f; done'),
            ]),

          _CmdGroup(icon: Icons.tune_rounded, label: 'CPU Frekuensi Min', accent: kBlue,
            subtitle: 'Batas bawah frekuensi CPU',
            children: [
              _CmdLeaf('450 MHz',  Icons.battery_saver_rounded, kGreen,  'Min standar — hemat idle',     cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo 450000 > \$f; done'),
              _CmdLeaf('700 MHz',  Icons.speed_rounded,         kBlue,   'Min sedang — respon cepat',    cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo 700000 > \$f; done'),
              _CmdLeaf('1000 MHz', Icons.bolt_rounded,          kOrange, 'Min tinggi — selalu responsif',cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo 1000000 > \$f; done'),
            ]),

          _CmdGroup(icon: Icons.memory_rounded, label: 'RAM & Cache', accent: kPurple,
            subtitle: 'Drop cache · Swappiness · Virtual memory',
            children: [
              _CmdLeaf('Clear PageCache',       Icons.cleaning_services_rounded, kGreen,  'Bebaskan cache halaman',        cmd: 'sync; echo 1 > /proc/sys/vm/drop_caches'),
              _CmdLeaf('Clear Dentries+Inodes', Icons.delete_sweep_rounded,      kTeal,   'Bersihkan dentries & inodes',   cmd: 'sync; echo 2 > /proc/sys/vm/drop_caches'),
              _CmdLeaf('Clear All Cache',       Icons.auto_delete_rounded,       kOrange, 'Bersihkan semua cache',         cmd: 'sync; echo 3 > /proc/sys/vm/drop_caches'),
              _CmdLeaf('Swappiness 10',         Icons.swap_horiz_rounded,        kBlue,   'Prioritaskan RAM — minimal swap',cmd: 'echo 10 > /proc/sys/vm/swappiness'),
              _CmdLeaf('Swappiness 60',         Icons.swap_vert_rounded,         kPurple, 'Default Linux — seimbang',      cmd: 'echo 60 > /proc/sys/vm/swappiness'),
              _CmdLeaf('Swappiness 100',        Icons.swap_calls_rounded,        kRed,    'Agresif swap — RAM selalu bebas',cmd: 'echo 100 > /proc/sys/vm/swappiness'),
              _CmdLeaf('vm.dirty_ratio 10',     Icons.save_rounded,              kCyan,   'Buffer tulis lebih kecil',      cmd: 'echo 10 > /proc/sys/vm/dirty_ratio'),
              _CmdLeaf('vm.dirty_ratio 40',     Icons.save_alt_rounded,          kBlue,   'Buffer tulis default',          cmd: 'echo 40 > /proc/sys/vm/dirty_ratio'),
            ]),

          _CmdGroup(icon: Icons.thermostat_rounded, label: 'Thermal', accent: kRed,
            subtitle: 'MT6895 · 47 zone · 13 cooling device',
            children: [
              _CmdLeaf('Baca Suhu Semua Zone',    Icons.thermostat_rounded,   kCyan,  'Tampilkan temp semua zone aktif',          cmd: 'for z in /sys/class/thermal/thermal_zone*/temp; do t=\$(cat \$z 2>/dev/null); [ -n "\$t" ] && echo "\$z: \$t"; done', readOnly: true),
              _CmdLeaf('Baca Cooling Device',     Icons.ac_unit_rounded,      kBlue,  'Lihat semua cooling device & state',       cmd: 'for c in /sys/class/thermal/cooling_device*/cur_state; do echo "\$c: \$(cat \$c 2>/dev/null)"; done', readOnly: true),
              _CmdLeaf('Disable Throttle Zone 0', Icons.warning_rounded,      kRed,   'Matikan throttle zone 0 — pantau suhu!',   cmd: 'echo disabled > /sys/class/thermal/thermal_zone0/mode'),
              _CmdLeaf('Enable Throttle Zone 0',  Icons.check_circle_rounded, kGreen, 'Aktifkan kembali throttle zone 0',         cmd: 'echo enabled > /sys/class/thermal/thermal_zone0/mode'),
              _CmdLeaf('Disable Throttle Zone 1', Icons.warning_amber_rounded,kOrange,'Matikan throttle zone 1',                  cmd: 'echo disabled > /sys/class/thermal/thermal_zone1/mode'),
              _CmdLeaf('Enable Throttle Zone 1',  Icons.check_rounded,        kTeal,  'Aktifkan kembali throttle zone 1',         cmd: 'echo enabled > /sys/class/thermal/thermal_zone1/mode'),
            ]),

          _CmdGroup(icon: Icons.storage_rounded, label: 'I/O Scheduler', accent: kTeal,
            subtitle: 'Optimasi baca/tulis storage',
            children: [
              _CmdLeaf('noop',       Icons.linear_scale_rounded, kGreen,  'Minimal overhead — SSD/eMMC',        cmd: 'for d in /sys/block/*/queue/scheduler; do echo noop > \$d 2>/dev/null; done'),
              _CmdLeaf('deadline',   Icons.timer_rounded,        kOrange, 'Deadline-based — responsif I/O',     cmd: 'for d in /sys/block/*/queue/scheduler; do echo deadline > \$d 2>/dev/null; done'),
              _CmdLeaf('cfq',        Icons.queue_rounded,        kBlue,   'Completely Fair Queuing — default',  cmd: 'for d in /sys/block/*/queue/scheduler; do echo cfq > \$d 2>/dev/null; done'),
              _CmdLeaf('mq-deadline',Icons.alarm_rounded,        kCyan,   'Multi-queue deadline — modern',      cmd: 'for d in /sys/block/*/queue/scheduler; do echo mq-deadline > \$d 2>/dev/null; done'),
              _CmdLeaf('Baca Scheduler', Icons.search_rounded,   kPurple, 'Tampilkan scheduler aktif',          cmd: 'for d in /sys/block/*/queue/scheduler; do echo "\$d: \$(cat \$d 2>/dev/null)"; done', readOnly: true),
            ]),

          _CmdGroup(icon: Icons.wifi_rounded, label: 'Network', accent: kBlue,
            subtitle: 'DNS · TCP · Buffer',
            children: [
              _CmdLeaf('DNS Google',     Icons.dns_rounded,        kBlue,   'Set DNS 8.8.8.8 / 8.8.4.4',           cmd: 'setprop net.dns1 8.8.8.8; setprop net.dns2 8.8.4.4'),
              _CmdLeaf('DNS Cloudflare', Icons.cloud_rounded,      kOrange, 'Set DNS 1.1.1.1 / 1.0.0.1',           cmd: 'setprop net.dns1 1.1.1.1; setprop net.dns2 1.0.0.1'),
              _CmdLeaf('DNS OpenDNS',    Icons.lock_rounded,       kGreen,  'Set DNS 208.67.222.222',               cmd: 'setprop net.dns1 208.67.222.222; setprop net.dns2 208.67.220.220'),
              _CmdLeaf('TCP BBR',        Icons.compress_rounded,   kGreen,  'Aktifkan congestion control BBR',      cmd: 'echo bbr > /proc/sys/net/ipv4/tcp_congestion_control'),
              _CmdLeaf('TCP Cubic',      Icons.show_chart_rounded, kPurple, 'Default Linux cubic',                  cmd: 'echo cubic > /proc/sys/net/ipv4/tcp_congestion_control'),
              _CmdLeaf('TCP Westwood+',  Icons.trending_up_rounded,kTeal,   'Optimal untuk jaringan wireless',      cmd: 'echo westwood > /proc/sys/net/ipv4/tcp_congestion_control'),
              _CmdLeaf('Baca DNS Aktif', Icons.search_rounded,     kCyan,   'Tampilkan DNS yang sedang aktif',      cmd: 'getprop net.dns1; getprop net.dns2', readOnly: true),
              _CmdLeaf('Baca TCP CC',    Icons.info_rounded,       kBlue,   'Tampilkan congestion control aktif',   cmd: 'cat /proc/sys/net/ipv4/tcp_congestion_control', readOnly: true),
            ]),

          _CmdGroup(icon: Icons.settings_rounded, label: 'System Misc', accent: kYellow,
            subtitle: 'Build info · Reboot · Logcat',
            children: [
              _CmdLeaf('Info Build',         Icons.info_rounded,           kCyan,   'Model, platform, Android version',     cmd: 'getprop ro.product.model; getprop ro.board.platform; getprop ro.build.version.release', readOnly: true),
              _CmdLeaf('Cek Root',           Icons.verified_rounded,       kGreen,  'Verifikasi status root saat ini',      cmd: 'id', readOnly: true),
              _CmdLeaf('Clear Logcat',       Icons.delete_rounded,         kOrange, 'Bersihkan buffer logcat',              cmd: 'logcat -c'),
              _CmdLeaf('Reboot System',      Icons.restart_alt_rounded,    kRed,    'Reboot perangkat sekarang',            cmd: 'reboot'),
              _CmdLeaf('Reboot Recovery',    Icons.build_circle_rounded,   kPurple, 'Reboot ke recovery mode',             cmd: 'reboot recovery'),
              _CmdLeaf('Reboot Bootloader',  Icons.developer_mode_rounded, kBlue,   'Reboot ke fastboot/bootloader',        cmd: 'reboot bootloader'),
            ]),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// CMD GROUP
class _CmdGroup extends StatefulWidget {
  final IconData icon;
  final String label, subtitle;
  final Color accent;
  final List<_CmdLeaf> children;
  const _CmdGroup({required this.icon, required this.label, required this.subtitle, required this.accent, required this.children});
  @override
  State<_CmdGroup> createState() => _CmdGroupState();
}

class _CmdGroupState extends State<_CmdGroup> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _c;
  late Animation<double> _exp, _rot;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _exp = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _rot = Tween(begin: 0.0, end: 0.5).animate(_exp);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder<bool>(
        valueListenable: isNightNotifier,
        builder: (_, __, ___) => Container(
          decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _open ? widget.accent.withOpacity(.4) : kBorder),
            boxShadow: _open ? [BoxShadow(color: widget.accent.withOpacity(.07), blurRadius: 20)] : []),
          child: Column(children: [
            GestureDetector(
              onTap: () { setState(() => _open = !_open); _open ? _c.forward() : _c.reverse(); HapticFeedback.selectionClick(); },
              behavior: HitTestBehavior.opaque,
              child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: widget.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accent.withOpacity(.2))),
                  child: Icon(widget.icon, color: widget.accent, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.label, style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: TextStyle(color: mut(.35), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: widget.accent.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${widget.children.length}', style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w800))),
                const SizedBox(width: 6),
                RotationTransition(turns: _rot, child: Icon(Icons.keyboard_arrow_down_rounded, color: mut(.35), size: 20)),
              ])),
            ),
            SizeTransition(sizeFactor: _exp, child: Column(children: [
              Divider(height: 1, color: kBorder),
              Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(children: widget.children)),
            ])),
          ]),
        ),
      ),
    );
  }
}

// CMD LEAF
class _CmdLeaf extends StatefulWidget {
  final String label, desc, cmd;
  final IconData icon;
  final Color color;
  final bool readOnly;
  const _CmdLeaf(this.label, this.icon, this.color, this.desc, {required this.cmd, this.readOnly = false});
  @override
  State<_CmdLeaf> createState() => _CmdLeafState();
}

class _CmdLeafState extends State<_CmdLeaf> {
  bool _running = false, _active = false;

  Future<void> _exec() async {
    if (_running) return;
    if (!isRootNotifier.value) {
      _snack('⚠ Butuh root untuk perintah ini', kYellow); return;
    }
    setState(() { _running = true; });
    HapticFeedback.mediumImpact();
    final out = await runRoot(widget.cmd);
    if (mounted) {
      setState(() { _running = false; if (!widget.readOnly) _active = !_active; });
      if (out.isNotEmpty && out != 'OK' && out.length > 5) {
        _showSheet(out);
      } else {
        _snack(widget.readOnly ? '📋 Selesai' : (_active ? '✓ ${widget.label}' : '○ ${widget.label} off'), widget.color);
      }
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: kPanel2, duration: const Duration(milliseconds: 2000),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  void _showSheet(String result) {
    showModalBottomSheet(context: context, backgroundColor: kPanel, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: .5, maxChildSize: .9,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
            decoration: BoxDecoration(color: mut(.2), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20,14,20,0),
            child: Row(children: [
              Icon(widget.icon, color: widget.color, size: 18),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: mut(.4), size: 20)),
            ])),
          Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.all(20),
            child: SelectableText(result, style: TextStyle(color: kCyan, fontSize: 11.5, fontFamily: 'monospace', height: 1.6)))),
          Padding(padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: widget.color.withOpacity(.15),
                  foregroundColor: widget.color, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Tutup')))),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isRootNotifier,
      builder: (_, root, __) {
        final locked = !root && !widget.readOnly;
        return Padding(padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: locked ? () => _snack('⚠ Butuh root', kYellow) : _exec,
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _active ? widget.color.withOpacity(.1) : locked ? mut(.03) : kPanel2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _active ? widget.color.withOpacity(.35) : kBorder.withOpacity(.4))),
              child: Row(children: [
                Container(width: 2.5, height: 36,
                  decoration: BoxDecoration(color: locked ? mut(.15) : widget.color.withOpacity(_active ? .9 : .35), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Icon(locked ? Icons.lock_rounded : widget.icon, color: locked ? mut(.3) : widget.color, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.label, style: TextStyle(color: locked ? mut(.4) : (_active ? widget.color : kWhite),
                      fontSize: 12.5, fontWeight: _active ? FontWeight.w700 : FontWeight.w500)),
                  Text(widget.desc, style: TextStyle(color: mut(.3), fontSize: 10.5)),
                ])),
                const SizedBox(width: 8),
                if (_running)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.color))
                else if (widget.readOnly)
                  Icon(Icons.chevron_right_rounded, color: mut(.3), size: 18)
                else
                  _Switch(on: _active, color: locked ? mut(.2) : widget.color),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Switch extends StatelessWidget {
  final bool on; final Color color;
  const _Switch({required this.on, required this.color});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200), width: 38, height: 22,
    decoration: BoxDecoration(color: on ? color.withOpacity(.25) : mut(.06),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: on ? color.withOpacity(.6) : mut(.15))),
    child: AnimatedAlign(duration: const Duration(milliseconds: 200),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(margin: const EdgeInsets.all(3), width: 16, height: 16,
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? color : mut(.25)))));
}

// TOOLS TAB
class ToolsTab extends StatefulWidget {
  const ToolsTab({super.key});
  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  Future<void> _run(String cmd, {bool needRoot = false}) async {
    if (needRoot && !isRootNotifier.value) {
      _sheet('Butuh Root', 'Fitur ini memerlukan akses root aktif.', kYellow); return;
    }
    String out;
    if (needRoot) {
      out = await runRoot(cmd);
    } else {
      try { final r = await Process.run('sh', ['-c', cmd]); out = r.stdout.toString().trim(); if (out.isEmpty) out = r.stderr.toString().trim(); }
      catch (e) { out = 'Error: $e'; }
    }
    _sheet(cmd.split(';')[0].split('|')[0].trim(), out.isEmpty ? 'Tidak ada output' : out, kCyan);
  }

  void _sheet(String title, String content, Color color) {
    showModalBottomSheet(context: context, backgroundColor: kPanel, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: .5, maxChildSize: .9,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
            decoration: BoxDecoration(color: mut(.2), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20,14,20,0),
            child: Row(children: [
              Text(title, style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, color: mut(.4), size: 20)),
            ])),
          Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.all(20),
            child: SelectableText(content, style: TextStyle(color: color, fontSize: 11.5, fontFamily: 'monospace', height: 1.6)))),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Tools', 'System Utilities', kOrange),
          const SizedBox(height: 18),

          _sectionLabel('INFO (TANPA ROOT)', kCyan),
          const SizedBox(height: 10),
          _tool('CPU Info', 'Model, core, frekuensi, BogoMIPS', Icons.developer_board_rounded, kCyan, false,
              'cat /proc/cpuinfo | grep -E "model name|processor|cpu MHz|BogoMIPS|Hardware" | head -20'),
          _tool('Memory Detail', 'MemTotal, MemFree, Cached, Swap', Icons.memory_rounded, kPurple, false, 'cat /proc/meminfo'),
          _tool('Battery Detail', 'Status, kapasitas, suhu', Icons.battery_full_rounded, kGreen, false,
              'cat /sys/class/power_supply/battery/uevent 2>/dev/null || cat /sys/class/power_supply/*/uevent 2>/dev/null'),
          _tool('Suhu Thermal', 'Semua zone thermal MT6895', Icons.thermostat_rounded, kRed, false,
              'for i in \$(seq 0 20); do t=\$(cat /sys/class/thermal/thermal_zone\$i/temp 2>/dev/null); [ -n "\$t" ] && echo "Zone\$i: \$t"; done'),
          _tool('Uptime & Load', 'Uptime dan load average sistem', Icons.timer_rounded, kTeal, false,
              'uptime; echo "---"; cat /proc/loadavg; echo "---"; cat /proc/uptime'),
          _tool('Disk Usage', 'Partisi dan penggunaan storage', Icons.storage_rounded, kOrange, false, 'df -h'),
          _tool('Network Info', 'IP, interface, DNS aktif', Icons.wifi_rounded, kBlue, false,
              'ip addr show 2>/dev/null; echo "---"; getprop net.dns1; getprop net.dns2'),
          _tool('Android Props', 'Build, model, versi OS', Icons.android_rounded, kGreen, false,
              'getprop ro.product.model; getprop ro.board.platform; getprop ro.build.version.release; getprop ro.product.manufacturer'),

          const SizedBox(height: 18),
          _sectionLabel('ROOT TOOLS', kRed),
          const SizedBox(height: 10),
          _tool('Kernel Log', 'dmesg 30 baris terakhir', Icons.article_rounded, kRed, true, 'dmesg | tail -30'),
          _tool('Proses Berjalan', 'Snapshot proses aktif', Icons.list_alt_rounded, kOrange, true, 'ps aux | head -25'),
          _tool('Governor Semua Core', 'Governor aktif tiap core CPU', Icons.tune_rounded, kCyan, true,
              'for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "\$c: \$(cat \$c 2>/dev/null)"; done'),
          _tool('Frekuensi Semua Core', 'Frekuensi aktif tiap core CPU', Icons.speed_rounded, kBlue, true,
              'for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do echo "\$c: \$(cat \$c 2>/dev/null)"; done'),
          _tool('Modules Kernel', 'List modul kernel yang terload', Icons.extension_rounded, kTeal, true, 'lsmod | head -25'),
          _tool('Swappiness Saat Ini', 'Baca nilai swappiness aktif', Icons.swap_horiz_rounded, kPurple, true, 'cat /proc/sys/vm/swappiness'),
          _tool('TCP Congestion Aktif', 'Algoritma TCP congestion aktif', Icons.compress_rounded, kGreen, true,
              'cat /proc/sys/net/ipv4/tcp_congestion_control'),
          _tool('I/O Scheduler Aktif', 'Scheduler storage tiap block device', Icons.storage_rounded, kOrange, true,
              'for d in /sys/block/*/queue/scheduler; do echo "\$d:"; cat \$d 2>/dev/null; echo; done'),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _tool(String title, String sub, IconData icon, Color color, bool needRoot, String cmd) {
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: ValueListenableBuilder<bool>(
        valueListenable: isRootNotifier,
        builder: (_, root, __) {
          final locked = needRoot && !root;
          return GestureDetector(
            onTap: () => _run(cmd, needRoot: needRoot),
            child: Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: locked ? kBorder.withOpacity(.4) : kBorder)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: locked ? mut(.05) : color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(locked ? Icons.lock_rounded : icon, color: locked ? mut(.3) : color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: locked ? mut(.4) : kWhite, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: mut(.35), fontSize: 11)),
                ])),
                Icon(Icons.play_circle_rounded, color: locked ? mut(.2) : color.withOpacity(.7), size: 24),
              ])),
          );
        }));
  }
}

// AVATAR
class _AvatarPainter extends CustomPainter {
  final double pulse, orbit;
  _AvatarPainter(this.pulse, this.orbit);
  double _c(double a) => 1 - a*a/2 + a*a*a*a/24;
  double _s(double a) => a - a*a*a/6 + a*a*a*a*a/120;

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width/2, cy = s.height/2, r = s.width/2;
    canvas.drawCircle(Offset(cx,cy), r, Paint()..shader =
      RadialGradient(colors: [const Color(0xFF1A1A40), const Color(0xFF060612)])
        .createShader(Rect.fromCircle(center: Offset(cx,cy), radius: r)));
    for (int i = 0; i < 8; i++) {
      final a = (i/8 + orbit) * 6.28318;
      canvas.drawCircle(Offset(cx + r*.82*_c(a), cy + r*.82*_s(a)), i%2==0 ? 2.5 : 1.5,
        Paint()..color = kCyan.withOpacity(i%2==0 ? .5+.3*pulse : .2));
    }
    canvas.drawCircle(Offset(cx,cy), r*(.78+.04*pulse),
      Paint()..style=PaintingStyle.stroke..color=kCyan.withOpacity(.15+.1*pulse)..strokeWidth=1.2);
    final body = Path()
      ..moveTo(cx-r*.3,cy+r*.2)..lineTo(cx+r*.3,cy+r*.2)
      ..lineTo(cx+r*.42,cy+r*.75)..lineTo(cx-r*.42,cy+r*.75)..close();
    canvas.drawPath(body, Paint()..shader =
      LinearGradient(colors:[const Color(0xFF1E1E50),kCyan.withOpacity(.2)],
        begin:Alignment.topCenter,end:Alignment.bottomCenter)
      .createShader(Rect.fromLTWH(cx-r*.42,cy+r*.2,r*.84,r*.55)));
    canvas.drawPath(Path()..moveTo(cx-r*.1,cy+r*.2)..lineTo(cx,cy+r*.35)..lineTo(cx+r*.1,cy+r*.2),
      Paint()..style=PaintingStyle.stroke..color=kCyan.withOpacity(.5)..strokeWidth=1.5..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(cx,cy-r*.18),r*.28, Paint()..shader =
      RadialGradient(colors:[const Color(0xFF252560),const Color(0xFF0F0F30)])
        .createShader(Rect.fromCircle(center:Offset(cx-r*.05,cy-r*.28),radius:r*.28)));
    canvas.drawCircle(Offset(cx,cy-r*.18),r*.28,
      Paint()..style=PaintingStyle.stroke..color=kCyan.withOpacity(.3)..strokeWidth=1.2);
    final hair = Path()
      ..addArc(Rect.fromCircle(center:Offset(cx,cy-r*.18),radius:r*.28),3.14159+.25,2.63)
      ..lineTo(cx,cy-r*.18)..close();
    canvas.drawPath(hair, Paint()..color=const Color(0xFF5030D0));
    canvas.drawArc(Rect.fromCircle(center:Offset(cx-r*.07,cy-r*.38),radius:r*.08),3.8,1.4,false,
      Paint()..style=PaintingStyle.stroke..color=kPurple.withOpacity(.5)..strokeWidth=2);
    for (final dx in [-r*.1, r*.1]) {
      canvas.drawCircle(Offset(cx+dx,cy-r*.2),3.5,
        Paint()..color=kCyan..maskFilter=const MaskFilter.blur(BlurStyle.normal,2));
      canvas.drawCircle(Offset(cx+dx,cy-r*.2),1.5,Paint()..color=Colors.white);
    }
    canvas.drawArc(Rect.fromCenter(center:Offset(cx,cy-r*.08),width:r*.22,height:r*.13),
      .3,2.5,false,
      Paint()..style=PaintingStyle.stroke..color=kCyan.withOpacity(.6)..strokeWidth=1.8..strokeCap=StrokeCap.round);
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(center:Offset(cx,cy+r*.4),width:r*.5,height:r*.17),const Radius.circular(4));
    canvas.drawRRect(badge,Paint()..color=kCyan.withOpacity(.12));
    canvas.drawRRect(badge,Paint()..style=PaintingStyle.stroke..color=kCyan.withOpacity(.45)..strokeWidth=1);
  }
  @override
  bool shouldRepaint(_AvatarPainter o) => o.pulse != pulse || o.orbit != orbit;
}

class _AnimatedAvatar extends StatefulWidget {
  const _AnimatedAvatar();
  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar> with TickerProviderStateMixin {
  late AnimationController _p, _o;
  @override
  void initState() {
    super.initState();
    _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _o = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() { _p.dispose(); _o.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_p, _o]),
    builder: (_, __) => CustomPaint(size: const Size(130,130), painter: _AvatarPainter(_p.value, _o.value)));
}

// ABOUT TAB
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightNotifier,
      builder: (_, __, ___) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader('Tentang', 'About This App', kGreen),
          const SizedBox(height: 20),
          Container(width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors:[kCyan.withOpacity(.08),kPurple.withOpacity(.06)],
                begin:Alignment.topLeft, end:Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kCyan.withOpacity(.2))),
            child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                const _AnimatedAvatar(),
                Container(width:22,height:22,
                  decoration:BoxDecoration(color:kGreen,shape:BoxShape.circle,border:Border.all(color:kPanel,width:2.5)),
                  child:const Icon(Icons.check_rounded,color:Colors.white,size:12)),
              ]),
              const SizedBox(height: 14),
              Text('Sahrul', style: TextStyle(color:kWhite,fontSize:24,fontWeight:FontWeight.w900,letterSpacing:-.5)),
              const SizedBox(height: 4),
              Text('Android Developer & Enthusiast', style: TextStyle(color:mut(.4),fontSize:13)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _chip('KernelSU', Icons.security_rounded, kGreen),
                const SizedBox(width: 8),
                _chip('MT6895', Icons.developer_board_rounded, kCyan),
                const SizedBox(width: 8),
                _chip('v2.0', Icons.rocket_launch_rounded, kPurple),
              ]),
            ])),
          const SizedBox(height: 20),
          _sectionLabel('SPESIFIKASI', kCyan),
          const SizedBox(height: 10),
          _info('Perangkat', 'Infinix GT 20 Pro', Icons.phone_android_rounded, kCyan),
          _info('Chipset', 'Dimensity 8200 (MT6895)', Icons.developer_board_rounded, kPurple),
          _info('RAM', '8 GB LPDDR5', Icons.memory_rounded, kBlue),
          _info('Root', 'KernelSU Active', Icons.verified_rounded, kGreen),
          _info('OS', 'Android + Ubuntu proot', Icons.android_rounded, kTeal),
          const SizedBox(height: 20),
          _sectionLabel('FITUR', kPurple),
          const SizedBox(height: 10),
          _feat(Icons.account_tree_rounded, kPurple, 'Nested Command Menu', 'Kontrol berlapis — governor, frekuensi, cache, thermal, network, I/O.'),
          _feat(Icons.terminal_rounded, kCyan, 'Eksekusi Root Real', 'Semua perintah dijalankan langsung via su -c ke kernel MT6895.'),
          _feat(Icons.dashboard_rounded, kBlue, 'Live Dashboard', 'CPU freq, governor, suhu, RAM, baterai — refresh tiap 3 detik.'),
          _feat(Icons.lock_rounded, kYellow, 'Non-Root Compatible', 'Mode aman tanpa root — info tetap tampil, kontrol dikunci.'),
          _feat(Icons.dark_mode_rounded, kOrange, 'Night / Light Mode', 'Ganti tema kapan saja dengan satu ketukan.'),
          const SizedBox(height: 24),
          Center(child: Text('Dibuat dengan ❤️ oleh Sahrul', style: TextStyle(color:mut(.3),fontSize:12))),
          const SizedBox(height: 6),
          Center(child: Text('Command Center © 2026', style: TextStyle(color:mut(.2),fontSize:11))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _chip(String l, IconData i, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10,vertical:6),
    decoration: BoxDecoration(color:c.withOpacity(.1),borderRadius:BorderRadius.circular(10),border:Border.all(color:c.withOpacity(.3))),
    child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:c,size:13),const SizedBox(width:5),Text(l,style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.w700))]));

  Widget _info(String label, String value, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom:8),
    child: Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
      decoration:BoxDecoration(color:kPanel,borderRadius:BorderRadius.circular(14),border:Border.all(color:kBorder)),
      child:Row(children:[Icon(icon,color:color,size:17),const SizedBox(width:10),
        Text(label,style:TextStyle(color:mut(.4),fontSize:12)),const Spacer(),
        Text(value,style:TextStyle(color:kWhite,fontSize:12,fontWeight:FontWeight.w600))])));

  Widget _feat(IconData ic, Color c, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom:8),
    child: Container(padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:kPanel,borderRadius:BorderRadius.circular(16),border:Border.all(color:kBorder)),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:c.withOpacity(.1),borderRadius:BorderRadius.circular(11)),child:Icon(ic,color:c,size:19)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:TextStyle(color:kWhite,fontSize:13,fontWeight:FontWeight.w700)),
          const SizedBox(height:3),
          Text(body,style:TextStyle(color:mut(.4),fontSize:11.5,height:1.4)),
        ])),
      ])));
}

// SHARED
Widget _pageHeader(String title, String subtitle, Color accent) {
  return ValueListenableBuilder<bool>(
    valueListenable: isNightNotifier,
    builder: (_, night, __) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _AppIcon(size: 36),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: kWhite, letterSpacing: -.5)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: mut(.35))),
      ])),
      GestureDetector(
        onTap: () => isNightNotifier.value = !isNightNotifier.value,
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: (night ? kPurple : kYellow).withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (night ? kPurple : kYellow).withOpacity(.35))),
          child: Icon(night ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18, color: night ? kPurple : kYellow))),
    ]),
  );
}

Widget _sectionLabel(String text, Color accent) => Padding(
  padding: const EdgeInsets.only(bottom: 2),
  child: Row(children: [
    Container(width: 3, height: 12, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
  ]));
