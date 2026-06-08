import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/timezone_service.dart';
import '../services/event_service.dart';

class WorldTimePage extends StatefulWidget {
  const WorldTimePage({super.key});

  @override
  State<WorldTimePage> createState() => _WorldTimePageState();
}

class _WorldTimePageState extends State<WorldTimePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _clockTimer;
  final _searchController = TextEditingController();
  final _converterFromController = TextEditingController();
  final _converterToController = TextEditingController();
  List<TimezoneInfo> _searchResults = [];

  TimezoneInfo? _selectedFrom;
  TimezoneInfo? _selectedTo;
  String _converterTime = '';

  final _eventTitleController = TextEditingController();
  final _eventNotesController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _eventTime = TimeOfDay(
    hour: DateTime.now().hour + 1,
    minute: DateTime.now().minute,
  );
  String? _selectedEventCity;
  List<TimezoneInfo> _visibleCities = [];
  bool _showAllCities = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _visibleCities = TimezoneService.cities.take(6).toList();
    _loadEvents();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _converterFromController.dispose();
    _converterToController.dispose();
    _eventTitleController.dispose();
    _eventNotesController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('World Time & Events'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: c.accent,
          unselectedLabelColor: c.textSecondary,
          indicatorColor: c.accent,
          tabs: const [
            Tab(icon: Icon(Icons.public, size: 20), text: 'World Clock'),
            Tab(icon: Icon(Icons.swap_horiz, size: 20), text: 'Converter'),
            Tab(icon: Icon(Icons.event, size: 20), text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWorldClock(c), _buildConverter(c), _buildEvents(c)],
      ),
    );
  }

  Widget _buildWorldClock(AppThemeColors c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'World Clock',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search city or country...',
            hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 20, color: c.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: c.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : null,
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (v) {
            setState(() {
              _searchResults = v.isEmpty ? [] : TimezoneService.search(v);
            });
          },
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (_, i) {
                final tz = _searchResults[i];
                return ListTile(
                  dense: true,
                  leading: Text(tz.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    '${tz.city}, ${tz.country}',
                    style: TextStyle(color: c.text, fontSize: 14),
                  ),
                  subtitle: Text(
                    tz.utcOffset,
                    style: TextStyle(color: c.textSecondary, fontSize: 11),
                  ),
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      if (!_visibleCities.any(
                        (x) => x.city == tz.city && x.country == tz.country,
                      )) {
                        _visibleCities = [tz, ..._visibleCities];
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_visibleCities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No cities added yet. Search above to add cities.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ..._visibleCities.map((tz) => _buildClockCard(tz, c)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showAllCities = !_showAllCities;
              _visibleCities = _showAllCities
                  ? List.from(TimezoneService.cities)
                  : TimezoneService.cities.take(6).toList();
            });
          },
          icon: Icon(
            _showAllCities ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          label: Text(_showAllCities ? 'Show Less' : 'Show All Cities'),
          style: TextButton.styleFrom(foregroundColor: c.accent),
        ),
      ],
    );
  }

  Widget _buildClockCard(TimezoneInfo tz, AppThemeColors c) {
    final isDay = tz.isDaytime;
    final now = tz.nowInZone();
    final hour = now.hour;
    final minute = now.minute;
    final second = now.second;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accentTertiary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(tz.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tz.city}, ${tz.country}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tz.utcOffset,
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDay ? Icons.wb_sunny : Icons.nights_stay,
                      size: 14,
                      color: isDay ? c.accent : c.accentSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.text,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tz.dateFormatted,
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConverter(AppThemeColors c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Timezone Converter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 16),
        Text('From', style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 4),
        _buildTimezonePicker(
          (tz) {
            setState(() => _selectedFrom = tz);
            _converterFromController.text =
                '${tz.flag} ${tz.city} (${tz.utcOffset})';
            _updateConverter();
          },
          c,
          _converterFromController,
        ),
        const SizedBox(height: 16),
        Text('To', style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 4),
        _buildTimezonePicker(
          (tz) {
            setState(() => _selectedTo = tz);
            _converterToController.text =
                '${tz.flag} ${tz.city} (${tz.utcOffset})';
            _updateConverter();
          },
          c,
          _converterToController,
        ),
        if (_converterTime.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Time Difference',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _converterTime,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimezonePicker(
    void Function(TimezoneInfo) onSelected,
    AppThemeColors c,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Select timezone...',
        hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          size: 20,
          color: c.textSecondary,
        ),
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onTap: () => _showTimezonePicker(c, onSelected),
    );
  }

  void _showTimezonePicker(
    AppThemeColors c,
    void Function(TimezoneInfo) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final search = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final results = search.text.isEmpty
                ? TimezoneService.cities
                : TimezoneService.search(search.text);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: search,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: c.textSecondary,
                      ),
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final tz = results[i];
                        return ListTile(
                          dense: true,
                          leading: Text(
                            tz.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            '${tz.city}, ${tz.country}',
                            style: TextStyle(color: c.text, fontSize: 14),
                          ),
                          subtitle: Text(
                            tz.utcOffset,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () {
                            onSelected(tz);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateConverter() {
    if (_selectedFrom == null || _selectedTo == null) return;
    final diff = TimezoneService.timeDifferenceMinutes(
      _selectedFrom!,
      _selectedTo!,
    );
    final fromTime = _selectedFrom!.nowInZone();
    final toTime = _selectedTo!.nowInZone();
    setState(() {
      _converterTime =
          'When it is ${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')} in ${_selectedFrom!.city},\n'
          'it is ${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')} in ${_selectedTo!.city}.\n'
          '${_selectedTo!.city} is ${TimezoneService.formatTimeDifference(diff)} of ${_selectedFrom!.city}.';
    });
  }

  Widget _buildEvents(AppThemeColors c) {
    final upcoming = eventService.getUpcoming();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: c.accent.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming events',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add a new event',
                    style: TextStyle(color: c.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...upcoming.map((e) => _buildEventCard(e, c)),
        const SizedBox(height: 16),
        Center(
          child: FloatingActionButton.extended(
            onPressed: () => _showAddEventDialog(c),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Event'),
            backgroundColor: c.accent,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent e, AppThemeColors c) {
    final now = DateTime.now();
    final diff = e.dateTime.difference(now);
    String remaining;
    if (diff.isNegative) {
      remaining = 'Past';
    } else if (diff.inDays > 0) {
      remaining = '${diff.inDays}d ${diff.inHours % 24}h remaining';
    } else if (diff.inHours > 0) {
      remaining = '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
    } else {
      remaining = '${diff.inMinutes}m remaining';
    }

    final month = e.dateTime.month.toString().padLeft(2, '0');
    final day = e.dateTime.day.toString().padLeft(2, '0');
    final hour = e.dateTime.hour.toString().padLeft(2, '0');
    final min = e.dateTime.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accentTertiary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 9,
                      color: c.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 16,
                      color: c.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$hour:$min',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  if (e.notes != null && e.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      e.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    remaining,
                    style: TextStyle(
                      fontSize: 10,
                      color: diff.isNegative ? c.accentSecondary : c.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: c.accentSecondary,
              ),
              onPressed: () async {
                await eventService.remove(e.id);
                _loadEvents();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(AppThemeColors c) {
    _eventTitleController.clear();
    _eventNotesController.clear();
    _eventDate = DateTime.now().add(const Duration(hours: 1));
    _eventTime = TimeOfDay(
      hour: DateTime.now().hour + 1,
      minute: DateTime.now().minute,
    );
    _selectedEventCity = null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'New Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextField(
                    controller: _eventTitleController,
                    decoration: InputDecoration(
                      labelText: 'Event title',
                      labelStyle: TextStyle(color: c.textSecondary),
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: c.text),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _eventNotesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      labelStyle: TextStyle(color: c.textSecondary),
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: c.text),
                  ),
                  const SizedBox(height: 12),
                  Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: _eventDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setDialogState(() => _eventDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 12, color: c.accent),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.accent,
                              side: BorderSide(
                                color: c.accent.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: ctx,
                                initialTime: _eventTime,
                              );
                              if (time != null) {
                                setDialogState(() => _eventTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              '${_eventTime.hour.toString().padLeft(2, '0')}:${_eventTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 12, color: c.accent),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.accent,
                              side: BorderSide(
                                color: c.accent.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Timezone city (optional)',
                      labelStyle: TextStyle(color: c.textSecondary),
                      hintText: 'e.g. Tokyo, London...',
                      hintStyle: TextStyle(color: c.textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: c.text),
                    onChanged: (v) => _selectedEventCity = v.isEmpty ? null : v,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: c.textSecondary)),
              ),
              FilledButton(
                onPressed: () async {
                  if (_eventTitleController.text.trim().isEmpty) return;
                  final dt = DateTime(
                    _eventDate.year,
                    _eventDate.month,
                    _eventDate.day,
                    _eventTime.hour,
                    _eventTime.minute,
                  );
                  final event = CalendarEvent(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _eventTitleController.text.trim(),
                    dateTime: dt,
                    notes: _eventNotesController.text.trim().isEmpty
                        ? null
                        : _eventNotesController.text.trim(),
                    city: _selectedEventCity,
                  );
                  await eventService.add(event);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadEvents();
                },
                style: FilledButton.styleFrom(backgroundColor: c.accent),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
  }
}
