# Changelog

## [Unreleased]

### Added

- Add `Resource.create!` method that raises on failure.
  ```ruby
  Post.create!
  # => raises RemoteResource::ResourceInvalid:
  #      Validation failed: Title Please use a title which is more than 5 characters.
  ```

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
