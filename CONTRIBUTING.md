# Contributing

## Workflow

1. **Fork** the [repository](https://github.com/moxwel/processlist-plasmoid) on GitHub and clone your fork.
2. Add the main repository as `upstream`. You only need to do this once:
   ```bash
   git remote add upstream https://github.com/moxwel/processlist-plasmoid.git
   ```
3. **Create the branch from `develop`**, one branch per feature or fix:
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/my-feature
   ```
4. Do the work and check the build.
5. **Open the pull request against `develop` of the main repository**, not against your fork.
6. Keep the PR focused. Describe what changed and why.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>(<optional scope>): <short summary>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `build`, `chore`. The scope is optional. Useful ones here are the folder or script the change touches: `ui`, `config`, `tools`, `build`, `translate`.

Write **descriptive** commits: say what changed and why. One logical change per commit, imperative mood, no vague messages like `update` or `fix stuff`.

```text
fix(tools): skip blank lines in the top output
feat(ui): highlight the row of the process being stopped
docs: explain how to build the widgets
```

## Translations

User-facing text goes through `i18n()`, `i18nc()`, `i18np()` or `i18ncp()`, so Plasma can translate it. When you add or change a string:

1. Refresh the template and merge it into the `.po` files:
   ```bash
   translate/update.sh
   ```
2. Fill in the new `msgstr` lines in `translate/es.po`. New strings stay untranslated until you do.

## Build

Install the [requirements](README.md#requirements) first. This project has no automated tests yet, so check your change by hand:

1. Build both widgets. The build also checks every translation with `msgfmt --check`:
   ```bash
   ./build.sh
   ```
2. Install them. The script restarts plasmashell, so the panel reloads for a moment:
   ```bash
   ./install.sh
   ```
