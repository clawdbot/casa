# Repository Guidelines

## Project Structure & Module Organization

- `Casa/` holds the Mac Catalyst app source, SwiftUI views, HomeKit server, and app settings.
- `CasaTests/` contains XCTest unit tests.
- `CasaCLI/` is a Swift Package for the `casa` CLI (embedded into the app build).
- `Casa.xcodeproj/` is the primary Xcode project and scheme.
- `scripts/` contains developer utilities (linting, local restart).
- `Casa/Assets.xcassets/` stores icons and asset catalogs.

## Build, Test, and Development Commands

- `./scripts/restart-mac.sh` builds and relaunches the app locally (terminal flow).
- `./scripts/lint.sh` runs SwiftLint with `.swiftlint.yml`.
- `cd CasaCLI && swift run casa devices` runs the CLI directly from the package.
- Xcode: open `Casa.xcodeproj`, set your Team, enable HomeKit capability, then Build/Run.
- Tests: run Product > Test in Xcode (or `xcodebuild -scheme Casa -destination 'platform=macOS' test`, adjust destination as needed).

## Coding Style & Naming Conventions

- Swift style follows Xcode defaults (4-space indentation, Swift API naming).
- Keep method names descriptive and use `test...` for XCTest methods.
- SwiftLint is enabled with a 120 warning / 160 error line length; keep lines within limits.

## Testing Guidelines

- Framework: XCTest in `CasaTests/`.
- Prefer small, fast unit tests that exercise request/response parsing and payload encoding.
- Name tests with the `test` prefix (e.g., `testHTTPResponseEnvelope`).

## Commit & Pull Request Guidelines

- Commit messages use short, imperative summaries (e.g., "Add settings and logging").
- PRs should include: a clear summary, testing notes, and screenshots for UI changes.
- Link related issues or describe motivation when no issue exists.

## Security & Configuration Notes

- HomeKit entitlement is required; run once from Xcode to trigger permissions.
- Sparkle update settings use `SPARKLE_FEED_URL` and `SPARKLE_PUBLIC_KEY` for builds.
- The local API is loopback-only; keep any auth tokens out of source control.
- When running `./scripts/restart-mac.sh` locally you may see a missing “Mac Development” certificate error because the sandboxed agent cannot access your keychain; give the CLI full filesystem access (or run outside the sandbox) so Xcode can read your certs and provisioning profiles.
