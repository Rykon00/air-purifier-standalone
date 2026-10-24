# air-purifier-standalone

Factorio mod "Air Purifier (Standalone)" (portal: https://mods.factorio.com/mod/air-purifier-standalone). The repository root is the mod folder.

## Rules

- English on GitHub: commits, issues, pull requests, comments and release notes.
- Every change adds its lines to the topmost section of `changelog.txt` (Factorio changelog format:
  categories such as `Features:`, `Changes:`, `Bugfixes:`, `Info:`, two-space indent, `- ` entries).
- Do not bump `version` in `info.json` outside a release.
- Test with the CI's load check before pushing (see below). It must pass for every mode in
  `.github/workflows/check.yml` (`LOAD_CHECK_MODES`: plain space-age).

## Build and load check

```
python tools/build.py                      # -> dist/air-purifier-standalone_<version>.zip
python tools/load_check.py --factorio <path to factorio(.exe)> --zip dist/air-purifier-standalone_<version>.zip --mode plain --mode space-age
```

`tools/build.py` packs everything except `.git*`, `.github/`, `tools/`, `dist/`, `CLAUDE.md`, `README.md` and editor
folders. `tools/load_check.py` puts the zip into a fresh mod folder, enables it (with `--mode space-age` also every
built-in mod: space-age, quality, elevated-rails, recycler), creates a map with `--create`, runs it with
`--benchmark ... --benchmark-ticks 600` and fails on a non-zero exit code, an error line in the log, or when the mod
was not loaded. `--data` points to the install's `data` folder when it is not `<binary>/../../data` (for example a
copied Steam binary).

## CI

- `check.yml`: on push, pull request, weekly and manually, against the latest stable headless Factorio for Linux.
  On the weekly run it opens one issue (label `load-check`) when the load fails or a newer Factorio minor version
  than `factorio_version` is out.
- `release.yml`: on a published GitHub release. Checks tag = `v` + info.json version and a dated changelog section,
  builds the zip, runs the load check, attaches the zip to the release and uploads it to the mod portal with the
  repository secret `FACTORIO_API_KEY`.

## Release

1. Set `version` in `info.json` and the `Date:` of the topmost changelog section (same version), commit, push.
2. Wait for the load check to pass, then publish a GitHub release with tag `v<version>` on `main`.
