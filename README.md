# activeadmin-command_palette

[![Gem Version](https://badge.fury.io/rb/activeadmin-command-palette.svg)](https://badge.fury.io/rb/activeadmin-command-palette) [![Test Status](https://github.com/amkisko/activeadmin-command_palette.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/activeadmin-command_palette.rb/actions/workflows/test.yml) [![codecov](https://codecov.io/gh/amkisko/activeadmin-command_palette.rb/graph/badge.svg)](https://app.codecov.io/github/amkisko/activeadmin-command_palette.rb)

Cmd+K / Ctrl+K command palette for ActiveAdmin 4.

Provides menu navigation, an allow-listed action catalog, and host-registered record finders. The gem does not know your domain models.

## Requirements

- Ruby 3.4+ (CI matrix: Ruby 3.4 and 4.0)
- Rails 7.2+ (Rails 7.2 and 8.1 tested in CI)
- ActiveAdmin 4.0.0.beta23+ (Tailwind CSS v4 host build)
- importmap-rails

## Install

Add the gem to your Gemfile:

```ruby
gem "activeadmin-command_palette"
```

Mount the engine inside your authenticated admin area:

```ruby
authenticate :user do
  mount ActiveAdmin::CommandPalette::Engine => "/admin/command_palette", as: "active_admin_command_palette"
end
```

Wire the layout body controller and data attributes, render the palette partial, and add a header button that calls `show`.

Register finders and actions in an initializer or with the resource DSL.

Built-in UI locales: English (`en`), Finnish (`fi`), Swedish (`sv`).

## Configuration

Prefer resource-level registration in `ActiveAdmin.register`:

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
```

Host initializer keeps auth, prefixes, global shortcuts, and a `default_finder` that receives each resource registration:

```ruby
ActiveAdmin::CommandPalette.configure do |config|
  config.register_prefix "@", kind: "user"
  config.search_kind_limit = 20
  config.default_finder = lambda { |registration:, query:, helpers:, user:, limit:|
    # return Array of { id:, kind:, label:, url:, detail?, keywords? }
  }
  config.actions = [
    {id: "open-jobs", label: "Open jobs", url: "/admin/good_job"}
  ]
  config.authorize_with = ->(controller) { controller.current_user.present? }
end
```

`reload!` (run from ActiveAdmin `after_load`) merges resource DSL actions/finders with the global `actions` list.

Action fields: `scope` (`global` / `collection` / `member`), `when` (`any` / `index` / `show` / `new` / `edit`), `resource`, `verb` (`view` / `create` / `edit` / `destroy` / …), `params`, `help`, `finder_kind`, `query`, `if` (boolean or callable evaluated in the view on each request), optional `detail` / `keywords`. The layout emits a page `context` value used to gate member and collection actions.

Finder rows may include optional `detail` (second line under the label; `subtitle` is accepted as an alias) and `keywords` (extra client match strings). Longer registered prefixes win when several share a start (for example `@team` before `@`).

### Host finder recipe

Apply host authorization before returning rows. Prefer this match order when building SQL: exact primary key, then exact unique columns from `find_by`, then prefix match, then `ILIKE` / `LIKE`, then `limit`. Put a stable person-facing name in `label` and email, identifier, or id in `detail` when that helps operators disambiguate.

Mount the engine inside your authenticated admin boundary and set `authorize_with` so the JSON options endpoint stays closed to unsigned or unauthorized callers.

### Related surfaces

Palette finders are a separate contract from admin GraphQL endpoints, ActiveAdmin controller finders, and form autocomplete. A host `default_finder` may use any backend; the palette still speaks the finder protocol above.

## Limits

- Minimum query length: 2 (configurable)
- Maximum options per kind: 20 (configurable)
- Maximum finder kinds in a combined search: 20 (configurable)
- Client debounce: 200ms
- The client sends finder queries as CSRF-protected JSON `POST` requests; `GET` remains available for existing integrations
- Finder responses use `Cache-Control: no-store`, and the engine filters `q` from Rails parameter logs
- Action methods are allow-listed to `get`, `post`, `put`, and `delete`
- `POST`, `PUT`, and `DELETE` registrations require non-empty `confirm` text; the client also refuses those methods without confirmation
- Member actions may set `path_args: []` and a `query` hash with `%{record_param}` placeholders
- Recent items use `sessionStorage` and store only static navigate/action GET destinations (not member actions)
- Local navigate and action filter matches label, detail, kind, and keywords (substring or character subsequence)

## Development

```bash
bundle install
bundle exec appraisal install
make lint
make test
```

`make lint` runs Biome (`npx @biomejs/biome@2.3.8`, same version as Trunk) on JavaScript under `app/assets`, plus RuboCop and RBS. `make test` also runs the JavaScript behavior suite. See `spec/README.md` for focused runs and coverage notes.

Release:

```bash
make release
```

## Design RFCs

Numbered design documents for the public contract live in [`rfcs/`](rfcs/README.md). Shipped features are specified in RFC 0003 through RFC 0006. Finder detail and bounded POST search are proposed in RFC 0007 and RFC 0008. Process rules are RFC 0001.

## Links

- [GitHub](https://github.com/amkisko/activeadmin-command_palette.rb)
- [GitLab](https://gitlab.com/amkisko/activeadmin-command_palette.rb)
- [RubyGems](https://rubygems.org/gems/activeadmin-command-palette)
- [libraries.io](https://libraries.io/rubygems/activeadmin-command-palette)
- [Deps.dev](https://deps.dev/rubygems/activeadmin-command-palette)
- [SonarCloud](https://sonarcloud.io/project/overview?id=amkisko_activeadmin-command_palette.rb)
- [Snyk](https://snyk.io/test/github/amkisko/activeadmin-command_palette.rb)
- [Codecov](https://app.codecov.io/github/amkisko/activeadmin-command_palette.rb)
- [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/amkisko/activeadmin-command_palette.rb)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Sponsors

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

<a href="https://www.kiskolabs.com">
  <img src="kisko.svg" width="200" alt="Sponsored by Kisko Labs" />
</a>
