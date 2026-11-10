defmodule XipeTotecWithoutNix.Root do
  # This repository's own. xipe_totec finds its own files from __DIR__, fixed
  # when Mix compiles; sync/transform.exs routes those through dir/1. Unset,
  # $XIPE_TOTEC_HOME changes nothing (the directory compiled from); set, the
  # same place under it -- where a release is installed (bin/xipe sets it).
  # Not XIPE_TOTEC_DIR: xipe_totec's Nix dev shell and tezcatl's E2E use that name.
  @moduledoc false
  @compile_root Path.expand("..", __DIR__)

  def dir(compiled_dir) do
    case System.get_env("XIPE_TOTEC_HOME") do
      home when is_binary(home) and home != "" ->
        Path.join(Path.expand(home), Path.relative_to(compiled_dir, @compile_root))

      _ ->
        compiled_dir
    end
  end
end
