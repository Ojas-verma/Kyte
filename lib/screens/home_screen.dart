import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/bootstrap.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_transitions.dart';
import '../widgets/org_tree_view.dart';
import 'add_member_screen.dart';
import 'profile_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _query = '';
  String? _highlightedMemberId;
  int _highlightFocusToken = 0;
  String? _selectedMemberId;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeConnectivity());
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    final connectivity = Connectivity();
    final initialResults = await connectivity.checkConnectivity();
    if (!mounted) {
      return;
    }

    setState(() {
      _isOffline = _isOfflineFromResults(initialResults);
    });

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isOffline = _isOfflineFromResults(results);
      });
    });
  }

  bool _isOfflineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return true;
    }

    return results.every((result) => result == ConnectivityResult.none);
  }

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
                  color: widget.bootstrap.demoMode
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.bootstrap.demoMode
                        ? Colors.orange.withValues(alpha: 0.35)
                        : Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  widget.bootstrap.demoMode ? 'Demo mode' : 'Firebase ready',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.bootstrap.demoMode
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
              final offlineBanner = _OfflineBanner(isOffline: _isOffline);
              final bootstrapWarning = widget.bootstrap.hasWarning
                  ? _ErrorBanner(message: widget.bootstrap.message!)
                  : null;
              final errorBanner = provider.errorMessage == null
                  ? null
                  : _ErrorBanner(message: provider.errorMessage!);

              if (provider.isLoading) {
                return Column(
                  children: [
                    offlineBanner,
                    if (bootstrapWarning != null) ...[
                      const SizedBox(height: 8),
                      bootstrapWarning,
                    ],
                    if (errorBanner != null) ...[
                      const SizedBox(height: 8),
                      errorBanner,
                    ],
                    const SizedBox(height: 8),
                    const Expanded(child: _HomeLoadingSkeleton()),
                  ],
                );
              }

              final isTablet = MediaQuery.sizeOf(context).width >= 900;
              final selectedMember = _resolveSelectedMember(provider.members);
              final suggestions = _buildSuggestions(provider.members);
              final showSuggestions =
                  _searchFocusNode.hasFocus && _query.trim().isNotEmpty;

              final treeArea = _TreeArea(
                bootstrap: widget.bootstrap,
                members: provider.members,
                suggestions: suggestions,
                showSuggestions: showSuggestions,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                highlightedMemberId: _highlightedMemberId,
                highlightedMemberFocusToken: _highlightFocusToken,
                onSearchChanged: (value) {
                  setState(() {
                    _query = value;
                    if (value.trim().isEmpty) {
                      _highlightedMemberId = null;
                    }
                  });
                },
                onSearchClear: () {
                  setState(() {
                    _query = '';
                    _highlightedMemberId = null;
                    _searchController.clear();
                  });
                },
                onSuggestionSelected: (hit) {
                  setState(() {
                    _searchController.text = hit.member.name;
                    _query = hit.member.name;
                    _selectedMemberId = hit.member.id;
                    _highlightedMemberId = hit.member.id;
                    _highlightFocusToken++;
                  });
                  _searchFocusNode.unfocus();
                },
                onAddRequested: () async {
                  await Navigator.of(context).push<bool>(
                    buildFadeSlideRoute<bool>(const AddMemberScreen()),
                  );
                },
                onMemberTap: (member) {
                  if (isTablet) {
                    setState(() {
                      _selectedMemberId = member.id;
                      _highlightedMemberId = member.id;
                      _highlightFocusToken++;
                    });
                    return;
                  }

                  showMemberProfileSheet(context, member, provider.members);
                },
              );

              if (!isTablet) {
                return Column(
                  children: [
                    offlineBanner,
                    if (bootstrapWarning != null) ...[
                      const SizedBox(height: 8),
                      bootstrapWarning,
                    ],
                    if (errorBanner != null) ...[
                      const SizedBox(height: 8),
                      errorBanner,
                    ],
                    const SizedBox(height: 8),
                    Expanded(child: treeArea),
                  ],
                );
              }

              return Column(
                children: [
                  offlineBanner,
                  if (bootstrapWarning != null) ...[
                    const SizedBox(height: 8),
                    bootstrapWarning,
                  ],
                  if (errorBanner != null) ...[
                    const SizedBox(height: 8),
                    errorBanner,
                  ],
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: treeArea),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _TabletProfilePanel(
                            member: selectedMember,
                            members: provider.members,
                          ),
                        ),
                      ],
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
          await Navigator.of(
            context,
          ).push<bool>(buildFadeSlideRoute<bool>(const AddMemberScreen()));
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Member? _resolveSelectedMember(List<Member> members) {
    final selectedMemberId = _selectedMemberId;
    if (selectedMemberId == null) {
      return members.isEmpty ? null : members.first;
    }

    for (final member in members) {
      if (member.id == selectedMemberId) {
        return member;
      }
    }

    return members.isEmpty ? null : members.first;
  }

  List<_SearchHit> _buildSuggestions(List<Member> members) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const <_SearchHit>[];
    }

    final hits = <_SearchHit>[];

    for (final member in members) {
      final name = member.name.toLowerCase();
      final role = member.role.toLowerCase();
      final department = member.department.toLowerCase();

      if (name.contains(normalizedQuery)) {
        hits.add(_SearchHit(member: member, reason: 'Name match'));
        continue;
      }

      if (role.contains(normalizedQuery)) {
        hits.add(_SearchHit(member: member, reason: 'Role match'));
        continue;
      }

      if (department.contains(normalizedQuery)) {
        hits.add(_SearchHit(member: member, reason: 'Dept match'));
      }
    }

    hits.sort((left, right) => left.member.name.compareTo(right.member.name));
    return hits.take(8).toList(growable: false);
  }
}

