local root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p"), ":h:h")
local tmpdir = vim.fn.tempname()
local biome = tmpdir .. "/node_modules/.bin/biome"

vim.fn.mkdir(vim.fn.fnamemodify(biome, ":h"), "p")

local output = [[
{"diagnostics":[
  {"severity":"error","category":"lint/suspicious/noDebugger","message":"Unexpected debugger.","location":{"path":"current.ts","start":{"line":3,"column":5}}},
  {"severity":"warning","category":"lint/correctness/noUnusedVariables","description":"Unused variable.","location":{"path":{"file":"legacy.ts"},"span":[6,7],"sourceCode":"first\nsecond"}}
]}
]]

local file = assert(io.open(biome, "w"))
file:write("#!/bin/sh\nprintf '%s' '", output:gsub("'", "'\\''"), "'\nexit 1\n")
file:close()
vim.fn.system({ "chmod", "+x", biome })

vim.cmd.cd(tmpdir)
vim.cmd("set rtp+=" .. vim.fn.fnameescape(root))
vim.cmd.runtime("plugin/biome-lint.lua")
vim.cmd("BiomeLint")

assert(
	vim.wait(5000, function()
		return #vim.fn.getqflist() == 2
	end),
	"BiomeLint did not populate quickfix"
)

local qf = vim.fn.getqflist()
assert(
	vim.fn.bufname(qf[1].bufnr):match("current%.ts$") and qf[1].lnum == 3 and qf[1].col == 5,
	"current schema location"
)
assert(qf[1].text == "lint/suspicious/noDebugger: Unexpected debugger.", "current schema message")
assert(
	vim.fn.bufname(qf[2].bufnr):match("legacy%.ts$") and qf[2].lnum == 2 and qf[2].col == 1,
	"legacy schema location"
)
assert(qf[2].text == "lint/correctness/noUnusedVariables: Unused variable.", "legacy schema message")

vim.cmd.cquit(0)
