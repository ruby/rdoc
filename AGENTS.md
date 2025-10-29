# RDoc Project Guide for AI Agents

## Project Overview

**RDoc** is Ruby's default documentation generation tool that produces HTML and command-line documentation for Ruby projects. It parses Ruby source code, C extensions, and markup files to generate documentation.

- **Repository:** https://github.com/ruby/rdoc
- **Homepage:** https://ruby.github.io/rdoc
- **Required Ruby:** See the version specified in gemspec
- **Main Executables:** `rdoc` and `ri`

## Key Development Commands

### Testing

```bash
# Run all tests (default task)
bundle exec rake

# Run unit tests only (excludes RubyGems integration)
bundle exec rake normal_test

# Run RubyGems integration tests only
bundle exec rake rubygems_test

# Verify generated parser files are current (CI check)
bundle exec rake verify_generated
```

**Test Framework:** Test::Unit with `test-unit` gem
**Test Location:** `test/` directory
**Test Helper:** `test/lib/helper.rb`

### Linting

#### RuboCop (Ruby Linting)

```bash
# Check Ruby code style
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop -A
```

**Configuration:** `.rubocop.yml`

- Target Ruby: 3.0
- Minimal cop set (opt-in approach)
- Excludes generated parser files

#### Herb Linter (ERB/RHTML Files)

```bash
# Lint ERB template files
npx @herb-tools/linter "**/*.rhtml"

# Lint specific directory
npx @herb-tools/linter "lib/**/*.rhtml"
```

**Template Location:** `lib/rdoc/generator/template/**/*.rhtml`
**CI Workflow:** `.github/workflows/lint.yml`

### Documentation Generation

```bash
# Generate documentation (creates _site directory)
bundle exec rake rdoc

# Force regenerate documentation
bundle exec rake rerdoc

# Show documentation coverage
bundle exec rake rdoc:coverage
bundle exec rake coverage
```

**Output Directory:** `_site/` (GitHub Pages compatible)
**Configuration:** `.rdoc_options`

### Parser Generation

RDoc uses generated parsers for Markdown and RD formats:

```bash
# Generate all parser files from sources
bundle exec rake generate

# Remove generated parser files
bundle exec rake clean
```

**Generated Files:**

- `lib/rdoc/rd/block_parser.rb` (from `.ry` via racc)
- `lib/rdoc/rd/inline_parser.rb` (from `.ry` via racc)
- `lib/rdoc/markdown.rb` (from `.kpeg` via kpeg)
- `lib/rdoc/markdown/literals.rb` (from `.kpeg` via kpeg)

**Note:** These files are auto-generated and should not be edited manually. Always regenerate after modifying source `.ry` or `.kpeg` files.

### Building and Releasing

```bash
# Build gem package
bundle exec rake build

# Install gem locally
bundle exec rake install

# Create tag and push to rubygems.org
bundle exec rake release
```

## Project Structure

```sh
lib/rdoc/
├── rdoc.rb                    # Main entry point (RDoc::RDoc class)
├── version.rb                 # Version constant
├── task.rb                    # Rake task integration
├── parser/                    # Source code parsers (Ruby, C, Markdown, RD)
│   ├── ruby.rb                # Ruby code parser
│   ├── c.rb                   # C extension parser
│   ├── prism_ruby.rb          # Prism-based Ruby parser
│   └── ...
├── generator/                 # Documentation generators
│   ├── darkfish.rb            # HTML generator (default theme)
│   ├── markup.rb              # Markup format generator
│   ├── ri.rb                  # RI command generator
│   └── template/darkfish/     # ERB templates (.rhtml files)
├── markup/                    # Markup parsing and formatting
├── code_object/               # AST objects for documented items
├── markdown/                  # Markdown parsing
├── rd/                        # RD format parsing
└── ri/                        # RI (Ruby Info) tool

test/                          # 79 test files
├── lib/helper.rb              # Test helpers
└── rdoc/                      # Main test directory

exe/
├── rdoc                       # rdoc command executable
└── ri                         # ri command executable
```

## Important Files

### Configuration

- `.rubocop.yml` - RuboCop configuration (main)
- `.generated_files_rubocop.yml` - RuboCop config for generated files
- `.rdoc_options` - RDoc generation options
- `.document` - File list for documentation
- `Rakefile` - Task definitions
- `lib/rdoc/task.rb` - Task definitions provided by RDoc
- `rdoc.gemspec` - Gem specification
- `Gemfile` - Development dependencies

### CI/CD

- `.github/workflows/test.yml` - Test execution across Ruby versions/platforms
- `.github/workflows/lint.yml` - Linting (RuboCop + Herb)
- `.github/workflows/push_gem.yml` - Gem publishing

### Documentation

- `README.md` - Basic usage guide
- `ExampleRDoc.rdoc` - RDoc markup examples
- `doc/rdoc/markup_reference.rb` - RDoc markup references
- `ExampleMarkdown.md` - Markdown examples

## Architecture Notes

### Pluggable System

- **Parsers:** Ruby, C, Markdown, RD, Prism-based Ruby (experimental)
- **Generators:** HTML/Darkfish, RI, POT (gettext), JSON, Markup

## Common Workflows

Do NOT commit anything. Ask the developer to review the changes after tasks are finished.

NEVER pushes code to any repositories.

### Making Code Changes

Use Red, Green, Refactor approach:

1. **Ensure Ruby version**: Verify you're using Ruby 3.3.0+ (prepend `chruby <ruby version>` if needed)
2. **Red - Write failing tests**: Add tests that fail for the new behavior
3. **Verify failure**: Run `bundle exec rake` to confirm tests fail as expected
4. **Green - Make it work**: Implement the minimum code to make tests pass
5. **Refactor - Make it right**: Improve code quality while keeping tests green
   - Run `bundle exec rake` after each refactor to ensure tests still pass
   - Iterate on steps 4-5 as needed
6. **Lint your changes**:
   - Ruby code: `bundle exec rubocop -A` (auto-fix when possible)
   - ERB templates: `npx @herb-tools/linter "**/*.rhtml"` (if modified)

### Modifying Parsers

1. Edit source files (`.ry` or `.kpeg`)
2. Regenerate: `bundle exec rake generate`
3. Verify: `bundle exec rake verify_generated`
4. Run tests: `bundle exec rake`

### Updating Documentation

1. Modify documentation comments in source
2. Regenerate: `bundle exec rake rerdoc`
3. Check output in `_site/` directory
4. Check coverage: `bundle exec rake coverage`

## Notes for AI Agents

1. **Always run tests** after making changes: `bundle exec rake`
2. **Check both RuboCop and Herb** for linting
3. **Regenerate parsers** if you modify `.ry` or `.kpeg` files
4. **Use `rake rerdoc`** to regenerate documentation (not just `rdoc`)
5. **Verify generated files** with `rake verify_generated`
6. **Don't edit generated files** directly (in `lib/rdoc/markdown/` and `lib/rdoc/rd/`)
