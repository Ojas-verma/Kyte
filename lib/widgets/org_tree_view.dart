import 'package:flutter/material.dart';

import '../models/member.dart';
import '../screens/profile_sheet.dart';
import '../utils/app_theme.dart';
import '../utils/tree_builder.dart';

class OrgTreeView extends StatefulWidget {
  const OrgTreeView({
    super.key,
    required this.members,
    required this.onAddRequested,
  });

  final List<Member> members;
  final VoidCallback onAddRequested;

  @override
  State<OrgTreeView> createState() => _OrgTreeViewState();
}

class _OrgTreeViewState extends State<OrgTreeView> {
  final Set<String> _collapsedNodeIds = <String>{};

  void _openProfile(Member member) {
    showMemberProfileSheet(context, member, widget.members);
  }

  @override
  Widget build(BuildContext context) {
    final tree = buildTree(widget.members);

    if (tree.isEmpty) {
      return _EmptyTreeState(onAddRequested: widget.onAddRequested);
    }

    return InteractiveViewer(
      constrained: false,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(100),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 32,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: tree
                .map(
                  (node) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _TreeBranch(
                      node: node,
                      collapsedNodeIds: _collapsedNodeIds,
                      onToggleCollapsed: _toggleNode,
                      onNodeTap: _openProfile,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _toggleNode(String nodeId) {
    setState(() {
      if (_collapsedNodeIds.contains(nodeId)) {
        _collapsedNodeIds.remove(nodeId);
      } else {
        _collapsedNodeIds.add(nodeId);
      }
    });
  }
}

class _TreeBranch extends StatelessWidget {
  const _TreeBranch({
    required this.node,
    required this.collapsedNodeIds,
    required this.onToggleCollapsed,
    required this.onNodeTap,
    this.depth = 0,
  });

  final TreeNode node;
  final Set<String> collapsedNodeIds;
  final ValueChanged<String> onToggleCollapsed;
  final ValueChanged<Member> onNodeTap;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = collapsedNodeIds.contains(node.member.id);
    final hasChildren = node.hasChildren;
    final children = node.children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 18.0),
          child: _TreeNodeCard(
            member: node.member,
            hasChildren: hasChildren,
            isCollapsed: isCollapsed,
            onTap: () => onNodeTap(node.member),
            onToggleCollapsed: hasChildren
                ? () => onToggleCollapsed(node.member.id)
                : null,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: hasChildren && !isCollapsed
              ? Padding(
                  padding: EdgeInsets.only(left: depth * 18.0 + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1,
                        height: 14,
                        color: const Color(0xFF24324A),
                      ),
                      ...children.map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: _TreeBranch(
                            node: child,
                            collapsedNodeIds: collapsedNodeIds,
                            onToggleCollapsed: onToggleCollapsed,
                            onNodeTap: onNodeTap,
                            depth: depth + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TreeNodeCard extends StatelessWidget {
  const _TreeNodeCard({
    required this.member,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onTap,
    this.onToggleCollapsed,
  });

  final Member member;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onTap;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 210),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E293B)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentBlue.withValues(
                      alpha: 0.16,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (hasChildren && onToggleCollapsed != null)
                    IconButton(
                      onPressed: onToggleCollapsed,
                      icon: Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(label: member.department),
                  const SizedBox(width: 8),
                  _Badge(
                    label: member.team,
                    tone: AppTheme.accentBlue.withValues(alpha: 0.2),
                    textColor: AppTheme.textPrimary,
                  ),
                ],
              ),
              if (hasChildren)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    isCollapsed ? 'Tap to expand' : 'Tap card to open profile',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.tone, this.textColor});

  final String label;
  final Color? tone;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone ?? AppTheme.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor ?? AppTheme.accentBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTreeState extends StatelessWidget {
  const _EmptyTreeState({required this.onAddRequested});

  final VoidCallback onAddRequested;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 56,
            color: AppTheme.accentBlue.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('No members yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Tap + to add the first person to your organization',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddRequested,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add member'),
          ),
        ],
      ),
    );
  }
}
