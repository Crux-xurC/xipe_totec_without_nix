# sync/transform.exs <dir> -- turn an extracted xipe_totec tree (in <dir>) into
# this repository's layout. Run by sync/sync.sh; changes files in <dir> only.
#
# xipe_totec loads its files with Code.require_file (main.exs, and files
# requiring each other). Here Mix compiles lib/**/*.ex instead, except the
# plugins, which xipe_totec itself loads at run time and lists by their
# `.exs` names (lib/info.exs): lib/repl/language/ and lib/repl/eval/scan/ stay
# `.exs`. So, for every line that is only `Code.require_file(<path>, __DIR__)`
# or `Code.require_file(Path.expand(<path>, __DIR__))`:
#
#   target compiled (a non-plugin lib file, now .ex)  -> the line is removed
#   target a plugin, in a plugin or a test            -> kept (as upstream)
#   target a plugin, in a compiled file               -> removed there, and the
#     plugin is loaded instead by XipeTotecWithoutNix.Plugins.load/0 (generated
#     here, lib/xipe_totec_without_nix/plugins.ex), which this repository's
#     application calls when it starts -- what main.exs's requires did
#
# A test that reads a compiled file's source by its path ("../lib/x.exs")
# gets ".ex".
#
# Relocation: xipe_totec finds its own files (info.json, tables/ ...) with
# Path.expand(<path>, __DIR__), which Mix fixes when it compiles. In compiled
# files __DIR__ there becomes XipeTotecWithoutNix.Root.dir(__DIR__) (app/root.ex:
# the same directory, or under $XIPE_TOTEC_HOME when that is set), and a module
# attribute holding such a path (@x Path.expand(...)) becomes a private
# function __xt_x__/0 evaluated when called, so a built release still finds
# the files where it is installed. Unset, nothing changes.
#
# Also: main.exs -> lib/cli.ex without its last line (the call of
# XipeTotec.CLI.main/1, which bin/xipe makes); tests without ExUnit.start
# (test/test_helper.exs starts it). Any other require of a compiled file is an
# error: this script must learn its form.

[dir] = System.argv()
dir = Path.expand(dir)

plugin? = fn rel ->
  String.starts_with?(rel, "lib/repl/language/") or String.starts_with?(rel, "lib/repl/eval/scan/")
end

compiled? = fn rel ->
  String.starts_with?(rel, "lib/") and String.ends_with?(rel, ".exs") and not plugin?.(rel)
end

rel_of = fn abs -> Path.relative_to(abs, dir) end

req_re =
  ~r/^\s*Code\.require_file\((?:"([^"]+)",\s*__DIR__|Path\.expand\("([^"]+)",\s*__DIR__\))\)\s*$/

# the target of a require line in file `rel`, relative to dir, or nil
target = fn line, rel ->
  case Regex.run(req_re, line) do
    [_, p, ""] -> rel_of.(Path.expand(p, Path.join(dir, Path.dirname(rel))))
    [_, "", p] -> rel_of.(Path.expand(p, Path.join(dir, Path.dirname(rel))))
    [_, p] -> rel_of.(Path.expand(p, Path.join(dir, Path.dirname(rel))))
    _ -> nil
  end
end

