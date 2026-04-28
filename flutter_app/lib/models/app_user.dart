class AppUser {
  final String id;
  final String? companyId;
  final String role;
  final String email;
  final String? fullName;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.companyId,
    this.role = 'admin',
    required this.email,
    this.fullName,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'],
    companyId: j['company_id'],
    role: j['role'] ?? 'admin',
    email: j['email'] ?? '',
    fullName: j['full_name'],
    createdAt: DateTime.parse(j['created_at']),
  );
}
