# Development guide

Day-to-day commands and workflows. Setup is in the [README](../README.md);
architecture in [architecture.md](architecture.md).

All `melos` commands below run from the repository root. Melos is a dev
dependency of the workspace, so `dart run melos <command>` always works; a
global install (`dart pub global activate melos 8.9.0`) lets you type
`melos <command>` instead.

## Command reference

| Command | What it does |
| --- | --- |
| `melos bootstrap` | Resolves dependencies for the whole workspace (`flutter pub get` at the root). |
| `melos run get` | Same as above, via a script. |
| `melos run format` | Formats every Dart file. |
| `melos run format:check` | Fails if any file is not formatted. |
| `melos run analyze` | `flutter analyze --fatal-infos --fatal-warnings` in every package, then `dart analyze` on `tool/`. |
| `melos run codegen` | Regenerates all generated code: `codegen:l10n` (`flutter gen-l10n`) and `codegen:build_runner` (drift). |
| `melos run codegen:check` | Regenerates and fails if the committed output was stale. |
| `melos run test` | Unit and widget tests in every package, in dependency order. |
| `melos run test:coverage` | Same, writing `coverage/lcov.info` in each package. |
| `melos run test:integration` | Integration tests of every app on a device (`DEVICE=<id>`, `APP=apps/app_bloc` to run one app). |
| `melos run check:packages` | Workspace rules: tests exist, SDK constraints, dependency direction, no cycles. |
| `melos run validate` | `check:packages` → `format:check` → `codegen:check` → `analyze` → `test`. Same gate as CI. |
| `melos run clean` | `flutter clean` in every package. |
| `dart run tool/rename_app.dart ...` | Renames application IDs and display names (see [environment-configuration.md](environment-configuration.md#identifiers-and-display-names)). |

Every multi-package script uses `failFast` and exits non-zero on the first
failure. Packages are never silently skipped: `check:packages` fails if a
package has no tests.

## Running the app

```sh
cd apps/app
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The same commands work for the Bloc app in `apps/app_bloc`. Both flags are
required on Android and iOS. The app refuses to start (and
lists the problems) if the flavor and `APP_ENV` disagree. VS Code and
IntelliJ/Android Studio launch configurations for each flavor are included
(`.vscode/launch.json`, `.idea/runConfigurations/`).

Web has no native flavors; pass only the configuration:

```sh
flutter run -d chrome --dart-define-from-file=config/dev.json
```

## Localization

1. Add the string to `packages/localization/lib/l10n/app_en.arb` with an
   `@key` entry containing a `description` (required by the configuration).
2. Add the translation to every other `app_<locale>.arb`.
3. Run `melos run codegen` and commit the regenerated files in
   `packages/localization/lib/src/generated/`.
4. Use it: `context.l10n.myKey`.

To add a language, create `app_<code>.arb` with all keys, run
`melos run codegen`, and add an option to the language list in
`features/settings/presentation/settings_page.dart`. The localization test
fails if any locale misses a key.

Reusable widgets (`design_system`) never contain user-facing text; they take
localized strings as parameters.

## Code generation

Two generators are used:

| Generator | Package | Output |
| --- | --- | --- |
| `flutter gen-l10n` | `localization` | `lib/src/generated/` |
| `build_runner` + `drift_dev` | `database` | `lib/**/*.g.dart` |

Generated files are committed so a fresh clone builds without extra steps,
and `melos run codegen:check` (part of `validate` and CI) fails if they are
out of date. It runs every generator in every workspace member that uses it,
so new `build_runner` users (for example `json_serializable`) are covered
automatically.

build_runner 2.16 removed `--delete-conflicting-outputs`; run plain
`dart run build_runner build` (or `watch`). Schema changes also need
`dart run drift_dev make-migrations` (see `packages/database/README.md`).

## Naming and file organization

- Packages: `snake_case`, a noun describing the responsibility
  (`networking`, not `network_utils`).
- Files: `snake_case.dart`; `*_page.dart` for routed screens, `*_view.dart`
  for stateless screen bodies shared by apps, `*_controller(s).dart` for
  Riverpod notifiers, `*_bloc.dart` / `*_cubit.dart` for Bloc,
  `*_repository.dart`, `*_data_source.dart`, `*_dao.dart`, `*_test.dart`.
- Public API of a package: `lib/<package>.dart` exports; implementation in
  `lib/src/`. Never import another package's `src/`.
- Imports: always `package:` imports, sorted (the analyzer enforces both).
- Tests mirror `lib/` (`lib/features/posts/...` → `test/features/posts/...`).

## Adding things

- A feature: [adding-features.md](adding-features.md)
- A package or a second app: [adding-packages.md](adding-packages.md)

## Dependency updates

- Constraints use caret ranges. The root `pubspec.lock` is committed and CI
  runs `flutter pub get --enforce-lockfile`.
- Dependabot opens weekly PRs for pub packages and GitHub Actions.
- To update manually: `flutter pub upgrade --major-versions` at the root,
  then `melos run validate` and the builds you support.
- Keep the same constraint for a dependency in every package that uses it.

## Upgrading Flutter

1. Install the new stable SDK.
2. Update `FLUTTER_VERSION` in `.github/workflows/*.yml` and the version table
   in the README.
3. Raise `environment.sdk` / `environment.flutter` in every `pubspec.yaml` only
   if you need newer language features or packages require it
   (`melos run check:packages` verifies they match the root).
4. Run `melos run validate`, the platform builds, and the integration tests.
