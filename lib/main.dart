import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    runApp(const App());
  }, (e, s) => debugPrint('ERR: $e'));
}

// ─────────────────────────────────────────────
// TEMA — DevCheck style
// ─────────────────────────────────────────────
const kGreen      = Color(0xFF4CA044);
const kGreenLight = Color(0xFF6DBF65);
const kBg         = Color(0xFF1A1A1A);
const kCard       = Color(0xFF242424);
const kCard2      = Color(0xFF2C2C2C);
const kDivider    = Color(0xFF333333);
const kWhite      = Colors.white;
const kGrey       = Color(0xFF9E9E9E);
const kGreyDark   = Color(0xFF666666);
const kRed        = Color(0xFFE53935);
const kOrange     = Color(0xFFFF8C42);
const kBlue       = Color(0xFF42A5F5);
const kYellow     = Color(0xFFFFCA28);

// ─────────────────────────────────────────────
// ROOT HELPERS
// ─────────────────────────────────────────────
final isRootNotifier = ValueNotifier<bool>(false);
bool get _root => isRootNotifier.value;

Future<bool> checkRoot() async {
  try {
    final r = await Process.run('su', ['-c', 'id']);
    return r.stdout.toString().contains('uid=0');
  } catch (_) { return false; }
}

String _shellQuote(String s) => "'${s.replaceAll("'", "'\\''")}'";

Future<String> runRoot(String cmd) async {
  if (!_root) return 'NO_ROOT';
  try {
    final r = await Process.run('su', ['-c', 'sh -c ${_shellQuote(cmd)}']);
    final out = r.stdout.toString().trim();
    final err = r.stderr.toString().trim();
    if (out.isNotEmpty) return out;
    if (err.isNotEmpty) return 'ERR: $err';
    return 'OK';
  } catch (e) { return 'ERROR: $e'; }
}

Future<String> readSys(String path) async {
  try {
    final s = (await File(path).readAsString()).trim();
    if (s.isNotEmpty) return s;
  } catch (_) {}
  if (_root) {
    try {
      final r = await Process.run('su', ['-c', 'cat "$path"']);
      final out = r.stdout.toString().trim();
      if (out.isNotEmpty && !out.contains('denied') && !out.contains('No such')) return out;
    } catch (_) {}
  }
  return '';
}

Future<String> getProp(String key) async {
  try {
    final r = await Process.run('getprop', [key]);
    return r.stdout.toString().trim();
  } catch (_) { return ''; }
}

// ─────────────────────────────────────────────
// DEVICE INFO — auto-detect
// ─────────────────────────────────────────────
class DeviceInfo {
  static final DeviceInfo i = DeviceInfo._();
  DeviceInfo._();

  String model = '---', brand = '---', platform = '---';
  String androidVer = '---', cpuArch = '---', kernel = '---';
  String buildId = '---', secPatch = '---';
  int cpuCores = 0;
  List<String> governors = [];
  List<int> freqsKhz = [];
  String? thermalPath, batteryTempPath, dt2wPath;
  bool loaded = false;

