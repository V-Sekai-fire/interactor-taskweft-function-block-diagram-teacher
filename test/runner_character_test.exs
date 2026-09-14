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
end
