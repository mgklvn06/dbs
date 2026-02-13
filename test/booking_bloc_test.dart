import 'package:flutter_test/flutter_test.dart';
import 'package:dbs/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:dbs/features/booking/presentation/bloc/booking_event.dart';
import 'package:dbs/features/booking/presentation/bloc/booking_state.dart';
import 'package:dbs/features/booking/domain/usecases/book_appointment.dart';
import 'package:dbs/features/booking/domain/usecases/get_appointments_for_user.dart';
import 'package:dbs/features/booking/domain/repositories/booking_repository.dart';
import 'package:dbs/features/booking/domain/entities/appointment.dart';

class FakeBookingRepository implements BookingRepository {
  bool updated = false;

  @override
  Future<AppointmentEntity> bookAppointment(AppointmentEntity appointment) async {
    return AppointmentEntity(id: '1', userId: appointment.userId, doctorId: appointment.doctorId, dateTime: appointment.dateTime, status: appointment.status);
  }

  @override
  Future<List<AppointmentEntity>> getAppointmentsForUser(String userId) async {
    return [AppointmentEntity(id: '1', userId: userId, doctorId: 'd1', dateTime: DateTime.now(), status: 'pending')];
  }

  @override
  Future<List<AppointmentEntity>> getAppointmentsForDoctor(String doctorId) async {
    return [AppointmentEntity(id: '1', userId: 'u1', doctorId: doctorId, dateTime: DateTime.now(), status: 'pending')];
  }

  @override
  Future<List<AppointmentEntity>> getAllAppointments() async {
    return [AppointmentEntity(id: '1', userId: 'u1', doctorId: 'd1', dateTime: DateTime.now(), status: 'pending')];
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    updated = true;
  }
}

void main() {
  group('BookingBloc', () {
    late FakeBookingRepository repo;
    late BookingBloc bloc;

    setUp(() {
      repo = FakeBookingRepository();
      bloc = BookingBloc(
        bookAppointment: BookAppointment(repo),
        getAppointmentsForUser: GetAppointmentsForUser(repo),
        bookingRepository: repo,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('loads all appointments and updates status', () async {
      // Expect loading then list loaded
      final loadFuture = expectLater(
        bloc.stream,
        emitsInOrder([isA<BookingLoading>(), isA<BookingListLoaded>()]),
      );

      bloc.add(const LoadAllAppointmentsRequested());
      await loadFuture;

      // Expect loading and then initial after update
      final updateFuture = expectLater(
        bloc.stream,
        emitsInOrder([isA<BookingLoading>(), isA<BookingInitial>()]),
      );

      bloc.add(const UpdateAppointmentStatusRequested(appointmentId: '1', status: 'accepted'));
      await updateFuture;

      expect(repo.updated, isTrue);
    });
  });
}
