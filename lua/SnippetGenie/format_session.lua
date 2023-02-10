local lib_selection = require("SnippetGenie.lib.visual_selection")
local lib_strings = require("SnippetGenie.lib.strings")

local M = {}

M.FormatSession = {
    original_buffer = nil,
    original_content = nil,
    row_offset = nil,

    holes = {},

    left_delimiter = "{",
    right_delimiter = "}",
}
M.FormatSession.__index = M.FormatSession

function M.FormatSession:initiate_original_values()
    self.original_content = lib_selection.get_selection_text()
    self.row_offset = lib_selection.get_visual_range()
    self.original_buffer = vim.api.nvim_get_current_buf()
end

local mutate_range_with_offet = function(offset, start_row, start_col, end_row, end_col)
    end_row = end_row - offset + 1
    start_row = start_row - offset + 1

    return { start_row, start_col, end_row, end_col }
end

function M.FormatSession:add_hole()
    if vim.api.nvim_get_current_buf() == self.original_buffer then
        local mutated_range =
            mutate_range_with_offet(self.row_offset, lib_selection.get_visual_range())

        local new_hole = {
            content = lib_selection.get_selection_text(),
            range = mutated_range,
        }
        table.insert(self.holes, new_hole)
    end
end

function M.FormatSession:produce_snippet_body()
    local ranges = {}
    for _, hole in ipairs(self.holes) do
        table.insert(ranges, hole.range)
    end

    local snippet_body = lib_strings.format_with_delimiters(self.original_content, ranges, "{}")
    return snippet_body
end

function M.FormatSession:produce_snippet_nodes()
    local snippet_nodes = {}

    for i, hole in ipairs(self.holes) do
        table.insert(snippet_nodes, string.format('i(%s, "%s")', i, hole.content))
    end

    return snippet_nodes
end

function M.FormatSession:produce_final_snippet()
    local snippet_body = self:produce_snippet_body()
    local snippet_nodes = self:produce_snippet_nodes()
end

function M.FormatSession.new()
    local session = vim.deepcopy(M.FormatSession)

    session:initiate_original_values()

    return session
end

return M
