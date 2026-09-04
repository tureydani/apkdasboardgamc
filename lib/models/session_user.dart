/// Refleja el objeto `user` que devuelve GET /api/auth/session en el backend
/// (ver src/lib/auth/config.ts callbacks.session del proyecto Next.js).
class SessionUser {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String firstName;
  final String lastName;
  final String role; // "INSTITUTION" | "CITIZEN"
  final String? privilegeCode; // CENTRAL_ADMIN, CENTRAL_OPERATOR, DISPATCHER, INSTITUTION_ADMIN, INSTITUTION_OPERATOR
  final String? privilegeName;
  final int? institutionId;
  final int? subinstitutionId;

  SessionUser({
    required this.id,
    this.email,
    this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.privilegeCode,
    this.privilegeName,
    this.institutionId,
    this.subinstitutionId,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isCentral =>
      privilegeCode == 'CENTRAL_ADMIN' ||
      privilegeCode == 'CENTRAL_OPERATOR' ||
      privilegeCode == 'DISPATCHER';

  bool get isAdmin =>
      privilegeCode == 'CENTRAL_ADMIN' || privilegeCode == 'INSTITUTION_ADMIN';

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'].toString(),
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? 'INSTITUTION',
      privilegeCode: json['privilegeCode'] as String?,
      privilegeName: json['privilegeName'] as String?,
      institutionId: json['institutionId'] as int?,
      subinstitutionId: json['subinstitutionId'] as int?,
    );
  }
}
