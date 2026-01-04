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

#### Stylelint (CSS Files)

```bash
# Lint CSS files
npm run lint:css

# Auto-fix style issues
npm run lint:css -- --fix

# Lint specific file
npx stylelint "lib/rdoc/generator/template/aliki/css/rdoc.css"
```

**Configuration:** `.stylelintrc.json`
**Features:**
- Detects undefined CSS custom properties (variables)
- Detects missing `var()` function for custom properties
- Style and formatting checks
- Many issues auto-fixable with `--fix`

### Type annotations

Annotate method types using [Sorbet flavored RBS](https://sorbet.org/docs/rbs-support) in inline comments.
For more information about RBS syntax, see the [documentation](https://github.com/ruby/rbs/blob/master/docs/syntax.md).

A few examples:

```ruby
# Method that receives an integer and doesn't return anything
#: (Integer) -> void
def foo(something); end

# Method that receives a string and returns an integer
#: (String) -> Integer
def bar(something)
   123
end

# Method that doesn't accept arguments and returns a hash of symbol to string
#: () -> Hash[Symbol, String]
def bar
   { key: "value" }
end

# Method that accepts a block, which yields a single integer argument and returns whatever the block returns
#: [T] () { (Integer) -> T } -> T
def bar
   yield(5)
end
```

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
│   ├── aliki.rb               # HTML generator (default theme)
│   ├── darkfish.rb            # HTML generator (deprecated, will be removed in v8.0)
│   ├── markup.rb              # Markup format generator
│   ├── ri.rb                  # RI command generator
│   └── template/              # ERB templates (.rhtml files)
│       ├── aliki/             # Aliki theme (default)
│       └── darkfish/          # Darkfish theme (deprecated)
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

- `README.md` - Basic usage guide and markup format reference
- `markup_reference/rdoc.rdoc` - Comprehensive RDoc markup syntax reference
- `markup_reference/markdown.md` - Markdown syntax reference
- `doc/rdoc/example.rb` - Ruby code examples for cross-references and directives

## Architecture Notes

### Pluggable System

- **Parsers:** Ruby, C, Markdown, RD, Prism-based Ruby (experimental)
- **Generators:** HTML/Aliki (default), HTML/Darkfish (deprecated), RI, POT (gettext), JSON, Markup

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
   - CSS files: `npm run lint:css -- --fix` (if modified)

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

### Modifying Markup Reference Documentation

When editing markup reference documentation, such as `doc/markup_reference/markdown.md` and `doc/markup_reference/rdoc.rdoc`:

1. **Always verify rendering** - After making changes, test that the content renders correctly using Ruby:

   For Markdown files:

   ```ruby
   ruby -r rdoc -r rdoc/markdown -e '
   md = RDoc::Markdown.new
   doc = md.parse("YOUR CONTENT HERE")
   formatter = RDoc::Markup::ToHtml.new(RDoc::Options.new)
   puts formatter.convert(doc)
   '
   ```

   For RDoc files:

   ```ruby
   ruby -r rdoc -e '
   parser = RDoc::Markup::Parser.new
   doc = parser.parse("YOUR CONTENT HERE")
   formatter = RDoc::Markup::ToHtml.new(RDoc::Options.new)
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

4. **Full verification**: Generate documentation and inspect the HTML output:

   ```bash
   bundle exec rake rerdoc
   # Inspect the generated HTML file directly
   grep -A5 "your content" _site/path/to/file.html
   ```

### Modifying Themes/Styling

When making changes to theme CSS or templates (e.g., Darkfish or Aliki themes):

1. **Generate documentation**: Run `bundle exec rake rerdoc` to create baseline
2. **Start HTTP server**: Run `cd _site && python3 -m http.server 8000` (use different port if 8000 is in use)
3. **Investigate with sub-agent**: Use Task tool to launch a general-purpose agent to inspect the documentation with Browser MCP
   - The agent will connect browser to `http://localhost:8000`, navigate pages, and take screenshots
   - Agent reports findings back (styling issues, layout problems, etc.)
   - This saves context in main conversation
4. **Make changes**: Edit files in `lib/rdoc/generator/template/<theme>/` as needed
5. **Regenerate**: Run `bundle exec rake rerdoc` to rebuild documentation with changes
6. **Verify with sub-agent**: Use Task tool again to launch agent that uses Browser MCP to verify fixes
   - Agent takes screenshots and compares to original issues
   - Agent reports back whether issues are resolved
7. **Lint changes** (if modified):
   - ERB templates: `npx @herb-tools/linter "lib/rdoc/generator/template/**/*.rhtml"`
   - CSS files: `npm run lint:css -- --fix`
8. **Stop server**: Kill the HTTP server process when done

**Tip:** Keep HTTP server running during iteration. Just regenerate with `bundle exec rake rerdoc` between changes.

## Notes for AI Agents

1. **Always run tests** after making changes: `bundle exec rake`
2. **Lint your changes**:
   - RuboCop for Ruby: `bundle exec rubocop -A`
   - Herb for ERB templates: `npx @herb-tools/linter "**/*.rhtml"`
   - Stylelint for CSS: `npm run lint:css -- --fix`
3. **Regenerate parsers** if you modify `.ry` or `.kpeg` files
4. **Use `rake rerdoc`** to regenerate documentation (not just `rdoc`)
5. **Verify generated files** with `rake verify_generated`
6. **Don't edit generated files** directly (in `lib/rdoc/markdown/` and `lib/rdoc/rd/`)

## Browser MCP for Testing Generated Documentation

Browser MCP allows AI agents to visually inspect and interact with the generated HTML documentation. This is useful for verifying CSS styling, layout issues, and overall appearance.

**Repository:** <https://github.com/BrowserMCP/mcp>

### Setup

If Browser MCP is not already installed, users should:

1. Install the BrowserMCP Chrome extension from the Chrome Web Store
2. Run: `claude mcp add --scope user browsermcp npx @browsermcp/mcp@latest`
3. Connect a browser tab by clicking the BrowserMCP extension icon and selecting "Connect"

### Testing Generated Documentation

To test the generated documentation with Browser MCP:

```bash
# Generate documentation
bundle exec rake rerdoc

# Start a simple HTTP server in the _site directory (use an available port)
cd _site && python3 -m http.server 8000
```

If port 8000 is already in use, try another port (e.g., `python3 -m http.server 9000`).

Then navigate to the appropriate URL (e.g., `http://localhost:8000`) in your connected browser tab and ask Claude to use browser MCP tools (e.g., "use browser MCP to navigate to <http://localhost:8000> and take a screenshot").

**Note:** Browser MCP requires a proper HTTP server (not `file://` URLs) for full functionality. The generated documentation must be served via HTTP/HTTPS.
