import 'package:flutter/material.dart';

import '../doctor/checks.dart';
import '../install/flutty_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'check_tile.dart';
import '../../../settings/settings_dialog.dart';
import '../../../core/ui/device_list.dart';
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
  Widget build(BuildContext context) => DeviceListSection(
    devices: controller.visibleDevices,
    selectedId: controller.selectedId,
    loading: controller.loadingDevices,
    onRefresh: controller.refreshDevices,
    onSelect: controller.select,
  );
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
