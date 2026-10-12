# RFC 0007: Finder result detail and client matching

- Feature Name: finder-result-detail-and-client-matching
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-10
- Author: Andrei Makarov
- Feedback until: 2026-10-24
- Relates: RFC 0003, RFC 0004, RFC 0005

## Summary

Extend the finder options payload with optional `detail` and `keywords`, match host prefixes longest-first, and tighten client local matching (substring, fuzzy subsequence, keywords, detail) plus a second-line detail row and single-item Enter activation. Document host finder ranking without coupling this gem to other admin search stacks.

## Motivation

Operators distinguish same-titled records by email, identifier, or id. A single `label` forces hosts to jam that into one string. Prefixes that share a start character can bind the wrong kind when Object entry order wins. Substring-only local filter misses typed abbreviations operators expect from other command palettes. Hosts may also run separate admin GraphQL or controller finders; those must stay distinct from the palette finder protocol.

## Guide-level explanation

Finder rows may include:

```text
{ id, kind, label, url, method, detail?, keywords? }
```

`detail` is a second line under the label. `keywords` is an array of extra strings the client may match. Navigate items may include `keywords` derived from breadcrumb crumbs.

Typing `@ada` still finds users when `@` is registered. If both `@` and `@team` are registered, the longer prefix wins.

Local navigate and action lists match when the query is a case-insensitive substring or fuzzy subsequence of the label, detail, any keyword, or kind. Empty Go / actions lists keep section headers by kind when adjacent rows change kind.

When the visible list has exactly one activatable item and Enter is pressed with no highlight, that item activates.

Hosts SHOULD order finder SQL as exact id, then exact unique column, then prefix, then ILIKE, and MUST apply authorization before returning rows. Palette finders are not GraphQL and are not ActiveAdmin controller finders.

## Reference-level explanation

### Finder normalize (RFC 0005 extension)

After existing keys, `Finder.normalize` may copy:

- `detail`: string from `detail` or `subtitle`; omitted when blank
- `keywords`: Array of strings; omitted when empty

Unknown keys remain ignored. Limit still applies after normalize.

### Prefix matching

Client `parseMode` sorts registered prefixes by descending string length, then picks the first whose `value.startsWith(prefix)`. Empty prefixes are skipped. This supersedes RFC 0005 “Object.entries order” for prefix selection.

### Local match

`filterLocal` keeps an item when the needle is empty, or when `matchesText` is true for any of: `label`, `detail`, `kind`, and each `keywords` entry. `matchesText(haystack, needle)` is true when lowercased haystack includes needle, or when needle characters appear in order as a subsequence of haystack.

### Rendering

Option rows may show `detail` under `label` in smaller muted text. When consecutive `visibleItems` differ in `kind`, the client MAY insert a non-option presentation header labeled with that kind before the group. Headers are not in `visibleItems` and do not affect highlight indices.

### Enter with one item

`activateHighlighted` treats a missing highlight as index `0` when `visibleItems.length === 1` and that item is activatable (`kind` not `help`).

### Navigate keywords

`Catalog.walk_menu` MAY set `keywords` to the downcased unique crumbs for that item.

## Security considerations

`detail` and `keywords` are visible to the signed-in admin session that can call options or read the layout payload. Hosts MUST NOT put secrets into those fields. Authorization remains host-owned on finder blocks.

## Registrar

Finder result keys: `detail`, `keywords` (optional). Client prefix algorithm: longest-first. Catalog navigate optional `keywords`.

## Drawbacks

Richer JSON and DOM rows increase payload and paint cost slightly. Fuzzy subsequence can over-match short needles; minimum query length still gates record fetch.

## Rationale and alternatives

Auto-discovering resource filters was rejected for core: it invents domain search inside the gem (RFC 0002). A separate GraphQL options path was rejected: hosts can call any backend inside `default_finder` if needed. Shipping only docs without `detail` leaves the label-stuffing problem.

## Prior art

Editor and launcher command palettes that use query prefixes, title plus secondary line, keywords, and longest-prefix mode selection.

## Unresolved questions

Whether `score` should become a first-class finder field for client re-sort.

Whether presentation section headers need locale strings instead of raw `kind`.

## Future possibilities

Optional resolve endpoint; filter-field drill-in adapter; I18n for compiled standard action labels; frecency beyond session recent.
