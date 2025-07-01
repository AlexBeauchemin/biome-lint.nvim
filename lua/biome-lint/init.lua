local M = {}

--- @class Opts
--- @field severity? string - ("error") The severity level of the diagnostics. Can be "error", "warn", "info"

local DEFAULT_CONFIG = {
	severity = "error",
}

M.config = DEFAULT_CONFIG

-- @return Opts
M.get_config = function()
	return M.config
end

--- @param opts Opts | nil
M.setup = function(opts)
	if
		opts ~= nil
		and opts.severity ~= nil
		and opts.severity ~= "error"
		and opts.severity ~= "warn"
		and opts.severity ~= "info"
	then
		error("Invalid severity level: " .. opts.severity)
	end
	M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
end

return M
