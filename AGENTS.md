# RDoc Project Guide for AI Agents

## Project Overview

**RDoc** produces HTML and command-line documentation for Ruby projects. It parses Ruby source code, C extensions, RBS signature files, and markup files.

- **Repository:** https://github.com/ruby/rdoc
- **Homepage:** https://ruby.github.io/rdoc
- **Required Ruby:** See `required_ruby_version` in `rdoc.gemspec`
- **Main Executables:** `rdoc` and `ri`

## Repository Instructions

This file is the canonical entrypoint for repository guidance. See [CONTRIBUTING.md](CONTRIBUTING.md) for contributor setup and project conventions.

These repository guides cover specific tasks:

- [Server testing](.claude/skills/test-server/SKILL.md): endpoint checks, live reload, file changes, and server shutdown.
- [Release checks](.claude/skills/release-check/SKILL.md): merged PRs, release labels, and version recommendations.

Read the relevant guide directly. Slash-command availability depends on the agent tool.

## Development References

Use the contributor guide for [test commands](CONTRIBUTING.md#running-tests), [documentation commands](CONTRIBUTING.md#documentation-generation), and [parser generation](CONTRIBUTING.md#parser-generation).

### Linting

See [lint commands](CONTRIBUTING.md#linting) for Ruby, templates, and CSS.
For templates, use `npx @herb-tools/linter "lib/**/*.rhtml"` to avoid scanning installed dependencies.

### Type annotations

Annotate method types using [Sorbet flavored RBS](https://sorbet.org/docs/rbs-support) in inline comments.
For more information about RBS syntax, see the [documentation](https://github.com/ruby/rbs/blob/master/docs/syntax.md).

For example:

```ruby
# Method that receives an integer and doesn't return anything
#: (Integer) -> void
def foo(something); end
```

### Parser Generation

**Generated Files:**

- `lib/rdoc/rd/block_parser.rb` (from `.ry` via racc)
- `lib/rdoc/rd/inline_parser.rb` (from `.ry` via racc)
- `lib/rdoc/markdown.rb` (from `.kpeg` via kpeg)

Do not edit these generated files directly. If you change `.ry` or `.kpeg` sources, use the [parser workflow](#modifying-parsers).

### Building and Releasing

```bash
# Build gem package
bundle exec rake build

# Install gem locally
bundle exec rake install

# Create tag and push to rubygems.org
bundle exec rake release
```

## Project Navigation

See [project structure](CONTRIBUTING.md#project-structure) for the directory map and [themes](CONTRIBUTING.md#themes) for generator guidance.

- [RDoc orchestration](lib/rdoc/rdoc.rb), [repository tasks](Rakefile), and [public Rake integration](lib/rdoc/task.rb).
- [Configuration](doc/configuration.md), [RDoc markup](doc/markup_reference/rdoc.rdoc), [Markdown](doc/markup_reference/markdown.md), and [directive examples](doc/rdoc/example.rb).
- Parser tests: `test/rdoc/parser/ruby_test.rb` (`RDocParserRubyTest`) and `test/rdoc/parser/rbs_test.rb` (`RDocParserRBSTest`).

## Architecture Notes

Ruby parsing uses Prism.

### RBS Documentation Input and Signature Merging

`RDoc::Parser::RBS` parses selected `.rbs` files as documentation input. RBS declarations can document classes, modules, methods, attributes, and constants. They can also extend objects already documented from Ruby source.

`RDoc::RDoc` also discovers `sig/**/*.rbs` files for type signature merging and live preview tracking. Keep these paths distinct. Selected `.rbs` inputs build documentation objects, while auto-discovered signatures feed the RBS type-signature merge path.

### Code Object Model and Constant Aliases

The code-object tree (`lib/rdoc/code_object/`) has two phases. Parsers and `RDoc::Context` (`add_constant`, `add_module_alias`) handle parse-time work. `Store#complete` finalizes each container through `ClassModule#update_aliases`. This step resolves forward-reference aliases through `Constant#resolved_alias_target`.

If you add an invariant to one alias path, apply it to the other path too. For example, both paths must preserve an existing class at the alias name. `add_module_alias` handles partial store state and registers the alias constant. `update_aliases` resolves targets during finalization and writes alias copies into `classes_hash` or `modules_hash`.

**Known limitation: lexical scope.** `Context#find_enclosing_module_named` uses the parent chain as an approximation of Ruby's lexical constant lookup. The Prism parser does not represent module nesting through that chain. Aliases in nested or reopened classes can resolve to the wrong target. Accurate lexical scope requires parse-time information and a separate feature change.

### Marshal / ri Data Compatibility

Code objects such as `RDoc::Constant` and `RDoc::ClassModule` persist ri data through `marshal_dump` and `marshal_load`. Each class has a `MARSHAL_VERSION` constant. The `ri` CLI (`lib/rdoc/ri/driver.rb`) and the `ri --server` servlet (`lib/rdoc/ri/servlet.rb`) read this format.

If you change the dumped array or a slot's meaning, bump `MARSHAL_VERSION`. Preserve support for older payloads in the loader. This compatibility keeps cached `.ri` data readable after an upgrade.

### Live Preview Server (`RDoc::Server`)

[RDoc::Server](lib/rdoc/server.rb) provides `rdoc --server` for live documentation preview.
The watcher polls documentation inputs and auto-discovered `sig/**/*.rbs` files every second.
Template and CSS changes require a server restart. Input changes clear the full page cache.
The server calls `clear_file_contributions` before `remove_file` for a deleted file.

## Common Workflows

Do not commit changes. Do not push to any repository. Ask the developer to review the changes after the task.

After changes, run `bundle exec rake` and `bundle exec rake verify_generated`. Run the linters from [Linting](#linting) for each changed file type. Use RuboCop and Stylelint auto-fixes where possible.

### Making Code Changes

Use Red, Green, Refactor approach:

1. **Ruby version**: Use Ruby 3.3.0+. If needed, select the version with `chruby <ruby version>`
2. **Red - Write failing tests**: Add tests that fail for the new behavior
3. **Check failure**: Run `bundle exec rake` to check that tests fail as expected
4. **Green - Make it work**: Implement the minimum code to make tests pass
5. **Refactor - Make it right**: Improve code quality while keeping tests green
   - Run `bundle exec rake` after each refactor to check that tests still pass
   - Iterate on steps 4-5 as needed

### Modifying Parsers

1. Edit source files (`.ry` or `.kpeg`)
2. Regenerate: `bundle exec rake generate`
3. Check generated files: `bundle exec rake verify_generated`
4. Run tests: `bundle exec rake`

### Updating Documentation

1. Modify documentation comments in source
2. Regenerate: `bundle exec rake rerdoc`
3. Check output in `_site/` directory
4. Check coverage: `bundle exec rake coverage`

### Modifying Markup Reference Documentation

When editing markup reference documentation, such as `doc/markup_reference/markdown.md` and `doc/markup_reference/rdoc.rdoc`:

1. **Check rendering** - After changes, check the rendered HTML with the local source:

   For Markdown files:

   ```ruby
   ruby -Ilib -r rdoc -r rdoc/markdown -e '
   md = RDoc::Markdown.new
   doc = md.parse("YOUR CONTENT HERE")
   formatter = RDoc::Markup::ToHtml.new
   puts formatter.convert(doc)
   '
   ```

   For RDoc files:

   ```ruby
   ruby -Ilib -r rdoc -e '
   doc = RDoc::Markup.parse("YOUR CONTENT HERE")
   formatter = RDoc::Markup::ToHtml.new
   puts formatter.convert(doc)
   '
   ```

2. **Watch for rendering issues:**
   - Backtick escaping (especially nested code blocks)
   - Tilde characters being interpreted as strikethrough
   - Special characters in examples
   - Anchor links pointing to correct headings

3. **Known RDoc Markdown limitations:**
   - Only triple backticks for fenced code blocks (no tildes, no quad-backticks)
   - Tilde fences (`~~~`) conflict with strikethrough syntax
   - Use 4-space indentation to show literal code fence examples

4. **Check generated documentation**: Generate documentation and inspect the HTML output:

   ```bash
   bundle exec rake rerdoc
   # Inspect the generated HTML file directly
   grep -A5 "your content" _site/path/to/file.html
   ```

### Modifying Themes/Styling

For theme CSS or template changes:

1. Start the preview server with `bundle exec rdoc --server` or `bundle exec rake rdoc:server`.
2. Edit files in `lib/rdoc/generator/template/<theme>/` or the source code.
3. If you change templates or CSS, restart the server.
4. Use the [server testing guide](.claude/skills/test-server/SKILL.md) for endpoint checks, live reload, and file changes.
5. Run the template and CSS linters from [Linting](#linting) for the file types you changed.

Watched documentation inputs trigger automatic page reloads. The preview server always uses Aliki. Darkfish output requires static documentation generation.

## Pull Requests and Forks

Pull request descriptions must be concise. Use 2–4 short paragraphs to explain the context, correctness, and notable side effects. Do not include a "Test plan" section. Do not append a Claude Code session link or any AI attribution.

If this repository is a fork of `ruby/rdoc`, fast-forward its `master` to `ruby/rdoc:master` before you create a branch. A stale base can cause merge conflicts and divergence from upstream history.
