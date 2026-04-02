import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideHoverPopup();
    super.dispose();
  }

  void _showHoverPopup(BuildContext context, DateTime date, Offset position) {
    _hideHoverPopup(); // Ensure no duplicates
    
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final income = provider.getDailyIncome(date);
    final expense = provider.getDailyExpense(date);
    
    if (income == 0 && expense == 0) return; // Only show if there's data

    final screenSize = MediaQuery.of(context).size;
    final popLeft = position.dx < screenSize.width / 2;
    final popTop = position.dy < screenSize.height / 2;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: popLeft ? position.dx + 20 : null,
          right: !popLeft ? (screenSize.width - position.dx) + 20 : null,
          top: popTop ? position.dy + 20 : null,
          bottom: !popTop ? (screenSize.height - position.dy) + 20 : null,
          child: TapRegion(
            onTapOutside: (_) => _hideHoverPopup(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(
                         fontWeight: FontWeight.w700, 
                         fontSize: 15,
                         color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.green[500], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '\$${income.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.red[400], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '\$${expense.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red[500],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideHoverPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildHoverableDay(BuildContext context, DateTime day, bool isSelected, bool isToday, {bool outside = false}) {
    final theme = Theme.of(context);
    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final textColor = outside 
        ? Colors.grey 
        : isSelected
            ? theme.colorScheme.onPrimary
            : isWeekend 
                ? theme.colorScheme.error 
                : theme.colorScheme.onSurface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _showHoverPopup(context, day, details.globalPosition),
      child: MouseRegion(
        onEnter: (event) => _showHoverPopup(context, day, event.position),
        onExit: (_) => _hideHoverPopup(),
        child: Container(
          margin: const EdgeInsets.all(6.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary 
                : isToday 
                    ? theme.colorScheme.primary.withValues(alpha: 0.3) 
                    : null,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                 ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => _buildHoverableDay(context, day, false, false),
                todayBuilder: (context, day, focusedDay) => _buildHoverableDay(context, day, false, true),
                selectedBuilder: (context, day, focusedDay) => _buildHoverableDay(context, day, true, false),
                outsideBuilder: (context, day, focusedDay) => _buildHoverableDay(context, day, false, false, outside: true),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; 
                });
              },
              eventLoader: (day) {
                final txs = txProvider.getTransactionsForDay(day);
                return txs.isNotEmpty ? ['has_transaction'] : [];
              },
            ),
          ),
        ),
      ),
    );
  }
}
