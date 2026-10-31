import 'package:flutter/material.dart';

import '../devices/mobile_device.dart';
import '../doctor/checks.dart';
import '../install/flutty_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'check_tile.dart';
import '../../../settings/settings_dialog.dart';
import 'widgets.dart';

/// 기기 탭: 연결된 기기 목록과 선택한 기기의 연결 점검.
class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key, required this.controller});

  final FluttyController controller;

  @override
  Widget build(BuildContext context) {
    final deviceChecks = only(controller.checks, {
      CheckId.connection,
      CheckId.developerMode,
      CheckId.androidAuth,
    });
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _DeviceList(controller: controller),
        if (controller.devices.isEmpty && !controller.loadingDevices)
          _NoDeviceCauses(controller: controller),
        if (deviceChecks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          CheckList(deviceChecks),
        ],
      ],
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.controller});

  final FluttyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          l10n.fdHomeDevicesTitle,
          trailing: controller.loadingDevices
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: l10n.fdHomeDevicesRefresh,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: controller.refreshDevices,
                ),
        ),
        if (controller.visibleDevices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fdHomeDevicesNone,
                    style: theme.textTheme.bodySmall,
                  ),
                  StepsBox(l10n.fdStepsNoDevice),
                ],
              ),
            ),
          )
        else
          Card(
            child: RadioGroup<String>(
              groupValue: controller.selectedId,
              onChanged: (id) {
                final d = controller.visibleDevices
                    .where((d) => d.id == id)
                    .firstOrNull;
                if (d != null) controller.select(d);
              },
              child: Column(
                children: [
                  for (final d in controller.visibleDevices)
                    RadioListTile<String>(
                      value: d.id,
                      dense: true,
                      title: Text(
                        _deviceName(l10n, d),
                        style: AppFonts.userContent,
                      ),
                      subtitle: Text(
                        [
                          _platformLabel(l10n, d.platform),
                          if (d.osVersion != null) d.osVersion!,
                          if (d.model != null && d.model != d.name) d.model!,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: InfoChip(_linkLabel(l10n, d.link)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 기기가 하나도 없을 때, 점검에서 이미 알고 있는 원인(adb·Xcode를 못 찾음)을 같이 보여 준다.
/// adb를 못 찾으면 Android 기기는 있어도 목록에 나오지 않는다.
class _NoDeviceCauses extends StatelessWidget {
  const _NoDeviceCauses({required this.controller});

  final FluttyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final causes = [
      for (final c in only(controller.checks, {CheckId.adb, CheckId.xcode}))
        if (c.status != CheckStatus.ok) c,
    ];
    if (causes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(l10n.fdHomeDevicesCauses),
          CheckList(causes),
          if (causes.any((c) => c.id == CheckId.adb))
            TextButton(
              onPressed: () =>
                  showSettingsDialog(context, initial: SettingsSection.tools),
              child: Text(l10n.fdToolPathsOpen),
            ),
        ],
      ),
    );
  }
}

/// 이 컴퓨터는 이름 대신 "이 Mac"/"이 PC"로 — 실기기 이름은 기기가 알려 준 그대로.
String _deviceName(AppLocalizations l10n, MobileDevice d) =>
    switch (d.platform) {
      DevicePlatform.macos => l10n.fdHomeThisMac,
      DevicePlatform.windows => l10n.fdHomeThisPc,
      _ => d.name,
    };

String _platformLabel(AppLocalizations l10n, DevicePlatform p) => switch (p) {
  DevicePlatform.ios => l10n.fdHomePlatformIos,
  DevicePlatform.android => l10n.fdHomePlatformAndroid,
  DevicePlatform.macos => l10n.fdHomePlatformMacos,
  DevicePlatform.windows => l10n.fdHomePlatformWindows,
};

String _linkLabel(AppLocalizations l10n, DeviceLink l) => switch (l) {
  DeviceLink.usb => l10n.fdHomeLinkUsb,
  DeviceLink.wireless => l10n.fdHomeLinkWireless,
  DeviceLink.local => l10n.fdHomeLinkLocal,
};
