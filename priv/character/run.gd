# RFD 2251 rung 1 smoke test. Reads an image path and a GGUF-set path
# from --image and --gguf-dir, calls Pixal3DModel.image_to_glb, writes
# the returned GLB bytes to --out. Emits nothing else on stdout so the
# Elixir caller can rely on the exit code.
extends SceneTree

func _init() -> void:
	var args := Dictionary()
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		var a: String = argv[i]
		if a.begins_with("--") and i + 1 < argv.size():
			args[a.substr(2)] = argv[i + 1]

	var image_path: String = args.get("image", "")
	var gguf_dir: String = args.get("gguf-dir", "")
	var out_path: String = args.get("out", "")
	if image_path.is_empty() or gguf_dir.is_empty() or out_path.is_empty():
		push_error("run.gd: --image, --gguf-dir, --out are all required")
		quit(2)
		return

	var image_file := FileAccess.open(image_path, FileAccess.READ)
	if image_file == null:
		push_error("run.gd: cannot open image: %s" % image_path)
		quit(3)
		return
	var image_bytes := image_file.get_buffer(image_file.get_length())
	image_file.close()

	var opts := {
		"dino_gguf": gguf_dir.path_join("dino.gguf"),
		"ss_flow_gguf": gguf_dir.path_join("ss_flow.gguf"),
		"ss_dec_gguf": gguf_dir.path_join("ss_dec.gguf"),
		"slat_flow_gguf": gguf_dir.path_join("slat_flow.gguf"),
		"shape_dec_gguf": gguf_dir.path_join("shape_dec.gguf"),
	}
	var pixal3d = Pixal3DModel.new()
	var glb: PackedByteArray = pixal3d.image_to_glb(image_bytes, opts)
	if glb.is_empty():
		push_error("run.gd: Pixal3DModel.image_to_glb returned empty")
		quit(4)
		return

	var out_file := FileAccess.open(out_path, FileAccess.WRITE)
	if out_file == null:
		push_error("run.gd: cannot write out: %s" % out_path)
		quit(5)
		return
	out_file.store_buffer(glb)
	out_file.close()

	# Rung 2: rig the body with skin-tokens if a bundle path is supplied.
	var st_bundle: String = args.get("skin-tokens-bundle", "")
	if not st_bundle.is_empty():
		var rig_out: String = args.get("rig-out", out_path)
		var skin = SkinTokensModel.new()
		var rig_status: int = skin.rig_file(st_bundle, out_path, rig_out, {})
		if rig_status != 0:
			push_error("run.gd: SkinTokensModel.rig_file returned %d" % rig_status)
			quit(6)
			return

	quit(0)
