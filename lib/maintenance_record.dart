// Data model for the maintenance log, plus placeholder records.
// (Java parallel: think of these as plain classes with final fields and
// getters. Dart's `const` constructors make instances immutable.)

// Money is stored as whole cents (int) rather than double, so totals never
// pick up floating-point rounding errors. Same reason Java devs use
// BigDecimal / cents for currency.

/// One line on an itemized report, e.g. "Brake pads (front set)  1 x $89.99".
class LineItem {
  final String description;
  final int quantity;
  final int unitCents;

  const LineItem(this.description, this.unitCents, {this.quantity = 1});

  int get totalCents => quantity * unitCents;
}

/// A mod is something added or upgraded; maintenance is upkeep/repair.
enum RecordKind { maintenance, mod }

/// Where the record came from. Kept from day one so the UI can later tell
/// shop-verified history apart from self-reported entries.
enum RecordSource { userEntered, shopVerified }

class MaintenanceRecord {
  final String id;
  final String title; // what was done
  final String
  part; // which part of the vehicle, e.g. "Wheels & Brakes › Brakes"
  final RecordKind kind;
  final DateTime date; // date and time of the service
  final int mileage;
  final String performedBy;
  final RecordSource source;
  final List<LineItem> items;
  final String notes;
  // Which kind of service this was (an id from the reference data, e.g.
  // 'oil_change'), so the app can find things like the last oil change.
  // Null when it doesn't match a known type.
  final String? serviceTypeId;

  const MaintenanceRecord({
    required this.id,
    required this.title,
    required this.part,
    required this.kind,
    required this.date,
    required this.mileage,
    required this.performedBy,
    required this.items,
    this.source = RecordSource.userEntered,
    this.notes = '',
    this.serviceTypeId,
  });

  int get totalCents => items.fold(0, (sum, item) => sum + item.totalCents);
}

// ---- Formatting helpers (no intl package needed for these basics) ----

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String monthAbbreviation(int month) => _months[month - 1];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String formatTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $suffix';
}

String formatDateTime(DateTime d) => '${formatDate(d)} · ${formatTime(d)}';

String formatMoney(int cents) {
  final dollars = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  final withCommas = dollars.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '\$$withCommas.$rest';
}

// A short "how long ago" phrase for the vehicle header, e.g. "3 months ago".
// Lowercase so it reads naturally after a lead-in like "Last service ...".
String relativeTimeAgo(DateTime date, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 30) return '$days days ago';
  final months = (days / 30.4375).round();
  if (months < 12) return months == 1 ? '1 month ago' : '$months months ago';
  final years = (days / 365.25).round();
  return years == 1 ? '1 year ago' : '$years years ago';
}

String formatMiles(int miles) {
  final withCommas = miles.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$withCommas mi';
}

// ---- Placeholder data (newest first) ----
// These mirror the placeholder mods/maintenance on the My Vehicle page.
// Later this will be replaced by real records from local storage.

