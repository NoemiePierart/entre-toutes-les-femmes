# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev          # Start the dev server (Rails + assets)
bin/setup        # Install dependencies and prepare the database
bin/rails test   # Run unit/integration tests
bin/rails test:system  # Run system (Capybara/Selenium) tests
bin/ci           # Run full CI suite: rubocop, bundler-audit, brakeman, tests, seeds
bin/rubocop      # Lint Ruby with rubocop-rails-omakase style
bin/brakeman --quiet --no-pager  # Static security analysis
```

Run a single test file:
```bash
bin/rails test test/models/post_test.rb
```

Seed the database (idempotent, safe to re-run):
```bash
bin/rails db:seed
```

## Architecture

Rails 8.1 app. Stack: PostgreSQL, Hotwire (Turbo + Stimulus), importmap, Bootstrap 5.3, Devise, SimpleForm, ActionText, Font Awesome.

### Data model

The core content model is: **Newsletter → Posts ← Theme**. A `Newsletter` is a numbered edition published on a date (with an optional liturgical context). Each `Post` belongs to exactly one `Newsletter` and one `Theme`, and has a rich-text `content` (ActionText). A `User` authors posts. The four themes seeded by default are: *Qui suis-je ?*, *Le coin des mamans*, *Du grain à moudre*, *Une œuvre d'art à savourer*.

`Newsletter` overrides `to_param` to use `number` instead of `id`, so URLs are `/newsletters/36` not `/newsletters/1`.

### Authorization

Devise handles authentication. `ApplicationController` enforces `before_action :authenticate_user!` globally. Controllers opt out with `skip_before_action`. Write actions on `PostsController` use a custom `require_admin!` guard that checks `current_user&.admin?` — there is no authorization gem. The `admin` boolean is a column on `users`.

Public (no login required): `pages#home`, `newsletters#index`, `newsletters#show`, `themes#show`, `posts#show`.

The seed admin credentials are `admin@entretouteslesfemmes.fr` / `password123`.

### Navigation

`ApplicationController#set_nav_themes` runs on every request and assigns `@nav_themes = Theme.order(:id)`, which the shared navbar uses to build the theme navigation links dynamically. When adding a new theme, it appears in the nav automatically.

### Stylesheet structure

`app/assets/stylesheets/application.scss` is the entry point. Import order: `config/` (fonts, colors, Bootstrap variable overrides) → Bootstrap + Font Awesome → `components/` → `pages/`. Add new component styles in `components/`, page-specific styles in `pages/`, and register them in the corresponding `_index.scss`.

The design palette is defined in `config/_colors.scss`: `$cream` (background), `$navy` (headings), `$burgundy` (accents), `$steel-blue` (links).

### Locale

The app is entirely in French (`config.i18n.default_locale = :fr`). All user-facing text — flash messages, labels, UI copy — must be written in French. Date formatting uses the `fr.yml` locale file; use `l(date, format: :long)` in views.

### Local environment

`dotenv-rails` loads `.env` in all environments. Because `.env` contains a production `DATABASE_URL`, a `.env.development` file (gitignored) must exist locally to override it:

```
DATABASE_URL=postgresql://localhost/entre_toutes_les_femmes_development
```

### CI pipeline

`bin/ci` runs: setup → rubocop → bundler-audit → importmap audit → brakeman → rails test → system tests → seed test. All steps must pass before merging.
