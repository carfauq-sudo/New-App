import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
                children: const [
                  _NavCard(
                    title: 'Maintenance logs',
                    subtitle: 'Every service, receipt, and repair',
                    icon: Icons.receipt_long_outlined,
                  ),
                  SizedBox(height: 16),
                  _NavCard(
                    title: 'Maintenance calendar',
                    subtitle: 'What\'s due, and when',
                    icon: Icons.calendar_month_outlined,
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

  const VehicleHotspot({
    required this.id,
    required this.name,
    required this.position,
    required this.normal,
    required this.cameraTarget,
    required this.cameraOrbit,
    required this.mods,
  });
}

// Placeholder data. Later this will come from the vehicle's real records.
const _vehicleHotspots = [
  VehicleHotspot(
    id: 'windshield',
    name: 'Windshield',
    // Point on the windshield surface, nudged slightly outward along its normal.
    position: '0.545m 0.994m 0m',
    normal: '0.55 0.83 0',
    cameraTarget: '0.528m 0.969m 0m',
    cameraOrbit: '90deg 62deg 1.6m',
    mods: ['35% tint'],
  ),
];

// Camera used for the full-vehicle view (also what we zoom back out to).
const _defaultOrbit = '35deg 75deg auto';

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

  void _deselect() {
    setState(() => _selected = null);
    _js("cameraTarget = 'auto auto auto'");
    _js("cameraOrbit = '$_defaultOrbit'");
  }

  // Builds the HTML for the dots. Each one is a <button> that model-viewer
  // pins to a spot on the model.
  String get _hotspotHtml => [
    for (final h in _vehicleHotspots)
      '<button class="hs" slot="hotspot-${h.id}" data-id="${h.id}" '
          'data-position="${h.position}" data-normal="${h.normal}">'
          '<span class="dot"></span><span class="line"></span>'
          '<span class="lbl">${h.name}</span></button>',
  ].join('\n');

  // Styles for the dots. The button itself is only the dot-sized target:
  // model-viewer pins the CENTER of this element to the 3D point, so the line
  // and label are absolutely positioned and don't shift that center.
  static const _hotspotCss = '''
    .hs { position: relative; width: 16px; height: 16px; display: block;
          padding: 0; background: none; border: none; cursor: pointer;
          transition: opacity 0.2s; }
    .hs.occluded { opacity: 0; pointer-events: none; }
    .dot { position: absolute; left: 2px; top: 2px; width: 12px; height: 12px;
           border-radius: 50%; background: #fff;
           border: 2px solid rgba(0,0,0,0.6);
           box-shadow: 0 0 0 4px rgba(255,255,255,0.35); }
    .line { position: absolute; left: 16px; top: 7px; width: 28px; height: 2px;
            background: #fff; box-shadow: 0 0 3px rgba(0,0,0,0.8); }
    .lbl { position: absolute; left: 44px; top: 0; line-height: 16px;
           white-space: nowrap; color: #fff;
           font: 600 12px/16px -apple-system, sans-serif;
           text-shadow: 0 0 4px #000, 0 0 2px #000; }
  ''';

  String get _hotspotJs {
    final spots = _vehicleHotspots
        .map(
          (h) => "'${h.id}': {t: '${h.cameraTarget}', o: '${h.cameraOrbit}'}",
        )
        .join(',');
    return '''
      const viewer = document.querySelector('model-viewer');
      const spots = {$spots};
      document.querySelectorAll('.hs').forEach((btn) => {
        btn.addEventListener('click', () => {
          const s = spots[btn.dataset.id];
          viewer.cameraTarget = s.t;
          viewer.cameraOrbit = s.o;
          HotspotChannel.postMessage(btn.dataset.id);
        });
      });

      // Hide a dot when the truck itself is blocking it. We cast a ray from
      // the camera through the dot; if it hits the truck somewhere other than
      // the dot's own spot, the dot is on the far side.
      const btns = [...document.querySelectorAll('.hs')];
      let queued = false;
      function updateVisibility() {
        queued = false;
        btns.forEach((b) => {
          const r = b.getBoundingClientRect();
          const hit = viewer.positionAndNormalFromPoint(
              r.left + r.width / 2, r.top + r.height / 2);
          const p = b.dataset.position.split(' ').map(parseFloat);
          const visible = hit &&
              Math.hypot(hit.position.x - p[0], hit.position.y - p[1],
                         hit.position.z - p[2]) < 0.12;
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
          if (match.isNotEmpty) {
            setState(() => _selected = _lastPanel = match.first);
          }
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
                  : _ModsPanel(spot: _lastPanel!, onClose: _deselect),
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
  final VoidCallback onClose;

  const _ModsPanel({required this.spot, required this.onClose});

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
                tooltip: 'Back to full view',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mods & maintenance',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
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

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
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
    );
  }
}
