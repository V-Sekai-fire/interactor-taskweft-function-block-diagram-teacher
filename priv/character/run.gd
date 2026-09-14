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

	# Rung 3: generate a motion clip through kimodo when a text prompt
	# and the kimodo GGUFs are supplied. Writes a JSON descriptor next
	# to --animate-out with frames, joints, and the flat float arrays;
	# GLB retargeting is a later rung.
	var kimodo_prompt: String = args.get("animate-prompt", "")
	if not kimodo_prompt.is_empty():
		var motion_gguf: String = args.get("kimodo-motion-gguf", "")
		var text_gguf: String = args.get("kimodo-text-gguf", "")
		var text_adapter_gguf: String = args.get("kimodo-text-adapter-gguf", "")
		if motion_gguf.is_empty() or text_gguf.is_empty():
			push_error("run.gd: --animate-prompt requires --kimodo-motion-gguf and --kimodo-text-gguf")
			quit(7)
			return
		var animate_out: String = args.get("animate-out", out_path.get_basename() + ".motion.json")
		var kimodo = KimodoModel.new()
		var motion: Dictionary = kimodo.generate_motion(motion_gguf, text_gguf, text_adapter_gguf, kimodo_prompt, {})
		if motion.is_empty():
			push_error("run.gd: KimodoModel.generate_motion returned empty")
			quit(8)
			return
		var animate_file := FileAccess.open(animate_out, FileAccess.WRITE)
		if animate_file == null:
			push_error("run.gd: cannot write animate out: %s" % animate_out)
			quit(9)
			return
		animate_file.store_string(JSON.stringify(motion))
		animate_file.close()

	quit(0)
