# RFC 0009: ActiveAdmin-owned options route

- Feature Name: activeadmin-owned-options-route
- Type: Standards Track
- Status: Stable
- Created: 2026-11-16
- Author: Andrei Makarov
- Relates: RFC 0003, RFC 0005, RFC 0008

## Summary

Draw the finder options endpoint through an ActiveAdmin page registration so
`ActiveAdmin.routes` owns the path and `PageController` owns authentication and
authorization. Hosts need no palette line in `routes.rb` by default. An explicit
engine mount remains available and must use the same ActiveAdmin auth contract.

## Motivation

Mounting an isolated engine next to ActiveAdmin does not inherit ActiveAdmin
config. Hosts wrapped the mount in session route constraints or special-cased the
engine controller in `ApplicationController`. That duplicated the admin session
boundary and made mapper placement look like the auth contract. The gem already
depends on ActiveAdmin 4; the options path should follow ActiveAdmin pages.

## Guide-level explanation

Add the gem. Keep `ActiveAdmin.routes(self)`. Do not mount the command palette
engine for options. The gem registers a hidden Command Palette page with a GET
and POST `options` page action at `/admin/command_palette/options` under the
default namespace.

For a custom path or mapper scope, set `config.auto_register_page = false` and
draw explicitly:

```ruby
ActiveAdmin::CommandPalette::Routes.draw(self)
# or: mount ActiveAdmin::CommandPalette::Engine => "/admin/command_palette", as: "active_admin_command_palette"
```

Auth still follows ActiveAdmin `authentication_method`, `current_user_method`,
and the namespace authorization adapter (`Auth::READ` on the page config).
Optional `authorize_with` overrides the adapter check only.

## Reference-level explanation

Default install adds the gem `app/admin` directory to ActiveAdmin `load_paths`
via `ActiveAdmin.before_load` and registers page "Command Palette" with
`menu false` when `configuration.auto_register_page` is true (default).

The page defines `page_action :options, method: [:get, :post]`. The generated
controller inherits `ActiveAdmin::PageController`. It authenticates through
`authenticate_active_admin_user`. It authorizes with `Auth::READ` on
`active_admin_config`, or with `authorize_with` when that callable is set.
Failure without a user after authentication configuration is exhausted is `401`.
Authorization failure is `403`. Successful responses match RFC 0005 and RFC 0008
(JSON finder rows, `Cache-Control: no-store`).

`index` is not a product surface: redirect to the ActiveAdmin namespace root.

When `auto_register_page` is false, hosts mount the engine (via `Routes.draw` or
`mount`). `OptionsController` must invoke the ActiveAdmin namespace
`authentication_method` / `current_user_method` and the same `Auth::READ`
authorization path (or `authorize_with`). Mapper placement does not substitute
for that contract. Hosts must not enable both the page registration and an
engine mount on the same path.

`Helper#command_palette_options_url` prefers `admin_command_palette_options_path`,
then falls back to the engine route helper while the escape hatch exists.

## Security considerations

Auth is a controller contract owned by ActiveAdmin. Host session route
constraints are optional defense in depth. Finder blocks remain responsible for
row-level policy as in RFC 0005.

## Registrar

`Configuration#auto_register_page`. `ActiveAdmin::CommandPalette::Routes.draw`.
Page name `Command Palette`. Page action `options`.

## Drawbacks

Hosts that hard-coded `active_admin_command_palette.options_path` must switch to
the page helper or the Helper method. Escape-hatch mounts require disabling
auto-registration to avoid duplicate routes.

## Rationale and alternatives

Wrapping `ActiveAdmin.routes` to auto-mount an isolate engine would keep the old
helper name but would still invent a parallel controller stack. Folding options
into a page action reuses `PageController` auth without a second vocabulary.
Removing the escape hatch would force every custom path through ActiveAdmin
namespace routing only.

## Prior art

ActiveAdmin hidden page registrations and `load_paths`; ActiveAdmin
`PageController#authorize_access!`.

## Unresolved questions

Whether multi-namespace hosts need one page registration per ActiveAdmin
namespace without a follow-up RFC.
