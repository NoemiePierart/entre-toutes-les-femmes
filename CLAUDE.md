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
bin/rails test test/models/user_test.rb
```

## Architecture

This is a Rails 8.1 app bootstrapped from the [Le Wagon devise template](https://github.com/lewagon/rails-templates). Stack: PostgreSQL, Hotwire (Turbo + Stimulus), importmap, Bootstrap 5.3, Devise, SimpleForm, Font Awesome.

**Authentication**: Devise is configured with `before_action :authenticate_user!` on `ApplicationController`, so all routes require login by default. Individual controllers opt out with `skip_before_action :authenticate_user!, only: [...]`. The home page (`PagesController#home`) is publicly accessible.

**Stylesheet structure**: `app/assets/stylesheets/application.scss` is the entry point. It imports in order: config (fonts, colors, Bootstrap variables overrides), Bootstrap + Font Awesome, then component and page partials under `components/` and `pages/`.

**Layout**: `app/views/layouts/application.html.erb` renders `shared/_navbar` and `shared/_flashes` on every page. The navbar conditionally shows authenticated vs. guest links via `user_signed_in?`.

**Routes**: Currently minimal — Devise routes + root → `pages#home`. New features should be added here.

**CI pipeline** (`bin/ci`): runs setup → rubocop → bundler-audit → importmap audit → brakeman → rails test → system tests → seed test. All steps must pass before merging.
