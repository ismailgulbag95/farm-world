import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../domain/opening_session.dart';
import '../domain/tech_tree.dart';

/// Full-screen, pannable research board for Farm World's technology tree.
class TechTreeOverlay extends StatefulWidget {
  const TechTreeOverlay({
    super.key,
    required this.session,
    this.onNodePurchased,
    this.researchOnly = false,
  });

  final OpeningSession session;
  final VoidCallback? onNodePurchased;
  final bool researchOnly;

  @override
  State<TechTreeOverlay> createState() => _TechTreeOverlayState();
}

class _TechTreeOverlayState extends State<TechTreeOverlay> {
  static const _engine = TechTreeEngine();
  static const _background = Color(0xFF080B09);
  static const _muted = Color(0xFF89938B);
  static const _gold = Color(0xFFE4C34E);
  static const _stageStart = 44.0;
  static const _stageGap = 390.0;
  static const _nodeWidth = 224.0;
  static const _nodeHeight = 96.0;
  static const _nodeStackGap = 14.0;
  static const _trackGap = 8.0;
  static const _layerUnlockPercent = 60;

  late final TransformationController _transformController;
  late final TextEditingController _searchController;
  late final Map<TechMainBranch, List<TechNode>> _branchNodeIndex = {
    for (final branch in TechMainBranch.values)
      branch: TechTreeCatalog.all
          .where((node) => node.mainBranch == branch)
          .toList(growable: false),
  };
  late final Map<String, int> _depthByNode = _calculateDepths();
  late final Map<String, int> _presentationDepthByNode =
      _createPresentationDepths();
  late final Map<int, List<TechNode>> _nodesByPresentationDepth =
      _indexNodesByPresentationDepth();
  late final List<_BranchLane> _lanes = _createLanes();
  late final Map<String, Offset> _nodePositions = _createNodePositions();
  Timer? _searchDebounce;
  List<TechNode> _visibleNodes = const [];
  Map<TechMainBranch, int> _purchasedByBranch = {};
  Map<int, int> _purchasedByPresentationDepth = {};

  Size _viewportSize = Size.zero;
  Matrix4 _homeTransform = Matrix4.identity();
  bool _hasInitialTransform = false;
  int _visibleThroughDepth = 0;
  int _totalPurchasedNodeCount = 0;
  int _currentLayerPurchasedCount = 0;
  int _currentLayerUnlockRequirement = 0;
  String? _selectedNodeId;
  TechMainBranch? _selectedBranch;
  String _searchQuery = '';

  int get _maxDepth => _presentationDepthByNode.values.fold<int>(
    0,
    (maximum, depth) => math.max(maximum, depth),
  );

  double get _canvasWidth =>
      _stageStart + (_visibleThroughDepth + 1) * _stageGap + 70;

  double get _canvasHeight =>
      _lanes.isEmpty ? 900 : _lanes.last.top + _lanes.last.height + 44;

  double get _currentScale => _transformController.value.storage[0].abs();

