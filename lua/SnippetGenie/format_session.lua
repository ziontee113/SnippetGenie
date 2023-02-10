local lib_selection = require("SnippetGenie.lib.visual_selection")
local lib_strings = require("SnippetGenie.lib.strings")
local fmt = require("SnippetGenie.lib.fmt")

local M = {}

M.FormatSession = {
    original_buffer = nil,
    original_content = nil,
    row_offset = nil,

    holes = {},

    left_delimiter = "{",
    right_delimiter = "}",

    trigger = "myTrigger",
    snippet_skeleton = [[
cs({{
    trigger = "{trigger}",
    nodes = fmt(
        [=[
{body}
]=],
        {{
            {nodes}
        }}
),
    target_table = snippets,
}})
]],
}
M.FormatSession.__index = M.FormatSession

function M.FormatSession:initiate_original_values(opts)
    opts = opts or {}
    for key, value in pairs(opts) do
        self[key] = value
    end

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
        if string.find(hole.content, "\n") then
            local splits = vim.split(hole.content, "\n")
            for j, split in ipairs(splits) do
                splits[j] = string.format('"%s"', split)
            end
            local joined = table.concat(splits, ", ")
            hole.content = string.format("{ %s }", joined)

            table.insert(snippet_nodes, string.format("i(%s, %s),", i, hole.content))
        else
            table.insert(snippet_nodes, string.format('i(%s, "%s"),', i, hole.content))
        end
    end

    return snippet_nodes
end

function M.FormatSession:produce_final_snippet()
    local snippet_body = self:produce_snippet_body()
    local snippet_nodes = table.concat(self:produce_snippet_nodes(), "\n")

    local final_snippet = fmt(self.snippet_skeleton, {
        trigger = self.trigger,
        body = snippet_body,
        nodes = snippet_nodes,
    }, {})

    return final_snippet
end

function M.FormatSession:new(opts)
    local session = vim.deepcopy(M.FormatSession)

    session:initiate_original_values(opts)

    return session
end

return M
