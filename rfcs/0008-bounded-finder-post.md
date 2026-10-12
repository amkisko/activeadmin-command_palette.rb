# RFC 0008: Bounded finder POST

- Feature Name: bounded-finder-post
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-10
- Author: Andrei Makarov
- Stakeholders: project maintainers and host application owners
- Feedback until: 2026-10-24
- Relates: RFC 0003, RFC 0005

## Summary

Send command palette finder queries in CSRF-protected JSON POST bodies, combine an unprefixed multi-kind search into one HTTP request, and apply server-side kind and result budgets. Keep the existing GET operation for callers that still use RFC 0005.

## Motivation

RFC 0005 puts `q` in a GET query string and the RFC 0003 client sends one request per finder kind. A search term may be a name, email address, or identifier. Query strings can enter HTTP access logs, and request count grows with every registered kind even though the client shows at most 20 records.

## Guide-level explanation

Hosts keep the same engine mount and finder blocks. The browser sends one JSON request for either a selected kind or the registered kind list:

```text
POST /admin/command_palette/options
Content-Type: application/json
X-CSRF-Token: ...

{"kinds":["user","article"],"q":"ada"}
```

`config.limit` remains the result ceiling. `config.search_kind_limit` sets the maximum number of distinct finder kinds evaluated by a combined search and defaults to 20. A prefixed or `view` search sends one `kind` and is not affected by the combined kind ceiling.

Existing integrations may continue to call `GET …/options?kind=user&q=ada`.

## Reference-level explanation

The options route accepts GET and POST. Authentication and authorization run before finder evaluation for both methods. Every response sets `Cache-Control: no-store`.

A POST body contains `q` and either `kind` or `kinds`. `kind` invokes `Finder.options`. `kinds` invokes `Finder.options_for`. The server reads at most `search_kind_limit` entries in request order, converts them to strings, and removes duplicates. Unknown kinds return no rows and still occupy one kind budget position.

The combined result contains at most `configuration.limit` rows. Each finder receives the remaining result budget as `limit`. Evaluation stops when the result budget is full. Result normalization follows RFC 0005 and RFC 0007.

The engine adds `q` to Rails parameter filtering. Hosts remain responsible for filtering legacy GET query strings in front-proxy access logs.

The client includes the page CSRF token, same-origin credentials, and a five-second timeout. A new query aborts the earlier browser request. HTTP 401, 403, and other errors retain the RFC 0003 presentation states.

## Security considerations

Moving `q` into the body keeps new-client search terms out of request URLs. TLS remains required because the request body and response can contain personal data. The POST operation is read-only at the application layer, but CSRF verification prevents another origin from spending authenticated finder capacity.

Kind and result budgets bound application work per request. They do not replace host rate limits or efficient, authorization-scoped finder queries.

## Registrar

Configuration field: `search_kind_limit`. Finder method: `Finder.options_for`. POST request fields: `kind`, `kinds`, `q`.

## Drawbacks

POST prevents ordinary intermediary caching, which is intentional for personalized finder results. A host with more finder kinds than the configured ceiling must raise the ceiling or give later kinds explicit prefixes.

Keeping GET preserves compatibility but means old clients can still put search terms in access logs.

## Rationale and alternatives

A separate endpoint would duplicate authentication and routing. Removing GET immediately would break existing integrations. Client-only concurrency limits bound simultaneous requests but leave total HTTP and finder work proportional to the kind count.

One POST operation preserves the response shape while giving the server one place to apply the total budgets.

## Prior art

JSON autocomplete endpoints commonly use CSRF-protected POST when search input can contain personal data. Server-side aggregate limits are the same shape as pagination limits: callers may request several sources, but one response owns the final ceiling.

## Unresolved questions

Whether a later contract should remove GET after a deprecation period.

Whether hosts need a callback that ranks kinds before the server applies `search_kind_limit`.
