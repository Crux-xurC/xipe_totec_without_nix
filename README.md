# Xipe Totec without Nix

[xipe_totec (Nix management: https://github.com/Crux-xurC/xipe_totec)](https://github.com/Crux-xurC/xipe_totec), made to run without
Nix.

Xipe Totec is a standalone local server and CLI that brings the structure of a spreadsheet to a functional-language project: cells with
addresses, references to addresses, and evaluating again by following the references in order. What it is and how to use it:
[README.xipe_totec.md](README.xipe_totec.md) (xipe_totec's own README) and [document/](document/how-to-use.md).

This repository is generated from xipe_totec (Nix management) by [`sync/sync.sh`](sync/README.md): the same code, made a Mix project
(`mix.exs`). Changes are made in xipe_totec (Nix management) and synced here; the xipe_totec commit this tree comes from is in
[`sync/UPSTREAM`](sync/UPSTREAM).

| xipe_totec (Nix management) | here |
|---|---|
| `nix develop`, then `xipe <args>` (`elixir main.exs <args>`) | `bin/xipe <args>` (put `bin/` on `PATH`, or link `bin/xipe` into it) |
| (none) | `bin/release`: a release (Erlang's runtime included) that `bin/xipe` runs when built; the directory can then be moved |
| BEAM packages from Nix | packages from Hex (`mix.lock`) |
| `./test/run.sh` | `bin/test` (`bin/test --live` adds the tests with real REPLs) |

Where xipe_totec's documents say `nix develop` or `xipe`, read them with this table.

## Requirements

- Linux (x86_64; others untried)
- Elixir 1.18 or later with Erlang/OTP 27 or later (checked with Elixir 1.20.0 / OTP 29)
- gcc, g++, make and libcap, to build erlexec (the REPLs)
- For OCaml and Haskell projects: `ocaml` / `ghci` in the target's environment, and
  [embody](https://github.com/Crux-xurC/embody) cloned next to this repository (or `XIPE_TOTEC_EMBODY_DIR` pointing at it)
- Optional: elixir-ls for scanning Elixir (without it, Xipe Totec's own scanner is used)

## Quick start

```sh
git clone https://github.com/Crux-xurC/xipe_totec_without_nix.git
git clone https://github.com/Crux-xurC/embody.git       # only for OCaml / Haskell
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

As in xipe_totec's README ("With tezcatl"): start the server on its own, `bin/xipe start --port 4200 --lsp ws://127.0.0.1:4100/lsp
--fs-root <root>`, and tezcatl's relay connects to it (`mode: "connect"` in tezcatl's `xipe.json`). For `mode: "spawn"`, the command in
`xipe.json` is `["<this directory>/bin/xipe", "serve"]` instead of `["elixir", "main.exs", "serve"]` (with `installDir` this directory).

## Status

A development version, not checked as widely as xipe_totec (Nix management): its tests pass (`bin/test`) and the CLI runs.

## License

MIT, as xipe_totec ([LICENSE](LICENSE)).
