import 'package:equatable/equatable.dart';

/// `GET /student-profile`. Name and class are school-managed (read-only);
/// only the roll number is student-editable.
class StudentProfile extends Equatable {
  const StudentProfile({
    required this.fullName,
    this.className,
    this.rollNumber,
    this.firstRunCompleted = false,
    this.email,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        fullName: json['fullName'] as String? ?? '',
        className: json['className'] as String?,
        rollNumber: json['rollNumber'] as String?,
        firstRunCompleted: json['firstRunCompleted'] as bool? ?? false,
      );

  /// Max roll number length enforced by the backend.
  static const int maxRollNumberLength = 32;

  final String fullName;
  final String? className;
  final String? rollNumber;
  final bool firstRunCompleted;

  /// Sign-in email, from `GET /auth/me`.
  final String? email;

  /// `AR` for "Alex Ramos".
  String get initials {
    final parts =
        fullName.split(RegExp(r'[\s\-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  StudentProfile copyWith({String? email, String? rollNumber}) =>
      StudentProfile(
        fullName: fullName,
        className: className,
        rollNumber: rollNumber ?? this.rollNumber,
        firstRunCompleted: firstRunCompleted,
        email: email ?? this.email,
      );

  @override
  List<Object?> get props =>
      [fullName, className, rollNumber, firstRunCompleted, email];
}