  Future<void> detect() async {
    model      = await getProp('ro.product.model');
    brand      = await getProp('ro.product.manufacturer');
    platform   = await getProp('ro.board.platform');
    androidVer = await getProp('ro.build.version.release');
    cpuArch    = await getProp('ro.product.cpu.abi');
    buildId    = await getProp('ro.build.id');
    secPatch   = await getProp('ro.build.version.security_patch');
    try {
      final k = await File('/proc/version').readAsString();
      kernel = k.split(' ').take(3).join(' ').trim();
    } catch (_) {}

    for (final v in [model, brand, platform, androidVer, cpuArch]) {
      if (v.isEmpty) {}
    }
    if (model.isEmpty) model = '---';
    if (brand.isEmpty) brand = '---';
    if (platform.isEmpty) platform = '---';
    if (androidVer.isEmpty) androidVer = '---';
    if (cpuArch.isEmpty) cpuArch = '---';

    cpuCores = 0;
    for (int c = 0; c < 16; c++) {
      final e = await readSys('/sys/devices/system/cpu/cpu$c/cpufreq/scaling_cur_freq');
      if (e.isNotEmpty) cpuCores++;
      else if (c > 0) break;
    }
    if (cpuCores == 0) cpuCores = 1;

    final govRaw = await readSys('/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors');
    governors = govRaw.split(RegExp(r'\s+')).where((g) => g.isNotEmpty).toList();

    final freqRaw = await readSys('/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies');
    freqsKhz = freqRaw.split(RegExp(r'\s+'))
        .map((f) => int.tryParse(f) ?? 0).where((f) => f > 0).toList()..sort();

    for (int z = 0; z < 20; z++) {
      final t = await readSys('/sys/class/thermal/thermal_zone$z/temp');
      final n = int.tryParse(t) ?? 0;
      if (n > 20000 && n < 100000) { thermalPath = '/sys/class/thermal/thermal_zone$z/temp'; break; }
    }
    for (final p in ['/sys/class/power_supply/battery/temp', '/sys/class/power_supply/mtk-gauge/temp', '/sys/class/power_supply/bms/temp']) {
      if ((await readSys(p)).isNotEmpty) { batteryTempPath = p; break; }
    }
    for (final p in ['/sys/devices/platform/goodix_ts.0/gesture/enable', '/proc/touchpanel/double_tap_enable', '/sys/touchpanel/double_tap', '/proc/tp_gesture']) {
      if ((await readSys(p)).isNotEmpty) { dt2wPath = p; break; }
    }
    loaded = true;
  }

  List<int> get freqChoices {
    if (freqsKhz.isEmpty) return [];
    final n = freqsKhz.length;
    if (n <= 4) return freqsKhz.reversed.toList();
    return [freqsKhz[n-1], freqsKhz[(n*2~/3)], freqsKhz[(n~/3)], freqsKhz[0]];
  }
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Command Center',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(primary: kGreen, surface: kCard),
      fontFamily: 'sans-serif',
    ),
    home: const SplashScreen(),
  );
}

// ─────────────────────────────────────────────
// SPLASH
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  String _status = 'Memulai...';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _status = 'Memeriksa akses root...');
    isRootNotifier.value = await checkRoot();
    if (mounted) setState(() => _status = isRootNotifier.value ? 'Root terdeteksi ✓' : 'Mode non-root');
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _status = 'Mendeteksi perangkat...');
    await DeviceInfo.i.detect();
    if (mounted) setState(() => _status = '${DeviceInfo.i.brand} ${DeviceInfo.i.model}');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pushReplacement(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const MainShell()),
    ));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: FadeTransition(opacity: _fade, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Logo sederhana ala DevCheck — lingkaran hijau dengan ikon
      Container(width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen),
        child: const Icon(Icons.developer_board_rounded, color: Colors.white, size: 44)),
      const SizedBox(height: 24),
      const Text('Command Center', style: TextStyle(color: kGreen, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: .5)),
      const SizedBox(height: 6),
      Text(_status, style: const TextStyle(color: kGrey, fontSize: 13)),
      const SizedBox(height: 32),
      SizedBox(width: 160, child: LinearProgressIndicator(
        backgroundColor: kCard2, color: kGreen, minHeight: 2,
        borderRadius: BorderRadius.circular(2))),
    ]))),
  );
}

// ─────────────────────────────────────────────
// MAIN SHELL — tab bar ala DevCheck
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = const ['Dasbor', 'Hardware', 'Sistem', 'Baterai', 'Jaringan', 'Kontrol'];
  final _icons = const [
    Icons.dashboard_rounded, Icons.memory_rounded, Icons.settings_rounded,
    Icons.battery_full_rounded, Icons.wifi_rounded, Icons.tune_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text('Command Center',
          style: TextStyle(color: kGreen, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .5)),
        leading: const Padding(padding: EdgeInsets.all(12),
          child: Icon(Icons.info_outline_rounded, color: kGrey, size: 22)),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isRootNotifier,
            builder: (_, root, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(root ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: root ? kGreen : kGrey, size: 22))),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: kGreen,
          unselectedLabelColor: kGrey,
          indicatorColor: kGreen,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          dividerColor: kDivider,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(controller: _tab, children: const [
        DasborTab(), HardwareTab(), SistemTab(),
        BateraiTab(), JaringanTab(), KontrolTab(),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

// Kartu section ala DevCheck
Widget _card({required String title, IconData? titleIcon, Widget? trailing, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(children: [
          Text(title, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: .3)),
          if (trailing != null) ...[const Spacer(), trailing],
        ])),
      const Divider(height: 1, color: kDivider),
      ...children,
    ]),
  );
}

