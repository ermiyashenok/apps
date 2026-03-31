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
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _showTransactionPopup(BuildContext context, DateTime date) {
    if (_tapPosition == null) return;
    
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final income = provider.getDailyIncome(date);
    final expense = provider.getDailyExpense(date);
    
    // Calculate best position
    final screenSize = MediaQuery.of(context).size;
    final popLeft = _tapPosition!.dx < screenSize.width / 2;
    final popTop = _tapPosition!.dy < screenSize.height / 2;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent, // Invisible barrier so it feels like a subtle popup
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              left: popLeft ? _tapPosition!.dx + 10 : null,
              right: !popLeft ? (screenSize.width - _tapPosition!.dx) + 10 : null,
              top: popTop ? _tapPosition!.dy : null,
              bottom: !popTop ? (screenSize.height - _tapPosition!.dy) : null,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
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
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                 ),
              ],
            ),
            child: Listener(
              onPointerDown: (event) {
                // Capture the exact location on the screen when tapped
                _tapPosition = event.position;
              },
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
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; 
                  });
                  _showTransactionPopup(context, selectedDay);
                },
                eventLoader: (day) {
                  // Show a small dot marker if there are any transactions on this day
                  final txs = txProvider.getTransactionsForDay(day);
                  return txs.isNotEmpty ? ['has_transaction'] : [];
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
