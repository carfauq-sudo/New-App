import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'maintenance_record.dart';
import 'scheduled_maintenance.dart';

void main() {
  runApp(const MaintenanceGoApp());
}

// ---- Color tokens ----
// Kept in one place so the palette is easy to tweak later.
class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1C1C1E);
  static const border = Color(0xFF2C2C2E);
  static const textPrimary = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFF9A9A9E);
  static const accent = Color(0xFFE8A33D); // dashboard warning-light amber
}

class MaintenanceGoApp extends StatelessWidget {
  const MaintenanceGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaintenanceGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.accent,
        ),
      ),
      home: const MainShell(),
    );
  }
}

// ---- App shell ----
// Owns the bottom nav bar and the currently selected tab, so the bar stays
// visible on every page. Profile and Settings are placeholders for now.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.directions_car_outlined,
              color: AppColors.textSecondary,
            ),
            selectedIcon: Icon(Icons.directions_car, color: AppColors.accent),
            label: 'My Vehicle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppColors.accent),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.settings, color: AppColors.accent),
            label: 'Settings',
          ),
        ],
      ),
      // Only the selected tab is built. That way the 3D viewer isn't running
      // in the background while you're on another tab.
      body: switch (_selectedIndex) {
        0 => const LandingPage(),
        1 => const MyVehiclePage(),
        2 => const _PlaceholderPage(label: 'Profile'),
        _ => const _PlaceholderPage(label: 'Settings'),
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;

  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 17),
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Top 40%: My Vehicle ----
          SizedBox(
            height: screenHeight * 0.4,
            child: const _MyVehicleSection(),
          ),

          // ---- Remaining space: navigation ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavCard(
                    title: 'Maintenance logs',
                    subtitle: 'Every service, receipt, and repair',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MaintenanceLogPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NavCard(
                    title: 'Maintenance calendar',
                    subtitle: 'What\'s due, and when',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MaintenanceCalendarPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- My Vehicle page ----
// Shown by the "My Vehicle" tab. A rotatable 3D model of the vehicle with
// tappable dots on different parts. Tapping a dot zooms the camera in on that
// part and lists the mods/maintenance done to it.

// One tappable spot on the 3D model.
class VehicleHotspot {
  final String id;
  final String name;
  final String position; // point on the model, in model units: "x y z"
  final String normal; // direction the dot faces: "x y z"
  final String cameraTarget; // where the camera looks when zoomed in
  final String cameraOrbit; // camera angle/distance when zoomed in
  final List<String> mods;
  // If set, this is a sub-part of another hotspot (e.g. "Brakes" under
  // "Wheels & Brakes"). Sub-part dots only appear once you've zoomed into
  // their parent.
  final String? parent;

  const VehicleHotspot({
    required this.id,
    required this.name,
    required this.position,
    required this.normal,
    required this.cameraTarget,
    required this.cameraOrbit,
    required this.mods,
    this.parent,
  });
}

// Placeholder data. Later this will come from the vehicle's real records.
const _vehicleHotspots = [
  VehicleHotspot(
    id: 'windshield',
    name: 'Windows & Tint',
    // Point on the windshield surface, nudged slightly outward along its normal.
    position: '0.545m 0.994m 0m',
    normal: '0.55 0.83 0',
    cameraTarget: '0.528m 0.969m 0m',
    cameraOrbit: '90deg 62deg 1.6m',
    mods: ['35% tint'],
  ),
  // Wheels & Brakes: the overview dot zooms in on the wheel, where two
  // sub-part dots appear (Wheel and Brakes), each with its own mods.
  VehicleHotspot(
    id: 'wheels',
    name: 'Wheels & Brakes',
    // Center of the front driver-side wheel, just outside the rim.
    position: '1.045m 0.245m 0.63m',
    normal: '0 0 1',
    cameraTarget: '1.045m 0.245m 0.6m',
    cameraOrbit: '0deg 80deg 1.0m',
    mods: [],
  ),
  VehicleHotspot(
    id: 'wheel',
    parent: 'wheels',
    name: 'Wheel',
    // On the tire sidewall, lower front of the wheel.
    position: '1.19m 0.10m 0.63m',
    normal: '0 0 1',
    cameraTarget: '1.19m 0.10m 0.6m',
    cameraOrbit: '0deg 80deg 0.9m',
    mods: ['All-terrain tires', 'Tire rotation'],
  ),
  VehicleHotspot(
    id: 'brakes',
    parent: 'wheels',
    name: 'Brakes',
    // Brakes sit behind the wheel (not modeled), so this marks the hub area.
    position: '1.045m 0.325m 0.59m',
    normal: '0 0 1',
    cameraTarget: '1.045m 0.3m 0.55m',
    cameraOrbit: '0deg 80deg 0.9m',
    mods: ['Brake pad replacement', 'Brake fluid flush'],
  ),
  // Rear: the overview dot sits in the middle of the tailgate (so it's only
  // visible from behind) and zooms to a rear three-quarter view with three
  // sub-parts.
  VehicleHotspot(
    id: 'rear',
    name: 'Rear',
    position: '-1.69m 0.62m 0m',
    normal: '-1 0 0',
    cameraTarget: '-1.2m 0.6m 0.1m',
    cameraOrbit: '-40deg 60deg 2.2m',
    mods: [],
  ),
  VehicleHotspot(
    id: 'tailgate',
    parent: 'rear',
    name: 'Tailgate',
    position: '-1.69m 0.62m 0m',
    normal: '-1 0 0',
    cameraTarget: '-1.66m 0.6m 0m',
    cameraOrbit: '-90deg 75deg 1.3m',
    mods: ['Tailgate assist damper', 'Tailgate lock'],
  ),
  VehicleHotspot(
    id: 'brake_lights',
    parent: 'rear',
    name: 'Brake lights',
    position: '-1.69m 0.65m 0.51m',
    normal: '-1 0 0',
    cameraTarget: '-1.65m 0.65m 0.5m',
    cameraOrbit: '-70deg 75deg 1.0m',
    mods: ['Smoked LED tail lights', 'Bulb replacement'],
  ),
  VehicleHotspot(
    id: 'bed',
    parent: 'rear',
    name: 'Bed',
    position: '-1.15m 0.56m 0m',
    normal: '0 1 0',
    cameraTarget: '-1.15m 0.55m 0m',
    cameraOrbit: '-90deg 40deg 1.6m',
    mods: ['Spray-in bed liner', 'Tonneau cover'],
  ),
];

// Camera used for the full-vehicle view (also what we zoom back out to).
const _defaultOrbit = '35deg 75deg 105%';

class MyVehiclePage extends StatefulWidget {
  const MyVehiclePage({super.key});

  @override
  State<MyVehiclePage> createState() => _MyVehiclePageState();
}

class _MyVehiclePageState extends State<MyVehiclePage> {
  VehicleHotspot? _selected; // null = full view
  VehicleHotspot? _lastPanel; // kept so the panel can slide out smoothly
  WebViewController? _web;

  // Runs a line of JavaScript on the 3D viewer (e.g. to move the camera).
  void _js(String code) =>
      _web?.runJavaScript("document.querySelector('model-viewer').$code");

  // Zooms in on a hotspot and shows its panel. Tapping a top-level dot also
  // reveals that part's sub-dots; tapping a sub-dot stays in the same group.
  void _focus(VehicleHotspot h) {
    setState(() => _selected = _lastPanel = h);
    _js("cameraTarget = '${h.cameraTarget}'");
    _js("cameraOrbit = '${h.cameraOrbit}'");
    _web?.runJavaScript("setContext('${h.parent ?? h.id}')");
  }

  // Closing a sub-part goes back to its parent; closing a top-level part goes
  // back to the full-vehicle view.
  void _back() {
    final parent = _selected?.parent;
    if (parent != null) {
      _focus(_vehicleHotspots.firstWhere((h) => h.id == parent));
    } else {
      setState(() => _selected = null);
      _js("cameraTarget = 'auto auto auto'");
      _js("cameraOrbit = '$_defaultOrbit'");
      _web?.runJavaScript("setContext('')");
    }
  }

  // Builds the HTML for the dots. Each one is a <button> that model-viewer
  // pins to a spot on the model.
  String get _hotspotHtml => [
    for (final h in _vehicleHotspots)
      '<button class="hs${h.parent == null ? '' : ' off'}" '
          'slot="hotspot-${h.id}" data-id="${h.id}" '
          'data-parent="${h.parent ?? ''}" '
          'data-position="${h.position}" data-normal="${h.normal}">'
          '<span class="dot"></span><span class="line"></span>'
          '<span class="lbl">${h.name}</span></button>',
  ].join('\n');

  // Styles for the dots. The button itself is only the dot-sized target:
  // model-viewer pins the CENTER of this element to the 3D point, so the line
  // and label are absolutely positioned and don't shift that center.
  static const _hotspotCss = '''
    .hs { position: relative; width: 36px; height: 36px; display: block;
          padding: 0; background: none; border: none; cursor: pointer;
          transition: opacity 0.2s; }
    .hs.occluded { opacity: 0; pointer-events: none; }
    .hs.off { display: none; }
    .dot { position: absolute; left: 12px; top: 12px; width: 12px; height: 12px;
           box-sizing: border-box; border-radius: 50%; background: #fff;
           border: 2px solid rgba(0,0,0,0.6);
           box-shadow: 0 0 0 4px rgba(255,255,255,0.35); }
    .line { position: absolute; left: 26px; top: 17px; width: 24px; height: 2px;
            background: #fff; box-shadow: 0 0 3px rgba(0,0,0,0.8); }
    .lbl { position: absolute; left: 52px; top: 10px; white-space: nowrap;
           color: #fff; font: 600 12px/16px -apple-system, sans-serif;
           text-shadow: 0 0 4px #000, 0 0 2px #000; }
  ''';

  String get _hotspotJs {
    return '''
      const viewer = document.querySelector('model-viewer');
      document.querySelectorAll('.hs').forEach((btn) => {
        btn.addEventListener('click', () => {
          HotspotChannel.postMessage(btn.dataset.id);
        });
      });

      // Which group of dots is showing: '' = the top-level dots, otherwise the
      // sub-dots of that parent (e.g. 'wheels'). Called from Dart.
      function setContext(ctx) {
        document.querySelectorAll('.hs').forEach((b) => {
          b.classList.toggle('off', (b.dataset.parent || '') !== ctx);
        });
        schedule();
      }
      window.setContext = setContext;

      // Hide a dot when the truck itself is blocking it. We cast a ray from
      // the camera through the dot; if it hits the truck clearly CLOSER to the
      // camera than the dot, something is in the way. (Comparing distance
      // along the ray, not position, avoids false hides at glancing angles.)
      const btns = [...document.querySelectorAll('.hs')];
      let queued = false;
      const dist = (a, b) => Math.hypot(a[0]-b[0], a[1]-b[1], a[2]-b[2]);
      function updateVisibility() {
        queued = false;
        const o = viewer.getCameraOrbit();
        const t = viewer.getCameraTarget();
        const cam = [
          t.x + o.radius * Math.sin(o.phi) * Math.sin(o.theta),
          t.y + o.radius * Math.cos(o.phi),
          t.z + o.radius * Math.sin(o.phi) * Math.cos(o.theta),
        ];
        btns.forEach((b) => {
          const r = b.getBoundingClientRect();
          const hit = viewer.positionAndNormalFromPoint(
              r.left + r.width / 2, r.top + r.height / 2);
          const p = b.dataset.position.split(' ').map(parseFloat);
          const hp = hit && [hit.position.x, hit.position.y, hit.position.z];
          const visible = hit && dist(cam, hp) > dist(cam, p) - 0.08;
          b.classList.toggle('occluded', !visible);
        });
      }
      function schedule() {
        if (!queued) { queued = true; requestAnimationFrame(updateVisibility); }
      }
      viewer.addEventListener('camera-change', schedule);
      viewer.addEventListener('load', schedule);
    ''';
  }

  // Built once and reused, so tapping a dot (which rebuilds this page) never
  // makes the 3D viewer reload or re-render from scratch.
  late final Widget _viewer = ModelViewer(
    src: 'assets/models/tacoma.glb',
    alt: 'Toyota Tacoma 3D model',
    backgroundColor: Colors.transparent,
    cameraControls: true,
    disablePan: true,
    cameraOrbit: _defaultOrbit,
    shadowIntensity: 0, // shadows cost extra rendering work every frame
    exposure: 0.6, // slightly darker lighting so white dots/labels stand out
    minHotspotOpacity: 1, // we hide dots ourselves (see relatedJs)
    interactionPrompt: InteractionPrompt.none,
    debugLogging: false,
    innerModelViewerHtml: _hotspotHtml,
    relatedCss: _hotspotCss,
    relatedJs: _hotspotJs,
    onWebViewCreated: (c) => _web = c,
    javascriptChannels: {
      JavascriptChannel(
        'HotspotChannel',
        onMessageReceived: (msg) {
          final match = _vehicleHotspots.where((h) => h.id == msg.message);
          if (match.isNotEmpty) _focus(match.first);
        },
      ),
    },
  );

  @override
  Widget build(BuildContext context) {
    // The mods panel floats over the bottom of the viewer instead of sitting
    // below it, so the viewer keeps a constant size (resizing a web view every
    // frame during the panel animation is a big source of choppiness).
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: _viewer),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              offset: _selected == null ? const Offset(0, 1.2) : Offset.zero,
              child: _lastPanel == null
                  ? const SizedBox.shrink()
                  : _ModsPanel(
                      spot: _lastPanel!,
                      parts: _vehicleHotspots
                          .where((h) => h.parent == _lastPanel!.id)
                          .toList(),
                      onSelectPart: _focus,
                      onClose: _back,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card shown under the zoomed image: the part name and its mods/maintenance.
class _ModsPanel extends StatelessWidget {
  final VehicleHotspot spot;
  final List<VehicleHotspot> parts; // sub-parts, if this spot has any
  final ValueChanged<VehicleHotspot> onSelectPart;
  final VoidCallback onClose;

  const _ModsPanel({
    required this.spot,
    required this.parts,
    required this.onSelectPart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spot.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                tooltip: spot.parent == null ? 'Back to full view' : 'Back',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            parts.isEmpty ? 'Mods & maintenance' : 'Tap a part to see its mods',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // A spot with sub-parts lists them as tappable rows (same as
          // tapping their dots on the truck).
          for (final part in parts)
            InkWell(
              onTap: () => onSelectPart(part),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        part.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          for (final mod in spot.mods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mod,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MyVehicleSection extends StatelessWidget {
  const _MyVehicleSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My vehicle',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '2026 Toyota Tacoma SR5',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          // Vehicle image sits under the name and takes the remaining space.
          // The photo has a near-black background, so it blends into the
          // dark theme.
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/tacoma.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                '42,180 miles',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Last service 3 months ago',
                style: TextStyle(color: AppColors.accent, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap; // null = placeholder that does nothing yet

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Material + InkWell gives the card a press ripple.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Maintenance log page ----
// Opened from the "Maintenance logs" card on the home page. A scrollable list
// of service records, newest first. Tapping one opens its full detail page;
// the + button at the top right adds a new one.
//
// NOTE: records added here only live in memory for now (they disappear when
// the app restarts) because the local storage layer isn't built yet.
class MaintenanceLogPage extends StatefulWidget {
  const MaintenanceLogPage({super.key});

  @override
  State<MaintenanceLogPage> createState() => _MaintenanceLogPageState();
}

class _MaintenanceLogPageState extends State<MaintenanceLogPage> {
  // Copy of the placeholder list so new entries can be added to it.
  final List<MaintenanceRecord> _records = [...placeholderRecords];

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add a maintenance log',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _AddOptionTile(
                icon: Icons.edit_outlined,
                title: 'Enter manually',
                subtitle: 'Type in the details yourself',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addManually();
                },
              ),
              // TODO(future): receipt photo needs camera / photo-library
              // access plus AI receipt parsing. Not built yet.
              _AddOptionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Receipt picture',
                subtitle: 'Snap a receipt and fill in the log for you',
                comingSoon: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon('Receipt scanning');
                },
              ),
              // TODO(future): needs an AI model to summarize the mechanic's
              // report into a log entry. Not built yet.
              _AddOptionTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Mechanic report (AI summary)',
                subtitle: 'Summarize a mechanic\'s report into a log',
                comingSoon: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon('AI report summary');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addManually() async {
    final record = await Navigator.of(context).push<MaintenanceRecord>(
      MaterialPageRoute(builder: (_) => const AddMaintenancePage()),
    );
    if (record != null) {
      setState(() {
        _records.add(record);
        _records.sort((a, b) => b.date.compareTo(a.date)); // newest first
      });
    }
  }

  // Opens a record's detail page. The page reports back `true` if the user
  // deleted the log, so we can remove it from the list.
  Future<void> _openDetail(MaintenanceRecord record) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MaintenanceDetailPage(record: record)),
    );
    if (deleted == true) {
      setState(() => _records.removeWhere((r) => r.id == record.id));
      _showUndoSnackBar(record);
    }
  }

  // "Log deleted" pop-up at the bottom with an Undo button, shown for 5
  // seconds. Undo puts the record back in its date-sorted place.
  void _showUndoSnackBar(MaintenanceRecord record) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar() // replace any earlier pop-up
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Log deleted',
            style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 5),
          // With an action, Flutter keeps a snackbar up until dismissed
          // unless we turn persistence off.
          persist: false,
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accent, // the app's amber
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.background,
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _records.add(record);
                _records.sort((a, b) => b.date.compareTo(a.date));
              });
            },
          ),
        ),
      );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming in a future update')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Maintenance logs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddOptions,
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Add maintenance log',
          ),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'No service records yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            )
          // ListView.builder only builds the rows currently on screen, which
          // keeps long logs smooth.
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _LogEntryCard(
                record: records[i],
                onTap: () => _openDetail(records[i]),
              ),
            ),
    );
  }
}

