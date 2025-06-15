# antlr4-parser
- can use antl4 grammer to gurantee structure of input data/files
- workflow
  - create grammar
  - generate parser, lexer, etc
  - use parser to validate input data/files in runtime

## Usage
```bash
> just
just --list
Available recipes:
    clean                                  # remove generated files
    setup                                  # install tools

    [antlr]
    gen file='JSON.g4' lang='Java'         # gen parser, lexer, etc in language of choice
    parse file='JSON.g4' input='test.json' # show parse tree as text
    vis file='JSON.g4' input='test.json'   # show parse tree in gui
```

```bash
just setup
```

```bash
> just parse
uv run antlr4-parse Expr.g4 prog -tree
1*10+3
^D
(prog:1 (expr:2 (expr:1 (expr:3 1) * (expr:3 10)) + (expr:3 3)) <EOF>)
```

```bash
> just vis
uv run antlr4-parse Expr.g4 prog -gui
1+2*3
^D
```