class _TreeArea extends StatelessWidget {
  const _TreeArea({
    required this.bootstrap,
    required this.members,
    required this.suggestions,
    required this.showSuggestions,
    required this.searchController,
    required this.searchFocusNode,
    required this.highlightedMemberId,
    required this.highlightedMemberFocusToken,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onSuggestionSelected,
    required this.onAddRequested,
    required this.onMemberTap,
  });

  final AppBootstrap bootstrap;
  final List<Member> members;
  final List<_SearchHit> suggestions;
  final bool showSuggestions;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? highlightedMemberId;
  final int highlightedMemberFocusToken;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<_SearchHit> onSuggestionSelected;
  final VoidCallback onAddRequested;
  final ValueChanged<Member> onMemberTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(
          title: 'Phase 7 resilience hardening',
          subtitle: bootstrap.demoMode
              ? 'Interactive tree rendered from local data with offline awareness and edge-case handling.'
              : 'Connected to Firestore with retries, friendly errors, and offline awareness.',
          primaryValue: members.length.toString(),
          primaryLabel: 'Loaded members',
          secondaryValue: bootstrap.demoMode ? 'Local data' : 'Ready',
          secondaryLabel: bootstrap.demoMode
              ? 'Demo mode is active'
              : 'App status',
        ),
        const SizedBox(height: 14),
        _SearchBar(
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onSearchChanged,
          onClear: onSearchClear,
        ),
        if (showSuggestions)
          _SearchSuggestions(
            suggestions: suggestions,
            onSelected: onSuggestionSelected,
          ),
        const SizedBox(height: 10),
        Text('Org chart', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Search by name, role, or department. Selecting a result highlights and focuses the matched node.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: OrgTreeView(
            members: members,
            onAddRequested: onAddRequested,
            highlightedMemberId: highlightedMemberId,
            highlightedMemberFocusToken: highlightedMemberFocusToken,
            onMemberTap: onMemberTap,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search by name, role, or department',
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppTheme.bgCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.accentBlue),
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<_SearchHit> suggestions;
  final ValueChanged<_SearchHit> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: suggestions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: AppTheme.textMuted.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No member found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hit = suggestions[index];
                return ListTile(
                  dense: true,
                  onTap: () => onSelected(hit),
                  title: Text(
                    hit.member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${hit.reason} • ${hit.member.role}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.north_east_rounded, size: 16),
                );
              },
            ),
    );
  }
}

class _TabletProfilePanel extends StatelessWidget {
  const _TabletProfilePanel({required this.member, required this.members});

  final Member? member;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    if (member == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(child: Text('Select a member to view details.')),
      );
    }

    final manager = members
        .where((candidate) => candidate.id == member!.managerId)
        .firstOrNull;

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
          Text('Profile panel', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.16),
            child: Text(
              member!.name.isEmpty ? '?' : member!.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            member!.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            member!.role,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _ProfileRow(label: 'Department', value: member!.department),
          _ProfileRow(label: 'Team', value: member!.team),
          _ProfileRow(
            label: 'Reports to',
            value: manager == null ? 'Root node' : manager.name,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  showMemberProfileSheet(context, member!, members),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open full profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonBlock(height: 132, radius: 20),
        SizedBox(height: 14),
        _SkeletonBlock(height: 52, radius: 16),
        SizedBox(height: 14),
        _SkeletonBlock(height: 24, width: 140, radius: 8),
        SizedBox(height: 8),
        _SkeletonBlock(height: 16, width: 280, radius: 8),
        SizedBox(height: 14),
        Expanded(child: _SkeletonBlock(height: double.infinity, radius: 20)),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOffline
            ? Colors.orange.withValues(alpha: 0.14)
            : Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffline
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.green.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
            color: isOffline ? Colors.orange.shade200 : Colors.green.shade200,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'You are offline - showing cached data'
                  : 'Online - real-time sync active',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isOffline
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade100),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.width = double.infinity,
    this.radius = 12,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.25, end: 0.45),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () {},
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SearchHit {
  const _SearchHit({required this.member, required this.reason});

  final Member member;
  final String reason;
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
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
