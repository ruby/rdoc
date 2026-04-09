# call-seq vs RBS: Can We Replace call-seq?

## The Overlap

Both express method signatures for documentation purposes:

```
# call-seq:
#   readlines(sep=$/)     -> array
#   readlines(limit)      -> array
#   readlines(sep, limit) -> array
```

```ruby
#: (?String sep) -> Array[String]
#: (Integer limit) -> Array[String]
#: (String sep, Integer limit) -> Array[String]
```

| Aspect | call-seq | RBS `#:` |
|--------|----------|----------|
| Multiple signatures/overloads | Yes (multiple lines) | Yes (multiple `#:` lines) |
| Argument names | Yes (`sep`, `limit`) | Yes (named params in RBS) |
| Return type | Yes (arrow notation) | Yes (formal type) |
| Parameter types | Implicit/prose | Explicit (String, Integer) |
| Default values | **YES** (`sep=$/`) | **NO** |
| Block/yield | Can describe | Formal block signature |
| Machine-readable | No (free-form text) | Yes (parseable by RBS tools) |

## The Gap: Default Values

call-seq from Ruby core (C extensions):
```c
/*  call-seq:
 *    commercial(cwyear, cweek=1, cwday=1, sg=nil) -> Date
 */
```

RBS cannot express `cweek=1` — only that the parameter is optional:
```ruby
#: (Integer cwyear, ?Integer cweek, ?Integer cwday, ?Symbol? sg) -> Date
```

The default value `1` is lost.

## Why This Matters

- In ruby/ruby, C extension methods have no Ruby source — call-seq is the ONLY way to document their signatures
- call-seq is free-form text (hard to parse, easy to get wrong, inconsistent across contributors)
- RBS is structured and machine-readable (enables type linking, validation, tooling)
- For a language that "doesn't want typing," using type signatures for documentation is a significant philosophical shift

## The Open Questions

1. Can RBS syntax be extended to support default values? (e.g., `?Integer cweek = 1`)
2. What's the migration path for thousands of existing call-seq entries in ruby/ruby?
3. Should call-seq remain for cases RBS can't express (version-specific overloads, prose descriptions)?

## Sources

- call-seq parsing: lib/rdoc/comment.rb `extract_call_seq` (lines 95-120)
- call-seq storage: lib/rdoc/code_object/any_method.rb `call_seq=`
- Real examples: test/rdoc/rdoc_comment_test.rb (ARGF.readlines, Date.commercial)
- RBS inline syntax: https://sorbet.org/docs/rbs-comments
