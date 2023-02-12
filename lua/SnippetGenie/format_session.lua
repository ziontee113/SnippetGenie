local lib_selection = require("SnippetGenie.lib.visual_selection")
local lib_strings = require("SnippetGenie.lib.strings")
local fmt = require("SnippetGenie.lib.fmt")

local M = {}

M.FormatSession = {
    original_buffer = nil,
    original_content = nil,
    initial_mode = nil,

    row_offset = nil,
    col_offset = nil,

    holes = {},

    left_delimiter = "{",
    right_delimiter = "}",

    -- HACK: we use these characters because both `\a` and `\f` are 1 byte
    -- which Lua counts as `1` in `#length`
    special_left_delimiter = "\a",
    special_right_delimiter = "\f",

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
    self.original_buffer = vim.api.nvim_get_current_buf()

    self.row_offset, self.col_offset = lib_selection.get_visual_range()
    self.initial_mode = vim.fn.mode()
end

local mutate_range_with_offset = function(
    row_offset,
    col_offset,
    start_row,
    start_col,
    end_row,
    end_col
)
    end_row = end_row - row_offset + 1
    start_row = start_row - row_offset + 1

    if start_row == 1 then
        end_col = end_col - col_offset + 1
        start_col = start_col - col_offset + 1
    end

    return { start_row, start_col, end_row, end_col }
end

function M.FormatSession:add_hole()
    if vim.api.nvim_get_current_buf() == self.original_buffer then
        local mutated_range = mutate_range_with_offset(
            self.row_offset,
            self.col_offset,
            lib_selection.get_visual_range()
        )

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

    -- HACK:
    local snippet_body = lib_strings.format_with_delimiters(
        self.original_content,
        ranges,
        self.special_left_delimiter .. self.special_right_delimiter
    )

    snippet_body =
        string.gsub(snippet_body, self.left_delimiter, string.rep(self.left_delimiter, 2))
    snippet_body =
        string.gsub(snippet_body, self.right_delimiter, string.rep(self.right_delimiter, 2))

    snippet_body = string.gsub(snippet_body, self.special_left_delimiter, self.left_delimiter)
    snippet_body = string.gsub(snippet_body, self.special_right_delimiter, self.right_delimiter)

    if self.initial_mode == "v" then
        local lines = vim.split(snippet_body, "\n")
        local first_line = table.remove(lines, 1)

        local dedented_lines = lib_strings.dedent(lines)

        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(dedented_lines, 1, first_line)

        ---@diagnostic disable-next-line: param-type-mismatch
        snippet_body = table.concat(dedented_lines, "\n")
    end

    return snippet_body
end

local escape_special_characters = function(input)
    input = string.gsub(input, '"', '\\"')
    input = string.gsub(input, "\\", '\\\\"')
    return input
end

function M.FormatSession:produce_snippet_nodes()
    local snippet_nodes = {}

    for i, hole in ipairs(self.holes) do
        if string.find(hole.content, "\n") then
            hole.content = escape_special_characters(hole.content)

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

function M.FormatSession:set_trigger(trigger)
    self.trigger = trigger
end

function M.FormatSession:new(opts)
    local session = vim.deepcopy(M.FormatSession)

    session:initiate_original_values(opts)

    return session
end

return M
