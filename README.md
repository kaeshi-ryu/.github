# .github — kaeshi-ryu

Organisation-wide defaults:

- `.github/workflows/bun-ci.yml`: reusable CI for every bun and TypeScript repo (supply-chain settings check, lint, typecheck, tests with coverage, audit, dependency review on public repos, single `CI` gate). Before `bun install`, the step "Check bun supply-chain settings" fails when `package.json` has no `trustedDependencies` array (bun would run the install scripts of its default allowlist) or when `bunfig.toml` does not set `minimumReleaseAge` to at least 604800 seconds under `[install]`. Dependency review runs on pull requests of public repos only: on private repos the action needs GitHub Code Security or GitHub Advanced Security, so they rely on `bun audit`.
- `.github/workflows/bun-audit.yml`: reusable weekly `bun audit`, called on a schedule by each repo, since Dependabot proposes no security update for bun.
- `.github/workflows/test-workflows.yml`: runs the supply-chain check, extracted from `bun-ci.yml`, on the example repos of `tests/bun-settings/` and compares each result with the case's `.expect` file. Required job: `bun settings`.
- `.github/workflows/release.yml`: reusable release-please flow (release PR, tag, `CHANGELOG.md`). Output `release_created`.
- `.github/workflows/release-self.yml`: releases of this repository. It calls `release.yml` by local path, so GitHub runs the called workflow from the same commit as the caller.
- `.github/workflows/actionlint.yml`: lints every workflow of this repository (binary pinned by version and SHA-256).
- `.github/ISSUE_TEMPLATE/`: task and epic forms used by the factory agents.
- `.github/pull_request_template.md`, `SECURITY.md`: inherited by every repo of the organisation (this repository is public, which GitHub requires for default community health files).

Actions are pinned by full commit SHA. `.github/dependabot.yml` proposes their updates weekly (`github-actions` ecosystem, 7-day cooldown).

## Releases and pinning

This repository is released with release-please (`release-please-config.json`, `.release-please-manifest.json`): the release PR updates `CHANGELOG.md` and the manifest, and merging it tags `vX.Y.Z` on `main`. Versions stay in 0.x until the workflows are stable (first release `v0.1.0`). `feat`, `fix`, `perf`, `revert` and `ci` commits make a release; `docs` and `chore` commits do not.

Merging the release PR needs one manual step: release-please opens it with `GITHUB_TOKEN`, which does not trigger `pull_request` workflows, so the owner closes and reopens it just before merging to run the checks on its head.

Every call to a reusable workflow of this repository is pinned by full commit SHA with the release tag as a comment on the same line, never a branch or a tag name:

```sh
gh api repos/kaeshi-ryu/.github/git/ref/tags/v0.1.0 --jq .object.sha
```

```yaml
    uses: kaeshi-ryu/.github/.github/workflows/bun-ci.yml@<sha40> # v0.1.0
```

release-please creates lightweight tags, so the command above returns the commit SHA directly; if `.object.type` is `tag`, follow it with `gh api repos/kaeshi-ryu/.github/git/tags/<sha> --jq .object.sha`. Dependabot (`github-actions` ecosystem) then proposes new releases and updates the version comment on the same line.

## Licence

MIT: see [`LICENSE`](LICENSE). It applies to this repository only; every other repository keeps its own licence.
