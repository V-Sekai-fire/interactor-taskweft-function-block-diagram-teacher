defmodule TaskweftFbdTeacher.Runner.CharacterTest do
  use ExUnit.Case, async: true

  alias TaskweftFbdTeacher.Runner.Character

  test "refuses when GODOT_ASSEMBLY_BIN is unset and no :bin given" do
    System.delete_env("GODOT_ASSEMBLY_BIN")
    assert {:error, {:no_godot_assembly_bin, _}} = Character.start([])
  end

  test "refuses when :bin points nowhere" do
    assert {:error, {:no_godot_assembly_bin, "/tmp/does-not-exist-godot"}} =
             Character.start(bin: "/tmp/does-not-exist-godot")
  end

  test "refuses when the priv script is missing" do
    scratch = System.tmp_dir!() |> Path.join("fake-godot-#{System.unique_integer([:positive])}")
    File.touch!(scratch)

    assert {:error, {:no_script, _}} =
             Character.start(bin: scratch, script: "/tmp/no-such-run.gd")
  after
    :ok
  end

  test "refuses when animate_prompt is set but the kimodo GGUFs are missing" do
    scratch = System.tmp_dir!() |> Path.join("fake-godot-#{System.unique_integer([:positive])}")
    fake_script = System.tmp_dir!() |> Path.join("fake-#{System.unique_integer([:positive])}.gd")
    File.touch!(scratch)
    File.touch!(fake_script)

    fake_image = System.tmp_dir!() |> Path.join("img-#{System.unique_integer([:positive])}.png")
    File.touch!(fake_image)
    fake_gguf_dir = System.tmp_dir!() |> Path.join("gguf-#{System.unique_integer([:positive])}")
    File.mkdir_p!(fake_gguf_dir)

    {:ok, r} = Character.start(bin: scratch, script: fake_script)

    assert {:refused, {:no_kimodo_motion_gguf, _}} =
             Character.run(r, %{
               image: fake_image,
               gguf_dir: fake_gguf_dir,
               out: "/tmp/out.glb",
               animate_prompt: "walk forward",
               kimodo_motion_gguf: "/tmp/no-motion.gguf",
               kimodo_text_gguf: "/tmp/no-text.gguf"
             })
  end

  test "refuses when the skin-tokens bundle path is missing" do
    scratch = System.tmp_dir!() |> Path.join("fake-godot-#{System.unique_integer([:positive])}")
    fake_script = System.tmp_dir!() |> Path.join("fake-#{System.unique_integer([:positive])}.gd")
    File.touch!(scratch)
    File.touch!(fake_script)

    fake_image = System.tmp_dir!() |> Path.join("img-#{System.unique_integer([:positive])}.png")
    File.touch!(fake_image)
    fake_gguf_dir = System.tmp_dir!() |> Path.join("gguf-#{System.unique_integer([:positive])}")
    File.mkdir_p!(fake_gguf_dir)

    {:ok, r} = Character.start(bin: scratch, script: fake_script)

    assert {:refused, {:no_skin_tokens_bundle, "/tmp/does-not-exist-bundle.gguf"}} =
             Character.run(r, %{
               image: fake_image,
               gguf_dir: fake_gguf_dir,
               out: "/tmp/out.glb",
               skin_tokens_bundle: "/tmp/does-not-exist-bundle.gguf"
             })
  end
end
