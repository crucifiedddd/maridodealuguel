import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  const BookingCard({super.key, required this.booking});

  Color _statusColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (booking.status) {
      case BookingStatus.pending:
        return cs.tertiary;
      case BookingStatus.confirmed:
        return cs.primary;
      case BookingStatus.done:
        return Colors.green;
      case BookingStatus.canceled:
        return Colors.red;
    }
  }

  String _statusLabel() {
    switch (booking.status) {
      case BookingStatus.pending:
        return 'Pendente';
      case BookingStatus.confirmed:
        return 'Confirmado';
      case BookingStatus.done:
        return 'Concluído';
      case BookingStatus.canceled:
        return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(_statusLabel()),
                  backgroundColor: _statusColor(context).withOpacity(.12),
                  labelStyle: TextStyle(
                    color: _statusColor(context).withOpacity(.95),
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.schedule, text: booking.formattedDate),
            _InfoRow(icon: Icons.place_outlined, text: booking.address),
            if (booking.notes.isNotEmpty)
              _InfoRow(icon: Icons.notes_outlined, text: booking.notes),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18),
                Text(
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                  ).format(booking.price),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}
