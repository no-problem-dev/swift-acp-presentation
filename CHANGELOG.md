# Changelog

## [Unreleased]

## [0.1.3] - 2026-08-11

### Changed

- The README links to the published DocC site. The documentation had been building and deploying
  all along with nothing pointing at it.
- The documentation is in English. The doc comments and the DocC catalog page are what the published
  DocC site is built from, so they were the last Japanese left on a surface people read.
  The localized strings in `ja.lproj` and `en.lproj` are untouched — those are the feature, not the
  documentation. No API or behavior changed.

## [0.1.2] - 2026-08-11

### Changed

- Builds and tests on Linux. `String(localized:bundle:)` is Apple-only; lookup now goes through
  `NSLocalizedString`, which reads the same `.lproj` files everywhere.


## [0.1.1] - 2026-07-19

See [GitHub Releases](../../releases) for changes up to and including this version.
