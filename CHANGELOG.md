# Changelog

## [Unreleased]

## [1.3.2] - 2023-08-08

### Added

- Allow using request body for GET requests by passing `force_get_params_in_body: true`.

    User.all(params: {ids: ids}, force_get_params_in_body: true)

## [1.3.1] - 2023-02-26

### Changed

- Update request_store dependency to 1.6.

## [1.3.0] - 2022-07-04

- Public release to Github.
