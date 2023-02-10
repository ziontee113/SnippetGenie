local M = {}

M.FormatSession = {
    original_content = nil,
    row_offset = nil,
    ranges = {},

    left_delimiter = "{",
    right_delimiter = "}",
}
M.FormatSession.__index = M.FormatSession

function M.FormatSession.new()
    local session = vim.deepcopy(M.FormatSession)

    return session
end

return M
