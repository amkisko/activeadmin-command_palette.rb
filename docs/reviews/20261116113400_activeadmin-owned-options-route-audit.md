# ActiveAdmin-owned options route audit

## Participants

Andrei Makarov

## Decisions

Diff audit of the RFC 0009 options ownership change. Pipeline: ingress options
GET/POST -> authentication -> authorization -> Finder JSON. Security and
contract modes on. Boundary and control skipped (library, no plant IO). Resource
and budget skipped for this pass (no new hot-path allocation contract beyond the
existing finder caps). Trace and identification: options still filter `q` from
parameter logs; no new identifiers.

## Effects

### Findings

1. Medium / high / coverage: default Auth::READ adapter denial had no request
   example; only `authorize_with` false was covered. Added adapter-deny example.
2. Medium / high / coverage: escape hatch without page config and without
   `authorize_with` (fail-closed 403) was undocumented by a request example.
   Added.
3. Medium / high / correctness: `command_palette_authorization_adapter` could
   raise if the ActiveAdmin namespace was missing. Fail closed with 403 instead.
4. Low / high / coverage: Command Palette index redirect had no request example.
   Added redirect to admin root.
5. Low / high / security contract: page controller lacked an explicit
   `protect_from_forgery` matching the engine escape hatch. Added on the page
   controller block (verify_authenticity_token was already present via the
   controller chain in this dummy; the explicit call keeps host templates from
   dropping CSRF).

### Claim check

Default page path under `ActiveAdmin.routes`, PageController auth, escape-hatch
mount with the same OptionsAction contract: supported by request specs after the
fixes above.

## Next

No further route reshape. Ship with the Unreleased RFC 0009 notes on the next
minor.
