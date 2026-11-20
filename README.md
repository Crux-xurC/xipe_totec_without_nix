# Xipe Totec without Nix

[xipe_totec (Nix management: https://github.com/Crux-xurC/xipe_totec)](https://github.com/Crux-xurC/xipe_totec), made to run without
Nix.

Xipe Totec keeps the calls you try at a REPL as calc rows and evaluates them again in your project's own REPL (Elixir, OCaml,
Haskell, Python, F#, C#, Scala, Java; JavaScript, TypeScript, Go and PHP scanned only), with references between rows as in a
spreadsheet. What it is and how to use it: [README.xipe_totec.md](README.xipe_totec.md) (xipe_totec's short README; the whole is
[README.full.md](README.full.md), whose links to `README.md` mean README.xipe_totec.md) and [document/](document/how-to-use.md).

This repository is generated from xipe_totec (Nix management) by [`sync/sync.sh`](sync/README.md): the same code, made a Mix project
(`mix.exs`). Changes are made in xipe_totec (Nix management) and synced here; the xipe_totec commit this tree comes from is in
[`sync/UPSTREAM`](sync/UPSTREAM) (its tree in `sync/UPSTREAM_TREE`; CI says when it is not upstream's `main`).

| xipe_totec (Nix management) | here |
|---|---|
| `nix develop`, then `xipe <args>` (`elixir main.exs <args>`) | `bin/xipe <args>` (put `bin/` on `PATH`, or link `bin/xipe` into it) |
| (none) | `bin/release`: a release (Erlang's runtime included) that `bin/xipe` runs when built; the directory can then be moved |
| BEAM packages from Nix | packages from Hex (`mix.lock`) |
| `./test/run.sh` | `bin/test` (`bin/test --live` adds the tests with real REPLs) |

Where xipe_totec's documents say `nix develop` or `xipe`, read them with this table.

## Requirements

- Linux (x86_64; others untried)
- Elixir 1.18 or later with Erlang/OTP 27 or later (checked with Elixir 1.18.4 / OTP 27 and 1.20.0 / OTP 29); `bin/test` needs
  Elixir 1.19 or later (it leaves the real-REPL tests out with `test_load_filters`, new in 1.19)
- gcc, g++, make and libcap, to build erlexec (the REPLs)
- For every language but Elixir: its REPL and build tool in the target's environment (`document/how-to-use.md` §9), and
  [embody](https://github.com/Crux-xurC/embody) cloned next to this repository (or `XIPE_TOTEC_EMBODY_DIR` pointing at it)
- **Scala and Java: build the project once yourself, online, before the first evaluation** (`sbt compile`, `scala-cli compile .`,
  `mvn compile`): nothing is fetched while evaluating, and an empty cache fails the rows with `Error downloading …`
- Optional: elixir-ls for scanning Elixir (without it, Xipe Totec's own scanner is used)

## Quick start

```sh
git clone https://github.com/Crux-xurC/xipe_totec_without_nix.git
git clone https://github.com/Crux-xurC/embody.git       # for every language but Elixir
cd xipe_totec_without_nix
mix deps.get                                           # once; bin/xipe compiles on its first run

cp -r test/fixtures/calc_sample ~/calc                 # a small Elixir target to try on
bin/xipe choice project ~/calc                         # 1. register and choose the project
bin/xipe scan                                          # 2. make the functions cards
bin/xipe show                                          # 3. look up the node id of Calc.add/2
bin/xipe do row/add node=<id> args=[2,3] -- effect/set id=<id> effect=pure -- eval 'call_ids=[$0.id]'
                                                       # 4. make a calc row, classify the function, evaluate it: 5
```

Xipe Totec keeps its state (`tables/`) and reads its settings (`info.json`, `pipelines.json`, `defaults.json`, `project_env.json`) in
this directory, as xipe_totec does in its own. `bin/xipe` tells it where that is (`XIPE_TOTEC_HOME`); without it, the place it was
compiled in is used.

## With tezcatl

As in xipe_totec's README.full.md ("With tezcatl"): start the server on its own, `bin/xipe start --port 4200 --lsp ws://127.0.0.1:4100/lsp
--fs-root <root>`, and tezcatl's relay connects to it (`mode: "connect"` in tezcatl's `xipe.json`). For `mode: "spawn"`, the command in
`xipe.json` is `["<this directory>/bin/xipe", "serve"]` instead of `["elixir", "main.exs", "serve"]` (with `installDir` this directory).

## With an AI agent (MCP)

`bin/xipe mcp` is the MCP server of xipe_totec's `document/mcp.md`, for a running `bin/xipe start`. For Claude Code, in the
project's `.mcp.json`: `{ "mcpServers": { "xipe-totec": { "command": "<this directory>/bin/xipe", "args": ["mcp"] } } }`. The agent's
class proposals wait for a person: `bin/xipe do effect/approve 'ids=[…]'`, or tezcatl's `matrix approve`.

## Status

A development version, not checked as widely as xipe_totec (Nix management): its tests pass (`bin/test`, also in CI), the CLI runs,
and `bin/xipe mcp` was tried from the release (2026-11-21).

## License

MIT, as xipe_totec ([LICENSE](LICENSE)).
