import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:openreads/core/helpers/backup/backup_helpers.dart';
import 'package:openreads/logic/bloc/migration_v1_to_v2_bloc/migration_v1_to_v2_bloc.dart';
import 'package:openreads/generated/locale_keys.g.dart';
import 'package:openreads/logic/bloc/theme_bloc/theme_bloc.dart';
import 'package:openreads/logic/cubit/backup_progress_cubit.dart';
import 'package:openreads/ui/welcome_screen/widgets/widgets.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';

class SettingsBackupScreen extends StatefulWidget {
  SettingsBackupScreen({
    super.key,
    this.autoMigrationV1ToV2 = false,
  });

  bool autoMigrationV1ToV2;

  @override
  State<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends State<SettingsBackupScreen> {
  bool _creatingLocal = false;
  bool _creatingCloud = false;
  bool _restoringLocal = false;
  bool _exportingCSV = false;
  bool _importingGoodreadsCSV = false;

  late DeviceInfoPlugin deviceInfo;
  late AndroidDeviceInfo androidInfo;

  _startCreatingLocalBackup(context) async {
    setState(() => _creatingLocal = true);

    if (androidInfo.version.sdkInt < 30) {
      await BackupGeneral.requestStoragePermission(context);
      await BackupExport.createLocalBackupLegacyStorage(context);
    } else {
      await BackupExport.createLocalBackup(context);
    }

    setState(() => _creatingLocal = false);
  }

  _startExportingCSV(context) async {
    setState(() => _exportingCSV = true);

    if (androidInfo.version.sdkInt < 30) {
      await BackupGeneral.requestStoragePermission(context);
      await CSVExport.exportCSVLegacyStorage(context);
    } else {
      await CSVExport.exportCSV();
    }

    setState(() => _exportingCSV = false);
  }

  _startImportingGoodreadsCSV(context) async {
    setState(() => _importingGoodreadsCSV = true);

    if (androidInfo.version.sdkInt < 30) {
      await BackupGeneral.requestStoragePermission(context);
      await CSVGoodreadsImport.importGoodreadsCSVLegacyStorage(context);
    } else {
      await CSVGoodreadsImport.importGoodreadsCSV(context);
    }

    setState(() => _importingGoodreadsCSV = false);
  }

  _startCreatingCloudBackup(context) async {
    setState(() => _creatingCloud = true);

    final tmpBackupPath = await BackupExport.prepareTemporaryBackup(context);
    if (tmpBackupPath == null) return;

    Share.shareXFiles([
      XFile(tmpBackupPath),
    ]);

    setState(() => _creatingCloud = false);
  }

  _startRestoringLocalBackup(context) async {
    setState(() => _restoringLocal = true);

    if (androidInfo.version.sdkInt < 30) {
      await BackupGeneral.requestStoragePermission(context);
      await BackupImport.restoreLocalBackupLegacyStorage(context);
    } else {
      await BackupImport.restoreLocalBackup(context);
    }

    setState(() => _restoringLocal = false);
  }

  _startMigratingV1ToV2() {
    BlocProvider.of<MigrationV1ToV2Bloc>(context).add(
      StartMigration(context: context, retrigger: true),
    );
  }

  initDeviceInfoPlugin() async {
    androidInfo = await DeviceInfoPlugin().androidInfo;
  }

  @override
  void initState() {
    initDeviceInfoPlugin();
    super.initState();
  }

  @override
  Widget build(BuildContext originalContext) {
    return BlocProvider(
      create: (context) => BackupProgressCubit(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              LocaleKeys.backup.tr(),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          body: Column(
            children: [
              BlocBuilder<BackupProgressCubit, String?>(
                builder: (context, state) {
                  if (state == null) return const SizedBox();

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LinearProgressIndicator(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: Text(
                                state,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    late final bool amoledDark;

                    if (state is SetThemeState) {
                      amoledDark = state.amoledDark;
                    } else {
                      amoledDark = false;
                    }

                    return SettingsList(
                      contentPadding: const EdgeInsets.only(top: 10),
                      darkTheme: SettingsThemeData(
                        settingsListBackground: amoledDark
                            ? Colors.black
                            : Theme.of(context).colorScheme.surface,
                      ),
                      lightTheme: SettingsThemeData(
                        settingsListBackground:
                            Theme.of(context).colorScheme.surface,
                      ),
                      sections: [
                        SettingsSection(
                          title: Text(
                            LocaleKeys.openreads_backup.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          tiles: <SettingsTile>[
                            _buildCreateLocalBackup(),
                            _buildCreateCloudBackup(),
                            _buildRestoreBackup(context),
                            _buildV1ToV2Migration(context),
                          ],
                        ),
                        SettingsSection(
                          title: Text(
                            LocaleKeys.csv.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          tiles: <SettingsTile>[
                            _buildExportAsCSV(),
                            _buildImportGoodreadsCSV(),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              BlocBuilder<MigrationV1ToV2Bloc, MigrationV1ToV2State>(
                builder: (context, migrationState) {
                  if (migrationState is MigrationOnging) {
                    return MigrationNotification(
                      done: migrationState.done,
                      total: migrationState.total,
                    );
                  } else if (migrationState is MigrationFailed) {
                    return MigrationNotification(
                      error: migrationState.error,
                    );
                  } else if (migrationState is MigrationSucceded) {
                    return const MigrationNotification(
                      success: true,
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  SettingsTile _buildV1ToV2Migration(BuildContext context) {
    return SettingsTile(
      title: Text(
        LocaleKeys.migration_v1_to_v2_retrigger.tr(),
        style: TextStyle(
          fontSize: 16,
          color: widget.autoMigrationV1ToV2
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      leading: Icon(
        FontAwesomeIcons.wrench,
        color: widget.autoMigrationV1ToV2
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      description: Text(
        LocaleKeys.migration_v1_to_v2_retrigger_description.tr(),
        style: TextStyle(
          color: widget.autoMigrationV1ToV2
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      onPressed: (context) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                LocaleKeys.are_you_sure.tr(),
              ),
              content: Text(
                LocaleKeys.restore_backup_alert_content.tr(),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                FilledButton.tonal(
                  onPressed: () {
                    _startMigratingV1ToV2();
                    Navigator.of(context).pop();
                  },
                  child: Text(LocaleKeys.yes.tr()),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LocaleKeys.no.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  SettingsTile _buildRestoreBackup(BuildContext builderContext) {
    return SettingsTile(
      title: Text(
        LocaleKeys.restore_backup.tr(),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: (_restoringLocal)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          : const Icon(FontAwesomeIcons.arrowUpFromBracket),
      description: Text(
        '${LocaleKeys.restore_backup_description_1.tr()}\n${LocaleKeys.restore_backup_description_2.tr()}',
      ),
      onPressed: (context) {
        showDialog(
          context: context,
          builder: (context) {
            return Builder(builder: (context) {
              return AlertDialog(
                title: Text(
                  LocaleKeys.are_you_sure.tr(),
                ),
                content: Text(
                  LocaleKeys.restore_backup_alert_content.tr(),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  FilledButton.tonal(
                    onPressed: () {
                      _startRestoringLocalBackup(builderContext);
                      Navigator.of(context).pop();
                    },
                    child: Text(LocaleKeys.yes.tr()),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(LocaleKeys.no.tr()),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  SettingsTile _buildCreateCloudBackup() {
    return SettingsTile(
      title: Text(
        LocaleKeys.create_cloud_backup.tr(),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: (_creatingCloud)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          : const Icon(FontAwesomeIcons.cloudArrowUp),
      description: Text(
        LocaleKeys.create_cloud_backup_description.tr(),
      ),
      onPressed: _startCreatingCloudBackup,
    );
  }

  SettingsTile _buildCreateLocalBackup() {
    return SettingsTile(
      title: Text(
        LocaleKeys.create_local_backup.tr(),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: (_creatingLocal)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          : const Icon(FontAwesomeIcons.solidFloppyDisk),
      description: Text(
        LocaleKeys.create_local_backup_description.tr(),
      ),
      onPressed: _startCreatingLocalBackup,
    );
  }

  SettingsTile _buildExportAsCSV() {
    return SettingsTile(
      title: Text(
        LocaleKeys.export_csv.tr(),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: (_exportingCSV)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          : const Icon(FontAwesomeIcons.fileCsv),
      description: Text(
        LocaleKeys.export_csv_description_1.tr(),
      ),
      onPressed: _startExportingCSV,
    );
  }

  SettingsTile _buildImportGoodreadsCSV() {
    return SettingsTile(
      title: Text(
        LocaleKeys.import_goodreads_csv.tr(),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      leading: (_importingGoodreadsCSV)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          : const Icon(FontAwesomeIcons.g),
      onPressed: _startImportingGoodreadsCSV,
    );
  }
}
