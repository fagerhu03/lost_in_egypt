import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_data_source.dart';
import '../models/review_model.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsDataSource dataSource;

  ReviewsRepositoryImpl({required this.dataSource});

  @override
  Stream<List<ReviewEntity>> getGuideReviews(String guideId) {
    return dataSource.getGuideReviews(guideId);
  }

  @override
  Stream<List<ReviewEntity>> getTourReviews(String tourId) {
    return dataSource.getTourReviews(tourId);
  }

  @override
  Future<Either<Failure, void>> submitReview(ReviewEntity review) async {
    try {
      final model = ReviewModel(
        id: review.id,
        tourId: review.tourId,
        guideId: review.guideId,
        touristId: review.touristId,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
      );

      await dataSource.submitReview(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }
}
