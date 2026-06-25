# Configuring RDoc

RDoc has four ways to configure it. Three control *how RDoc runs* — [`.rdoc_options`](#rdoc_options), [`RDoc::Task`](#rdoctask-rakefile), and the [`RDOCOPT`](#rdocopt-environment-variable) environment variable. One controls *which files get documented* — [`.document`](#document).

## Choosing a mechanism

| Mechanism | What it does | When to use |
|---|---|---|
| [`.rdoc_options`](#rdoc_options) | YAML file, persistent | Gems/libraries — committed to the repo |
| [`RDoc::Task`](#rdoctask-rakefile) (Rakefile) | Programmatic Ruby API | When the project already uses Rake |
| [`.document`](#document) | File selection list | Control *which* files get documented |
| [`RDOCOPT`](#rdocopt-environment-variable) env var | Shell override | **Not recommended** — included for completeness |

**Precedence.** Command-line flags override `.rdoc_options`. `RDOCOPT` is prepended to `ARGV`, so command-line flags that appear later in the same invocation still win.

## Name cheat sheet

> **Convention:** unless flagged in the tables below, a CLI flag converts kebab-case to snake_case for its `.rdoc_options` key. For example, `--hyperlink-all` on the command line is `hyperlink_all:` in YAML.

### Watch out for these names and caveats

These options either use a non-obvious name across mechanisms or are not available in every mechanism — the single most common source of confusion.

| Concept | CLI flag | `.rdoc_options` key | `RDoc::Task` attr |
|---|---|---|---|
| Main page | `--main` / `-m` | `main_page` | `rdoc.main` |
| Output directory | `--output` / `-o` / `--op` | `op_dir` | `rdoc.rdoc_dir` |
| Generator / format | `--format` / `-f` / `--fmt` | `generator_name` | `rdoc.generator` |
| Template | `--template` / `-T` | *(not supported)* | `rdoc.template` |
| Include paths (for `:include:`) | `--include` / `-i` | `rdoc_include` | — (use `rdoc.options <<`) |
| Copy static files | `--copy-files` | `static_path` | — |
| All methods | `--all` / `-a` | `visibility: :private` | — |
| Skip tests | `--no-skipping-tests` | *(CLI only)* | — |
| Locale | `--locale` | `locale_name` | — |
| Locale data directory | `--locale-data-dir` | `locale_dir` | — |

### Full naming reference

Every option that is accessible from more than one mechanism. The ⚠ column flags rows where the name or availability is surprising.

| ⚠ | CLI flag | `.rdoc_options` key | `RDoc::Task` attr |
|---|---|---|---|
| ⚠  | `--all` / `-a`                         | `visibility: :private`   | — |
|    | `--apply-default-exclude`              | `apply_default_exclude`  | — |
|    | `--autolink-excluded-words`            | `autolink_excluded_words`| — |
|    | `--charset` / `-c` *(legacy)*          | `charset`                | — |
| ⚠  | `--copy-files`                         | `static_path`            | — |
|    | `--embed-mixins`                       | `embed_mixins`           | — |
|    | `--encoding` / `-e`                    | `encoding`               | — |
|    | `--exclude` / `-x`                     | `exclude`                | — |
| ⚠  | `--format` / `-f` / `--fmt`            | `generator_name`         | `rdoc.generator` |
|    | `--hyperlink-all` / `-A`               | `hyperlink_all`          | — |
| ⚠  | `--include` / `-i`                     | `rdoc_include`           | — |
|    | `--line-numbers` / `-N`                | `line_numbers`           | — |
| ⚠  | `--locale`                             | `locale_name`            | — |
| ⚠  | `--locale-data-dir`                    | `locale_dir`             | — |
| ⚠  | `--main` / `-m`                        | `main_page`              | `rdoc.main` |
|    | `--markup`                             | `markup`                 | `rdoc.markup` |
| ⚠  | `--output` / `-o` / `--op`             | `op_dir`                 | `rdoc.rdoc_dir` |
|    | `--page-dir`                           | `page_dir`               | — |
|    | `--show-hash` / `-H`                   | `show_hash`              | — |
|    | `--tab-width` / `-w`                   | `tab_width`              | — |
| ⚠  | `--template` / `-T`                    | **not supported**        | `rdoc.template` |
|    | `--title` / `-t`                       | `title`                  | `rdoc.title` |
|    | `--visibility`                         | `visibility: :public` etc. | — |
|    | `--warn-missing-rdoc-ref`              | `warn_missing_rdoc_ref`  | — |
|    | `--webcvs` / `-W`                      | `webcvs`                 | — |
|    | *(no CLI)*                             | `canonical_root`         | — |
|    | *(no CLI)*                             | `footer_content`         | — |

## Configuration mechanisms

### `.rdoc_options`

A YAML file at the project root that RDoc auto-loads on every run. The preferred mechanism for gem and library authors — it's declarative, committed to the repo, and visible to collaborators.

**Location.** The current working directory. Resolved by `RDoc::Options.load_options`.

**Syntax.** A YAML map of option keys to values.

```yaml
# .rdoc_options
title: MyGem
main_page: README.md
markup: markdown
exclude:
  - test/
  - tmp/
```

**Bootstrap it.** If you already configure RDoc via CLI flags, run:

```sh
rdoc --markup markdown --main README.md --write-options
```

This writes a `.rdoc_options` file containing the current settings.

**Limitation.** Some options cannot be stored in `.rdoc_options` (they are silently ignored even if you add them). These are flagged in the [options reference](#options-reference) below. Examples: `--dry-run`, `--force-output`, `--force-update`, `--server`, `--pipe`, `--no-skipping-tests`, `--template`, `--template-stylesheets`.

### `RDoc::Task` (Rakefile)

A programmatic alternative that integrates with Rake. Creates these tasks: `rdoc`, `rerdoc`, `clobber_rdoc`, `rdoc:coverage`, `rdoc:server`.

**Setup.**

```ruby
# Rakefile
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.main       = 'README.md'
  rdoc.title      = 'MyGem'
  rdoc.rdoc_dir   = 'doc'
  rdoc.markup     = 'markdown'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/**/*_internal.rb')
end
```

**Selecting files to document.** `rdoc.rdoc_files` is a `Rake::FileList`, so it accepts both `include` and `exclude` with shell glob patterns. This is the Rake-native equivalent of passing positional file arguments on the CLI; for regex-pattern exclusion across the full source tree, use the `--exclude` option (via `rdoc.options`) instead.

**Available attributes.** `name`, `rdoc_dir`, `main`, `title`, `template`, `markup`, `generator`, `rdoc_files`, `options`, `external`.

**Escape hatch.** `RDoc::Task` exposes only a handful of attributes as setters. For any other option, append to `rdoc.options`:

```ruby
RDoc::Task.new do |rdoc|
  rdoc.title = 'MyGem'
  rdoc.options << '--visibility' << 'private'
  rdoc.options << '--embed-mixins'
  rdoc.options << '--exclude' << 'test/'
end
```

`RDoc::Task` also reads `.rdoc_options` (same loader as the CLI), so you can split: structural settings in `.rdoc_options`, environment-specific settings in the `Rakefile`.

### `.document`

A plain-text file that lists **which files to document**. Unlike the three options mechanisms, it doesn't set options — it controls what RDoc parses when it recurses into a directory.

**How it works.** When RDoc enters a directory, if that directory contains a `.document` file, only the patterns in the file are processed (via `Dir.glob` relative to the directory). Otherwise RDoc processes every parseable file in the directory.

**Syntax.**

- Whitespace-separated patterns (newlines count as whitespace).
- `#` starts a comment that runs to the end of the line.
- Patterns are shell globs, evaluated relative to the directory containing the `.document` file.

**Example (this repo's `.document`):**

```text
*.md
*.rdoc
lib
doc
```

**Per-directory scoping.** You can place a `.document` file inside any subdirectory to narrow what gets documented there:

```text
# lib/internal/.document
# Nothing — this subtree is excluded from generated docs.
```

### `RDOCOPT` environment variable

A shell environment variable whose contents are **prepended to `ARGV`** before RDoc parses options.

```sh
export RDOCOPT="--show-hash --visibility=private"
rdoc
```

**Precedence.** Because `RDOCOPT` is prepended, later command-line flags override it for the same option.

**Not recommended for project configuration.** `RDOCOPT` is machine-local and invisible to collaborators — use `.rdoc_options` instead. It exists for personal overrides (e.g., always turning on `--show-hash` on your workstation) and for compatibility with the `RUBYOPT` convention.

## Options reference

Each group below renders as a table with these columns:

| Column | Content |
|---|---|
| Option | CLI flag(s) and a brief name |
| `.rdoc_options` | YAML key, **not supported** if there is no YAML form, or **CLI only** if the option exists only on the CLI |
| `RDoc::Task` | Task attribute, or — if none (use `rdoc.options <<` as an escape hatch) |
| Effective default | Behavior after option setup |
| Notes | Behavior, gotchas, flags |

### What to document

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| Files to document | *(none — CLI uses positional args)* | `rdoc.rdoc_files` (a `Rake::FileList`; supports `.include` / `.exclude`) | current directory recursively when omitted | The set of files RDoc parses. CLI: positional arguments. Rake: a `Rake::FileList`. `.document`: per-directory selection. |
| `--exclude PATTERN` / `-x` | `exclude` (array) | — *(or `rdoc.rdoc_files.exclude(...)` at the file-list level)* | `[]` + default set | Regex applied to filenames during processing. Repeatable. Defaults add `*~`, `*.orig`, `*.rej`, `*.bak`, `*.gemspec`. |
| `--[no-]apply-default-exclude` | `apply_default_exclude` | — | `true` | Turn the default exclude list on/off. |
| `--no-skipping-tests` | **CLI only** | — | skip tests | Without this flag, RDoc skips common test directory names (`test`, `spec`). |
| `--page-dir DIR` | `page_dir` | — | `nil` | Directory holding guides, FAQ, and other non-class pages. Do not reuse filenames from the project root. |
| `--root DIR` | **CLI only** | — | current dir | Root of the source tree. Set when building docs outside the source directory. |
| `--visibility VIS` | `visibility: :public` etc. | — | `:protected` | Minimum visibility: `:public`, `:protected`, `:private`, or `:nodoc` (show everything). YAML values must be symbols. |
| `--all` / `-a` | `visibility: :private` | — | — | Synonym for `--visibility=private`. |
| `--include DIR` / `-i` | `rdoc_include` (array of paths) | — | `[project root]` | Directories searched to satisfy `:include:` directives. Comma-separated on the CLI; repeatable. |
| `--extension NEW=OLD` / `-E` | **CLI only** | — | — | Parse files with extension `.new` as if they had extension `.old`. Example: `-E cgi=rb`. |

### Appearance & content

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| `--title TITLE` / `-t` | `title` | `rdoc.title` | `nil` | Documentation title. |
| `--main NAME` / `-m` | `main_page` | `rdoc.main` | `nil` | File, class, or module shown on the initial page. |
| `--markup MARKUP` | `markup` | `rdoc.markup` | `'rdoc'` | One of `rdoc`, `markdown`, `rd`, `tomdoc`. |
| `--encoding ENCODING` / `-e` | `encoding` | — | `UTF-8` | Output encoding. All input files are transcoded to this encoding. Prefer over `--charset`. |
| `--charset CHARSET` / `-c` | `charset` | — | `'UTF-8'` | **Legacy.** HTML character-set. Use `--encoding` instead. |
| `--[no-]line-numbers` / `-N` | `line_numbers` | — | `false` | Show line numbers in source code listings. |
| `--show-hash` / `-H` | `show_hash` | — | `false` | Keep the leading `#` on hyperlinked instance method names. |
| `--tab-width WIDTH` / `-w` | `tab_width` | — | `8` | Column width of a tab character. |
| `--template NAME` / `-T` | **not supported** | `rdoc.template` | generator's template (`aliki` by default) | Template to use. YAML `template_dir` is not a supported persistent setting. |
| `--template-stylesheets FILES` | **CLI only** | — | `[]` | Extra stylesheets to include with the HTML template. Comma-separated. |
| `--[no-]embed-mixins` | `embed_mixins` | — | `false` | Inline mixin methods, attributes, and constants into the including class's documentation. |
| *(no CLI flag)* | `footer_content` | — | `nil` | **Aliki theme only.** Structured footer links; see [Examples](#examples). |
| `--copy-files PATH` | `static_path` (array) | — | `[]` | File or directory of static assets to copy into the output directory. Repeatable. |
| *(no CLI flag; internal)* | — | — | `true` | `output_decoration` controls heading decorations. Programmatic only. |

### Development & preview

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| `--server[=PORT]` | **CLI only** | (via `rdoc:server` task) | `false` | Start a live-reloading preview server. Default port `4000`. |
| `--pipe` / `-p` | **CLI only** | — | `false` | Convert RDoc on stdin to HTML. |
| `--write-options` | **CLI only** | — | — | Write a `.rdoc_options` file from current CLI flags, then exit. |
| `--[no-]coverage-report[=LEVEL]` / `--[no-]dcov` / `-C` | **CLI only** | (via `rdoc:coverage` task) | `false` | Print a report on undocumented items; skip file generation. |
| `--[no-]force-update` / `-U` | **CLI only** | — | `true` | Scan all sources even if none is newer than the flag file. |
| `--force-output` / `-O` | **CLI only** | — | `false` | Write output even if the output directory doesn't look like an RDoc output directory. |
| `--[no-]dry-run` | **CLI only** | — | `false` | Don't write any files. |
| `-D` / `--[no-]debug` | **CLI only** | — | `false` | Sets `$DEBUG_RDOC`; dumps internals. |
| `--quiet` / `-q` | **CLI only** | — | verbosity `1` | Suppress progress output by setting verbosity to `0`. |
| `--verbose` / `-V` | **CLI only** | — | verbosity `1` | Extra progress output by setting verbosity to `2`. |
| `--[no-]ignore-invalid` | **CLI only** | — | `true` | Ignore unknown options (used when new options meet old `.rdoc_options` files). |

### Cross-references & links

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| `--hyperlink-all` / `-A` | `hyperlink_all` | — | `false` | Hyperlink every word that matches a method name, even without `#` or `::` prefix. Legacy behavior. |
| `--autolink-excluded-words WORDS` | `autolink_excluded_words` (array) | — | `[]` | Words ignored by autolink. Comma-separated on the CLI. |
| `--webcvs URL` / `-W` | `webcvs` | — | `nil` | URL to a web CVS frontend. `%s` (or appended) is the filename. |
| `--warn-missing-rdoc-ref` | `warn_missing_rdoc_ref` | — | `true` | Warn when `rdoc-ref:` links can't be resolved. |
| *(no CLI flag)* | `canonical_root` | — | `nil` | Preferred root URL for the generated docs; used for `<link rel="canonical">`. |
| *(no CLI flag; internal)* | — | — | `nil` | `class_module_path_prefix` — path prefix for class/module pages. Programmatic only. |
| *(no CLI flag; internal)* | — | — | `nil` | `file_path_prefix` — path prefix for file pages. Programmatic only. |

### Output location & format

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| `--output DIR` / `-o` / `--op` | `op_dir` | `rdoc.rdoc_dir` | CLI: `'doc'`; `RDoc::Task`: `'html'` | Output directory. RDoc also writes a `created.rid` marker here. |
| `--format FORMAT` / `-f` / `--fmt` | `generator_name` | `rdoc.generator` | `'aliki'` | Generator name. Installed generators: `aliki` (HTML, default), `darkfish` *(deprecated, removal in v9.0)*, `ri`, `pot`. |
| `--ri` / `-r` | *(sets `generator_name: ri`)* | — | — | Shortcut: generate `ri` output into `~/.rdoc`. |
| `--ri-site` / `-R` | *(sets `generator_name: ri`)* | — | — | Shortcut: generate `ri` output into the site-wide directory. |

### Internationalization

| Option | `.rdoc_options` | `RDoc::Task` | Effective default | Notes |
|---|---|---|---|---|
| `--locale NAME` | `locale_name` | — | `nil` | Output locale. |
| `--locale-data-dir DIR` | `locale_dir` | — | `'locale'` | Directory containing locale data (`.po` files). |

## Examples

### Minimal gem setup

A `.rdoc_options` that covers title, entry page, markup, and exclusions:

```yaml
# .rdoc_options
title: MyGem
main_page: README.md
markup: markdown
exclude:
  - test/
  - tmp/
```

Commit this file to the repo. RubyGems' doc generator and `rdoc` on the command line both pick it up.

### Rakefile equivalent

The same outcome via `RDoc::Task`, using the `rdoc.options <<` escape hatch for options that aren't exposed as attributes:

```ruby
# Rakefile
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.title  = 'MyGem'
  rdoc.main   = 'README.md'
  rdoc.markup = 'markdown'
  rdoc.options << '--exclude' << 'test/'
  rdoc.options << '--exclude' << 'tmp/'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
end
```

### Customizing the Aliki footer

`footer_content` is a structured YAML value consumed by the Aliki theme. Each top-level key becomes a column; each nested key becomes a link label.

```yaml
# .rdoc_options
title: MyGem
footer_content:
  DOCUMENTATION:
    Home: index.html
    Guide: guide.html
  RESOURCES:
    GitHub: https://github.com/me/mygem
    Issues: https://github.com/me/mygem/issues
```

This option is only read by the Aliki generator (the default). Other generators silently ignore it.

### Tuning what gets documented

Combining the three knobs that control scope:

**`.document`** — narrow what gets parsed at all:

```text
# .document
*.md
*.rdoc
lib
```

**`.rdoc_options`** — exclude specific file patterns and raise the visibility bar:

```yaml
# .rdoc_options
exclude:
  - lib/mygem/internal/
  - '**/*_spec.rb'
visibility: :public
```

**Command line** — a one-off dry run without skipping test directories:

```sh
rdoc --no-skipping-tests --dry-run --verbose
```
