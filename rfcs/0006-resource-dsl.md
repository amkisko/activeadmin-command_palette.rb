# RFC 0006: Resource DSL

- Feature Name: resource-dsl
- Type: Standards Track
- Status: Stable
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0004, RFC 0005

## Summary

Let hosts declare command palette behavior inside `ActiveAdmin.register` through `command_palette`. `reload!` runs after ActiveAdmin load and compiles registrations into actions and finder registrations. Optional `default_finder` turns `find_by` columns into the finder protocol from RFC 0005.

## Motivation

Repeating view/create/edit/destroy action hashes per resource drifts from the ActiveAdmin resource definition. Compiling too early (bare `to_prepare` around unload/load) yields an empty catalog. The DSL keeps registration next to the resource and forces compile after resources exist.

## Guide-level explanation

```ruby
ActiveAdmin.register User do
  command_palette do
    kind "user"
    noun "user"
    label_method :name_or_email
    find_by :email, :nickname, :name
    order :name
    actions :view, :create, :edit, :destroy
    create help: "Create user — optional email=", params: [
      {name: "email", required: false, query_key: "user[email]"}
    ]
    member "Open in chat",
      path: :admin_chat_path,
      path_args: [],
      query: {context_selector: "user:%{record_param}"},
      if: -> { feature_enabled? }
  end
end

ActiveAdmin::CommandPalette.configure do |config|
  config.default_finder = lambda { |registration:, query:, helpers:, user:, limit:|
    # return Array of { id:, kind:, label:, url: }
  }
end
```

Engine wiring calls `ActiveAdmin::CommandPalette.reload!` from `ActiveAdmin.after_load` (and immediately when already loaded).

## Reference-level explanation

### DSL methods

`command_palette` enables the resource config and evaluates the block on `ResourceDSL`.

- `kind`, `noun`, `label_method`, `order` set registration metadata.
- `find_by(*columns)` sets finder columns; empty columns skip finder registration.
- `actions(*names)` selects standard actions among `:view`, `:create`, `:edit`, `:destroy`.
- `create(help:, params:)` sets create help and param metadata for the create action.
- `member(label, **options)` appends a custom member (or scoped) action; options follow RFC 0004 fields (`path`, `url`, `path_args`, `query`, `method`, `confirm`, `scope`, `when`, `verb`, `if`, `id`).

Default kind is the demodulized underscored resource class name. Default noun replaces underscores with spaces in kind.

### Compile output

`Compiler.compile` walks ActiveAdmin resources that respond to `command_palette_config` and are enabled.

Standard actions:

- `view`: global, `verb` `view`, `finder_kind` set, no URL required.
- `create`: global, `path` `new_*_path`, optional `params` / `help`.
- `edit`: member, `when` `show`, `path` `edit_*_path`, `resource` demodulized class name.
- `destroy`: member, `when` `show`, `method` `delete`, default confirm `Delete this #{noun}?`, `path` show path.

Member actions default `scope` `member`, `when` `show`, `verb` `custom`, and derive `id` from parameterized label plus kind when omitted.

Finder registration is a `Compiler::Registration` struct: `kind`, `noun`, `resource_name`, `resource_class`, `find_columns`, `label_method`, `order_column`, `show_path`, `new_path`, `edit_path`.

### `reload!`

Copies manual finders, adds compiled finders for kinds not already registered when `default_finder` is present, and sets `actions` to global actions plus compiled normalized actions. `default_finder` receives `registration:`, `query:`, `helpers:`, `user:`, `limit:`.

### Fail modes

Compile before resources load yields no resource actions or finders. Missing `default_finder` leaves `find_by` without a callable. Manual `register_finder` for the same kind suppresses the compiled finder.

## Registrar

DSL: `command_palette`, `kind`, `noun`, `label_method`, `order`, `find_by`, `actions`, `create`, `member`. Module API: `ActiveAdmin::CommandPalette.reload!`, `ActiveAdmin::CommandPalette.configure`.

## Drawbacks

Hosts still write `default_finder` SQL. Compile timing couples the gem to ActiveAdmin `after_load`. Standard action labels are English strings today.

## Rationale and alternatives

Only global `config.actions` would work and would duplicate resource paths. Auto-enabling every ActiveAdmin resource would register destroy without host intent. Bare `to_prepare` was tried and left empty catalogs around unload/load.

## Prior art

ActiveAdmin resource DSL; Rails `after_initialize` / engine load hooks; RFC 0004 action shapes.

## Unresolved questions

Whether standard action labels and confirm strings should move to I18n in a later RFC.

Whether `order` and `label_method` should become mandatory when `find_by` is present, instead of advisory metadata for `default_finder`.
