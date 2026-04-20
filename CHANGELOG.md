# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-20

### Added

- `Product#url` — returns the canonical storefront URL for a product (`/products/:handle`)
- `Product#prices` — deduplicated list of raw price strings across all variants
- `Product#main_image` — returns the image with `position: 1`, distinct from `featured_image` (which returns `images.first`)
- `Collection#url` — returns the canonical storefront URL for a collection (`/collections/:handle`)
- `Client#base_url` — exposes the resolved HTTPS base URL for the configured store
- `Resource#client` accessor — models now carry a reference to the client that fetched them
- Ruby 4.0 added to CI matrix
- Dependabot configuration for automated dependency updates

### Changed

- All models returned by `Client` methods (`products`, `product`, `collections`, `collection`) now have their `client` attribute set automatically, enabling instance-scoped operations without relying on the global `Showroom.client`
- `Collection#products` uses the instance client when available, falling back to the global client

## [0.1.0] - 2026-04-11

### Added

- `Showroom::Product` — fetch, find, and paginate products from public Shopify stores
- `Showroom::Collection` — fetch and find collections, with nested `CollectionProduct` support
- `Showroom::Product.all` / `Showroom::Product.each_page` — lazy Enumerator-based full-catalog pagination with `max_pages:` or `force_all_without_limit:` guard
- `Showroom::Core::Countable` — binary-search based total-count estimation (`Product.count`, `Collection.count`) with a configurable `max_count` ceiling
- `Showroom::Client` — per-instance client for multi-store usage with configurable `per_page` (default 250, capped at `MAX_PER_PAGE`)
- `Showroom.search` / `Showroom::Search.suggest` — search suggest endpoint with typed result objects (`ProductSuggestion`, `CollectionSuggestion`, `PageSuggestion`, `ArticleSuggestion`, `QuerySuggestion`)
- Loadable suggestions: `result.products.first.load` fetches the full `Product` record
- Full error hierarchy: `ConfigurationError`, `ConnectionError`, `InvalidResponse`, `NotFound`, `TooManyRequests`, `ServerError`, and more
- Module-level configuration via `Showroom.configure` with environment-variable fallbacks
- Custom Faraday middleware hook via `c.middleware`
