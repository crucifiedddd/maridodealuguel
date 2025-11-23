import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingRepository {
  CollectionReference<Map<String, dynamic>> _userCol(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings');

  Stream<List<Booking>> watchUserBookings(String uid) => _userCol(uid)
      .orderBy('dateTime', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());

  Future<void> create(String uid, Booking booking) =>
      _userCol(uid).add(booking.toMap());

  Future<void> cancel(String uid, String bookingId) =>
      _userCol(uid).doc(bookingId).update({'status': 'canceled'});
}
