import 'package:flutter/material.dart';

import '../models/member.dart';
import '../screens/profile_sheet.dart';
import '../utils/app_theme.dart';
import '../utils/department_colors.dart';
import '../utils/tree_builder.dart';

class OrgTreeView extends StatefulWidget {
  const OrgTreeView({
    super.key,
    required this.members,
    required this.onAddRequested,
    this.onMemberTap,
    this.highlightedMemberId,
    this.highlightedMemberFocusToken = 0,
  });

  final List<Member> members;
  final VoidCallback onAddRequested;
  final ValueChanged<Member>? onMemberTap;
  final String? highlightedMemberId;
  final int highlightedMemberFocusToken;

  @override
  State<OrgTreeView> createState() => _OrgTreeViewState();
}

class _OrgTreeViewState extends State<OrgTreeView>
    with SingleTickerProviderStateMixin {
  final Set<String> _collapsedNodeIds = <String>{};
  final Map<String, GlobalKey> _nodeKeys = <String, GlobalKey>{};
  final GlobalKey _viewerKey = GlobalKey();
  final GlobalKey _sceneKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  late final AnimationController _focusAnimationController;
  Animation<Matrix4>? _focusAnimation;

  @override
  void initState() {
    super.initState();
    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _focusAnimationController.addListener(() {
      final animation = _focusAnimation;
      if (animation != null) {
        _transformationController.value = animation.value;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusHighlightedMember();
    });
  }

  @override
  void didUpdateWidget(covariant OrgTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final highlightChanged =
        oldWidget.highlightedMemberId != widget.highlightedMemberId;
    final focusRequested =
        oldWidget.highlightedMemberFocusToken !=
        widget.highlightedMemberFocusToken;
    final memberListChanged = oldWidget.members != widget.members;

    if (highlightChanged || focusRequested || memberListChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusHighlightedMember();
      });
    }
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _openProfile(Member member) {
    final onMemberTap = widget.onMemberTap;
    if (onMemberTap != null) {
      onMemberTap(member);
      return;
    }

    showMemberProfileSheet(context, member, widget.members);
  }

  @override
  Widget build(BuildContext context) {
    _syncNodeKeys();
    _expandAncestorsForHighlight();

    final tree = buildTree(widget.members);

    if (tree.isEmpty) {
      return _EmptyTreeState(onAddRequested: widget.onAddRequested);
    }

    return InteractiveViewer(
      key: _viewerKey,
      transformationController: _transformationController,
      constrained: false,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(180),
      child: ConstrainedBox(
        key: _sceneKey,
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
                      nodeKeys: _nodeKeys,
                      highlightedMemberId: widget.highlightedMemberId,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _syncNodeKeys() {
    final existingIds = widget.members.map((member) => member.id).toSet();
    _nodeKeys.removeWhere((id, _) => !existingIds.contains(id));

    for (final member in widget.members) {
      _nodeKeys.putIfAbsent(member.id, () => GlobalKey());
    }
  }

  void _expandAncestorsForHighlight() {
    final highlightedMemberId = widget.highlightedMemberId;
    if (highlightedMemberId == null || highlightedMemberId.isEmpty) {
      return;
    }

    final membersById = <String, Member>{
      for (final member in widget.members) member.id: member,
    };

    var current = membersById[highlightedMemberId];
    while (current != null && current.managerId != null) {
      _collapsedNodeIds.remove(current.managerId!);
      current = membersById[current.managerId!];
    }
  }

  void _focusHighlightedMember() {
    final highlightedMemberId = widget.highlightedMemberId;
    if (highlightedMemberId == null || highlightedMemberId.isEmpty) {
      return;
    }

    final targetContext = _nodeKeys[highlightedMemberId]?.currentContext;
    final sceneContext = _sceneKey.currentContext;
    final viewerContext = _viewerKey.currentContext;

    if (targetContext == null ||
        sceneContext == null ||
        viewerContext == null) {
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final sceneBox = sceneContext.findRenderObject() as RenderBox?;
    final viewerBox = viewerContext.findRenderObject() as RenderBox?;

    if (targetBox == null || sceneBox == null || viewerBox == null) {
      return;
    }

    final sceneCenter = targetBox.localToGlobal(
      targetBox.size.center(Offset.zero),
      ancestor: sceneBox,
    );

    final currentScale = _transformationController.value.storage[0];
    final targetScale = currentScale < 0.75 ? 0.75 : currentScale;

    final targetMatrix = Matrix4.identity()
      ..translate(
        viewerBox.size.width / 2 - sceneCenter.dx * targetScale,
        viewerBox.size.height / 2 - sceneCenter.dy * targetScale,
      )
      ..scale(targetScale);

    _focusAnimationController.stop();
    _focusAnimationController.reset();

    _focusAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _focusAnimationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _focusAnimationController.forward();
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
    required this.nodeKeys,
    required this.highlightedMemberId,
    this.depth = 0,
  });

  final TreeNode node;
  final Set<String> collapsedNodeIds;
  final ValueChanged<String> onToggleCollapsed;
  final ValueChanged<Member> onNodeTap;
  final Map<String, GlobalKey> nodeKeys;
  final String? highlightedMemberId;
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
            key: nodeKeys[node.member.id],
            member: node.member,
            hasChildren: hasChildren,
            isCollapsed: isCollapsed,
            isOrphan: node.isOrphan,
            onTap: () => onNodeTap(node.member),
            onToggleCollapsed: hasChildren
                ? () => onToggleCollapsed(node.member.id)
                : null,
            isHighlighted: highlightedMemberId == node.member.id,
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
                            nodeKeys: nodeKeys,
                            highlightedMemberId: highlightedMemberId,
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
    super.key,
    required this.member,
    required this.hasChildren,
    required this.isCollapsed,
    required this.isOrphan,
    required this.onTap,
    required this.isHighlighted,
    this.onToggleCollapsed,
  });

  final Member member;
  final bool hasChildren;
  final bool isCollapsed;
  final bool isOrphan;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minWidth: 210),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.accentBlue.withValues(alpha: 0.18)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF1E293B),
              width: isHighlighted ? 1.8 : 1,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              if (isHighlighted)
                const BoxShadow(
                  color: Color(0x44FFB74D),
                  blurRadius: 20,
                  spreadRadius: 1,
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
                  _Badge(
                    label: member.department,
                    tone: departmentBadgeColor(
                      member.department,
                    ).withValues(alpha: 0.22),
                    textColor: departmentBadgeColor(member.department),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: member.team,
                    tone: AppTheme.accentBlue.withValues(alpha: 0.2),
                    textColor: AppTheme.textPrimary,
                  ),
                ],
              ),
              if (isOrphan)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _Badge(
                    label: '⚠ Manager missing',
                    tone: const Color(0x22FF8A65),
                    textColor: const Color(0xFFFF8A65),
                  ),
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
