import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review_entity.dart';

abstract class ReviewsRepository {
  Future<Either<Failure, void>> submitReview(ReviewEntity review);
  Stream<List<ReviewEntity>> getTourReviews(String tourId);
  Stream<List<ReviewEntity>> getGuideReviews(String guideId);
}