// One choice in the "add a log" sheet.
class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool comingSoon;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.accent, size: 26),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: comingSoon
          ? const Text(
              'Coming soon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}

// One row in the log: date/time, what was done, total spent, itemized lines.
class _LogEntryCard extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback onTap;

  const _LogEntryCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDateTime(record.date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatMoney(record.totalCents),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                record.part,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              for (final item in record.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.quantity > 1
                              ? '${item.description}  x${item.quantity}'
                              : item.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatMoney(item.totalCents),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Maintenance detail page ----
// Full details for one record: when/where/who, the full itemized report with
// quantities and unit prices, the total, and notes.
class MaintenanceDetailPage extends StatelessWidget {
  final MaintenanceRecord record;

  const MaintenanceDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Service details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            record.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(record.kind == RecordKind.mod ? 'Mod' : 'Maintenance'),
              // Verified vs. self-reported is kept visible on purpose: it's
              // what will make a history trustworthy to a future buyer.
              _Chip(
                record.source == RecordSource.shopVerified
                    ? 'Shop-verified'
                    : 'User-entered',
                highlight: record.source == RecordSource.shopVerified,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailSection(
            children: [
              _DetailRow('Date', formatDate(record.date)),
              _DetailRow('Time', formatTime(record.date)),
              _DetailRow('Mileage', formatMiles(record.mileage)),
              _DetailRow('Part', record.part),
              _DetailRow('Performed by', record.performedBy),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Itemized report'),
          _DetailSection(
            children: [
              for (final item in record.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            if (item.quantity > 1)
                              Text(
                                '${item.quantity} x ${formatMoney(item.unitCents)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatMoney(item.totalCents),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24, color: AppColors.border),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(record.totalCents),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel('Notes'),
            _DetailSection(
              children: [
                Text(
                  record.notes,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              // The log page shows an Undo pop-up, so no confirmation box is needed.
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete Log',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Rounded card that groups related rows.
class _DetailSection extends StatelessWidget {
  final List<Widget> children;

  const _DetailSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _Chip(this.label, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accent : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

// ---- Add maintenance page (manual entry) ----
// A simple form. When saved it returns a MaintenanceRecord to the log page.
// The receipt-photo and AI-summary options will eventually fill in this same
// form for the user to review and correct.

const _partOptions = [
  'Windows & Tint',
  'Wheels & Brakes › Wheel',
  'Wheels & Brakes › Brakes',
  'Rear › Tailgate',
  'Rear › Brake lights',
  'Rear › Bed',
  'Engine',
  'Interior',
  'Drivetrain',
  'Other',
];

// One editable line in the itemized report.
class _ItemDraft {
  final description = TextEditingController();
  final price = TextEditingController(); // dollars, e.g. "89.99"
  final quantity = TextEditingController(text: '1');

  void dispose() {
    description.dispose();
    price.dispose();
    quantity.dispose();
  }
}

InputDecoration _fieldDecoration(String label, {String? hint}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: AppColors.border),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    border: border,
  );
}

class AddMaintenancePage extends StatefulWidget {
  const AddMaintenancePage({super.key});

  @override
  State<AddMaintenancePage> createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends State<AddMaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _mileage = TextEditingController(text: '42180');
  final _performedBy = TextEditingController(text: 'DIY');
  final _notes = TextEditingController();
  final List<_ItemDraft> _items = [_ItemDraft()];
  // Removed rows are disposed with the page, not immediately, because their
  // text fields are still on screen until the next frame.
  final List<_ItemDraft> _removedItems = [];

  String _part = _partOptions.first;
  RecordKind _kind = RecordKind.maintenance;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _title.dispose();
    _mileage.dispose();
    _performedBy.dispose();
    _notes.dispose();
    for (final item in [..._items, ..._removedItems]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Turn each filled-in row into a LineItem (price typed in dollars, stored
    // as cents). Rows with no description are ignored.
    final items = <LineItem>[];
    for (final draft in _items) {
      final description = draft.description.text.trim();
      if (description.isEmpty) continue;
      final dollars = double.tryParse(draft.price.text.trim()) ?? 0;
      final qty = int.tryParse(draft.quantity.text.trim()) ?? 1;
      items.add(LineItem(description, (dollars * 100).round(), quantity: qty));
    }

    Navigator.pop(
      context,
      MaintenanceRecord(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        part: _part,
        kind: _kind,
        date: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        mileage: int.tryParse(_mileage.text.trim()) ?? 0,
        performedBy: _performedBy.text.trim().isEmpty
            ? 'DIY'
            : _performedBy.text.trim(),
        items: items,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'New log',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextFormField(
              controller: _title,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                'What was done',
                hint: 'e.g. Oil change',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            gap,
            SegmentedButton<RecordKind>(
              segments: const [
                ButtonSegment(
                  value: RecordKind.maintenance,
                  label: Text('Maintenance'),
                ),
                ButtonSegment(value: RecordKind.mod, label: Text('Mod')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
              style: SegmentedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                selectedForegroundColor: AppColors.accent,
                // Soft transparent amber highlight, like the nav bar's.
                selectedBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.18,
                ),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _part,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Part'),
              items: [
                for (final p in _partOptions)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _part = v ?? _part),
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Date',
                    value: formatDate(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Time',
                    value: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            gap,
            TextFormField(
              controller: _mileage,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Mileage'),
              keyboardType: TextInputType.number,
            ),
            gap,
            TextFormField(
              controller: _performedBy,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Performed by'),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Itemized report'),
            for (var i = 0; i < _items.length; i++) ...[
              _ItemRow(
                draft: _items[i],
                onRemove: _items.length > 1
                    ? () =>
                          setState(() => _removedItems.add(_items.removeAt(i)))
                    : null,
              ),
              const SizedBox(height: 10),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _items.add(_ItemDraft())),
                icon: const Icon(Icons.add, color: AppColors.accent),
                label: const Text(
                  'Add item',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Notes (optional)'),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}

// Tappable field that opens a date or time picker.
class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }
}

// One editable line of the itemized report: description, quantity, price.
class _ItemRow extends StatelessWidget {
  final _ItemDraft draft;
  final VoidCallback? onRemove; // null when it's the only row

  const _ItemRow({required this.draft, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: TextFormField(
            controller: draft.description,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('Item'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: draft.quantity,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('Qty'),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: draft.price,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('Price', hint: '0.00'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Remove item',
          ),
      ],
    );
  }
}

// ---- Maintenance calendar page ----
// A month grid. Days with scheduled maintenance are softly highlighted in
// amber and show short labels inside the box. Tapping a highlighted day opens
// a sheet with the full details. The arrows in the header change months.
class MaintenanceCalendarPage extends StatefulWidget {
  const MaintenanceCalendarPage({super.key});

  @override
  State<MaintenanceCalendarPage> createState() =>
      _MaintenanceCalendarPageState();
}

class _MaintenanceCalendarPageState extends State<MaintenanceCalendarPage> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // First day of the month being shown.
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // Copy of the placeholder list so new items can be added. Like the log,
  // this only lives in memory until the storage layer exists.
  final List<ScheduledMaintenance> _scheduled = [...placeholderScheduled];

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Schedule maintenance',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _AddOptionTile(
                icon: Icons.edit_calendar_outlined,
                title: 'Schedule manually',
                subtitle: 'Pick a date and fill in the details',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addManually();
                },
              ),
              // TODO(future): describe what you need and an AI model picks the
              // date and details. Not built yet.
              _AddOptionTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Schedule with AI',
                subtitle: 'Describe it and let AI set it up',
                comingSoon: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI scheduling is coming in a future update',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addManually() async {
    final item = await Navigator.of(context).push<ScheduledMaintenance>(
      MaterialPageRoute(builder: (_) => const AddScheduledPage()),
    );
    if (item != null) {
      setState(() {
        _scheduled.add(item);
        // Jump to the month it landed in so the new item is visible.
        _month = DateTime(item.date.year, item.date.month);
      });
    }
  }

  // Full details for one day, in a bottom sheet.
  void _showDay(DateTime date, List<ScheduledMaintenance> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              formatDate(date),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              items.length == 1
                  ? '1 item scheduled'
                  : '${items.length} items scheduled',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            for (final item in items) _ScheduledItemCard(item: item),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Weeks start on Sunday. DateTime.weekday is Mon=1..Sun=7, so `% 7` gives
    // Sun=0..Sat=6 = number of blank cells before the 1st.
    final leadingBlanks = _month.weekday % 7;
    final rows = ((leadingBlanks + daysInMonth) / 7).ceil();

    // Scheduled items in this month, grouped by day of the month.
    final byDay = <int, List<ScheduledMaintenance>>{};
    for (final m in _scheduled) {
      if (m.date.year == _month.year && m.date.month == _month.month) {
        byDay.putIfAbsent(m.date.day, () => []).add(m);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Maintenance calendar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddOptions,
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Schedule maintenance',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final letter in _weekdayLetters)
                  Expanded(
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // The grid: 7 columns, as many rows as the month needs. Cells draw
            // their own right/bottom lines so the whole thing reads as a grid.
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: GridView.count(
                crossAxisCount: 7,
                childAspectRatio: 0.62, // taller than wide, room for labels
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < rows * 7; i++)
                    _DayCell(
                      day:
                          (i - leadingBlanks + 1 >= 1 &&
                              i - leadingBlanks + 1 <= daysInMonth)
                          ? i - leadingBlanks + 1
                          : null,
                      items: byDay[i - leadingBlanks + 1] ?? const [],
                      isToday:
                          today.year == _month.year &&
                          today.month == _month.month &&
                          today.day == i - leadingBlanks + 1,
                      lineRight: i % 7 != 6,
                      lineBottom: i ~/ 7 != rows - 1,
                      onTap: byDay[i - leadingBlanks + 1] == null
                          ? null
                          : () => _showDay(
                              DateTime(
                                _month.year,
                                _month.month,
                                i - leadingBlanks + 1,
                              ),
                              byDay[i - leadingBlanks + 1]!,
                            ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Maintenance scheduled. Tap a day for details.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildUpcoming(today),
          ],
        ),
      ),
    );
  }

  // The next few scheduled items from today on, soonest first.
  Widget _buildUpcoming(DateTime now) {
    final todayDate = DateTime(now.year, now.month, now.day);
    final upcoming =
        _scheduled.where((m) => !m.date.isBefore(todayDate)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final next = upcoming.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Upcoming',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (next.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Nothing scheduled ahead',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        for (final item in next)
          _UpcomingRow(
            item: item,
            daysAway: DateTime(
              item.date.year,
              item.date.month,
              item.date.day,
            ).difference(todayDate).inDays,
            // Tapping opens the same details sheet as tapping that day.
            onTap: () => _showDay(
              item.date,
              _scheduled
                  .where(
                    (m) =>
                        m.date.year == item.date.year &&
                        m.date.month == item.date.month &&
                        m.date.day == item.date.day,
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// One row in the Upcoming list: date block, title, part, and how far away it
// is. Items within a week get a "Due soon" tag.
class _UpcomingRow extends StatelessWidget {
  final ScheduledMaintenance item;
  final int daysAway;
  final VoidCallback onTap;

  const _UpcomingRow({
    required this.item,
    required this.daysAway,
    required this.onTap,
  });

  String get _relative {
    if (daysAway == 0) return 'Today';
    if (daysAway == 1) return 'Tomorrow';
    if (daysAway < 60) return 'in $daysAway days';
    return 'in ${(daysAway / 30).round()} months';
  }

  @override
  Widget build(BuildContext context) {
    final dueSoon = daysAway <= 7;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date block: month over day number.
                Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        monthAbbreviation(item.date.month).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.date.day}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.part,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _relative,
                      style: TextStyle(
                        color: dueSoon
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: dueSoon ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (dueSoon) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Due soon',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// One box in the month grid: the day number, plus short labels for anything
// scheduled that day (up to two, then "+N more").
class _DayCell extends StatelessWidget {
  final int? day; // null = blank filler cell before the 1st / after the last
  final List<ScheduledMaintenance> items;
  final bool isToday;
  final bool lineRight;
  final bool lineBottom;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.items,
    required this.isToday,
    required this.lineRight,
    required this.lineBottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maxShown = 2;
    final scheduled = items.isNotEmpty;
    final extra = items.length - maxShown;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 3),
        decoration: BoxDecoration(
          // Soft transparent amber on days with maintenance.
          color: scheduled ? AppColors.accent.withValues(alpha: 0.18) : null,
          border: Border(
            right: lineRight
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
            bottom: lineBottom
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: day == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's number sits in a small outlined circle.
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textSecondary,
                              width: 1.5,
                            ),
                          )
                        : null,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: scheduled
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: scheduled || isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (final item in items.take(maxShown))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ),
                  if (extra > 0)
                    Text(
                      '+$extra more',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// Detail card for one scheduled item, shown in the day sheet.
class _ScheduledItemCard extends StatelessWidget {
  final ScheduledMaintenance item;

  const _ScheduledItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.part,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (item.dueMileage != null)
            _DetailRow('Due at', formatMiles(item.dueMileage!)),
          if (item.estimatedCents != null)
            _DetailRow(
              'Est. cost',
              item.estimatedCents == 0
                  ? 'Free if DIY'
                  : formatMoney(item.estimatedCents!),
            ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          _DiyVideosSection(taskName: item.title),
        ],
      ),
    );
  }
}

// "Do it yourself" help for a scheduled item: credible YouTube how-to videos
// picked by AI. Placeholder only for now (no AI, no YouTube connection); the
// sparkle icon marks it as an AI feature.
//
// TODO(future): search YouTube for this task on this vehicle, have an AI model
// pick trustworthy videos, and open them when tapped. The AI's picks should be
// shown as suggestions the user can judge, not as guaranteed-correct advice,
// and safety-critical jobs (like brakes) should still point to a mechanic.
class _DiyVideosSection extends StatelessWidget {
  final String taskName;

  const _DiyVideosSection({required this.taskName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Do it yourself',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'AI will find trusted, well-reviewed YouTube videos that show how '
          'to do this job yourself, matched to your vehicle. '
          '(Placeholder text.)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _VideoTile(title: 'How to: $taskName', meta: 'Channel name · 8:24'),
        const SizedBox(height: 8),
        _VideoTile(
          title: '$taskName on a Toyota Tacoma',
          meta: 'Channel name · 12:05',
        ),
      ],
    );
  }
}

// One placeholder video row: play thumbnail, title, channel and length.
class _VideoTile extends StatelessWidget {
  final String title;
  final String meta;

  const _VideoTile({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 84,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.textSecondary,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Schedule maintenance page (manual entry) ----
// A simple form. When saved it returns a ScheduledMaintenance to the calendar.
// Later, the vehicle manual / VIN data and the AI option will fill in items
// like this automatically.
class AddScheduledPage extends StatefulWidget {
  const AddScheduledPage({super.key});

  @override
  State<AddScheduledPage> createState() => _AddScheduledPageState();
}

class _AddScheduledPageState extends State<AddScheduledPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _label = TextEditingController();
  final _mileage = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  String _part = _partOptions.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _label.dispose();
    _mileage.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Short text for the calendar box: what the user typed, otherwise the first
  // word of the title (cut to fit).
  String _shortLabel() {
    final typed = _label.text.trim();
    if (typed.isNotEmpty) return typed;
    final firstWord = _title.text.trim().split(' ').first;
    return firstWord.length > 7 ? firstWord.substring(0, 7) : firstWord;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final miles = int.tryParse(_mileage.text.trim());
    final dollars = double.tryParse(_cost.text.trim());
    Navigator.pop(
      context,
      ScheduledMaintenance(
        title: _title.text.trim(),
        shortLabel: _shortLabel(),
        date: _date,
        part: _part,
        dueMileage: miles,
        estimatedCents: dollars == null ? null : (dollars * 100).round(),
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Schedule maintenance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextFormField(
              controller: _title,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                'What needs to be done',
                hint: 'e.g. Oil change',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            gap,
            _PickerField(
              label: 'Date',
              value: formatDate(_date),
              onTap: _pickDate,
            ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _part,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Part'),
              items: [
                for (final p in _partOptions)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _part = v ?? _part),
            ),
            gap,
            TextFormField(
              controller: _label,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLength: 8,
              decoration: _fieldDecoration(
                'Calendar label (optional)',
                hint: 'Short text shown in the box',
              ),
            ),
            TextFormField(
              controller: _mileage,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Due at mileage (optional)'),
              keyboardType: TextInputType.number,
            ),
            gap,
            TextFormField(
              controller: _cost,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                'Estimated cost (optional)',
                hint: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            gap,
            TextFormField(
              controller: _notes,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Notes (optional)'),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
