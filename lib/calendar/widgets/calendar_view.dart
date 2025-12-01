import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/calendar/data/event_data_source.dart';
import 'package:success_academy/helpers/tz_date_time_range.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_10y.dart' as tz show initializeTimeZones;
import 'package:timezone/timezone.dart' as tz show getLocation;
import 'package:timezone/timezone.dart' show Location, TZDateTime;

import '../../account/data/account_model.dart';
import '../../generated/l10n.dart';
import '../calendar_utils.dart';
import '../data/event_model.dart';
import 'cancel_event_dialog.dart';
import 'create_event_dialog.dart';
import 'delete_event_dialog.dart';
import 'edit_event_dialog.dart';
import 'signup_event_dialog.dart';
import 'view_event_dialog.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventDataSource(
        timeZone: context.read<AccountModel>().myUser!.timeZone,
      ),
      child: _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView>
    with SingleTickerProviderStateMixin {
  late final List<EventType> _availableEventTypes;
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late final Location _location;
  late final EventDataSource _eventDataSource;
  late final TabController _tabController;

  late TZDateTime _currentDay;
  late TZDateTime _focusedDay;
  late TZDateTime _selectedDay;
  late TZDateTimeRange _eventsDateTimeRange;
  late List<EventType> _selectedEventTypes;

  final Set<EventModel> _allEvents = {};
  List<EventModel> _selectedEvents = [];
  Map<DateTime, List<EventModel>> _displayedEvents = {};
  EventDisplay _eventDisplay = EventDisplay.all;
  bool _showLoadingIndicator = false;

  // フィルター状態
  bool _showFree = true;
  bool _showPreschool = true;
  bool _showPrivate = true;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _tabController = TabController(length: 2, vsync: this);
    final account = context.read<AccountModel>();
    _location = tz.getLocation(account.myUser!.timeZone);
    _currentDay = _focusedDay = _selectedDay = _getCurrentDate();
    _firstDay = _currentDay.subtract(const Duration(days: 1000));
    _lastDay = _currentDay.add(const Duration(days: 1000));
    _availableEventTypes = _selectedEventTypes =
        getEventTypesCanView(account.userType, account.subscriptionPlan);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _eventDataSource = context.watch<EventDataSource>();
    _eventsDateTimeRange = TZDateTimeRange(
      start: _focusedDay.subtract(Duration(days: 21)),
      end: _focusedDay.add(Duration(days: 21)),
    );
    _loadEvents(_eventsDateTimeRange);
  }

  void _loadEvents(TZDateTimeRange dateTimeRange) async {
    setState(() {
      _showLoadingIndicator = true;
    });

    _allEvents.addAll(
      await _eventDataSource.loadDataByKey(
        dateTimeRange,
      ),
    );
    _filterEvents();

    setState(() {
      _displayedEvents = buildEventMap(_allEvents);
      _selectedEvents = _getEventsForDay(_selectedDay);
      _showLoadingIndicator = false;
    });
  }

  void _filterEvents() {
    final account = context.read<AccountModel>();
    _displayedEvents = buildEventMap(
      _allEvents.where((event) {
        if (!_selectedEventTypes.contains(event.eventType)) {
          return false;
        }
        if (_eventDisplay == EventDisplay.mine) {
          if (account.userType == UserType.teacher) {
            return isTeacherInEvent(account.teacherProfile!.profileId, event);
          }
          if (account.userType == UserType.student) {
            return isStudentInEvent(account.studentProfile!.profileId, event);
          }
        }
        return true;
      }).toList(),
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _displayedEvents[DateUtils.dateOnly(day)] ?? [];
  }

  void _deleteEventsLocally({
    required String eventId,
    bool isRecurrence = false,
    DateTime? from,
  }) {
    if (isRecurrence) {
      setState(() {
        for (final eventList in _displayedEvents.values) {
          eventList.removeWhere((e) {
            if (from != null) {
              return e.startTime.isAfter(from) && e.recurrenceId == eventId;
            }
            return e.recurrenceId == eventId;
          });
        }
      });
    } else {
      setState(() {
        for (final eventList in _displayedEvents.values) {
          eventList.removeWhere((e) => e.eventId == eventId);
        }
      });
    }
  }

  void _onTodayButtonClick() {
    setState(() {
      _focusedDay = _selectedDay = _currentDay = _getCurrentDate();
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  void _onEventFiltersChanged(
    List<EventType> eventTypes,
    EventDisplay eventDisplay,
  ) {
    setState(() {
      _selectedEventTypes = eventTypes;
      _eventDisplay = eventDisplay;
    });
    _filterEvents();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = TZDateTime(
        _location,
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      _focusedDay = TZDateTime(
        _location,
        focusedDay.year,
        focusedDay.month,
        focusedDay.day,
      );
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = TZDateTime(
      _location,
      focusedDay.year,
      focusedDay.month,
      focusedDay.day,
    );
    if (_focusedDay
        .subtract(Duration(days: 7))
        .isBefore(_eventsDateTimeRange.start)) {
      _eventsDateTimeRange = TZDateTimeRange(
        start: _focusedDay.subtract(const Duration(days: 42)),
        end: _eventsDateTimeRange.end,
      );
      _loadEvents(
        _eventsDateTimeRange,
      );
    }
    if (_focusedDay.add(Duration(days: 14)).isAfter(_eventsDateTimeRange.end)) {
      _eventsDateTimeRange = TZDateTimeRange(
        start: _eventsDateTimeRange.start,
        end: _focusedDay.add(const Duration(days: 42)),
      );
      _loadEvents(
        _eventsDateTimeRange,
      );
    }
  }

  TZDateTime _getCurrentDate() {
    return TZDateTime.from(
      DateUtils.dateOnly(
        TZDateTime.now(
          _location,
        ),
      ),
      _location,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              Text(S.of(context).filter),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Text(S.of(context).free),
                subtitle: const Text('フリーレッスン'),
                value: _showFree,
                activeColor: Colors.amber,
                onChanged: (value) {
                  setDialogState(() {
                    _showFree = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text(S.of(context).preschool),
                subtitle: const Text('未就学レッスン'),
                value: _showPreschool,
                activeColor: Colors.lightBlue,
                onChanged: (value) {
                  setDialogState(() {
                    _showPreschool = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text(S.of(context).private),
                subtitle: const Text('個別レッスン'),
                value: _showPrivate,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setDialogState(() {
                    _showPrivate = value!;
                  });
                },
              ),
              const Divider(),
              // 自分のイベントのみ表示
              RadioListTile<EventDisplay>(
                title: Text(EventDisplay.all.getName(context)),
                value: EventDisplay.all,
                groupValue: _eventDisplay,
                onChanged: (value) {
                  setDialogState(() {
                    _eventDisplay = value!;
                  });
                },
              ),
              RadioListTile<EventDisplay>(
                title: Text(EventDisplay.mine.getName(context)),
                value: EventDisplay.mine,
                groupValue: _eventDisplay,
                onChanged: (value) {
                  setDialogState(() {
                    _eventDisplay = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {});
                _filterEvents();
                Navigator.pop(context);
              },
              child: Text(S.of(context).confirm),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);
    final userType = context.select<AccountModel, UserType>((a) => a.userType);
    final teacherId = context
        .select<AccountModel, String?>((a) => a.teacherProfile?.profileId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _showLoadingIndicator
            ? LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.background,
              )
            : const SizedBox(height: 4),
        Card(
          child: TableCalendar(
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              leftChevronPadding: EdgeInsets.all(8),
              rightChevronPadding: EdgeInsets.all(8),
              leftChevronMargin: EdgeInsets.symmetric(horizontal: 4),
              rightChevronMargin: EdgeInsets.symmetric(horizontal: 4),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) => _CalendarHeader(
                day: day,
                onTodayButtonClick: _onTodayButtonClick,
                onFilterButtonClick: _showFilterDialog,
              ),
            ),
            calendarFormat: CalendarFormat.week,
            daysOfWeekHeight: 20,
            locale: locale,
            currentDay: _currentDay,
            focusedDay: _focusedDay,
            firstDay: _firstDay,
            lastDay: _lastDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            eventLoader: _getEventsForDay,
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              DateFormat.yMMMMEEEEd(locale).format(_selectedDay),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        // タブバー
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).colorScheme.primary,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'フリーレッスン'),
              Tab(text: '個別レッスン'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  // フリーレッスンタブ（フリー＋未就学）
                  _GroupLessonList(
                    events: _selectedEvents,
                    showFree: _showFree,
                    showPreschool: _showPreschool,
                    refreshState: () {
                      setState(() {});
                    },
                  ),
                  // 個別レッスンタブ
                  _PrivateLessonList(
                    events: _selectedEvents,
                    showPrivate: _showPrivate,
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    refreshState: () {
                      setState(() {});
                    },
                    deleteEventsLocally: _deleteEventsLocally,
                  ),
                ],
              ),
              if (canEditEvents(userType))
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(kFloatingActionButtonMargin),
                    child: FloatingActionButton.extended(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => CreateEventDialog(
                          teacherId: teacherId,
                          firstDay: _firstDay,
                          lastDay: _lastDay,
                          selectedDay: _selectedDay,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                        S.of(context).createEvent,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// カレンダーヘッダー（タイムゾーンバナー付き）
// ============================================

class _CalendarHeader extends StatelessWidget {
  final DateTime day;
  final VoidCallback onTodayButtonClick;
  final VoidCallback onFilterButtonClick;

  const _CalendarHeader({
    required this.day,
    required this.onTodayButtonClick,
    required this.onFilterButtonClick,
  });

  // タイムゾーンを見やすくフォーマット
  String _formatTimeZone(String timeZone) {
    final abbreviations = {
      'Asia/Tokyo': 'Tokyo (JST)',
      'America/Los_Angeles': 'Los Angeles (PST)',
      'America/New_York': 'New York (EST)',
      'America/Chicago': 'Chicago (CST)',
      'America/Denver': 'Denver (MST)',
      'Europe/London': 'London (GMT)',
      'Europe/Paris': 'Paris (CET)',
      'Australia/Sydney': 'Sydney (AEST)',
      'Pacific/Honolulu': 'Honolulu (HST)',
      'Asia/Singapore': 'Singapore (SGT)',
      'Asia/Hong_Kong': 'Hong Kong (HKT)',
      'Asia/Shanghai': 'Shanghai (CST)',
      'Asia/Seoul': 'Seoul (KST)',
      'Pacific/Auckland': 'Auckland (NZST)',
      'America/Sao_Paulo': 'São Paulo (BRT)',
      'Europe/Berlin': 'Berlin (CET)',
      'Asia/Dubai': 'Dubai (GST)',
    };

    return abbreviations[timeZone] ??
        timeZone.replaceAll('_', ' ').split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);
    final timeZone =
        context.select<AccountModel, String>((a) => a.myUser!.timeZone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // タイムゾーンバナー（目立つ表示）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public,
                color: Colors.blue.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '表示タイムゾーン: ',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                ),
              ),
              Text(
                _formatTimeZone(timeZone),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 月表示とフィルター
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMMM(locale).format(day),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: Text(S.of(context).filter),
                  onPressed: onFilterButtonClick,
                ),
                TextButton.icon(
                  icon: Text(S.of(context).today),
                  label: const Icon(Icons.today, size: 18),
                  onPressed: onTodayButtonClick,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// フリーレッスンタブ（フリー＋未就学）
// ============================================

class _GroupLessonList extends StatelessWidget {
  final List<EventModel> events;
  final bool showFree;
  final bool showPreschool;
  final VoidCallback refreshState;

  const _GroupLessonList({
    required this.events,
    required this.showFree,
    required this.showPreschool,
    required this.refreshState,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);

    // フィルタリング
    final freeEvents = showFree
        ? events.where((e) => e.eventType == EventType.free).toList()
        : <EventModel>[];
    final preschoolEvents = showPreschool
        ? events.where((e) => e.eventType == EventType.preschool).toList()
        : <EventModel>[];

    // グループ化
    final groupedFreeEvents = _groupEventsBySummary(freeEvents);
    final groupedPreschoolEvents = _groupEventsBySummary(preschoolEvents);

    final hasEvents =
        groupedFreeEvents.isNotEmpty || groupedPreschoolEvents.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // フリーレッスンセクション
              if (groupedFreeEvents.isNotEmpty) ...[
                _SectionHeader(
                  title: S.of(context).free,
                  color: EventType.free.getColor(context),
                  icon: EventType.free.getIcon(context),
                ),
                ...groupedFreeEvents.entries.map((entry) => _GroupedEventCard(
                      summary: entry.key,
                      events: entry.value,
                      eventType: EventType.free,
                      locale: locale,
                      refreshState: refreshState,
                    )),
                const SizedBox(height: 16),
              ],

              // 未就学レッスンセクション
              if (groupedPreschoolEvents.isNotEmpty) ...[
                _SectionHeader(
                  title: S.of(context).preschool,
                  color: EventType.preschool.getColor(context),
                  icon: EventType.preschool.getIcon(context),
                ),
                ...groupedPreschoolEvents.entries
                    .map((entry) => _GroupedEventCard(
                          summary: entry.key,
                          events: entry.value,
                          eventType: EventType.preschool,
                          locale: locale,
                          refreshState: refreshState,
                        )),
              ],

              // イベントがない場合
              if (!hasEvents)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'この日はフリーレッスンがありません',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<EventModel>> _groupEventsBySummary(List<EventModel> events) {
    final Map<String, List<EventModel>> grouped = {};
    for (final event in events) {
      final key = event.summary;
      if (grouped.containsKey(key)) {
        grouped[key]!.add(event);
      } else {
        grouped[key] = [event];
      }
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }
}

// ============================================
// 個別レッスンタブ
// ============================================

class _PrivateLessonList extends StatelessWidget {
  final List<EventModel> events;
  final bool showPrivate;
  final DateTime firstDay;
  final DateTime lastDay;
  final VoidCallback refreshState;
  final void Function({
    required String eventId,
    bool isRecurrence,
    DateTime? from,
  }) deleteEventsLocally;

  const _PrivateLessonList({
    required this.events,
    required this.showPrivate,
    required this.firstDay,
    required this.lastDay,
    required this.refreshState,
    required this.deleteEventsLocally,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);

    // フィルタリング
    final privateEvents = showPrivate
        ? events.where((e) => e.eventType == EventType.private).toList()
        : <EventModel>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (privateEvents.isNotEmpty) ...[
                ...privateEvents.map((event) => _SingleEventCard(
                      event: event,
                      locale: locale,
                      firstDay: firstDay,
                      lastDay: lastDay,
                      refreshState: refreshState,
                      deleteEventsLocally: deleteEventsLocally,
                    )),
              ],

              // イベントがない場合
              if (privateEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'この日は個別レッスンがありません',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// 共通ウィジェット
// ============================================

// セクションヘッダー
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final Widget icon;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// グループ化されたイベントカード（フリーレッスン用）
class _GroupedEventCard extends StatelessWidget {
  final String summary;
  final List<EventModel> events;
  final EventType eventType;
  final String locale;
  final VoidCallback refreshState;

  const _GroupedEventCard({
    required this.summary,
    required this.events,
    required this.eventType,
    required this.locale,
    required this.refreshState,
  });

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountModel>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: eventType.getColor(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // クラス名
            Text(
              summary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // 時間帯ボタン（横並び、折り返し可能）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: events.map((event) {
                final isSignedUp = account.userType == UserType.student &&
                    isStudentInEvent(account.studentProfile!.profileId, event);
                final isFull = isEventFull(event);
                final timeText = DateFormat.jm(locale).format(event.startTime);

                return _TimeSlotChip(
                  time: timeText,
                  isSignedUp: isSignedUp,
                  isFull: isFull,
                  onTap: () {
                    if (isSignedUp) {
                      showDialog(
                        context: context,
                        builder: (context) => CancelEventDialog(
                          event: event,
                          refresh: refreshState,
                        ),
                      );
                    } else if (!isFull) {
                      showDialog(
                        context: context,
                        builder: (context) => SignupEventDialog(
                          event: event,
                          refresh: refreshState,
                        ),
                      );
                    } else {
                      // イベント詳細を表示
                      showDialog(
                        context: context,
                        builder: (context) => ViewEventDialog(event: event),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// 時間帯チップ
class _TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isSignedUp;
  final bool isFull;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.time,
    required this.isSignedUp,
    required this.isFull,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    if (isSignedUp) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
    } else if (isFull) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
      icon = null;
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.blue.shade700;
      icon = null;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSignedUp
                ? Colors.green.shade400
                : isFull
                    ? Colors.grey.shade400
                    : Colors.blue.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              time,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (isFull && !isSignedUp) ...[
              const SizedBox(width: 4),
              Text(
                '満',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 単一イベントカード（個別レッスン用）
class _SingleEventCard extends StatelessWidget {
  final EventModel event;
  final String locale;
  final DateTime firstDay;
  final DateTime lastDay;
  final VoidCallback refreshState;
  final void Function({
    required String eventId,
    bool isRecurrence,
    DateTime? from,
  }) deleteEventsLocally;

  const _SingleEventCard({
    required this.event,
    required this.locale,
    required this.firstDay,
    required this.lastDay,
    required this.refreshState,
    required this.deleteEventsLocally,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: event.eventType.getColor(context),
      child: ListTile(
        leading: event.eventType.getIcon(context),
        trailing: _getEventActions(context),
        title: Text(
          event.summary,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          '${DateFormat.jm(locale).format(event.startTime)} - ${DateFormat.jm(locale).format(event.endTime)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        onTap: () => showDialog(
          context: context,
          builder: (context) => ViewEventDialog(event: event),
        ),
      ),
    );
  }

  Widget _getEventActions(BuildContext context) {
    final account = context.read<AccountModel>();

    if (account.userType == UserType.student) {
      if (isStudentInEvent(account.studentProfile!.profileId, event)) {
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.check, size: 18),
          label: Text(S.of(context).signedUp),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => CancelEventDialog(
              event: event,
              refresh: refreshState,
            ),
          ),
        );
      } else if (isEventFull(event)) {
        return OutlinedButton(
          onPressed: null,
          child: Text(S.of(context).eventFull),
        );
      } else {
        return OutlinedButton(
          child: Text(S.of(context).signup),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => SignupEventDialog(
              event: event,
              refresh: refreshState,
            ),
          ),
        );
      }
    }
    if (account.userType == UserType.teacher) {
      if (isTeacherInEvent(account.teacherProfile!.profileId, event)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditEventDialog(
                  event: event,
                  firstDay: firstDay,
                  lastDay: lastDay,
                  onRefresh: refreshState,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => DeleteEventDialog(
                  event: event,
                  deleteEventsLocally: deleteEventsLocally,
                ),
              ),
            ),
          ],
        );
      }
    }
    if (account.userType == UserType.admin) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => EditEventDialog(
                event: event,
                firstDay: firstDay,
                lastDay: lastDay,
                onRefresh: () {},
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => DeleteEventDialog(
                event: event,
                deleteEventsLocally: deleteEventsLocally,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
