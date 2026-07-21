import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// List tile for audit trail entry showing action, resource, timestamp, user.
class AuditEntryTile extends StatelessWidget {
  const AuditEntryTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  final AuditEntry entry;
  final VoidCallback? onTap;

  Color _actionColor(AuditAction action) {
    return switch (action) {
      AuditAction.create => AppColors.success,
      AuditAction.update => AppColors.info,
      AuditAction.delete => AppColors.error,
      AuditAction.login => AppColors.info,
      AuditAction.logout => const Color(0xFF6B7280),
      AuditAction.export => const Color(0xFF0891B2),
      AuditAction.import => const Color(0xFF8B5CF6),
      AuditAction.approve => AppColors.success,
      AuditAction.reject => AppColors.error,
      AuditAction.archive => AppColors.warning,
      AuditAction.restore => AppColors.info,
      AuditAction.permissionChange => AppColors.warning,
      AuditAction.roleChange => AppColors.warning,
      AuditAction.passwordChange => AppColors.warning,
      AuditAction.mfaEnable => AppColors.success,
      AuditAction.mfaDisable => AppColors.error,
      AuditAction.sessionInvalidate => AppColors.warning,
      AuditAction.apiKeyCreate => AppColors.success,
      AuditAction.apiKeyRevoke => AppColors.error,
      AuditAction.read => const Color(0xFF6B7280),
    };
  }

  IconData _actionIcon(AuditAction action) {
    return switch (action) {
      AuditAction.create => Icons.add_circle_outline_rounded,
      AuditAction.update => Icons.edit_rounded,
      AuditAction.delete => Icons.delete_outline_rounded,
      AuditAction.login => Icons.login_rounded,
      AuditAction.logout => Icons.logout_rounded,
      AuditAction.export => Icons.upload_file_rounded,
      AuditAction.import => Icons.download_rounded,
      AuditAction.approve => Icons.check_circle_outline_rounded,
      AuditAction.reject => Icons.cancel_rounded,
      AuditAction.archive => Icons.archive_outlined,
      AuditAction.restore => Icons.restore_rounded,
      AuditAction.permissionChange => Icons.admin_panel_settings_outlined,
      AuditAction.roleChange => Icons.swap_horiz_rounded,
      AuditAction.passwordChange => Icons.password_rounded,
      AuditAction.mfaEnable => Icons.security_rounded,
      AuditAction.mfaDisable => Icons.security_outlined,
      AuditAction.sessionInvalidate => Icons.phonelink_erase_rounded,
      AuditAction.apiKeyCreate => Icons.vpn_key_rounded,
      AuditAction.apiKeyRevoke => Icons.vpn_key_off_rounded,
      AuditAction.read => Icons.visibility_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final color = _actionColor(entry.action);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDarkMode ? 0.20 : 0.12),
          borderRadius: Spacings.borderRadiusSm,
        ),
        child: Icon(_actionIcon(entry.action), size: Spacings.mdIcon, color: color),
      ),
      title: Row(
        children: [
          Text(
            entry.action.label,
            style: tt.bodyMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            entry.resourceType,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Text(
        '${entry.userId} · ${_formatDate(entry.timestamp)}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: onTap != null ? Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant) : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
