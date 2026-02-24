# Changelog

## [Unreleased]

## [1.3.5] - 2026-02-24

### Added

- Enrich DELETE action with body params

## [1.3.4] - 2024-10-29

### Added

- Add an alias `:update` for the method `:update_attributes`

## [1.3.3] - 2023-08-20

### Added

- Add HTTP 429 TooManyRequests error

## [1.3.2] - 2023-08-08

### Added

- Allow using request body for GET requests by passing `force_get_params_in_body: true`.

  ```ruby
  User.all(params: {ids: ids}, force_get_params_in_body: true)
  ```

## [1.3.1] - 2023-02-26

### Changed

- Update request_store dependency to 1.6.

## [1.3.0] - 2022-07-04

- Public release to Github.