  int get _deliveryCount => widget.session.fleetManager.vehicles.fold<int>(
    0,
    (sum, vehicle) => sum + vehicle.totalDeliveriesCount,
  );

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _searchController = TextEditingController();
    _refreshProgressState();
  }

  @override
  void didUpdateWidget(covariant TechTreeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshProgressState();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wideLayout = screenWidth >= 860;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(screenWidth),
            if (!wideLayout) _buildMobileBranchPicker(),
            Expanded(
              child: Row(
                children: [
                  if (wideLayout)
                    SizedBox(width: 178, child: _buildBranchRail()),
                  Expanded(child: _buildResearchViewport(wideLayout)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(double screenWidth) {
    final compact = screenWidth < 680;
    final unlocked = _totalPurchasedNodeCount;

    return Container(
      height: 58,
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090C0A),
        border: Border(bottom: BorderSide(color: Color(0xFF252C27))),
      ),
      child: Row(
        children: [
          if (compact)
            SizedBox(
              width: 62,
              child: TextButton(
                onPressed: _returnToMap,
                style: TextButton.styleFrom(
                  foregroundColor: _gold,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFF66572D)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 17),
                    Text(
                      'HARİTA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            TextButton.icon(
              onPressed: _returnToMap,
              icon: const Icon(Icons.map_rounded, size: 17),
              label: const Text('HARİTA'),
              style: TextButton.styleFrom(
                foregroundColor: _gold,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF303B32)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (!compact) ...[
            const Icon(Icons.account_tree_rounded, color: _gold, size: 23),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? 'ARAŞTIRMA' : 'ÇİFTLİK ARAŞTIRMALARI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),
                if (!compact)
                  Text(
                    '${TechTreeCatalog.all.length} teknoloji  ·  $unlocked açık  ·  3 ana kol',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: compact ? 106 : 220,
            height: 36,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _searchQuery = value);
                });
              },
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                setState(() => _searchQuery = value);
                _focusSearchResult();
              },
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ağaçta ara',
                hintStyle: const TextStyle(
                  color: Color(0xFF778078),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 17),
                prefixIconColor: _muted,
                filled: true,
                fillColor: Color(0xFF111713),
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF29332C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _gold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _BalancePill(credits: widget.session.farmCredits, compact: compact),
          IconButton(
            tooltip: 'Görünür katmanları göster',
            onPressed: _fitCanvas,
            icon: const Icon(Icons.center_focus_strong_rounded),
            color: _gold,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _returnToMap() {
    Navigator.of(context).maybePop();
  }

  Widget _buildMobileBranchPicker() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          _BranchChip(
            label: 'TÜMÜ',
            selected: _selectedBranch == null,
            color: _gold,
            onTap: () => _selectBranch(null),
          ),
          for (final branch in TechMainBranch.values)
            _BranchChip(
              label: '${branch.icon} ${_branchName(branch)}',
              selected: _selectedBranch == branch,
              color: _branchColor(branch),
              onTap: () => _selectBranch(branch),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchRail() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B100D),
        border: Border(right: BorderSide(color: Color(0xFF28312A))),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 7,
            left: 8,
            right: 8,
            height: 42,
            child: _BranchRailItem(
              label: 'TÜM DALLAR',
              detail: '${TechTreeCatalog.all.length} araştırma',
              icon: Icons.hub_rounded,
              color: _gold,
              selected: _selectedBranch == null,
              onTap: () => _selectBranch(null),
            ),
          ),
          AnimatedBuilder(
            animation: _transformController,
            builder: (context, child) {
              final matrix = _transformController.value.storage;
              final scale = matrix[0].abs().clamp(0.01, 10.0);
              final translateY = matrix[13];

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final lane in _lanes)
                    _buildRailItem(lane, scale, translateY),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRailItem(_BranchLane lane, double scale, double translateY) {
    final centerY = (lane.top + lane.height / 2) * scale + translateY;
    final itemHeight = (lane.height * scale * 0.76).clamp(42.0, 68.0);
    final top = centerY - itemHeight / 2;
    if (top + itemHeight < 0 || top > _viewportSize.height) {
      return const SizedBox.shrink();
    }

    final nodes = _nodesForBranch(lane.branch);
    final activeCount = _purchasedByBranch[lane.branch] ?? 0;
    final eligibleCount = nodes
        .where(
          (node) =>
              node.implementationStatus !=
              TechNodeImplementationStatus.unsupported,
        )
        .length;

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: itemHeight,
      child: _BranchRailItem(
        label: _branchName(lane.branch),
        detail: '$activeCount/$eligibleCount açık',
        icon: Icons.circle,
        iconText: lane.branch.icon,
        color: _branchColor(lane.branch),
        selected: _selectedBranch == lane.branch,
        onTap: () => _selectBranch(lane.branch),
      ),
    );
  }

  Widget _buildResearchViewport(bool wideLayout) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _homeTransform = _makeFitTransform(_viewportSize);
        if (!_hasInitialTransform) {
          _hasInitialTransform = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _transformController.value = _homeTransform.clone();
          });
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _InfiniteGridPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                alignment: Alignment.topLeft,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.065,
                maxScale: 2.0,
                clipBehavior: Clip.hardEdge,
                child: _buildResearchCanvas(),
              ),
            ),
            _buildStageRuler(),
            Positioned(
              top: 37,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Flexible(
                    child: _buildLayerProgress(
                      compact: _viewportSize.width < 560,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCanvasTools(),
                ],
              ),
            ),
            if (_selectedNodeId case final selectedId?)
              _buildNodeInspector(selectedId, wideLayout)
            else
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: IgnorePointer(
                  child: Center(
                    child: _HintPill(
                      text: 'Sürükle: gezin  ·  Tekerlek/iki parmak: yakınlaştır  ·  Düğüm: incele',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildResearchCanvas() {
    final width = _canvasWidth;
    final height = _canvasHeight;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final point = details.localPosition;
                TechNode? selected;
                for (final node in _visibleNodes.reversed) {
                  final position = _nodePositions[node.id]!;
                  if (Rect.fromLTWH(
                    position.dx,
                    position.dy,
                    _nodeWidth,
                    _nodeHeight,
                  ).contains(point)) {
                    selected = node;
                    break;
                  }
                }
                if (selected == null) {
                  if (_selectedNodeId != null) {
                    setState(() => _selectedNodeId = null);
                  }
                  return;
                }
                HapticFeedback.selectionClick();
                setState(() => _selectedNodeId = selected!.id);
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ResearchConnectionsPainter(
                    lanes: _lanes,
                    nodes: _visibleNodes,
                    positions: _nodePositions,
                    visibleThroughDepth: _visibleThroughDepth,
                    session: widget.session,
                    researchOnly: widget.researchOnly,
                    selectedBranch: _selectedBranch,
                    selectedNodeId: _selectedNodeId,
                    searchQuery: _searchQuery,
                    onNodeTap: (nodeId) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedNodeId = nodeId);
                    },
                  ),
                  isComplex: true,
                  willChange: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageRuler() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _transformController,
          builder: (context, child) {
            final matrix = _transformController.value.storage;
            final scale = matrix[0];
            final translateX = matrix[12];
            final width = _viewportSize.width;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 31,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _background.withValues(alpha: 0.94),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF273129)),
                      ),
                    ),
                  ),
                ),
                for (var depth = 0; depth <= _visibleThroughDepth; depth++)
                  _stageLabel(depth, scale, translateX, width),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stageLabel(int depth, double scale, double translateX, double width) {
    final worldCenter = _stageStart + depth * _stageGap + _stageGap / 2;
    final screenCenter = worldCenter * scale + translateX;
    if (screenCenter < -90 || screenCenter > width + 90) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: screenCenter - 65,
      width: 130,
      height: 31,
      child: Center(
        child: Text(
          depth == 0 ? 'BAŞLANGIÇ' : '$depth. ADIM',
          maxLines: 1,
          style: TextStyle(
            color: depth == 0 ? _gold : const Color(0xFFACB5AD),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasTools() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xE9101511),
        border: Border.all(color: const Color(0xFF303B32)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolIcon(
            tooltip: 'Uzaklaştır',
            icon: Icons.remove_rounded,
            onPressed: () => _zoomBy(-0.12),
          ),
          SizedBox(
            width: 42,
            child: Center(
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _transformController,
                builder: (context, matrix, child) => Text(
                  '${(matrix.storage[0].abs() * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFFCFD8D0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _ToolIcon(
            tooltip: 'Yakınlaştır',
            icon: Icons.add_rounded,
            onPressed: () => _zoomBy(0.12),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: const Color(0xFF354037),
          ),
          _ToolIcon(
            tooltip: 'Görünür katmanları göster',
            icon: Icons.center_focus_strong_rounded,
            onPressed: _fitCanvas,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerProgress({required bool compact}) {
    final allLayersVisible = _visibleThroughDepth >= _maxDepth;
    final required = _currentLayerUnlockRequirement;
    final progress = allLayersVisible || required == 0
        ? 1.0
        : (_currentLayerPurchasedCount / required).clamp(0.0, 1.0);
    final stepName = _visibleThroughDepth == 0
        ? 'BAŞLANGIÇ'
        : '$_visibleThroughDepth. KATMAN';
    final countLabel = allLayersVisible
        ? 'TAMAM'
        : '$_currentLayerPurchasedCount/$required';

    return Tooltip(
      message: allLayersVisible
          ? 'Tüm teknoloji katmanları görünür.'
          : 'Sonraki katman, mevcut katmandaki teknolojilerin '
                '%$_layerUnlockPercent’i araştırılınca ücretsiz görünür. '
                'Katman açmak için ayrıca kredi harcanmaz.',
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: const Color(0xE9101511),
              border: Border.all(color: const Color(0xFF303B32)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Icon(
                  allLayersVisible
                      ? Icons.check_circle_outline_rounded
                      : Icons.lock_open_rounded,
                  size: 14,
                  color: _gold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    compact ? countLabel : '$stepName  ·  $countLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCFD8D0),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 58,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: const Color(0xFF303B32),
                      valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeInspector(String nodeId, bool wideLayout) {
    final node = TechTreeCatalog.byId(nodeId);
    if (node == null) return const SizedBox.shrink();

    final status = _engine.getNodeStatus(
      node,
      widget.session,
      researchOnly: widget.researchOnly,
    );
    final canPurchase = _engine.canPurchaseNode(
      node.id,
      widget.session,
      researchOnly: widget.researchOnly,
    );
    final initialUnlockNote = switch (node.id) {
      'H01'
          when widget.session.hasMower &&
              !widget.session.hasPurchasedTechnology(node.id) =>
        'Açılışta verilen mini biçerdöver bu uzmanlığı zaten açıyor.',
      'H02'
          when widget.session.hasWorker &&
              !widget.session.hasPurchasedTechnology(node.id) =>
        'Açılışta verilen üretim ekibi bu uzmanlığı zaten açıyor.',
      _ => null,
    };
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Align(
        alignment: wideLayout ? Alignment.bottomRight : Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wideLayout ? 420 : 520,
            maxHeight: _viewportSize.height * 0.43,
          ),
          child: _NodeInspector(
            node: node,
            status: status,
            canPurchase: canPurchase,
            credits: widget.session.farmCredits,
            production: widget.session.lifetimeProductionEvidence,
            diversity: widget.session.cropDiversityCount,
            deliveries: _deliveryCount,
            researchOnly: widget.researchOnly,
            initialUnlockNote: initialUnlockNote,
            isPrerequisiteSatisfied: _isPrerequisiteSatisfied,
            isRouteSatisfied: _isRouteSatisfied,
            onClose: () => setState(() => _selectedNodeId = null),
            onPurchase: canPurchase ? () => _purchaseNode(node) : null,
          ),
        ),
      ),
    );
  }

  void _selectBranch(TechMainBranch? branch) {
    setState(() {
      _selectedBranch = branch;
      _selectedNodeId = null;
    });
    if (branch == null) {
      _fitCanvas();
    } else {
      _focusBranch(branch);
    }
  }

  void _focusSearchResult() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return;

    TechNode? match;
    var matchedFutureLayer = false;
    for (final node in TechTreeCatalog.all) {
      final matches =
          node.id.toLowerCase().contains(query) ||
          node.name.toLowerCase().contains(query) ||
          node.track.toLowerCase().contains(query) ||
          node.description.toLowerCase().contains(query);
      if (!matches) continue;
      if (!_isNodeVisible(node)) {
        matchedFutureLayer = true;
        continue;
      }
      match = node;
      break;
    }

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matchedFutureLayer
                ? 'Bu teknoloji ileriki bir katmanda. Sonraki adım için '
                      'mevcut katmandaki teknolojilerin '
                      '%$_layerUnlockPercent’ini araştır.'
                : 'Açık katmanlarda eşleşme bulunamadı.',
          ),
        ),
      );
      return;
    }

    final node = match;
    final position = _nodePositions[node.id]!;
    final scale = _currentScale.clamp(0.48, 1.8).toDouble();
    setState(() {
      _selectedBranch = node.mainBranch;
      _selectedNodeId = node.id;
    });
    _moveWorldPointToScreen(
      Offset(position.dx + _nodeWidth / 2, position.dy + _nodeHeight / 2),
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      scale,
    );
  }

  void _focusBranch(TechMainBranch branch) {
    final lane = _lanes.firstWhere((item) => item.branch == branch);
    final currentScale = _currentScale.clamp(0.24, 1.8).toDouble();
    final matrix = _transformController.value.storage;
    final currentWorldX = (_viewportSize.width / 2 - matrix[12]) / currentScale;
    _moveWorldPointToScreen(
      Offset(currentWorldX, lane.top + lane.height / 2),
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      currentScale,
    );
  }

  void _fitCanvas() {
    if (_viewportSize.isEmpty) return;
    _homeTransform = _makeFitTransform(_viewportSize);
    _transformController.value = _homeTransform.clone();
  }

  Matrix4 _makeFitTransform(Size viewport) {
    final contentBounds = _visibleContentBounds();
    final horizontalScale = (viewport.width - 48) / contentBounds.width;
    final verticalScale = (viewport.height - 56) / contentBounds.height;
    final scale = math
        .min(horizontalScale, verticalScale)
        .clamp(0.065, 0.62)
        .toDouble();
    final translateX =
        (viewport.width - contentBounds.width * scale) / 2 -
        contentBounds.left * scale;
    final translateY =
        (viewport.height - contentBounds.height * scale) / 2 -
        contentBounds.top * scale;

    final transform = Matrix4.identity();
    transform.storage[0] = scale;
    transform.storage[5] = scale;
    transform.storage[12] = translateX;
    transform.storage[13] = translateY;
    return transform;
  }

  Rect _visibleContentBounds() {
    Rect? bounds;
    for (final node in _visibleNodes) {
      final position = _nodePositions[node.id];
      if (position == null) continue;
      final nodeBounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        _nodeWidth,
        _nodeHeight,
      );
      bounds = bounds == null ? nodeBounds : bounds.expandToInclude(nodeBounds);
    }
    return (bounds ?? Rect.fromLTWH(0, 0, _canvasWidth, _canvasHeight)).inflate(
      32,
    );
  }

  void _zoomBy(double amount) {
    final nextScale = (_currentScale + amount).clamp(0.065, 2.0).toDouble();
    _moveWorldPointToScreen(
      Offset(
        (_viewportSize.width / 2 - _transformController.value.storage[12]) /
            _currentScale,
        (_viewportSize.height / 2 - _transformController.value.storage[13]) /
            _currentScale,
      ),
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      nextScale,
    );
  }

  void _moveWorldPointToScreen(
    Offset worldPoint,
    Offset screenPoint,
    double scale,
  ) {
    final transform = Matrix4.identity();
    transform.storage[0] = scale;
    transform.storage[5] = scale;
    transform.storage[12] = screenPoint.dx - worldPoint.dx * scale;
    transform.storage[13] = screenPoint.dy - worldPoint.dy * scale;
    _transformController.value = transform;
  }

  void _purchaseNode(TechNode node) {
    if (!_engine.purchaseNode(
      node.id,
      widget.session,
      researchOnly: widget.researchOnly,
    )) {
      return;
    }
    HapticFeedback.mediumImpact();
    _refreshProgressState();
    setState(() {});
    widget.onNodePurchased?.call();
  }

  bool _isPrerequisiteSatisfied(String id) =>
      widget.session.hasPurchasedTechnology(id) ||
      (id == 'H01' && widget.session.hasMower) ||
      (id == 'H02' && widget.session.hasWorker);

  bool _isRouteSatisfied(List<String> route) =>
      route.every(_isPrerequisiteSatisfied);

  List<TechNode> _nodesForBranch(TechMainBranch branch) =>
      _branchNodeIndex[branch] ?? const [];

  Map<int, List<TechNode>> _indexNodesByPresentationDepth() {
    final result = <int, List<TechNode>>{};
    for (final node in TechTreeCatalog.all) {
      final depth = _presentationDepthByNode[node.id] ?? 0;
      result.putIfAbsent(depth, () => []).add(node);
    }
    return result;
  }

  int _requiredForLayer(List<TechNode> nodes) {
    final eligibleCount = nodes
        .where(
          (node) =>
              node.implementationStatus !=
              TechNodeImplementationStatus.unsupported,
        )
        .length;
    if (eligibleCount == 0) return 0;
    return (eligibleCount * _layerUnlockPercent + 99) ~/ 100;
  }

  void _refreshProgressState() {
    final branchCounts = {
      for (final branch in TechMainBranch.values) branch: 0,
    };
    final depthCounts = <int, int>{};
    var total = 0;
    for (final node in TechTreeCatalog.all) {
      // Unsupported legacy purchases must not inflate research progress.
      if (node.implementationStatus ==
          TechNodeImplementationStatus.unsupported) {
        continue;
      }
      if (_engine.getNodeStatus(
            node,
            widget.session,
            researchOnly: widget.researchOnly,
          ) !=
          TechNodeStatus.purchased) {
        continue;
      }
      total++;
      branchCounts[node.mainBranch] = (branchCounts[node.mainBranch] ?? 0) + 1;
      final depth = _presentationDepthByNode[node.id] ?? 0;
      depthCounts[depth] = (depthCounts[depth] ?? 0) + 1;
    }

    _purchasedByBranch = branchCounts;
    _purchasedByPresentationDepth = depthCounts;
    _totalPurchasedNodeCount = total;
    _visibleThroughDepth = _calculateVisibleThroughDepth();
    _visibleNodes = TechTreeCatalog.all
        .where(_isNodeVisible)
        .toList(growable: false);
    final currentLayer =
        _nodesByPresentationDepth[_visibleThroughDepth] ?? const <TechNode>[];
    _currentLayerPurchasedCount =
        _purchasedByPresentationDepth[_visibleThroughDepth] ?? 0;
    _currentLayerUnlockRequirement = _requiredForLayer(currentLayer);
  }

  int _calculateVisibleThroughDepth() {
    final stageDepths = _nodesByPresentationDepth.keys.toList()..sort();
    if (stageDepths.isEmpty) return 0;

    var visibleDepth = stageDepths.first;
    for (final nextDepth in stageDepths.skip(1)) {
      final currentLayer = _nodesByPresentationDepth[visibleDepth]!;
      final required = _requiredForLayer(currentLayer);
      final purchased = _purchasedByPresentationDepth[visibleDepth] ?? 0;
      if (required > 0 && purchased < required) break;
      visibleDepth = nextDepth;
    }
    return visibleDepth;
  }

  bool _isNodeVisible(TechNode node) =>
      (_presentationDepthByNode[node.id] ?? 0) <= _visibleThroughDepth;

  Map<String, int> _calculateDepths() {
    final result = <String, int>{};
    final visiting = <String>{};

    int depthOf(TechNode node) {
      final cached = result[node.id];
      if (cached != null) return cached;
      if (!visiting.add(node.id)) return 0;

      var depth = 0;
      for (final prerequisiteId in node.prereqIds) {
        final prerequisite = TechTreeCatalog.byId(prerequisiteId);
        if (prerequisite != null) {
          depth = math.max(depth, depthOf(prerequisite) + 1);
        }
      }
      if (node.alternativePrerequisiteSets.isNotEmpty) {
        final routeDepths = node.alternativePrerequisiteSets.map((route) {
          var routeDepth = 0;
          for (final prerequisiteId in route) {
            final prerequisite = TechTreeCatalog.byId(prerequisiteId);
            if (prerequisite != null) {
              routeDepth = math.max(routeDepth, depthOf(prerequisite) + 1);
            }
          }
          return routeDepth;
        });
        // The engine accepts any complete alternative route, so layout depth
        // follows the earliest route that can satisfy the OR gate.
        depth = math.max(depth, routeDepths.reduce(math.min));
      }

      visiting.remove(node.id);
      result[node.id] = depth;
      return depth;
    }

    for (final node in TechTreeCatalog.all) {
      depthOf(node);
    }
    return result;
  }

  Map<String, int> _createPresentationDepths() {
    const evidenceMilestones = [0, 1200, 3000, 8000, 20000, 50000, 125000];
    const cropNodesPerStep = 8;
    final crops = TechTreeCatalog.all
        .where((node) => node.branch == TechBranch.crops)
        .toList();

    int targetDepth(TechNode node) {
      final evidenceStep = evidenceMilestones.indexWhere(
        (milestone) => node.requiredEvidenceP <= milestone,
      );
      return (_depthByNode[node.id] ?? 0) +
          (evidenceStep < 0 ? evidenceMilestones.length - 1 : evidenceStep);
    }

    String directPrerequisiteKey(TechNode node) {
      final ids = node.prereqIds.toList()..sort();
      return ids.join(',');
    }

    int numericId(TechNode node) =>
        int.tryParse(RegExp(r'\d+').firstMatch(node.id)?.group(0) ?? '') ?? 0;

    crops.sort((left, right) {
      final byTargetDepth = targetDepth(left).compareTo(targetDepth(right));
      if (byTargetDepth != 0) return byTargetDepth;
      final byPrerequisite = directPrerequisiteKey(left)
          .compareTo(directPrerequisiteKey(right));
      if (byPrerequisite != 0) return byPrerequisite;
      final byTrack = left.track.compareTo(right.track);
      if (byTrack != 0) return byTrack;
      final byNumber = numericId(left).compareTo(numericId(right));
      return byNumber != 0 ? byNumber : left.id.compareTo(right.id);
    });

    final cropTargetDepths = <String, int>{};
    final cropCountByDepth = <int, int>{};
    for (final node in crops) {
      var depth = targetDepth(node);
      while ((cropCountByDepth[depth] ?? 0) >= cropNodesPerStep) {
        depth++;
      }
      cropTargetDepths[node.id] = depth;
      cropCountByDepth[depth] = (cropCountByDepth[depth] ?? 0) + 1;
    }

    final result = <String, int>{};
    final visiting = <String>{};

    int presentationDepthOf(TechNode node) {
      final cached = result[node.id];
      if (cached != null) return cached;
      if (!visiting.add(node.id)) return _depthByNode[node.id] ?? 0;

      var depth = _depthByNode[node.id] ?? 0;
      for (final prerequisiteId in node.prereqIds) {
        final prerequisite = TechTreeCatalog.byId(prerequisiteId);
        if (prerequisite != null) {
          depth = math.max(depth, presentationDepthOf(prerequisite) + 1);
        }
      }
      if (node.alternativePrerequisiteSets.isNotEmpty) {
        final routeDepths = node.alternativePrerequisiteSets.map((route) {
          var routeDepth = 0;
          for (final prerequisiteId in route) {
            final prerequisite = TechTreeCatalog.byId(prerequisiteId);
            if (prerequisite != null) {
              routeDepth = math.max(
                routeDepth,
                presentationDepthOf(prerequisite) + 1,
              );
            }
          }
          return routeDepth;
        });
        depth = math.max(depth, routeDepths.reduce(math.min));
      }
      final cropTarget = cropTargetDepths[node.id];
      if (cropTarget != null) depth = math.max(depth, cropTarget);
      result[node.id] = depth;
      visiting.remove(node.id);
      return depth;
    }

    for (final node in TechTreeCatalog.all) {
      presentationDepthOf(node);
    }
    return result;
  }

  List<_BranchLane> _createLanes() {
    final lanes = <_BranchLane>[];
    var top = 58.0;

    for (final branch in TechMainBranch.values) {
      final nodesByTrack = <String, List<TechNode>>{};
      for (final node in _nodesForBranch(branch)) {
        nodesByTrack.putIfAbsent(node.track, () => []).add(node);
      }
      final trackEntries = nodesByTrack.entries.toList();
      if (branch == TechMainBranch.production) {
        final originalOrder = {
          for (var index = 0; index < trackEntries.length; index++)
            trackEntries[index].key: index,
        };
        int firstDepth(MapEntry<String, List<TechNode>> entry) => entry.value
            .map((node) => _presentationDepthByNode[node.id] ?? 0)
            .reduce(math.min);
        trackEntries.sort((left, right) {
          final byStartDepth = firstDepth(right).compareTo(firstDepth(left));
          return byStartDepth != 0
              ? byStartDepth
              : originalOrder[left.key]!.compareTo(originalOrder[right.key]!);
        });
      }
      final tracks = <_TrackLane>[];
      var trackTop = top + 34;
      for (final entry in trackEntries) {
        final stackByDepth = <int, int>{};
        for (final node in entry.value) {
          final depth = _presentationDepthByNode[node.id] ?? 0;
          stackByDepth[depth] = (stackByDepth[depth] ?? 0) + 1;
        }
        final largestStack = stackByDepth.values.fold<int>(
          1,
          (largest, count) => math.max(largest, count),
        );
        final requiredHeight =
            44 +
            largestStack * _nodeHeight +
            (largestStack - 1) * _nodeStackGap;
        final height = math.max(176.0, requiredHeight.toDouble());
        tracks.add(_TrackLane(track: entry.key, top: trackTop, height: height));
        trackTop += height + _trackGap;
      }
      final height = trackTop - top + 8;
      lanes.add(
        _BranchLane(branch: branch, top: top, height: height, tracks: tracks),
      );
      top += height + 12;
    }

    return lanes;
  }

  Map<String, Offset> _createNodePositions() {
    final positions = <String, Offset>{};

    for (final lane in _lanes) {
      final branchNodes = _nodesForBranch(lane.branch);
      for (final track in lane.tracks) {
        final trackNodes = branchNodes
            .where((node) => node.track == track.track)
            .toList();
        final byDepth = <int, List<TechNode>>{};
        for (final node in trackNodes) {
          final depth = _presentationDepthByNode[node.id] ?? 0;
          byDepth.putIfAbsent(depth, () => []).add(node);
        }

        for (final entry in byDepth.entries) {
          final stackHeight =
              entry.value.length * _nodeHeight +
              (entry.value.length - 1) * _nodeStackGap;
          final firstTop = track.top + (track.height - stackHeight) / 2;
          final left = _stageStart + entry.key * _stageGap + 58;
          for (var index = 0; index < entry.value.length; index++) {
            positions[entry.value[index].id] = Offset(
              left,
              firstTop + index * (_nodeHeight + _nodeStackGap),
            );
          }
        }
      }
    }
    return positions;
  }
}

class _BranchLane {
  const _BranchLane({
    required this.branch,
    required this.top,
    required this.height,
    required this.tracks,
  });

  final TechMainBranch branch;
  final double top;
  final double height;
  final List<_TrackLane> tracks;
}

class _TrackLane {
  const _TrackLane({
    required this.track,
    required this.top,
    required this.height,
  });

  final String track;
  final double top;
  final double height;
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.credits, required this.compact});

  final int credits;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111713),
        border: Border.all(color: const Color(0xFF303B32)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.paid_outlined, size: 16, color: Color(0xFF97CB75)),
          const SizedBox(width: 5),
          Text(
            '$credits${compact ? '' : ' ÇK'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, maxLines: 1),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          color: selected ? color : const Color(0xFFABB4AC),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: color.withValues(alpha: 0.14),
        backgroundColor: const Color(0xFF111713),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.65)
              : const Color(0xFF29332C),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class _BranchRailItem extends StatelessWidget {
  const _BranchRailItem({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.iconText,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.1) : const Color(0xFF101510),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: selected ? 3 : 2),
              top: BorderSide(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : const Color(0xFF263028),
              ),
              right: BorderSide(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : const Color(0xFF263028),
              ),
              bottom: BorderSide(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : const Color(0xFF263028),
              ),
            ),
          ),
          child: Row(
            children: [
              if (iconText != null)
                Text(iconText!, style: const TextStyle(fontSize: 17))
              else
                Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _TechTreeOverlayState._muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      color: const Color(0xFFD2D9D2),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 34),
    );
  }
}

