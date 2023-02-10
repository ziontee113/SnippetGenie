local lib_selection = require("SnippetGenie.lib.visual_selection")

local M = {}

M.FormatSession = {
    original_content = nil,
    row_offset = nil,
    ranges = {},

    left_delimiter = "{",
    right_delimiter = "}",
}
M.FormatSession.__index = M.FormatSession

function M.FormatSession:initiate_original_values()
    self.original_content = lib_selection.get_selection_text()
    self.row_offset = lib_selection.get_visual_range()
end

function M.FormatSession.new()
    local session = vim.deepcopy(M.FormatSession)

    session:initiate_original_values()

    return session
end

return M
