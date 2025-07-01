-- Loading state management
local loading_jobs = {}

-- Simple spinner animation
local function create_spinner()
	local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
	local frame_index = 1
	return {
		next = function()
			local frame = frames[frame_index]
			frame_index = frame_index % #frames + 1
			return frame
		end,
	}
end

local function show_loading(job_id, message)
	local spinner = create_spinner()

	loading_jobs[job_id] = vim.fn.timer_start(100, function()
		vim.schedule(function()
			if loading_jobs[job_id] then
				print("\r" .. spinner.next() .. " " .. message)
			end
		end)
	end, { ["repeat"] = -1 })
end

local function stop_loading(job_id)
	if loading_jobs[job_id] then
		vim.fn.timer_stop(loading_jobs[job_id])
		loading_jobs[job_id] = nil
		print("\r") -- Clear the line
	end
end

local function find_biome_executable()
	local cwd = vim.fn.getcwd()

	-- Check for local biome executable in node_modules
	local paths_to_check = {
		cwd .. "/node_modules/.bin/biome",
		cwd .. "/../node_modules/.bin/biome",
		cwd .. "/../../node_modules/.bin/biome",
	}

	for _, path in ipairs(paths_to_check) do
		if vim.fn.executable(path) == 1 then
			return path
		end
	end

	-- Fallback to npx with specific version
	return "npx @biomejs/biome"
end

local function analyze_output(output)
	local ok, json_data = pcall(vim.fn.json_decode, output)
	if not ok then
		print("Failed to parse Biome JSON output")
		return
	end

	local qf_list = {}

	if json_data.diagnostics then
		for _, diagnostic in ipairs(json_data.diagnostics) do
			local location = diagnostic.location
			if location and location.path then
				-- Parse line/column from span and source code
				local line = 1
				local col = 1

				if location.span and location.sourceCode then
					local start_pos = location.span[1]
					local source_lines = vim.split(location.sourceCode, "\n")
					local char_count = 0

					for line_num, line_content in ipairs(source_lines) do
						if char_count + #line_content >= start_pos then
							line = line_num
							col = start_pos - char_count + 1
							break
						end
						char_count = char_count + #line_content + 1 -- +1 for newline
					end
				end

				table.insert(qf_list, {
					filename = location.path.file,
					lnum = line,
					col = col,
					type = diagnostic.severity == "error" and "E" or "W",
					text = diagnostic.category .. ": " .. diagnostic.description,
				})
			end
		end
	end

	vim.fn.setqflist(qf_list)
	if #qf_list > 0 then
		vim.cmd("copen")
		print("Found " .. #qf_list .. " Biome issue(s)")
	else
		print("No Biome issues found")
	end
end

-- Run biome lint and send report to quickfix
local function biome_lint()
	-- local file = vim.fn.expand("%")
	local biome_cmd = find_biome_executable()
	local config = require("biome-lint").get_config()

	local job_id = vim.fn.rand()

	print("🚀 Launching Biome's linter")
	show_loading(job_id, "Running Biome's linter...")

	local cmd = biome_cmd .. " lint --diagnostic-level=" .. config.severity .. " --reporter=json"

	-- if file then
	-- 	cmd = cmd .. " " .. vim.fn.shellescape(file)
	-- end

	-- Redirect stderr to /dev/null to hide the warning
	cmd = cmd .. " 2>/dev/null"

	-- Use vim.system for async execution (Neovim 0.10+)
	vim.system({ "sh", "-c", cmd }, {
		text = true,
	}, function(result)
		vim.schedule(function()
			stop_loading(job_id)

			if vim.trim(result.stdout) == "" then
				print("No Biome issues found" .. cmd)
				vim.fn.setqflist({})
				return
			end

			if result.code == 0 then
				print("No Biome issues found" .. cmd)
				vim.fn.setqflist({})
			elseif result.code == 1 then
				print(result.stdout)
				local output = result.stdout
				analyze_output(output)
			else
				print("❌ Command failed with code: " .. result.code)
				if result.stderr and result.stderr ~= "" then
					print("Error: " .. result.stderr)
				end
			end
		end)
	end)
end

vim.api.nvim_create_user_command("BiomeLint", biome_lint, {})
