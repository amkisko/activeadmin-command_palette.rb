# RFC 0003: Palette shell

- Feature Name: palette-shell
- Type: Standards Track
- Status: Stable
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0004, RFC 0005

## Summary

Ship a Stimulus-driven Cmd+K / Ctrl+K dialog that hosts mount inside ActiveAdmin, feed with layout data attributes, and localize through Rails I18n. The shell owns open/close, query modes, debounce, recent GET destinations, confirmation for mutating methods, and combobox accessibility state.

## Motivation

Without a shared shell, every host would reimplement shortcut handling, list rendering, and session expiry messaging against ActiveAdmin 4 and importmap. Those names become the integration surface: controller identifier, data attribute keys, locale keys, and client constants.

## Guide-level explanation

Mount the engine, for example:

```ruby
authenticate :user do
  mount ActiveAdmin::CommandPalette::Engine => "/admin/command_palette", as: "active_admin_command_palette"
end
```

On the admin layout body, set the Stimulus controller `activeadmin-command-palette--command-palette` and merge `command_palette_data_attributes`. Render `render_command_palette` and expose a header control that calls `show`. Operators press Cmd+K or Ctrl+K to toggle. Query prefixes: `>` for actions, `?` for help, host-configured kind prefixes for record search, otherwise combined find across navigate and finders.

## Reference-level explanation

### Install contract

- Engine route helper prefix `active_admin_command_palette` exposes `options_path` (RFC 0005).
- Helper module `ActiveAdmin::CommandPalette::Helper` provides `command_palette_controller_name`, `command_palette_data_attributes`, `render_command_palette`, and related readers.
- Importmap pin: `controllers/activeadmin_command_palette/command_palette_controller`.
- Locales under `active_admin.command_palette.*` for empty, loading, error, unauthorized, and help rows. Built-in files: `en`, `fi`, `sv`.

### Client modes

`parseMode` treats leading `>` as actions, leading `?` as help, configured prefixes as kind find, otherwise find. Selecting a `view` action enters forced kind find. Client debounce is 200ms. Record list limit is 20; local list limit is 40.

### Recent items

`sessionStorage` key `activeadmin-command-palette-recent` stores at most 8 items. Only kinds `navigate` and `action` with GET and non-member scope are remembered. Member actions and mutating methods are excluded.

### Mutating navigation

Methods `post`, `put`, and `delete` require non-empty `confirm` text. The client refuses those methods without confirmation, then submits a POST form with CSRF and optional `_method`.

### Accessibility

The query input exposes combobox state: `aria-expanded` while open, `aria-activedescendant` for the highlighted option. Options use `role="option"` and `aria-selected`. Status rows use `role="presentation"`.

### Fail modes

Unauthorized options responses surface the unauthorized locale string and sign-in path. Network or other fetch failures surface the error string. Empty matches surface the empty string. Debounced searches clear selection and abort stale fetches.

## Registrar

Stimulus controller: `activeadmin-command-palette--command-palette`. Helper methods: `command_palette_controller_name`, `command_palette_data_attributes`, `render_command_palette`. sessionStorage key: `activeadmin-command-palette-recent`.

## Drawbacks

Hosts must wire layout and importmap. Client constants (debounce, limits, storage key) are part of observable behavior; changing them without an RFC surprises operators mid-session.

## Rationale and alternatives

A Turbo Frame-only palette would still need the same shortcut and mode logic in JavaScript. Shipping without recent items or confirm gates would shrink code and would lose safety and speed for repeated GET destinations. Doing nothing leaves each host with a private fork of the shell.

## Prior art

Stimulus controllers in ActiveAdmin 4; HTML dialog patterns; ARIA combobox guidance; browser `sessionStorage` for ephemeral UI state.

## Unresolved questions

Whether the sign-in path helper should require an explicit configuration key instead of `new_user_session_path` with a `/user/sign_in` fallback.

Whether recent items should ever persist across tabs beyond `sessionStorage`.
