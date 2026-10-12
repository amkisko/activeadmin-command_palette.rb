## Decisions

Implement RFC 0008 with a CSRF-protected finder POST while retaining the existing GET operation. Bound combined search to 20 distinct finder kinds and 20 total records by default. Keep finder authorization in the host callback.

Reject executable navigation URLs and cross-origin mutating actions in the client. Preserve URL fragments when create actions add query parameters.

Run JavaScript behavior tests in CI and release checks. Require the complete Git worktree, including staged and untracked files, to be clean before building a release.

## Effects

An unprefixed search sends one HTTP request instead of one request per finder kind. New-client search terms stay out of request URLs, finder responses are not stored by caches, and Rails parameter logs filter `q`.

The command palette announces loading, empty, authentication, authorization, and failure states through a polite status region.

## Next

Review RFC 0008 through 2026-10-24. Run a rendered browser and assistive-technology check in a host application. Shipped in product CHANGELOG as 0.1.6.

## Source

`rfcs/0008-bounded-finder-post.md`.
