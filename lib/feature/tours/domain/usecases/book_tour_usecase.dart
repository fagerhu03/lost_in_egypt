import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/tours_repository.dart';

class BookTourUseCase {
  final ToursRepository repository;

  BookTourUseCase({required this.repository});

  Future<Either<Failure, void>> call(BookingEntity booking) async {
    return await repository.bookTour(booking);
  }
}
