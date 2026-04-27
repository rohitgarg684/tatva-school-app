import 'package:flutter/material.dart';
import '../../../models/activity_event.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/activity_event_row.dart';

class ActivityTab extends StatefulWidget {
  final ApiService api;

  const ActivityTab({super.key, required this.api});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  final _items = <ActivityEvent>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoad = true;
  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final after =
          _items.isNotEmpty ? _items.last.createdAt?.toIso8601String() : null;
      final data = await widget.api.getActivitiesPaginated(
        limit: _pageSize,
        after: after,
      );
      final rawItems =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final newItems =
          rawItems.map((m) => ActivityEvent.fromJson(m)).toList();
      setState(() {
        _items.addAll(newItems);
        _hasMore = data['hasMore'] == true;
        _initialLoad = false;
      });
    } catch (e) {
      debugPrint('Activity paginated error: $e');
      setState(() => _initialLoad = false);
    }
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _hasMore = true;
      _initialLoad = true;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activity Feed',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900,
                        letterSpacing: -0.8)),
                const SizedBox(height: 4),
                const Text('School-wide events and updates',
                    style: TextStyle(
                        fontSize: 13, color: TatvaColors.neutral400)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _initialLoad
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timeline_outlined,
                                color: TatvaColors.neutral400, size: 48),
                            const SizedBox(height: 12),
                            const Text('No recent activity',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: TatvaColors.neutral400)),
                            const SizedBox(height: 6),
                            const Text(
                                'Events will appear here as they happen',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: TatvaColors.purple,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index == _items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                  child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))),
                            );
                          }
                          final event = _items[index];
                          final isLast =
                              index == _items.length - 1 && !_hasMore;
                          return StaggeredItem(
                            index: index,
                            child: ActivityEventRow(
                              event: event,
                              isLast: isLast,
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

}
