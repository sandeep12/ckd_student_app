part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, failure }

enum SaveStatus { idle, saving, saved, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.editing = false,
    this.saveStatus = SaveStatus.idle,
    this.fieldError,
    this.saveError,
  });

  final ProfileStatus status;
  final StudentProfile? profile;
  final String? errorMessage;

  /// Roll-number edit mode.
  final bool editing;
  final SaveStatus saveStatus;
  final String? fieldError;
  final String? saveError;

  bool get isLoading =>
      status == ProfileStatus.initial || status == ProfileStatus.loading;

  ProfileState copyWith({
    ProfileStatus? status,
    StudentProfile? Function()? profile,
    String? Function()? errorMessage,
    bool? editing,
    SaveStatus? saveStatus,
    String? Function()? fieldError,
    String? Function()? saveError,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile != null ? profile() : this.profile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      editing: editing ?? this.editing,
      saveStatus: saveStatus ?? this.saveStatus,
      fieldError: fieldError != null ? fieldError() : this.fieldError,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        errorMessage,
        editing,
        saveStatus,
        fieldError,
        saveError,
      ];
}
