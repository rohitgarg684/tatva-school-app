import 'package:flutter/material.dart';
import '../../models/activity_event.dart';
import '../../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/activity_event_row.dart';

class ActivityListScreen extends StatefulWidget {
  final ApiService api;
  final String? targetUid;
  final String? classId;
  final String title;

  const ActivityListScreen({
    super.key,
    required this.api,
    this.targetUid,
    this.classId,
    this.title = 'Activity',
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
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
        targetUid: widget.targetUid,
        classId: widget.classId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      appBar: AppBar(
        backgroundColor: TatvaColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TatvaColors.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TatvaColors.neutral900)),
        centerTitle: false,
      ),
      body: _initialLoad
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.timeline_outlined,
                        color: TatvaColors.neutral400, size: 48),
                    const SizedBox(height: 12),
                    const Text('No recent activity',
                        style: TextStyle(
                            fontSize: 15, color: TatvaColors.neutral400)),
                  ]))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child:
                                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    return ActivityEventRow(
                      event: _items[i],
                      isLast: i == _items.length - 1,
                    );
                  },
                ),
    );
  }
}
