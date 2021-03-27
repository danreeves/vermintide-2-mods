function init()

end

function update()
	local output_dir = ""
	local argv = {Application.argv()}
	for i = 1, table.maxn(argv) do
		if argv[i] == '-output_dir' then
			output_dir = argv[i + 1]
			break
		end
	end

	local targets_to_serialize = {
		"ibl_brdf_lut"
	}

	for _, target in pairs(targets_to_serialize) do
		f = (output_dir .. target .. ".dds")
		print ("Saving LUT: " .. f)
		Application.save_render_target(target, f)
	end

	print "All done!"
	print "Shutting down"

	Application.quit()
end
