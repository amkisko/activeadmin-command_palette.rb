## Participants

Andrei Makarov (@amkisko)

## Decisions

Implement Proposed RFC 0007: optional finder `detail` / `keywords`, navigate crumb keywords, longest-prefix matching, fuzzy local match, detail rows, kind section headers, and single-item Enter. Document host finder ranking in README.

## Effects

Finder normalize keeps `detail` (from `detail` or `subtitle`) and non-empty `keywords`. Catalog navigate adds downcased crumb keywords. Stimulus client sorts prefixes by length, matches keywords and fuzzy subsequence, renders detail and section headers, and activates the sole item on Enter when highlight is missing.

## Next

Lazy-consensus review for RFC 0007 through 2026-10-24. Shipped in product CHANGELOG as 0.1.6.

## Source

`docs/issues/20261010105500_finder-detail-client-matching.md`; RFC 0007.
