---
name: release-check
description: Audit PRs since a release tag, verify labels, and recommend a version bump
---

# Release Check

Audit PRs merged since a given version tag, verify labels, and recommend a version bump.

## Steps

### 1. Determine repo and latest release tag

Detect the repo and latest release tag automatically. If the user provides a specific tag or compare URL, use that instead.

```bash
# Get repo from git remote (e.g. "ruby/rdoc")
gh repo view --json nameWithOwner --jq '.nameWithOwner'

# Get latest release tag
gh release list --limit 1 --json tagName --jq '.[0].tagName'

# Get the release date
gh api repos/{repo}/releases/tags/{tag} --jq '.published_at'
```

If the user provides a specific tag or compare URL, use that instead.

### 2. Fetch PRs merged since the tag

```bash
gh pr list --repo {repo} --state merged --base master \
  --search "merged:>={release_date}" \
  --json number,title,body,labels,mergedAt,url --limit 100
```

Filter out the version-bump commit for the tag itself (e.g., "Bump version to v7.1.0").

### 3. Identify release-relevant labels

Read `.github/release.yml` to find which labels map to changelog categories (currently `breaking-change`, `bug`, `enhancement`, `documentation`). PRs outside these categories appear under "Other Changes" and do not need labels.

### 4. Report: PRs missing release-relevant labels

List PRs that look like they **should** have a release-relevant label but don't. Use the PR title and description to judge:

- PRs that remove public API or change default behavior in ways that break existing usage → likely needs `breaking-change` (note: dropping Ruby version support is not a breaking change, just a minor bump)
- Titles starting with "Fix" or describing a fix → likely needs `bug`
- Titles describing new features or capabilities → likely needs `enhancement`
- Titles about docs → likely needs `documentation`

PRs that are clearly CI, dependency bumps, refactors, or test-only changes do **not** need these labels.

**Format each PR as a clickable URL** (not just a number), followed by its title and current labels:

```
### PRs that may need labels

- https://github.com/ruby/rdoc/pull/1547 — Expand GitHub style references in ChangeLog to URL
  Suggested: `enhancement`

### PRs without release-relevant labels (OK)

- https://github.com/ruby/rdoc/pull/1577 — Fix a test that uses invalid syntax
- https://github.com/ruby/rdoc/pull/1586 — Removed truffleruby from CI
```

### 5. Full PR list grouped by label

Show all PRs grouped by their release-relevant label, with URLs:

```
### Breaking Changes
- https://github.com/ruby/rdoc/pull/1616 — Remove deprecated CLI options and directives

### Enhancements
- https://github.com/ruby/rdoc/pull/1544 — Highlight bash commands

### Bug Fixes
- https://github.com/ruby/rdoc/pull/1559 — Replace attribute_manager with new parser
...

### Documentation
...

### Other Changes
- (dependency bumps, CI, refactors, test fixes)
```

### 6. Version bump recommendation

Apply semver reasoning:

- **Major** — breaking changes to public API or behavior users depend on (any PR with `breaking-change` label)
- **Minor** — new features, significant internal rewrites that change behavior, enhancements
- **Patch** — only bug fixes, documentation, and maintenance

If any PR has the `breaking-change` label, recommend a **major** version bump.

Explain the reasoning, highlighting the most impactful changes by URL.
