import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_exception.dart';
import '../cubit/profile_cubit.dart';
import '../data/models/student_profile.dart';
import '../data/profile_repository.dart';

/// Profile (Figma 10 web / 11 mobile). Expects [ProfileCubit] and a
/// [ProfileRepository] (for change password) above it.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.wide,
    required this.onSignOut,
    this.schoolName,
  });

  final bool wide;
  final VoidCallback onSignOut;

  /// For the "records come from …" footnote.
  final String? schoolName;

  static const double _twoColumnsFrom = 760;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => a.saveStatus != b.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == SaveStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated.')),
          );
        }
      },
      builder: (context, state) {
        final pad = wide ? DsSpacing.layoutPageMargin : DsSpacing.insetLg;
        final cubit = context.read<ProfileCubit>();
        if (state.isLoading && state.profile == null) {
          return const Center(
            child: CircularProgressIndicator(color: DsColors.actionPrimaryBg),
          );
        }
        final profile = state.profile;
        if (profile == null) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: DsEmptyState(
              tone: DsEmptyStateTone.danger,
              icon: Icons.error_outline,
              title: 'Couldn’t load your profile',
              message: state.errorMessage ??
                  'Something went wrong. Check your connection and try again.',
              action: DsButton(
                label: 'Try again',
                size: DsButtonSize.md,
                expand: false,
                onPressed: cubit.load,
              ),
            ),
          );
        }

        final personal = _Section(
          title: 'Personal details',
          child: _PersonalCard(state: state, profile: profile, wide: wide),
        );
        final prefs = _Section(
          title: wide ? 'Preferences and security' : 'Preferences',
          child: _DetailCard(
            children: [
              DsDetailRow(
                iconAsset: DsAssets.icLock,
                label: 'Password',
                value: 'Change your password',
                showDivider: false,
                onTap: () => _ChangePasswordDialog.show(context),
              ),
            ],
          ),
        );
        final footnote = Text(
          'Your name and class come from '
          '${schoolName?.isNotEmpty == true ? '$schoolName’s' : 'your school’s'}'
          ' student records. Ask your class adviser to correct them.',
          style: DsTypography.caption.copyWith(color: DsColors.textSecondary),
        );
        final logout = DsButton(
          label: 'Log out',
          size: wide ? DsButtonSize.md : DsButtonSize.lg,
          tone: DsButtonTone.secondary,
          expand: !wide,
          onPressed: onSignOut,
        );

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: wide
                  ? [
                      Text('Profile', style: DsTypography.h1),
                      const SizedBox(height: DsSpacing.stackXs),
                      Text(
                        'Your account details. Scanning and uploading answer '
                        'sheets happen in the CKD mobile app.',
                        style: DsTypography.body
                            .copyWith(color: DsColors.textSecondary),
                      ),
                      const SizedBox(height: DsSpacing.layoutSectionGap),
                      _IdentityCard(profile: profile),
                      const SizedBox(height: DsSpacing.layoutSectionGap),
                      LayoutBuilder(
                        builder: (context, c) => c.maxWidth < _twoColumnsFrom
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  personal,
                                  const SizedBox(
                                      height: DsSpacing.layoutSectionGap),
                                  prefs,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: personal),
                                  const SizedBox(width: DsSpacing.layoutGutter),
                                  Expanded(child: prefs),
                                ],
                              ),
                      ),
                      const SizedBox(height: DsSpacing.layoutSectionGap),
                      Row(
                        children: [
                          Expanded(child: footnote),
                          const SizedBox(width: DsSpacing.inlineLg),
                          logout,
                        ],
                      ),
                    ]
                  : [
                      _MobileIdentity(profile: profile),
                      const SizedBox(height: DsSpacing.layoutSectionGap),
                      personal,
                      const SizedBox(height: DsSpacing.layoutSectionGap),
                      prefs,
                      const SizedBox(height: DsSpacing.stackLg),
                      footnote,
                      const SizedBox(height: DsSpacing.stackLg),
                      logout,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Card wrapping a stack of [DsDetailRow]s (clips the rows to the radius).
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadii.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: DsTypography.h4),
          const SizedBox(height: DsSpacing.stackSm),
          child,
        ],
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        children: [
          DsAvatar(initials: profile.initials, large: true),
          const SizedBox(width: DsSpacing.inlineLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: DsTypography.h3),
                if (_eyebrow(profile) case final eyebrow?) ...[
                  const SizedBox(height: DsSpacing.stackXs),
                  Text(
                    eyebrow,
                    style: DsTypography.overline
                        .copyWith(color: DsColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.inlineLg),
          const DsBadge(label: 'Active', tone: DsBadgeTone.success),
        ],
      ),
    );
  }
}

