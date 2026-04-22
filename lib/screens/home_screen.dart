import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/bootstrap.dart';
import '../providers/member_provider.dart';
import 'add_member_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/org_tree_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kyte'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bootstrap.demoMode
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: bootstrap.demoMode
                        ? Colors.orange.withValues(alpha: 0.35)
                        : Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  bootstrap.demoMode ? 'Demo mode' : 'Firebase ready',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: bootstrap.demoMode
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<MemberProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusCard(
                    title: 'Phase 4 tree core',
                    subtitle: provider.isDemoMode
                        ? 'Interactive tree rendered from the local demo hierarchy.'
                        : 'Connected to Firestore and streaming members in real time.',
                    primaryValue: provider.members.length.toString(),
                    primaryLabel: 'Loaded members',
                    secondaryValue: bootstrap.demoMode ? 'Local data' : 'Ready',
                    secondaryLabel: bootstrap.demoMode
                        ? 'Demo mode is active'
                        : 'App status',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Org chart',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a card to open the profile sheet. Use the chevron to collapse or expand a branch.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: OrgTreeView(
                      members: provider.members,
                      onAddRequested: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const AddMemberScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentBlue,
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(builder: (_) => const AddMemberScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryValue,
    required this.secondaryLabel,
  });

  final String title;
  final String subtitle;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryValue;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(value: primaryValue, label: primaryLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBlock(
                  value: secondaryValue,
                  label: secondaryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
