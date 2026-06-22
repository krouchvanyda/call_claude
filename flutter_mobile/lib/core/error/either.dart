import 'package:dartz/dartz.dart';

import 'failure.dart';

export 'package:dartz/dartz.dart' show Either, Left, Right;

/// Convenience alias for the canonical repository return type.
///
/// Repositories return `Result<Foo>` instead of throwing — use cases pattern
/// match on `Left(failure)` / `Right(value)` and surface either to the BLoC.
typedef Result<T> = Either<Failure, T>;

/// Sugar for the success branch.
Result<T> ok<T>(T value) => Right<Failure, T>(value);

/// Sugar for the failure branch.
Result<T> err<T>(Failure failure) => Left<Failure, T>(failure);
