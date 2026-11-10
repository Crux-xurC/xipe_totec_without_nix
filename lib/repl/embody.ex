defmodule XipeTotec.Repl.Embody do
  @moduledoc """
  Where embody is: the per-language fixed modules evaluated rows are
  wrapped in (`embody.ml`, `embody.hs`), kept in their own repository
  (git@github.com:Crux-xurC/embody.git). `$XIPE_TOTEC_EMBODY_DIR`, else the
  `embody` directory next to this xipe_totec checkout.
  """

  defp __xt_default_dir__, do: Path.expand("../../../embody", XipeTotecWithoutNix.Root.dir(__DIR__))
  @spec dir() :: String.t()
  def dir, do: Path.expand(System.get_env("XIPE_TOTEC_EMBODY_DIR") || __xt_default_dir__())

  @doc "A file in it (`\"embody.ml\"`, `\"embody.hs\"`)."
  @spec path(String.t()) :: String.t()
  def path(file), do: Path.join(dir(), file)
end