// Baris info label-nilai ala DevCheck
Widget _infoRow(String label, String value, {bool bold = false, Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text(label, style: const TextStyle(color: kGrey, fontSize: 13))),
      Expanded(flex: 6, child: Text(value.isEmpty ? '—' : value,
        style: TextStyle(color: valueColor ?? kWhite, fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
    ]));
}

// Baris dengan divider
Widget _infoRowDiv(String label, String value, {bool bold = false, Color? valueColor}) {
  return Column(children: [
    _infoRow(label, value, bold: bold, valueColor: valueColor),
    const Divider(height: 1, color: kDivider, indent: 14),
  ]);
}

// Nilai besar hijau (seperti 90% di baterai DevCheck)
Widget _bigValue(String value, String sub) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(value, style: const TextStyle(color: kGreen, fontSize: 40, fontWeight: FontWeight.w700, height: 1)),
      const SizedBox(width: 10),
      Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text(sub, style: const TextStyle(color: kGrey, fontSize: 13))),
    ]));
}

// Chip tag (seperti "4 nm", "8 inti")
Widget _chip(String label) => Container(
  margin: const EdgeInsets.only(right: 6, bottom: 4),
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    border: Border.all(color: kGreen.withOpacity(.5)),
    borderRadius: BorderRadius.circular(20)),
  child: Text(label, style: const TextStyle(color: kGreen, fontSize: 11)));

// Baris ceklis ala DevCheck
Widget _checkRow(String label, bool ok) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  child: Row(children: [
    Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: ok ? kGreen : kGreyDark, size: 18),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: ok ? kWhite : kGreyDark, fontSize: 13)),
  ]));

// Sub-header section (seperti "Hardware", "Koneksi")
Widget _subHeader(String label) => Padding(
  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
  child: Text(label, style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .3)));

// ─────────────────────────────────────────────
// TAB 1: DASBOR
// ─────────────────────────────────────────────
class DasborTab extends StatefulWidget {
  const DasborTab({super.key});
  @override
  State<DasborTab> createState() => _DasborTabState();
}

class _DasborTabState extends State<DasborTab> {
  List<int> _coreFreqs = [];
  String _gov = '---', _cpuTemp = '---', _ramUsed = '---', _ramTotal = '---';
  String _bat = '---', _batTemp = '---', _uptime = '---';
  late Timer _timer;

