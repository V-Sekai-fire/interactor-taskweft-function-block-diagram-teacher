defmodule TaskweftFbdTeacher.Runner.Character do
  @moduledoc """
  RFD 2251 rung 1 runner. Reads an image plus a GGUF-set directory, boots
  the assembled Godot binary named by `GODOT_ASSEMBLY_BIN`, runs the
  character workflow GDScript in headless mode, and returns the GLB bytes.

  A missing `GODOT_ASSEMBLY_BIN` is a refusal, not a silent skip: the
  runner never falls back to a stub. Same shape as the compiler runner
  in this repository.
  """

  @behaviour TaskweftFbdTeacher.Runner

  defstruct [:bin, :script, :sha, timeout: 600_000]

  @impl true
  def start(opts) do
    bin = Keyword.get_lazy(opts, :bin, fn -> System.get_env("GODOT_ASSEMBLY_BIN") end)

    cond do
      bin in [nil, ""] ->
        {:error, {:no_godot_assembly_bin, "set GODOT_ASSEMBLY_BIN or pass :bin"}}

      not File.regular?(bin) ->
        {:error, {:no_godot_assembly_bin, bin}}

      true ->
        script = Keyword.get_lazy(opts, :script, fn -> default_script() end)

        cond do
          not File.regular?(script) ->
            {:error, {:no_script, script}}

          true ->
            {:ok,
             %__MODULE__{
               bin: Path.expand(bin),
               script: Path.expand(script),
               sha: sha(bin),
               timeout: Keyword.get(opts, :timeout, 600_000)
             }}
        end
    end
  end

  @impl true
  def provenance(%__MODULE__{} = c),
    do: %{godot_assembly_bin: c.bin, godot_assembly_sha: c.sha, script: c.script}

  @impl true
  def stop(%__MODULE__{}), do: :ok

  @impl true
  def run(%__MODULE__{} = c, %{image: image, gguf_dir: gguf_dir, out: out}) do
    cond do
      not File.regular?(image) ->
        {:refused, {:no_image, image}}

      not File.dir?(gguf_dir) ->
        {:refused, {:no_gguf_dir, gguf_dir}}

      true ->
        args = [
          "--headless",
          "--script",
          c.script,
          "++",
          "--image",
          Path.expand(image),
          "--gguf-dir",
          Path.expand(gguf_dir),
          "--out",
          Path.expand(out)
        ]

        case System.cmd(c.bin, args, stderr_to_stdout: true) do
          {out_str, 0} ->
            {:ok, %{glb_path: Path.expand(out), godot_log: out_str}}

          {out_str, code} ->
            {:refused, {:godot_exit, code, out_str}}
        end
    end
  end

  defp default_script do
    Application.app_dir(:taskweft_fbd_teacher, ["priv", "character", "run.gd"])
  end

  defp sha(bin) do
    case System.cmd("shasum", ["-a", "256", bin], stderr_to_stdout: true) do
      {out, 0} -> out |> String.split() |> List.first()
      _ -> nil
    end
  end
end
