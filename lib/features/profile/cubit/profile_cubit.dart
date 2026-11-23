import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/models/student_profile.dart';
import '../data/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.fetchProfile();
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: () => profile,
        errorMessage: () => null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: () => e.message,
      ));
    }
  }

  void startEditing() => emit(state.copyWith(
        editing: true,
        saveStatus: SaveStatus.idle,
        fieldError: () => null,
        saveError: () => null,
      ));

  void cancelEditing() => emit(state.copyWith(
        editing: false,
        fieldError: () => null,
        saveError: () => null,
      ));

  Future<void> saveRollNumber(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(fieldError: () => 'Enter your roll number.'));
      return;
    }
    if (trimmed.length > StudentProfile.maxRollNumberLength) {
      emit(state.copyWith(
        fieldError: () => 'Use at most '
            '${StudentProfile.maxRollNumberLength} characters.',
      ));
      return;
    }
    emit(state.copyWith(
      saveStatus: SaveStatus.saving,
      fieldError: () => null,
      saveError: () => null,
    ));
    try {
      final saved = await _repository.saveRollNumber(trimmed);
      emit(state.copyWith(
        saveStatus: SaveStatus.saved,
        editing: false,
        profile: () => saved.copyWith(email: state.profile?.email),
      ));
    } on ApiException catch (e) {
      final field = e.fieldErrors['rollNumber'];
      emit(state.copyWith(
        saveStatus: SaveStatus.failed,
        fieldError: () => field,
        saveError: () => field == null ? e.message : null,
      ));
    }
  }
}
