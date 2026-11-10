# sync

This repository is [xipe_totec](https://github.com/Crux-xurC/xipe_totec) made a Mix project, to run without Nix. Almost every file
comes from xipe_totec through `sync/sync.sh` (see its header, and `sync/transform.exs`'s, for what they change); the files that came
are listed in `.upstream-files`, and the xipe_totec commit in `sync/UPSTREAM`. Do not edit those here: change xipe_totec and sync again.

This repository's own files:

| File | What |
|---|---|
| `README.md` | the entrance (upstream's README is `README.xipe_totec.md`) |
| `mix.exs`, `mix.lock` | the Mix project (versions follow xipe_totec's `nix/relay-packages.nix`) |
| `app/application.ex` | loads the plugins upstream's compiled files required (the generated `lib/xipe_totec_without_nix/plugins.ex`) |
| `app/root.ex` | where xipe_totec's own files are: the compiled place, or under `$XIPE_TOTEC_HOME` (relocation, see `sync/transform.exs`) |
| `bin/xipe` | the CLI (upstream: `elixir main.exs`) |
| `bin/test` | the tests (upstream: `test/run.sh`) |
| `test/test_helper.exs`, `test/isolated/test_helper.exs`, `test/live/test_helper.exs` | start ExUnit |
| `sync/` | this, `sync.sh`, `transform.exs`, `gitignore.extra`, `replaced.txt` (upstream files replaced by work of this repository; upstream's versions in `sync/upstream/`), `UPSTREAM` |

To update: `sync/sync.sh ~/path/to/xipe_totec`, review `git diff`, `bin/test`, commit with the upstream commit in the message.
