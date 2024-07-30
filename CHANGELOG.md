# Changelog

## [Unreleased]

- Deprecate `.find_by` raising an error

  To make RemoteResource behave more like ActiveRecord add a `.find_by!` method
  that raises if the record isn't found. `.find_by` raising an error is
  deprecated. In version 2.0 `.find_by` wil return `nil` instead.

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