final placeholderRecords = <MaintenanceRecord>[
  MaintenanceRecord(
    id: 'r11',
    serviceTypeId: 'brake_fluid',
    title: 'Brake fluid flush',
    part: 'Wheels & Brakes › Brakes',
    kind: RecordKind.maintenance,
    date: DateTime(2026, 6, 18, 16, 40),
    mileage: 41950,
    performedBy: 'Placeholder Auto Care',
    source: RecordSource.shopVerified,
    items: const [
      LineItem('DOT 3 brake fluid', 1800, quantity: 2),
      LineItem('Labor (1.0 hr)', 9500),
      LineItem('Shop supplies', 750),
    ],
    notes: 'Fluid was dark. Recommend repeating every 2 years.',
  ),
  MaintenanceRecord(
    id: 'r10',
    title: 'Brake pad replacement',
    part: 'Wheels & Brakes › Brakes',
    kind: RecordKind.maintenance,
    date: DateTime(2026, 6, 18, 15, 15),
    mileage: 41950,
    performedBy: 'Placeholder Auto Care',
    source: RecordSource.shopVerified,
    items: const [
      LineItem('Front brake pads (set)', 8999),
      LineItem('Rotor resurfacing', 3000, quantity: 2),
      LineItem('Labor (1.5 hr)', 14250),
    ],
    notes: 'Front pads at roughly 2 mm. Rear pads checked, about 60% left.',
  ),
  MaintenanceRecord(
    id: 'r12',
    serviceTypeId: 'oil_change',
    title: 'Oil & filter change',
    part: 'Engine',
    kind: RecordKind.maintenance,
    date: DateTime(2026, 3, 12, 9, 30),
    mileage: 39100,
    performedBy: 'DIY',
    items: const [
      LineItem('0W-20 synthetic oil (per qt)', 799, quantity: 6),
      LineItem('Oil filter', 899),
    ],
    notes: 'Reset the oil maintenance reminder afterward.',
  ),
  MaintenanceRecord(
    id: 'r09',
    serviceTypeId: 'tire_rotation',
    title: 'Tire rotation',
    part: 'Wheels & Brakes › Wheel',
    kind: RecordKind.maintenance,
    date: DateTime(2026, 3, 5, 10, 20),
    mileage: 38900,
    performedBy: 'DIY',
    items: const [LineItem('Tire rotation (own tools)', 0)],
    notes: 'Rotated front-to-back. Set pressure to 35 psi.',
  ),
  MaintenanceRecord(
    id: 'r08',
    title: 'Bulb replacement',
    part: 'Rear › Brake lights',
    kind: RecordKind.maintenance,
    date: DateTime(2026, 2, 11, 18, 5),
    mileage: 37600,
    performedBy: 'DIY',
    items: const [LineItem('Brake light bulb', 899, quantity: 2)],
    notes: 'Driver-side brake light was out. Replaced both for matching color.',
  ),
  MaintenanceRecord(
    id: 'r07',
    title: 'All-terrain tires',
    part: 'Wheels & Brakes › Wheel',
    kind: RecordKind.mod,
    date: DateTime(2026, 1, 9, 13, 30),
    mileage: 36200,
    performedBy: 'Placeholder Tire & Wheel',
    source: RecordSource.shopVerified,
    items: const [
      LineItem('All-terrain tire 265/70R16', 22999, quantity: 4),
      LineItem('Mount & balance', 2500, quantity: 4),
      LineItem('Valve stems', 400, quantity: 4),
      LineItem('Old tire disposal', 300, quantity: 4),
    ],
    notes: 'Replaced the stock highway tires.',
  ),
  MaintenanceRecord(
    id: 'r06',
    title: 'Tailgate lock',
    part: 'Rear › Tailgate',
    kind: RecordKind.maintenance,
    date: DateTime(2025, 12, 2, 9, 10),
    mileage: 34800,
    performedBy: 'DIY',
    items: const [LineItem('Tailgate lock cylinder', 4599)],
    notes: 'Old lock was sticking in cold weather.',
  ),
  MaintenanceRecord(
    id: 'r05',
    title: 'Tailgate assist damper',
    part: 'Rear › Tailgate',
    kind: RecordKind.mod,
    date: DateTime(2025, 11, 15, 11, 0),
    mileage: 33900,
    performedBy: 'DIY',
    items: const [LineItem('Tailgate assist damper kit', 3499)],
    notes: 'Tailgate now lowers slowly instead of dropping.',
  ),
  MaintenanceRecord(
    id: 'r04',
    title: 'Tonneau cover',
    part: 'Rear › Bed',
    kind: RecordKind.mod,
    date: DateTime(2025, 10, 4, 14, 45),
    mileage: 32100,
    performedBy: 'DIY',
    items: const [
      LineItem('Roll-up tonneau cover', 24999),
      LineItem('Shipping', 1500),
    ],
  ),
  MaintenanceRecord(
    id: 'r03',
    title: 'Spray-in bed liner',
    part: 'Rear › Bed',
    kind: RecordKind.mod,
    date: DateTime(2025, 9, 20, 8, 30),
    mileage: 31500,
    performedBy: 'Placeholder Truck Accessories',
    source: RecordSource.shopVerified,
    items: const [
      LineItem('Spray-in liner (materials)', 34000),
      LineItem('Labor (3.0 hr)', 27000),
    ],
    notes: '3-year warranty on the coating.',
  ),
  MaintenanceRecord(
    id: 'r02',
    title: 'Smoked LED tail lights',
    part: 'Rear › Brake lights',
    kind: RecordKind.mod,
    date: DateTime(2025, 8, 30, 17, 20),
    mileage: 30700,
    performedBy: 'DIY',
    items: const [
      LineItem('Smoked LED tail light pair', 28900),
      LineItem('Wiring adapter', 1999),
    ],
  ),
  MaintenanceRecord(
    id: 'r01',
    title: '35% window tint',
    part: 'Windows & Tint',
    kind: RecordKind.mod,
    date: DateTime(2025, 8, 9, 15, 0),
    mileage: 29800,
    performedBy: 'Placeholder Tint Co.',
    source: RecordSource.shopVerified,
    items: const [
      LineItem('35% ceramic tint film', 14000),
      LineItem('Labor (2.5 hr)', 11000),
    ],
    notes: 'Front side windows only. Windshield strip not included.',
  ),
];
