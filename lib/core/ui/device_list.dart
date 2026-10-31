// 연결된 기기 목록 카드: 제목 + 새로 고침 + 라디오 목록. Flutty 칸과 Gradle 칸이 함께 쓴다.
// 상태(기기 목록·선택)는 각 칸의 컨트롤러가 갖고 여기는 그리기만 한다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../devices/mobile_device.dart';
import 'info_chip.dart';
import 'section_widgets.dart';

class DeviceListSection extends StatelessWidget {
  const DeviceListSection({
    super.key,
    required this.devices,
    required this.selectedId,
    required this.loading,
    required this.onRefresh,
    required this.onSelect,
  });

  final List<MobileDevice> devices;
  final String? selectedId;
  final bool loading;
  final VoidCallback onRefresh;
  final ValueChanged<MobileDevice> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          l10n.fdHomeDevicesTitle,
          trailing: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: l10n.fdHomeDevicesRefresh,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: onRefresh,
                ),
        ),
        if (devices.isEmpty)
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
              groupValue: selectedId,
              onChanged: (id) {
                final d = devices.where((d) => d.id == id).firstOrNull;
                if (d != null) onSelect(d);
              },
              child: Column(
                children: [
                  for (final d in devices)
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