# a require of a compiled file not matched by req_re would be left behind
check_left = fn rel, lines ->
  for l <- lines, String.contains?(l, "Code.require_file("), t = target.(l, rel), t == nil do
    if Regex.match?(~r/Code\.require_file\(\s*(Path\.expand\()?"[^"]*\.exs"/, l) and
         not Regex.match?(~r/(language|eval\/scan|fixtures)\//, l) do
      IO.puts(:stderr, "transform: #{rel}: a require this script does not know: #{String.trim(l)}")
      System.halt(1)
    end
  end
end

files = fn pattern -> dir |> Path.join(pattern) |> Path.wildcard() |> Enum.map(rel_of) |> Enum.sort() end

plugin_loads = :ets.new(:loads, [:ordered_set, :public])
counter = :counters.new(1, [])

process = fn rel, mode ->
  abs = Path.join(dir, rel)
  lines = abs |> File.read!() |> String.split("\n")

  kept =
    Enum.reject(lines, fn l ->
      case target.(l, rel) do
        nil ->
          mode == :test and Regex.match?(~r/^ExUnit\.start\([^)]*\)\s*$/, l)

        t ->
          cond do
            compiled?.(t) ->
              true

            plugin?.(t) and mode == :compiled ->
              unless :ets.match(plugin_loads, {:_, t}) != [] do
                :counters.add(counter, 1, 1)
                :ets.insert(plugin_loads, {:counters.get(counter, 1), t})
              end

              true

            true ->
              false
          end
      end
    end)

  check_left.(rel, kept)

  # a test that reads a compiled file's source by its path ("../lib/x.exs")
  # reads it as .ex
  kept =
    if mode == :test do
      Enum.map(kept, fn l ->
        Regex.replace(~r/"((?:\.\.\/)+lib\/[A-Za-z0-9_\/]+)\.exs"/, l, fn whole, p ->
          t = rel_of.(Path.expand(p <> ".exs", Path.join(dir, Path.dirname(rel))))
          if compiled?.(t), do: "\"#{p}.ex\"", else: whole
        end)
      end)
    else
      kept
    end

  File.write!(abs, Enum.join(kept, "\n"))
end

# main.exs -> lib/cli.ex (its requires resolved from where it is, then moved)
lib = files.("lib/**/*.exs")
main = Path.join(dir, "main.exs")
call = "XipeTotec.CLI.main(System.argv())"
process.("main.exs", :compiled)
src = File.read!(main)

unless String.contains?(src, "\n" <> call <> "\n") or String.ends_with?(src, "\n" <> call) do
  IO.puts(:stderr, "transform: main.exs does not end with #{call}")
  System.halt(1)
end

if File.exists?(Path.join(dir, "lib/cli.ex")), do: raise("transform: upstream has lib/cli.ex")
File.write!(Path.join(dir, "lib/cli.ex"), src |> String.replace("\n" <> call, "") |> String.trim_trailing() |> Kernel.<>("\n"))
File.rm!(main)

Enum.each(lib, fn rel -> process.(rel, if(plugin?.(rel), do: :plugin, else: :compiled)) end)

for rel <- lib, compiled?.(rel) do
  File.rename!(Path.join(dir, rel), Path.join(dir, String.replace_suffix(rel, ".exs", ".ex")))
end

Enum.each(files.("test/**/*_test.exs"), &process.(&1, :test))

# --- relocation (see the head) ---
attr_re = ~r/^(\s*)@(\w+) Path\.expand\(("[^"]*"), __DIR__\)\s*$/m

for rel <- files.("lib/**/*.ex") do
  abs = Path.join(dir, rel)
  src = File.read!(abs)
  names = Regex.scan(attr_re, src) |> Enum.map(fn [_, _, n, _] -> n end)

  src =
    Regex.replace(attr_re, src, fn _, ind, n, p ->
      "#{ind}defp __xt_#{n}__, do: Path.expand(#{p}, XipeTotecWithoutNix.Root.dir(__DIR__))"
    end)

  src = Enum.reduce(names, src, fn n, s -> Regex.replace(~r/@#{n}(?![A-Za-z0-9_])/, s, "__xt_#{n}__()") end)
  src = Regex.replace(~r/Path\.expand\(("[^"]*"), __DIR__\)/, src, "Path.expand(\\1, XipeTotecWithoutNix.Root.dir(__DIR__))")
  File.write!(abs, src)
end

loads = :ets.tab2list(plugin_loads) |> Enum.map(&elem(&1, 1))
File.mkdir_p!(Path.join(dir, "lib/xipe_totec_without_nix"))

File.write!(Path.join(dir, "lib/xipe_totec_without_nix/plugins.ex"), """
defmodule XipeTotecWithoutNix.Plugins do
  # Generated by sync/transform.exs (do not edit): the plugins (.exs, loaded at
  # run time) that xipe_totec's compiled files required when main.exs loaded
  # them. This repository's application loads them when it starts.
  @moduledoc false
  @files #{inspect(loads)}

  def load do
    for f <- @files, do: Code.require_file(Path.expand("../../" <> f, XipeTotecWithoutNix.Root.dir(__DIR__)))
    :ok
  end
end
""")

IO.puts("transform: #{length(lib)} lib files, plugins loaded at start: #{inspect(loads)}")
