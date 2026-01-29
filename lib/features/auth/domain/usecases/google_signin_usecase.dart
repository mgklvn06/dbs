import 'package:dartz/dartz.dart';
import 'package:dbs/core/errors/failures.dart';
import 'package:dbs/features/auth/domain/entities/user.dart';
import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await repository.signInWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
