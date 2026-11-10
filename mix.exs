defmodule XipeTotecWithoutNix.MixProject do
  use Mix.Project

  # Xipe Totec as a Mix project, for running without Nix.
  #
  # lib/ and test/ come from xipe_totec (the upstream, run with Nix as
  # `elixir main.exs`) through sync/sync.sh; this repository's own files are
  # listed in sync/README.md. The dependency versions follow upstream's
  # nix/relay-packages.nix.
  def project do
    [
      app: :xipe_totec,
      version: "0.1.0",
      elixir: "~> 1.18",
      # lib/**/*.ex; the plugins (lib/repl/language/, lib/repl/eval/scan/) stay
      # .exs and are loaded at run time, as upstream does
      elixirc_paths: ["lib", "app"],
      test_paths: [System.get_env("XIPE_TEST_PATH", "test")],
      # tests define protocol implementations of their own (@derive Inspect),
      # which consolidated protocols would not see
      consolidate_protocols: Mix.env() != :test,
      # test/live/ needs real REPLs and test/isolated/ runs one file at a time
      # (bin/test); neither is part of a plain `mix test`
      test_load_filters: [&load_test?/1],
      test_ignore_filters: [&(not load_test?(&1))],
      # erlexec only loaded: xipe_totec starts it when it first runs a program
      # (ensure_all_started), after app/release_env.ex has cleaned the environment
      # the release gave the VM -- erlexec's port program keeps the one it starts with
      releases: [xipe_totec: [include_executables_for: [:unix], applications: [erlexec: :load]]],
      deps: deps()
    ]
  end

  defp load_test?(path) do
    String.ends_with?(path, "_test.exs") and
      (System.get_env("XIPE_TEST_PATH") != nil or
         not String.contains?(path, ["test/live/", "test/isolated/"]))
  end

  def application do
    [extra_applications: [:logger, :crypto, :inets], mod: {XipeTotecWithoutNix.Application, []}]
  end

  defp deps do
    [
      {:cowboy, "== 2.12.0"},
      {:cowlib, "== 2.13.0", override: true},
      {:ranch, "== 2.1.0", override: true},
      {:gun, "== 2.1.0"},
      {:erlexec, "== 2.3.4", runtime: false}
    ]
  end
end
