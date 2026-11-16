# ActiveAdmin-owned options route

## Participants

Andrei Makarov

## Decisions

Own finder options through an ActiveAdmin page registration so hosts need no
palette line in `routes.rb` when they already call `ActiveAdmin.routes`. Keep an
explicit engine mount when `auto_register_page` is false. Auth follows
ActiveAdmin `authentication_method` and `Auth::READ` on the Command Palette page
(or optional `authorize_with`). Do not treat mapper placement as the auth
boundary.

## Effects

- Gem `app/admin/command_palette.rb` registers the hidden page with GET/POST
  `options`.
- Engine initializers add that admin path to ActiveAdmin `load_paths`.
- Dummy app routes only call `ActiveAdmin.routes`.
- Request specs cover the default page path and the escape-hatch mount.
- README, RFC 0003 / 0005 notes, and RFC 0009 document the contract.
- Audit pass added adapter-deny, index redirect, escape-hatch fail-closed
  coverage; authorization fails closed when namespace or page config is missing;
  page controller sets `protect_from_forgery` explicitly.
- Browser system specs cover palette open, keyboard filter, finder options, and
  admin GraphQL endpoint coexistence; CI installs Chromium from
  `.playwright-version`.

## Next

Prepared for 0.2.0 (docs/changelogs/20261116131700_release-0-2-0.md). Hosts that
mounted the engine can remove the mount when using the default page
registration.
