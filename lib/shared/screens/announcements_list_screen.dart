import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/announcement_card.dart';

class AnnouncementsListScreen extends StatefulWidget {
  final ApiService api;
  final String currentUid;
  final String currentRole;
  final String? grade;
  final void Function(AnnouncementModel)? onToggleLike;

  const AnnouncementsListScreen({
    super.key,
    required this.api,
    required this.currentUid,
    required this.currentRole,
    this.grade,
    this.onToggleLike,
  });

  @override
  State<AnnouncementsListScreen> createState() =>
      _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  final _items = <AnnouncementModel>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoad = true;
  static const _pageSize = 10;

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
      final data = await widget.api.getAnnouncementsPaginated(
        grade: widget.grade,
        limit: _pageSize,
        after: after,
      );
      final rawItems =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final newItems =
          rawItems.map((m) => AnnouncementModel.fromJson(m)).toList();
      setState(() {
        _items.addAll(newItems);
        _hasMore = data['hasMore'] == true;
        _initialLoad = false;
      });
    } catch (e) {
      debugPrint('Announcements paginated error: $e');
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
        title: const Text('Announcements',
            style: TextStyle(
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
                    Icon(Icons.campaign_outlined,
                        color: TatvaColors.neutral400, size: 48),
                    const SizedBox(height: 12),
                    const Text('No announcements yet',
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
                    final a = _items[i];
                    return AnnouncementCard(
                      announcement: a,
                      currentUid: widget.currentUid,
                      currentRole: widget.currentRole,
                      isFirst: i == 0,
                      onLike: widget.onToggleLike != null
                          ? () => widget.onToggleLike!(a)
                          : null,
                    );
                  },
                ),
    );
  }
}
