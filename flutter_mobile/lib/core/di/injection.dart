import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// Global service locator.
///
/// Use `getIt<T>()` from anywhere outside widgets/blocs (which receive deps
/// via constructor) to retrieve a registered dependency. Direct usage inside
/// widgets is discouraged — always inject via `BlocProvider`/constructor.
final GetIt getIt = GetIt.instance;

/// Bootstraps every `@injectable`/`@module` annotated dependency.
///
/// Call this **once** during app start, before `runApp`. The generated
/// [`injection.config.dart`](injection.config.dart) — produced by
/// `dart run build_runner build` — owns the actual registration code.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
GetIt configureDependencies({String environment = Environment.prod}) =>
    getIt.init(environment: environment);