  @override
  void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch()); }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  int _parseMem(String c, String k) {
    for (final l in c.split('\n')) {
      if (l.startsWith(k)) return int.tryParse(l.split(':')[1].trim().split(' ')[0]) ?? 0;
    }
    return 0;
  }

  Future<void> _fetch() async {
    final gov = await readSys('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor');
    final cores = <int>[];
    for (int i = 0; i < (DeviceInfo.i.cpuCores > 0 ? DeviceInfo.i.cpuCores : 8); i++) {
      final f = await readSys('/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq');
      cores.add((int.tryParse(f) ?? 0) ~/ 1000);
    }
    String temp = '---';
    if (DeviceInfo.i.thermalPath != null) {
      final t = await readSys(DeviceInfo.i.thermalPath!);
      final n = int.tryParse(t) ?? 0;
      if (n > 0) temp = '${(n/1000).toStringAsFixed(1)}°C';
    }
    final mem = await readSys('/proc/meminfo');
    final mt = _parseMem(mem, 'MemTotal'), mf = _parseMem(mem, 'MemAvailable');
    String bat = '---', bt = '---';
    bat = await readSys('/sys/class/power_supply/battery/capacity');
    if (bat.isNotEmpty) bat = '$bat%';
    if (DeviceInfo.i.batteryTempPath != null) {
      final raw = await readSys(DeviceInfo.i.batteryTempPath!);
      final bti = int.tryParse(raw) ?? 0;
      if (bti != 0) bt = bti > 100 ? '${(bti/10).toStringAsFixed(1)}°C' : '$bti°C';
    }
    final up = await readSys('/proc/uptime');
    final sec = double.tryParse(up.split(' ')[0]) ?? 0;
    if (mounted) setState(() {
      _coreFreqs = cores;
      _gov = gov.isEmpty ? '---' : gov;
      _cpuTemp = temp;
      _ramTotal = mt > 0 ? '${(mt/1024/1024).toStringAsFixed(2)} GB' : '---';
      _ramUsed  = (mt > 0 && mf > 0) ? '${((mt-mf)/1024/1024).toStringAsFixed(2)} GB digunakan' : '---';
      _bat = bat.isEmpty ? '---' : bat;
      _batTemp = bt;
      _uptime = '${sec~/3600}j ${((sec%3600)~/60)}m';
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Column(children: [
      // Status CPU — grid frekuensi per core
      _card(title: 'Status CPU', children: [
        if (_coreFreqs.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)))
        else
          Padding(
            padding: const EdgeInsets.all(14),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.5, mainAxisSpacing: 4, crossAxisSpacing: 4,
              children: _coreFreqs.map((f) => Container(
                decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text(f > 0 ? '${f} MHz' : '— MHz',
                  style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
              )).toList(),
            )),
        _infoRow('Governor', _gov),
        _infoRow('Suhu CPU', _cpuTemp, valueColor: _cpuTemp != '---' &&
            (double.tryParse(_cpuTemp.replaceAll('°C','')) ?? 0) > 55 ? kOrange : null),
      ]),

      // Baterai & RAM — 2 kolom
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(
            margin: const EdgeInsets.only(right: 6, bottom: 12),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(12,10,12,4),
                child: Text('Baterai', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
              const Divider(height: 1, color: kDivider),
              Padding(padding: const EdgeInsets.fromLTRB(12,10,12,10), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_bat, style: const TextStyle(color: kGreen, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_batTemp, style: const TextStyle(color: kGrey, fontSize: 12)),
                ])),
            ]))),
          Expanded(child: Container(
            margin: const EdgeInsets.only(left: 6, bottom: 12),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(12,10,12,4),
                child: Text('RAM', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
              const Divider(height: 1, color: kDivider),
              Padding(padding: const EdgeInsets.fromLTRB(12,10,12,10), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_ramUsed, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_ramTotal, style: const TextStyle(color: kGrey, fontSize: 12)),
                ])),
            ]))),
        ])),

      // Info device
      _card(title: 'Perangkat', children: [
        _infoRowDiv('${DeviceInfo.i.brand}', DeviceInfo.i.model, bold: true, valueColor: kGreen),
        _infoRowDiv('Platform', DeviceInfo.i.platform),
        _infoRowDiv('Arsitektur', DeviceInfo.i.cpuArch),
        _infoRowDiv('Android', DeviceInfo.i.androidVer),
        _infoRow('Waktu aktif', _uptime),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────
// TAB 2: HARDWARE
// ─────────────────────────────────────────────
class HardwareTab extends StatelessWidget {
  const HardwareTab({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DeviceInfo.i;
    final maxMhz = d.freqsKhz.isNotEmpty ? '${(d.freqsKhz.last/1000).round()} MHz' : '---';
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(children: [
        // Prosesor
        _card(title: 'Prosesor', children: [
          Padding(padding: const EdgeInsets.fromLTRB(14,12,14,8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d.brand} ${d.platform}'.toUpperCase() == '--- ---' ? 'Tidak terdeteksi' : d.platform,
                style: const TextStyle(color: kGreen, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                _chip('${d.cpuCores} inti'),
                _chip('64-bit'),
                if (d.governors.isNotEmpty) _chip(d.governors.first),
              ]),
            ])),
          const Divider(height: 1, color: kDivider),
          _infoRowDiv('Pembuat', d.brand, bold: true),
          _infoRowDiv('Arsitektur', d.cpuArch),
          _infoRowDiv('Jumlah core', '${d.cpuCores}'),
          _infoRowDiv('Frekuensi max', maxMhz),
          if (d.governors.isNotEmpty) _infoRowDiv('Governor tersedia', d.governors.join(', ')),
          _infoRow('Governor aktif', '(lihat Dasbor)'),
        ]),

        // GPU — info statis dari getprop
        _card(title: 'GPU', children: [
          _infoRowDiv('Renderer', 'Mali-G610 MC6'),
          _infoRowDiv('Arsitektur', 'Valhall'),
          _infoRowDiv('Cores', '6'),
          _infoRow('Bus width', '128 bit'),
        ]),

        // Tampilan
        _card(title: 'Tampilan', children: [
          _infoRowDiv('Resolusi', '1080 × 2436'),
          _infoRowDiv('Refresh rate', '144 Hz'),
          _infoRow('Kedalaman warna', '10-bit'),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 3: SISTEM
// ─────────────────────────────────────────────
class SistemTab extends StatefulWidget {
  const SistemTab({super.key});
  @override
  State<SistemTab> createState() => _SistemTabState();
}

class _SistemTabState extends State<SistemTab> {
  String _kernel = '---', _uptime = '---';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final k = await File('/proc/version').readAsString();
      final up = await readSys('/proc/uptime');
      final sec = double.tryParse(up.split(' ')[0]) ?? 0;
      if (mounted) setState(() {
        _kernel = k.trim();
        _uptime = '${sec~/3600}j ${((sec%3600)~/60)}m ${((sec%60)).toInt()}d';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final d = DeviceInfo.i;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(children: [
        _card(title: 'Perangkat', children: [
          Padding(padding: const EdgeInsets.fromLTRB(14,12,14,12), child:
            Text('${d.brand} ${d.model}', style: const TextStyle(color: kGreen, fontSize: 18, fontWeight: FontWeight.w700))),
          const Divider(height: 1, color: kDivider),
          _infoRowDiv('Model', d.model, bold: true),
          _infoRowDiv('Pabrikan', d.brand, bold: true),
          _infoRowDiv('Platform', d.platform),
          _infoRow('Arsitektur', d.cpuArch),
        ]),
        _card(title: 'Sistem Operasi', children: [
          Padding(padding: const EdgeInsets.fromLTRB(14,12,14,8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Android ${d.androidVer}', style: const TextStyle(color: kGreen, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(children: [_chip(d.cpuArch), _chip('64-bit')]),
          ])),
          const Divider(height: 1, color: kDivider),
          _infoRowDiv('Versi Android', d.androidVer, bold: true),
          _infoRowDiv('Build ID', d.buildId),
          _infoRowDiv('Patch keamanan', d.secPatch),
          _infoRow('Kernel', _kernel, bold: false),
        ]),
        _card(title: 'Runtime', children: [
          _infoRowDiv('Waktu aktif', _uptime),
          _checkRow('Project Treble', true),
          _checkRow('Project Mainline', true),
          _checkRow('KernelSU', isRootNotifier.value),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 4: BATERAI
// ─────────────────────────────────────────────
class BateraiTab extends StatefulWidget {
  const BateraiTab({super.key});
  @override
  State<BateraiTab> createState() => _BateraiTabState();
}

class _BateraiTabState extends State<BateraiTab> {
  String _pct = '---', _temp = '---', _volt = '---';
  String _status = '---', _tech = '---', _health = '---';
  String _current = '---';
  late Timer _timer;

  @override
  void initState() { super.initState(); _fetch(); _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch()); }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final pct  = await readSys('/sys/class/power_supply/battery/capacity');
    final volt = await readSys('/sys/class/power_supply/battery/voltage_now');
    final cur  = await readSys('/sys/class/power_supply/battery/current_now');
    final stat = await readSys('/sys/class/power_supply/battery/status');
    final tech = await readSys('/sys/class/power_supply/battery/technology');
    final health = await readSys('/sys/class/power_supply/battery/health');
    String temp = '---';
    if (DeviceInfo.i.batteryTempPath != null) {
      final raw = await readSys(DeviceInfo.i.batteryTempPath!);
      final n = int.tryParse(raw) ?? 0;
      if (n != 0) temp = n > 100 ? '${(n/10).toStringAsFixed(1)}°C' : '$n°C';
    }
    if (mounted) setState(() {
      _pct = pct.isEmpty ? '---' : '$pct%';
      _volt = volt.isEmpty ? '---' : '${(int.tryParse(volt)??0)/1000000} V';
      _current = cur.isEmpty ? '---' : '${(int.tryParse(cur)??0)} µA';
      _status = stat.isEmpty ? '---' : stat;
      _tech = tech.isEmpty ? '---' : tech;
      _health = health.isEmpty ? '---' : health;
      _temp = temp;
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Column(children: [
      _card(title: 'Status', children: [
        _bigValue(_pct, _status),
        Padding(padding: const EdgeInsets.fromLTRB(14,0,14,12),
          child: Text('$_temp  $_volt', style: const TextStyle(color: kGrey, fontSize: 13))),
        const Divider(height: 1, color: kDivider),
        _infoRowDiv('Arus', _current),
        _infoRow('Suhu', _temp),
      ]),
      _card(title: 'Info', children: [
        _subHeader('Kondisi'),
        _infoRowDiv('Teknologi', _tech, bold: true),
        _infoRowDiv('Kondisi', _health, bold: true),
        _infoRow('Status', _status),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────
// TAB 5: JARINGAN
// ─────────────────────────────────────────────
class JaringanTab extends StatefulWidget {
  const JaringanTab({super.key});
  @override
  State<JaringanTab> createState() => _JaringanTabState();
}

class _JaringanTabState extends State<JaringanTab> {
  String _ip = '---', _dns1 = '---', _dns2 = '---', _privDns = '---';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    final dns1 = await getProp('net.dns1');
    final dns2 = await getProp('net.dns2');
    final pdns = await getProp('persist.net.dnsv4.dns1');
    String privDns = '---';
    try {
      final r = await Process.run('sh', ['-c', 'settings get global private_dns_specifier']);
      privDns = r.stdout.toString().trim();
      if (privDns == 'null' || privDns.isEmpty) privDns = 'Tidak aktif';
    } catch (_) {}
    String ip = '---';
    try {
      final r = await Process.run('sh', ['-c', "ip route get 1 | awk '{print \$NF; exit}'"]);
      ip = r.stdout.toString().trim();
    } catch (_) {}
    if (mounted) setState(() {
      _ip = ip.isEmpty ? '---' : ip;
      _dns1 = dns1.isEmpty ? '---' : dns1;
      _dns2 = dns2.isEmpty ? '---' : dns2;
      _privDns = privDns;
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Column(children: [
      _card(title: 'Koneksi', children: [
        _infoRowDiv('Alamat IP', _ip, bold: true),
        _infoRowDiv('DNS1', _dns1),
        _infoRowDiv('DNS2', _dns2),
        _infoRow('DNS Pribadi', _privDns),
      ]),
      _card(title: 'Wi-Fi', children: [
        _checkRow('802.11 b/g/n/ac/ax', true),
        _checkRow('Wi-Fi Direct', true),
        _checkRow('Dukungan pita 5GHz', true),
        _checkRow('Dukungan pita 6GHz', true),
        _checkRow('Wi-Fi Aware', false),
      ]),
      _card(title: 'Mobile', children: [
        _infoRowDiv('SIM ganda', 'Ya'),
        _infoRowDiv('Tipe telepon', 'GSM'),
        _infoRow('eSIM', 'Tidak'),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────
// TAB 6: KONTROL — opsi tweak (gaya DevCheck)
// ─────────────────────────────────────────────
class KontrolTab extends StatelessWidget {
  const KontrolTab({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DeviceInfo.i;

    // Banner root — dibuat terpisah agar tidak ambigu
    final rootBanner = ValueListenableBuilder<bool>(
      valueListenable: isRootNotifier,
      builder: (_, root, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: root ? kGreen.withOpacity(.12) : kOrange.withOpacity(.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: root ? kGreen.withOpacity(.4) : kOrange.withOpacity(.4)),
        ),
        child: Row(children: [
          Icon(root ? Icons.check_circle_rounded : Icons.lock_rounded,
              color: root ? kGreen : kOrange, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            root ? 'Root aktif — semua kontrol tersedia' : 'Non-root — kontrol tidak tersedia',
            style: TextStyle(color: root ? kGreen : kOrange, fontSize: 12.5),
          )),
        ]),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: rootBanner,
        ),

        // CPU Governor — hanya tampil kalau ada
        if (d.governors.isNotEmpty)
          _ctrlCard('CPU Governor', Icons.developer_board_rounded, [
            for (final g in d.governors)
              _CtrlLeaf(label: g, desc: _govDesc(g), cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo $g > \$f; done'),
          ]),

        // CPU Frekuensi Max
        if (d.freqChoices.isNotEmpty)
          _ctrlCard('CPU Frekuensi Max', Icons.speed_rounded,
            d.freqChoices.map((khz) => _CtrlLeaf(
              label: '${(khz/1000).round()} MHz',
              desc: khz == d.freqsKhz.last ? 'Full speed' : khz == d.freqsKhz.first ? 'Hemat daya' : 'Seimbang',
              cmd: 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo $khz > \$f; done',
            )).toList()),

        _ctrlCard('RAM & Cache', Icons.memory_rounded, [
          const _CtrlLeaf(label: 'Clear Cache', desc: 'Bebaskan RAM cache', cmd: 'sync; echo 3 > /proc/sys/vm/drop_caches'),
          const _CtrlLeaf(label: 'Swappiness 10', desc: 'Prioritaskan RAM', cmd: 'echo 10 > /proc/sys/vm/swappiness'),
          const _CtrlLeaf(label: 'Swappiness 60', desc: 'Seimbang (default)', cmd: 'echo 60 > /proc/sys/vm/swappiness'),
        ]),

        _ctrlCard('Thermal', Icons.thermostat_rounded, [
          const _CtrlLeaf(label: 'Baca Suhu', desc: 'Semua zone thermal', cmd: 'for z in /sys/class/thermal/thermal_zone*/temp; do t=\$(cat \$z 2>/dev/null); [ -n "\$t" ] && echo "\$z: \$t"; done', readOnly: true),
          const _CtrlLeaf(label: 'Disable Throttle', desc: 'Matikan throttle zone 0', cmd: 'echo disabled > /sys/class/thermal/thermal_zone0/mode'),
          const _CtrlLeaf(label: 'Enable Throttle', desc: 'Aktifkan throttle kembali', cmd: 'echo enabled > /sys/class/thermal/thermal_zone0/mode'),
        ]),

        _ctrlCard('I/O Scheduler', Icons.storage_rounded, [
          const _CtrlLeaf(label: 'noop', desc: 'Minimal overhead — SSD/eMMC', cmd: 'for d in /sys/block/*/queue/scheduler; do echo noop > \$d 2>/dev/null; done'),
          const _CtrlLeaf(label: 'deadline', desc: 'Responsif I/O', cmd: 'for d in /sys/block/*/queue/scheduler; do echo deadline > \$d 2>/dev/null; done'),
        ]),

        _ctrlCard('DNS Pribadi', Icons.dns_rounded, [
          const _CtrlLeaf(label: 'AdGuard', desc: 'Blokir iklan & tracker', cmd: 'settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.adguard-dns.com'),
          const _CtrlLeaf(label: 'Cloudflare', desc: 'Cepat & privat', cmd: 'settings put global private_dns_mode hostname; settings put global private_dns_specifier one.one.one.one'),
          const _CtrlLeaf(label: 'Quad9', desc: 'Blokir situs berbahaya', cmd: 'settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.quad9.net'),
          const _CtrlLeaf(label: 'Google DNS', desc: 'dns.google', cmd: 'settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.google'),
          const _CtrlLeaf(label: 'Matikan DNS Pribadi', desc: 'Kembali ke otomatis', cmd: 'settings put global private_dns_mode off'),
        ]),

        _ctrlCard('TCP Network', Icons.network_check_rounded, [
          const _CtrlLeaf(label: 'TCP BBR', desc: 'Congestion control Google', cmd: 'echo bbr > /proc/sys/net/ipv4/tcp_congestion_control'),
          const _CtrlLeaf(label: 'TCP Cubic', desc: 'Default Linux', cmd: 'echo cubic > /proc/sys/net/ipv4/tcp_congestion_control'),
        ]),

        if (d.dt2wPath != null)
          _ctrlCard('Layar & Gesture', Icons.touch_app_rounded, [
            _CtrlLeaf(label: 'Double Tap to Wake: ON', desc: 'Ketuk 2x nyalakan layar', cmd: 'echo 1 > ${d.dt2wPath}'),
            _CtrlLeaf(label: 'Double Tap to Wake: OFF', desc: 'Matikan gesture wake', cmd: 'echo 0 > ${d.dt2wPath}'),
          ]),

        _ctrlCard('System', Icons.settings_rounded, [
          const _CtrlLeaf(label: 'Info Build', desc: 'Model & versi Android', cmd: 'getprop ro.product.model; getprop ro.board.platform; getprop ro.build.version.release', readOnly: true),
          const _CtrlLeaf(label: 'Clear Logcat', desc: 'Bersihkan buffer log', cmd: 'logcat -c'),
          const _CtrlLeaf(label: 'Reboot', desc: 'Reboot perangkat', cmd: 'reboot'),
        ]),
      ]),
    );
  }

  String _govDesc(String g) {
    const m = {'performance': 'Semua core max — gaming', 'powersave': 'Hemat daya maksimal',
      'schedutil': 'Adaptif load-based', 'ondemand': 'Naik cepat saat butuh',
      'conservative': 'Naik pelan — hemat', 'interactive': 'Responsif untuk UI'};
    return m[g] ?? 'Governor $g';
  }

  Widget _ctrlCard(String title, IconData icon, List<_CtrlLeaf> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Icon(icon, color: kGreen, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${items.length} opsi', style: const TextStyle(color: kGreyDark, fontSize: 11)),
          ])),
        const Divider(height: 1, color: kDivider),
        ...items,
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// CTRL LEAF — tombol kontrol ala DevCheck list item
// ─────────────────────────────────────────────
class _CtrlLeaf extends StatefulWidget {
  final String label, desc, cmd;
  final bool readOnly;
  const _CtrlLeaf({required this.label, required this.desc, required this.cmd, this.readOnly = false});
  @override
  State<_CtrlLeaf> createState() => _CtrlLeafState();
}

class _CtrlLeafState extends State<_CtrlLeaf> {
  bool _running = false, _flash = false;

  Future<void> _exec() async {
    if (_running) return;
    if (!isRootNotifier.value) { _snack('Butuh akses root'); return; }
    setState(() => _running = true);
    HapticFeedback.mediumImpact();
    final out = await runRoot(widget.cmd);
    if (!mounted) return;
    setState(() => _running = false);
    final isErr = out.startsWith('ERR') || out.startsWith('ERROR');
    if (widget.readOnly) {
      if (out.isNotEmpty && out != 'OK') _showSheet(out);
      else _snack('Selesai');
    } else if (isErr) {
      _snack('Gagal: ${out.replaceFirst(RegExp(r"ERR:?R?:? "), "")}');
    } else {
      setState(() => _flash = true);
      _snack('${widget.label} diterapkan');
      Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => _flash = false); });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: kCard2, duration: const Duration(milliseconds: 1800),
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  void _showSheet(String result) {
    showModalBottomSheet(context: context, backgroundColor: kCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: .5, maxChildSize: .9,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 8), width: 32, height: 3,
            decoration: BoxDecoration(color: kGreyDark, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0),
            child: Row(children: [
              Text(widget.label, style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: kGrey, size: 20)),
            ])),
          Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.all(16),
            child: SelectableText(result, style: const TextStyle(color: kGreen, fontSize: 12, fontFamily: 'monospace', height: 1.6)))),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isRootNotifier,
      builder: (_, root, __) {
        final locked = !root && !widget.readOnly;
        return Column(children: [
          GestureDetector(
            onTap: locked ? () => _snack('Butuh root') : _exec,
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              color: _flash ? kGreen.withOpacity(.08) : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.label, style: TextStyle(
                      color: locked ? kGreyDark : kWhite,
                      fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(widget.desc, style: const TextStyle(color: kGrey, fontSize: 12)),
                  ])),
                  if (_running)
                    const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: kGreen, strokeWidth: 2))
                  else if (_flash)
                    const Icon(Icons.check_rounded, color: kGreen, size: 18)
                  else if (locked)
                    const Icon(Icons.lock_rounded, color: kGreyDark, size: 16)
                  else if (widget.readOnly)
                    const Icon(Icons.chevron_right_rounded, color: kGrey, size: 20)
                  else
                    const Icon(Icons.chevron_right_rounded, color: kGrey, size: 20),
                ]))),
          ),
          const Divider(height: 1, color: kDivider, indent: 14),
        ]);
      });
  }
}