/// `ROLL NO · 11-SI-24 · GRADE 11`.
String? _eyebrow(StudentProfile p) {
  final parts = [
    if (p.rollNumber != null) 'ROLL NO · ${p.rollNumber}',
    if (p.className != null) p.className!,
  ];
  return parts.isEmpty ? null : parts.join(' · ').toUpperCase();
}

class _MobileIdentity extends StatelessWidget {
  const _MobileIdentity({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DsAvatar(initials: profile.initials, large: true),
        const SizedBox(height: DsSpacing.stackMd),
        Text(
          profile.fullName,
          style: DsTypography.h3,
          textAlign: TextAlign.center,
        ),
        if (_eyebrow(profile) case final eyebrow?) ...[
          const SizedBox(height: DsSpacing.stackXs),
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: DsTypography.overline.copyWith(color: DsColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({
    required this.state,
    required this.profile,
    required this.wide,
  });

  final ProfileState state;
  final StudentProfile profile;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return _DetailCard(
      children: [
        if (profile.email != null)
          DsDetailRow(
            iconAsset: DsAssets.icMail,
            label: 'Email address',
            value: profile.email!,
          ),
        DsDetailRow(
          iconAsset: DsAssets.icGraduationCap,
          label: 'Class',
          value: profile.className ?? 'Not assigned yet',
        ),
        if (state.editing)
          _RollNumberEditor(state: state, wide: wide)
        else
          DsDetailRow(
            iconAsset: DsAssets.icClipboardList,
            label: 'Roll number',
            value: profile.rollNumber ?? 'Not set',
            showDivider: false,
            trailing: DsLink(
              label: profile.rollNumber == null ? 'Add' : 'Change',
              onTap: cubit.startEditing,
            ),
          ),
      ],
    );
  }
}

class _RollNumberEditor extends StatefulWidget {
  const _RollNumberEditor({required this.state, required this.wide});

  final ProfileState state;
  final bool wide;

  @override
  State<_RollNumberEditor> createState() => _RollNumberEditorState();
}

class _RollNumberEditorState extends State<_RollNumberEditor> {
  late final _controller =
      TextEditingController(text: widget.state.profile?.rollNumber ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final saving = widget.state.saveStatus == SaveStatus.saving;
    return Padding(
      padding: const EdgeInsets.all(DsSpacing.insetMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.state.saveError != null) ...[
            DsDangerBanner(
              title: 'Couldn’t save your profile',
              message: widget.state.saveError!,
            ),
            const SizedBox(height: DsSpacing.stackMd),
          ],
          DsTextField(
            label: 'Roll number',
            controller: _controller,
            errorText: widget.state.fieldError,
            enabled: !saving,
            size: widget.wide ? DsFieldSize.md : DsFieldSize.lg,
            textInputAction: TextInputAction.done,
            onSubmitted: cubit.saveRollNumber,
          ),
          const SizedBox(height: DsSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DsButton(
                label: 'Cancel',
                size: DsButtonSize.md,
                tone: DsButtonTone.secondary,
                expand: false,
                onPressed: saving ? null : cubit.cancelEditing,
              ),
              const SizedBox(width: DsSpacing.inlineSm),
              DsButton(
                label: 'Save',
                size: DsButtonSize.md,
                expand: false,
                loading: saving,
                onPressed: () => cubit.saveRollNumber(_controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.repository});

  final ProfileRepository repository;

  static Future<void> show(BuildContext context) async {
    final repository = context.read<ProfileRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(repository: repository),
    );
    if (changed == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed. Other devices have been signed out.',
          ),
        ),
      );
    }
  }

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = <String, String>{
      if (_current.text.isEmpty)
        'currentPassword': 'Enter your current password.',
      if (_next.text.isEmpty) 'newPassword': 'Enter a new password.',
      if (_next.text.isNotEmpty && _confirm.text != _next.text)
        'confirm': 'Passwords don’t match.',
    };
    setState(() {
      _fieldErrors = errors;
      _error = null;
    });
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.repository.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DsColors.surfaceOverlay,
      title: Text('Change password', style: DsTypography.h4),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                DsDangerBanner(message: _error!),
                const SizedBox(height: DsSpacing.stackMd),
              ],
              DsTextField(
                label: 'Current password',
                controller: _current,
                obscureText: true,
                enabled: !_saving,
                errorText: _fieldErrors['currentPassword'],
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: DsSpacing.stackMd),
              DsTextField(
                label: 'New password',
                controller: _next,
                obscureText: true,
                enabled: !_saving,
                errorText: _fieldErrors['newPassword'],
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: DsSpacing.stackMd),
              DsTextField(
                label: 'Confirm new password',
                controller: _confirm,
                obscureText: true,
                enabled: !_saving,
                errorText: _fieldErrors['confirm'],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        DsButton(
          label: 'Cancel',
          size: DsButtonSize.md,
          tone: DsButtonTone.secondary,
          expand: false,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        DsButton(
          label: 'Change password',
          size: DsButtonSize.md,
          expand: false,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
