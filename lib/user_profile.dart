// The account owner's profile info. Placeholder data for now — there's no
// auth/account system yet (see CLAUDE.md: account structure is explicitly
// not finalized), so this is a stand-in for the "standard profile" fields
// most apps have, editable locally like everything else in the app.

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final DateTime memberSince;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
  });

  UserProfile copyWith({String? name, String? email, String? phone}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberSince: memberSince,
    );
  }
}

// Deliberately a fake sample person, not the real account owner — this is
// placeholder UI, not a place to put anyone's real contact info, and it
// lives in source control.
final placeholderProfile = UserProfile(
  name: 'Alex Morgan',
  email: 'alex.morgan@example.com',
  phone: '(555) 012-3456',
  memberSince: DateTime(2026, 9, 1),
);
