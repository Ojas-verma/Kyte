import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/member.dart';
import '../providers/member_provider.dart';
import 'add_member_screen.dart';
import '../utils/app_theme.dart';

Future<void> showMemberProfileSheet(
  BuildContext context,
  Member member,
  List<Member> members,
) {
  final rootContext = context;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final managerName = _resolveManagerName(member, members);
          final directReports =
              members
                  .where((candidate) => candidate.managerId == member.id)
                  .toList()
                ..sort((left, right) => left.name.compareTo(right.name));

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF1E3A5F), width: 1),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.accentBlue.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage:
                          member.photoUrl != null && member.photoUrl!.isNotEmpty
                          ? NetworkImage(member.photoUrl!)
                          : null,
                      child:
                          member.photoUrl != null && member.photoUrl!.isNotEmpty
                          ? null
                          : Text(
                              member.name.isEmpty
                                  ? '?'
                                  : member.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.role,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Pill(
                                label: member.department,
                                color: AppTheme.accentBlue,
                              ),
                              _Pill(label: member.team, color: Colors.teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Member ID',
                      value: member.id,
                    ),
                    _InfoRow(
                      icon: Icons.apartment_outlined,
                      label: 'Department',
                      value: member.department,
                    ),
                    _InfoRow(
                      icon: Icons.groups_rounded,
                      label: 'Team',
                      value: member.team,
                    ),
                    _InfoRow(
                      icon: Icons.account_tree_outlined,
                      label: 'Reports to',
                      value: managerName,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Direct Reports (${directReports.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (directReports.isEmpty)
                  Text(
                    'No direct reports yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: directReports
                        .map(
                          (report) => _ReportChip(
                            label: report.name,
                            subtitle: report.role,
                            color: _departmentColor(report.department),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(rootContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AddMemberScreen(member: member),
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final shouldDelete = await _showDeleteConfirmation(
                            context: context,
                            member: member,
                          );
                          if (!shouldDelete || !context.mounted) {
                            return;
                          }

                          await rootContext.read<MemberProvider>().deleteSubtree(member.id);
                          if (!rootContext.mounted) {
                            return;
                          }

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(content: Text('${member.name} deleted')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _resolveManagerName(Member member, List<Member> members) {
  if (member.managerId == null) {
    return 'Root node';
  }

  Member? manager;
  for (final candidate in members) {
    if (candidate.id == member.managerId) {
      manager = candidate;
      break;
    }
  }
  return manager?.name ?? 'Manager missing';
}

Future<bool> _showDeleteConfirmation({
  required BuildContext context,
  required Member member,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('Delete member?'),
        content: Text(
          'This will also delete ${member.name} and all of their subordinates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Color _departmentColor(String department) {
  switch (department.toLowerCase()) {
    case 'engineering':
      return const Color(0xFF6366F1);
    case 'marketing':
      return const Color(0xFF10B981);
    case 'hr':
    case 'human resources':
      return const Color(0xFFF59E0B);
    case 'operations':
      return const Color(0xFFEF4444);
    case 'product':
      return const Color(0xFFEC4899);
    default:
      return AppTheme.accentBlue;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(children: rows),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