class _NodeInspector extends StatelessWidget {
  const _NodeInspector({
    required this.node,
    required this.status,
    required this.canPurchase,
    required this.credits,
    required this.production,
    required this.diversity,
    required this.deliveries,
    required this.researchOnly,
    required this.initialUnlockNote,
    required this.isPrerequisiteSatisfied,
    required this.isRouteSatisfied,
    required this.onClose,
    required this.onPurchase,
  });

  final TechNode node;
  final TechNodeStatus status;
  final bool canPurchase;
  final int credits;
  final int production;
  final int diversity;
  final int deliveries;
  final bool researchOnly;
  final String? initialUnlockNote;
  final bool Function(String id) isPrerequisiteSatisfied;
  final bool Function(List<String> route) isRouteSatisfied;
  final VoidCallback onClose;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(status);
    final implementationStatus = node.implementationStatus;
    final hasImplementedEffect =
        implementationStatus == TechNodeImplementationStatus.runtimeEffect ||
        implementationStatus == TechNodeImplementationStatus.permissionGate;
    final unsupportedNode =
        implementationStatus == TechNodeImplementationStatus.unsupported;
    final implementationTitle = switch (implementationStatus) {
      TechNodeImplementationStatus.runtimeEffect => 'ŞU ANKİ OYUN ETKİSİ',
      TechNodeImplementationStatus.permissionGate => 'ŞU ANKİ AÇILAN İZİN',
      TechNodeImplementationStatus.prerequisiteOnly => 'ŞU ANKİ DURUM',
      TechNodeImplementationStatus.unsupported => 'ŞU ANKİ DURUM · UYGULANMADI',
    };
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF20C110E),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  node.id,
                  style: TextStyle(
                    color: _nodeBranchColor(node.branch),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Detayı kapat',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  color: const Color(0xFF9BA49C),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _InspectorInfo(
              title: implementationTitle,
              body: node.currentEffectDescription,
              accent: hasImplementedEffect
                  ? const Color(0xFF97CB75)
                  : const Color(0xFFE1C04E),
            ),
            const SizedBox(height: 5),
            _InspectorInfo(
              title: hasImplementedEffect
                  ? 'AĞAÇTAKİ ORİJİNAL TEKNOLOJİ AÇIKLAMASI'
                  : 'PLANLANAN TEKNOLOJİ AÇIKLAMASI · OYUNDA UYGULANMIYOR',
              body: node.description,
              accent: const Color(0xFF89938B),
            ),
            const SizedBox(height: 5),
            _InspectorInfo(
              title: hasImplementedEffect
                  ? 'AĞAÇTAKİ ORİJİNAL AÇILIM NOTU'
                  : 'PLANLANAN AÇILIM NOTU · OYUNDA UYGULANMIYOR',
              body: node.unlocksDescription,
              accent: const Color(0xFF89938B),
            ),
            const SizedBox(height: 8),
            const Text(
              'AÇILMA KOŞULLARI',
              style: TextStyle(
                color: Color(0xFF89938B),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            _RequirementLine(
              title: 'Araştırma maliyeti',
              detail: 'Bakiye $credits ÇK · Gerekli ${node.creditCost} ÇK',
              satisfied: credits >= node.creditCost,
            ),
            if (node.prereqIds.isEmpty &&
                node.alternativePrerequisiteSets.isEmpty)
              const _RequirementLine(
                title: 'Ön koşul',
                detail: 'Başka bir teknoloji gerekmiyor.',
                satisfied: true,
              ),
            for (final id in node.prereqIds)
              _RequirementLine(
                title: 'Zorunlu teknoloji',
                detail: _prerequisiteLabel(id),
                satisfied: isPrerequisiteSatisfied(id),
              ),
            if (node.alternativePrerequisiteSets.isNotEmpty) ...[
              _RequirementLine(
                title: 'Alternatif ön koşul',
                detail: 'Aşağıdaki rotalardan en az biri tamamlanmalı.',
                satisfied: node.alternativePrerequisiteSets.any(
                  (route) => route.every(isPrerequisiteSatisfied),
                ),
              ),
              for (
                var index = 0;
                index < node.alternativePrerequisiteSets.length;
                index++
              )
                _RequirementLine(
                  title: 'Rota ${index + 1}',
                  detail: node.alternativePrerequisiteSets[index]
                      .map(_prerequisiteLabel)
                      .join('  +  '),
                  satisfied: isRouteSatisfied(
                    node.alternativePrerequisiteSets[index],
                  ),
                ),
            ],
            if (!researchOnly && node.requiredEvidenceP > 0)
              _RequirementLine(
                title: 'Üretim kanıtı',
                detail: '$production / ${node.requiredEvidenceP}',
                satisfied: production >= node.requiredEvidenceP,
              ),
            if (!researchOnly && node.requiredDiversityV > 0)
              _RequirementLine(
                title: 'Ürün çeşitliliği',
                detail: '$diversity / ${node.requiredDiversityV}',
                satisfied: diversity >= node.requiredDiversityV,
              ),
            if (!researchOnly && node.requiredDeliveriesD > 0)
              _RequirementLine(
                title: 'Teslimat',
                detail: '$deliveries / ${node.requiredDeliveriesD}',
                satisfied: deliveries >= node.requiredDeliveriesD,
              ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  status == TechNodeStatus.purchased
                      ? Icons.check_circle_rounded
                      : Icons.circle,
                  color: accent,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    switch (status) {
                      TechNodeStatus.purchased =>
                        unsupportedNode
                            ? 'Bu düğüm önceki kayıtta açılmış; oyunda etkisi yok.'
                            : initialUnlockNote ??
                                  'Bu uzmanlık çiftliğinde zaten açık.',
                      TechNodeStatus.unlockable =>
                        unsupportedNode
                            ? 'Bu araştırma zincirinde çalışan etki yok; satın alınamaz ve kredi kesilmez.'
                            : canPurchase
                            ? 'Araştırma için hazır.'
                            : 'Bakiye maliyeti karşılamıyor.',
                      TechNodeStatus.locked =>
                        unsupportedNode
                            ? 'Bu araştırma zincirinde çalışan etki yok; satın alınamaz ve kredi kesilmez.'
                            : 'Yukarıdaki bekleyen koşulları tamamla.',
                    },
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (status != TechNodeStatus.purchased)
                  FilledButton.icon(
                    onPressed: onPurchase,
                    icon: Icon(
                      unsupportedNode
                          ? Icons.block_rounded
                          : status == TechNodeStatus.unlockable
                          ? Icons.science_rounded
                          : Icons.lock_outline_rounded,
                      size: 14,
                    ),
                    label: Text(
                      unsupportedNode
                          ? 'Uygulanmıyor'
                          : status == TechNodeStatus.unlockable
                          ? 'Araştır · ${node.creditCost} ÇK'
                          : 'Kilitli',
                      maxLines: 1,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF668443),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF262D28),
                      disabledForegroundColor: const Color(0xFF838D84),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )
                else
                  const Text(
                    'AÇILDI',
                    style: TextStyle(
                      color: Color(0xFF97CB75),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _prerequisiteLabel(String id) {
    final prerequisite = TechTreeCatalog.byId(id);
    final name = prerequisite?.name;
    return name == null ? id : '$id · $name';
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({
    required this.title,
    required this.detail,
    required this.satisfied,
  });

  final String title;
  final String detail;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied ? const Color(0xFF91C679) : const Color(0xFFB29D5B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 9, height: 1.25),
                children: [
                  TextSpan(
                    text: '$title · ',
                    style: const TextStyle(
                      color: Color(0xFF89938B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                    style: TextStyle(
                      color: satisfied ? const Color(0xFFD4DED5) : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorInfo extends StatelessWidget {
  const _InspectorInfo({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF111713),
      border: Border.all(color: accent.withValues(alpha: 0.32)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFDCE5DC),
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xD90C110E),
      border: Border.all(color: const Color(0xFF2B352D)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFA8B2A9), fontSize: 9),
    ),
  );
}

class _InfiniteGridPainter extends CustomPainter {
  const _InfiniteGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 44.0;
    final gridPaint = Paint()..color = const Color(0xFF344238);
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteGridPainter oldDelegate) => false;
}

class _ResearchConnectionsPainter extends CustomPainter {
  const _ResearchConnectionsPainter({
    required this.lanes,
    required this.nodes,
    required this.positions,
    required this.visibleThroughDepth,
    required this.session,
    required this.researchOnly,
    required this.selectedBranch,
    required this.selectedNodeId,
    required this.searchQuery,
    required this.onNodeTap,
  });

  final List<_BranchLane> lanes;
  final List<TechNode> nodes;
  final Map<String, Offset> positions;
  final int visibleThroughDepth;
  final OpeningSession session;
  final bool researchOnly;
  final TechMainBranch? selectedBranch;
  final String? selectedNodeId;
  final String searchQuery;
  final ValueChanged<String> onNodeTap;

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final node in nodes)
          if (positions[node.id] case final position?)
            CustomPainterSemantics(
              rect: Rect.fromLTWH(
                position.dx,
                position.dy,
                _TechTreeOverlayState._nodeWidth,
                _TechTreeOverlayState._nodeHeight,
              ),
              properties: SemanticsProperties(
                label: '${node.name}, ${node.track}, ${node.mainBranch.title}',
                textDirection: TextDirection.ltr,
                button: true,
                onTap: () => onNodeTap(node.id),
              ),
            ),
      ];

  @override
  bool shouldRebuildSemantics(
    covariant _ResearchConnectionsPainter oldDelegate,
  ) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleBounds = canvas.getLocalClipBounds().inflate(8);
    final maxDepth = visibleThroughDepth;
    final laneFill = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index <= maxDepth; index++) {
      if (index.isEven) {
        laneFill.color = Colors.white.withValues(alpha: 0.012);
        final left =
            _TechTreeOverlayState._stageStart +
            index * _TechTreeOverlayState._stageGap;
        final band = Rect.fromLTWH(
          left,
          0,
          _TechTreeOverlayState._stageGap,
          size.height,
        );
        if (band.overlaps(visibleBounds)) canvas.drawRect(band, laneFill);
      }
    }

    final stageLinePaint = Paint()
      ..color = const Color(0xFF344137).withValues(alpha: 0.54)
      ..strokeWidth = 1;
    for (var depth = 0; depth <= maxDepth + 1; depth++) {
      final x =
          _TechTreeOverlayState._stageStart +
          depth * _TechTreeOverlayState._stageGap;
      if (x >= visibleBounds.left && x <= visibleBounds.right) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), stageLinePaint);
      }
    }

    final separatorPaint = Paint()
      ..color = const Color(0xFF38443A).withValues(alpha: 0.46)
      ..strokeWidth = 1;
    final visibleTracks = <TechMainBranch, Set<String>>{};
    for (final node in nodes) {
      visibleTracks
          .putIfAbsent(node.mainBranch, () => <String>{})
          .add(node.track);
    }
    for (var index = 0; index < lanes.length; index++) {
      final lane = lanes[index];
      final laneBounds = Rect.fromLTWH(0, lane.top, size.width, lane.height);
      if (!laneBounds.overlaps(visibleBounds)) continue;
      final tint = _branchColor(lane.branch);
      canvas.drawRect(
        laneBounds,
        Paint()..color = tint.withValues(alpha: index.isEven ? 0.035 : 0.022),
      );
      canvas.drawLine(
        Offset(0, lane.top + lane.height),
        Offset(size.width, lane.top + lane.height),
        separatorPaint,
      );
      canvas.drawLine(
        Offset(0, lane.top),
        Offset(0, lane.top + lane.height),
        Paint()
          ..color = tint.withValues(alpha: 0.8)
          ..strokeWidth = 3,
      );
      _drawLabel(canvas, lane.branch.title, Offset(14, lane.top + 7), tint);

      for (var trackIndex = 0; trackIndex < lane.tracks.length; trackIndex++) {
        final track = lane.tracks[trackIndex];
        if (!(visibleTracks[lane.branch]?.contains(track.track) ?? false)) {
          continue;
        }
        final trackBounds = Rect.fromLTWH(
          0,
          track.top,
          size.width,
          track.height,
        );
        if (!trackBounds.overlaps(visibleBounds)) continue;
        canvas.drawRect(
          trackBounds,
          Paint()
            ..color = tint.withValues(alpha: trackIndex.isEven ? 0.018 : 0.032),
        );
        canvas.drawLine(
          Offset(0, track.top),
          Offset(size.width, track.top),
          separatorPaint,
        );
        _drawLabel(
          canvas,
          track.track.toUpperCase(),
          Offset(18, track.top + 5),
          tint.withValues(alpha: 0.75),
          fontSize: 9,
        );
      }
    }

    for (final node in nodes) {
      final targetPosition = positions[node.id];
      if (targetPosition == null) continue;
      for (final prerequisiteId in node.prereqIds) {
        _drawConnection(
          canvas,
          node,
          prerequisiteId,
          targetPosition,
          visibleBounds: visibleBounds,
          alternativeRouteLabel: null,
        );
      }
      for (
        var routeIndex = 0;
        routeIndex < node.alternativePrerequisiteSets.length;
        routeIndex++
      ) {
        final route = node.alternativePrerequisiteSets[routeIndex];
        for (final prerequisiteId in route) {
          _drawConnection(
            canvas,
            node,
            prerequisiteId,
            targetPosition,
            visibleBounds: visibleBounds,
            alternativeRouteLabel: 'VEYA ${routeIndex + 1}',
          );
        }
      }
    }

    for (final node in nodes) {
      final position = positions[node.id];
      if (position == null) continue;
      final bounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        _TechTreeOverlayState._nodeWidth,
        _TechTreeOverlayState._nodeHeight,
      );
      if (!bounds.overlaps(visibleBounds)) continue;
      _drawNodeCard(canvas, node, bounds);
    }
  }

  void _drawConnection(
    Canvas canvas,
    TechNode node,
    String prerequisiteId,
    Offset targetPosition, {
    required Rect visibleBounds,
    required String? alternativeRouteLabel,
  }) {
    final sourcePosition = positions[prerequisiteId];
    if (sourcePosition == null) return;

    final start = Offset(
      sourcePosition.dx + _TechTreeOverlayState._nodeWidth,
      sourcePosition.dy + _TechTreeOverlayState._nodeHeight / 2,
    );
    final end = Offset(
      targetPosition.dx,
      targetPosition.dy + _TechTreeOverlayState._nodeHeight / 2,
    );
    final edgeBounds = Rect.fromLTRB(
      math.min(start.dx, end.dx),
      math.min(start.dy, end.dy),
      math.max(start.dx, end.dx),
      math.max(start.dy, end.dy),
    ).inflate(6);
    if (!edgeBounds.overlaps(visibleBounds)) return;
    final railX = start.dx + (end.dx - start.dx) * 0.52;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(railX, start.dy)
      ..lineTo(railX, end.dy)
      ..lineTo(end.dx, end.dy);
    final targetStatus = const TechTreeEngine().getNodeStatus(
      node,
      session,
      researchOnly: researchOnly,
    );
    final connectedToSelection =
        selectedNodeId == node.id || selectedNodeId == prerequisiteId;
    final sourceNode = TechTreeCatalog.byId(prerequisiteId);
    final onSelectedBranch =
        selectedBranch == null ||
        node.mainBranch == selectedBranch ||
        sourceNode?.mainBranch == selectedBranch;
    final alpha = !onSelectedBranch
        ? 0.1
        : selectedNodeId != null && !connectedToSelection
        ? 0.2
        : 0.88;
    final isAlternative = alternativeRouteLabel != null;
    final color = connectedToSelection
        ? const Color(0xFFF1D76F)
        : isAlternative
        ? const Color(0xFFB99CEB)
        : _statusColor(targetStatus);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAlternative ? 1.65 : 1.45
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = color.withValues(alpha: alpha);

    if (isAlternative) {
      _drawDashedPath(canvas, path, edgePaint);
      _drawLabel(
        canvas,
        alternativeRouteLabel,
        Offset(railX, (start.dy + end.dy) / 2 - 5),
        color.withValues(alpha: alpha),
        fontSize: 7,
        centered: true,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = connectedToSelection ? 6 : 4
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter
          ..color = color.withValues(alpha: alpha * 0.12),
      );
      canvas.drawPath(path, edgePaint);
    }
    canvas.drawCircle(
      end,
      2.4,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    double fontSize = 11,
    bool centered = false,
  }) {
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 340);
    label.paint(
      canvas,
      Offset(
        centered ? position.dx - label.width / 2 : position.dx,
        position.dy,
      ),
    );
  }

  void _drawNodeCard(Canvas canvas, TechNode node, Rect bounds) {
    const engine = TechTreeEngine();
    final status = engine.getNodeStatus(
      node,
      session,
      researchOnly: researchOnly,
    );
    final canPurchase = engine.canPurchaseNode(
      node.id,
      session,
      researchOnly: researchOnly,
    );
    final unsupportedNode =
        node.implementationStatus ==
        TechNodeImplementationStatus.unsupported;
    final selected = selectedNodeId == node.id;
    final matchingBranch =
        selectedBranch == null || node.mainBranch == selectedBranch;
    final query = searchQuery.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        node.id.toLowerCase().contains(query) ||
        node.name.toLowerCase().contains(query) ||
        node.track.toLowerCase().contains(query) ||
        node.description.toLowerCase().contains(query) ||
        node.mainBranch.title.toLowerCase().contains(query);
    final opacity = matchingBranch && matchesSearch ? 1.0 : 0.24;
    final accent = _statusColor(status);
    final borderColor = selected
        ? const Color(0xFFF3D665)
        : accent.withValues(alpha: 0.72);
    final card = RRect.fromRectAndRadius(bounds, const Radius.circular(2));

    if (selected) {
      canvas.drawShadow(
        Path()..addRRect(card),
        const Color(0xFFE4C34E).withValues(alpha: 0.24),
        10,
        false,
      );
    }
    canvas.drawRRect(
      card,
      Paint()..color = const Color(0xF0121713).withValues(alpha: opacity),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1
        ..color = borderColor.withValues(alpha: opacity),
    );

    final top = bounds.top + 6;
    _paintText(
      canvas,
      node.id,
      Offset(bounds.left + 10, top),
      _nodeBranchColor(node.branch).withValues(alpha: opacity),
      fontSize: 8,
      bold: true,
      maxWidth: 44,
    );
    _paintText(
      canvas,
      node.track.toUpperCase(),
      Offset(bounds.left + 55, top),
      const Color(0xFF88958B).withValues(alpha: opacity),
      fontSize: 7,
      bold: true,
      maxWidth: bounds.width - 128,
    );
    final stateLabel = unsupportedNode
        ? 'UYGULANMADI'
        : switch (status) {
            TechNodeStatus.purchased => 'AÇILDI',
            TechNodeStatus.unlockable => canPurchase ? 'ARAŞTIR' : 'HAZIR',
            TechNodeStatus.locked => 'KİLİTLİ',
          };
    _paintText(
      canvas,
      stateLabel,
      Offset(bounds.right - 65, top),
      accent.withValues(alpha: opacity),
      fontSize: 7,
      bold: true,
      maxWidth: 55,
      align: TextAlign.right,
    );
    _paintText(
      canvas,
      node.name,
      Offset(bounds.left + 10, bounds.top + 24),
      const Color(0xFFE4E9E4).withValues(alpha: opacity),
      fontSize: 10,
      bold: true,
      maxWidth: bounds.width - 20,
      maxLines: 2,
    );
    _paintText(
      canvas,
      unsupportedNode ? 'KAPALI' : '${node.creditCost} ÇK',
      Offset(bounds.left + 10, bounds.bottom - 19),
      (status == TechNodeStatus.purchased ? const Color(0xFF97CB75) : accent)
          .withValues(alpha: opacity),
      fontSize: 9,
      bold: true,
      maxWidth: 84,
    );
    final gates = researchOnly
        ? [
            if (node.prereqIds.isNotEmpty) 'VE ${node.prereqIds.length}',
            if (node.alternativePrerequisiteSets.isNotEmpty)
              'VEYA ${node.alternativePrerequisiteSets.length}',
          ].join('  ·  ')
        : [
            if (node.requiredEvidenceP > 0) 'P${node.requiredEvidenceP}',
            if (node.requiredDiversityV > 0) 'V${node.requiredDiversityV}',
            if (node.requiredDeliveriesD > 0) 'D${node.requiredDeliveriesD}',
          ].join('  ·  ');
    _paintText(
      canvas,
      gates,
      Offset(bounds.left + 84, bounds.bottom - 19),
      const Color(0xFF939D94).withValues(alpha: opacity),
      fontSize: 7,
      bold: true,
      maxWidth: bounds.width - 94,
      align: TextAlign.right,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    required double fontSize,
    required bool bold,
    required double maxWidth,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
  }) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          height: 1.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, position);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 5, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ResearchConnectionsPainter oldDelegate) => true;
}

String _branchName(TechMainBranch branch) => branch.title;

Color _branchColor(TechMainBranch branch) => switch (branch) {
  TechMainBranch.production => const Color(0xFFB4CE65),
  TechMainBranch.logistics => const Color(0xFF78B8C9),
  TechMainBranch.landDevelopment => const Color(0xFFE0BD58),
};

Color _nodeBranchColor(TechBranch branch) => _branchColor(branch.mainBranch);

Color _statusColor(TechNodeStatus status) => switch (status) {
  TechNodeStatus.purchased => const Color(0xFF8CC66D),
  TechNodeStatus.unlockable => const Color(0xFFE1C04E),
  TechNodeStatus.locked => const Color(0xFF78837A),
};
