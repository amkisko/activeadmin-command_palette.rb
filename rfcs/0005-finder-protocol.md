# RFC 0005: Finder protocol

- Feature Name: finder-protocol
- Type: Standards Track
- Status: Stable
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0003, RFC 0006

## Summary

Hosts register per-kind finder callables (or supply `default_finder` for the resource DSL). The engine exposes an authenticated JSON `options` endpoint. The client searches with kind and query; the gem normalizes results and enforces minimum query length and per-kind limit. Prefixes map query prefixes to kinds.

## Motivation

Record search needs host SQL, authorization, and label rules. Putting queries inside the gem would invent schemas. An unauthenticated options endpoint would leak admin search. Without normalization, hosts would disagree on result keys and the client would break.

## Guide-level explanation

```ruby
ActiveAdmin::CommandPalette.configure do |config|
  config.register_prefix "@", kind: "user"
  config.register_finder "user" do |query:, helpers:, user:, limit:|
    # return Array of { id:, kind:, label:, url: }
  end
  config.min_query_length = 2
  config.limit = 20
  config.authorize_with = ->(controller) { controller.current_user.present? }
end
```

The client calls `GET …/options?kind=user&q=an` after debounce. Operators type `@an` when a prefix is registered, or enter kind find from a `view` action.

## Reference-level explanation

### Finder callable

Arity keywords: `query`, `helpers`, `user`, `limit`. `helpers` is `UrlHelpers` for path generation outside a view. Return an Array-like of hashes or objects responding to `to_h`.

Normalized item:

```text
{ id, kind, label, url, method }
```

Missing `kind` defaults to the requested kind. Missing `method` defaults to `get`. Results are truncated to `configuration.limit` after normalize. Queries shorter than `min_query_length` return `[]`. Unknown kinds return `[]`.

Defaults: `min_query_length` 2, `limit` 20.

### Prefixes

`register_prefix(prefix, kind:)` stores string prefix to kind. The client strips the prefix and searches that kind. Longer host prefixes that share a start character are matched in `Object.entries` order; hosts SHOULD choose non-overlapping prefixes.

### Options endpoint

Route: engine `GET options` as `options`. Controller authenticates with ActiveAdmin `authentication_method` when set, else requires `current_user_method` to return a user, else `401`. Authorization uses `authorize_with` when set, else presence of the current palette user; failure is `403`. Success renders JSON from `Finder.options`.

### Manual vs compiled finders

`register_finder` wins over a compiled resource finder for the same kind. Compiled finders require `default_finder` (RFC 0006).

## Security considerations

Mount the engine inside the host authentication boundary. `authorize_with` is the host policy hook for the JSON endpoint. Finder blocks MUST apply host authorization before returning rows. Labels and URLs in JSON are visible to the signed-in admin session that can call options.

## Registrar

`Configuration#register_finder`, `Configuration#register_prefix`, `Configuration#authorize_with`, `Configuration#default_finder`, `Configuration#min_query_length`, `Configuration#limit`. Finder API: `Finder.options`, `Finder.kinds`. Route helper: `active_admin_command_palette.options_path`.

## Drawbacks

Every searchable kind needs a host block or DSL plus `default_finder`. Prefix collisions are host-owned. Limits are global, not per kind.

## Rationale and alternatives

Server-rendered autocomplete without JSON would couple finders to full page reloads. Returning raw ActiveRecord would leak attributes. Doing nothing leaves navigate and actions without record jump.

## Prior art

ActiveAdmin filters; Select2/Tom Select AJAX sources; omnibox keyword search.

## Unresolved questions

Whether `method` on finder results other than `get` should be rejected at normalize time.

Whether `limit` should become per-kind without a new configuration object.

Optional `detail` / `keywords` and longest-prefix client matching are specified in RFC 0007 while that change is Proposed.
