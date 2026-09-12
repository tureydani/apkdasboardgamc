import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/index.dart';
import '../../core/services/nominatim_service.dart';

enum _SearchStatus { idle, loading, results, empty, error }

/// Buscador de sectores para el mapa: busca zonas, calles y direcciones vía
/// [NominatimService] y, una vez elegida una zona, la muestra como chip de
/// filtro activo con cantidad de resultados y acción de limpiar. El
/// desplegable de sugerencias se dibuja en el [Overlay] de la app (vía
/// [CompositedTransformFollower]) para que siempre quede por encima de todo
/// lo demás en pantalla, incluidos los controles flotantes del mapa.
class MapZoneSearchField extends StatefulWidget {
  final GeoSearchResult? selectedZone;
  final int? filteredCount;
  final ValueChanged<GeoSearchResult> onZoneSelected;
  final VoidCallback onZoneCleared;

  const MapZoneSearchField({
    super.key,
    required this.onZoneSelected,
    required this.onZoneCleared,
    this.selectedZone,
    this.filteredCount,
  });

  @override
  State<MapZoneSearchField> createState() => _MapZoneSearchFieldState();
}

class _MapZoneSearchFieldState extends State<MapZoneSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  Timer? _debounce;
  int _searchGeneration = 0;
  OverlayEntry? _overlayEntry;

  _SearchStatus _status = _SearchStatus.idle;
  List<GeoSearchResult> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _overlayEntry?.remove();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _status = _SearchStatus.idle;
        _results = const [];
      });
      _syncOverlay();
      return;
    }

    setState(() => _status = _SearchStatus.loading);
    _syncOverlay();
    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final generation = ++_searchGeneration;
    try {
      final results = await NominatimService.search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _status = results.isEmpty ? _SearchStatus.empty : _SearchStatus.results;
      });
      _syncOverlay();
    } on NominatimException {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _status = _SearchStatus.error;
      });
      _syncOverlay();
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _status = _SearchStatus.error;
      });
      _syncOverlay();
    }
  }

  void _selectResult(GeoSearchResult result) {
    _debounce?.cancel();
    _searchGeneration++;
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _status = _SearchStatus.idle;
      _results = const [];
    });
    _syncOverlay();
    widget.onZoneSelected(result);
  }

  void _clearZone() {
    widget.onZoneCleared();
  }

  /// Limpia tanto el texto escrito como cualquier sugerencia pendiente —
  /// a diferencia de un simple reset de la búsqueda, es "empezar de cero".
  void _clearQuery() {
    _debounce?.cancel();
    _searchGeneration++;
    _controller.clear();
    setState(() {
      _status = _SearchStatus.idle;
      _results = const [];
    });
    _syncOverlay();
  }

  void _editZone() {
    widget.onZoneCleared();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedZone != null) {
      return _buildActiveZoneChip(widget.selectedZone!);
    }

    // El desplegable se muestra vía OverlayEntry (ver _syncOverlay) en vez
    // de quedar en línea debajo del campo, así siempre queda por encima del
    // resto de la pantalla — incluidos los botones flotantes del mapa — sin
    // importar dónde esté este widget en el Stack de la página.
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(key: _fieldKey, child: _buildSearchInput()),
    );
  }

  void _syncOverlay() {
    if (!mounted) return;
    final shouldShow = _status != _SearchStatus.idle;
    if (shouldShow) {
      if (_overlayEntry == null) {
        _overlayEntry = _buildOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? MediaQuery.sizeOf(context).width;
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            child: Material(
              type: MaterialType.transparency,
              child: _buildDropdown(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar sector o dirección',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
          prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: AppSpacing.iconMd),
          suffixIcon: _status == _SearchStatus.loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: AppColors.textTertiary, size: AppSpacing.iconSm),
                      onPressed: _clearQuery,
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildDropdownContent(),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildDropdownContent() {
    switch (_status) {
      case _SearchStatus.results:
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: _results.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) => _buildResultTile(_results[index]),
        );
      case _SearchStatus.empty:
        return _buildDropdownMessage(Icons.search_off, 'No encontramos ese sector.');
      case _SearchStatus.error:
        return _buildDropdownMessage(Icons.wifi_off, 'No se pudo realizar la búsqueda. Intenta nuevamente.');
      case _SearchStatus.loading:
      case _SearchStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDropdownMessage(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyMediumSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(GeoSearchResult result) {
    final icon = switch (result.kind) {
      GeoResultKind.area => Icons.location_city,
      GeoResultKind.street => Icons.route,
      GeoResultKind.place => Icons.place_outlined,
    };

    return InkWell(
      onTap: () => _selectResult(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSpacing.iconMd, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.primaryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.secondaryLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.secondaryLabel,
                      style: AppTextStyles.bodySmallSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveZoneChip(GeoSearchResult zone) {
    // Solo un resultado de área realmente filtra emergencias — mostrar un
    // conteo para una calle/lugar implicaría un filtro que nunca ocurrió.
    final count = zone.kind == GeoResultKind.area ? widget.filteredCount : null;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.secondary, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _editZone,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Row(
          children: [
            Icon(Icons.place, color: AppColors.secondary, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zone.primaryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null)
                    Text(
                      '$count ${count == 1 ? 'emergencia encontrada' : 'emergencias encontradas'}',
                      style: AppTextStyles.bodySmallSecondary,
                    ),
                ],
              ),
            ),
            InkWell(
              onTap: _clearZone,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.close, color: AppColors.textTertiary, size: AppSpacing.iconSm),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}
