local M = {}

local module = require("SnippetGenie.format_session")

local current_session
local user_options = {
    regex = [[-\+ Snippets goes here]],
    snippets_directory = "/home/ziontee113/.config/nvim/snippets/",
    file_name = "generated",
}

M.create_new_snippet_or_add_placeholder = function()
    if not current_session then
        current_session = module.FormatSession:new(user_options)
    else
        current_session:add_hole()
    end
end

local write_snippet_to_file = function(snippet_string)
    local file_path = user_options.snippets_directory
        .. user_options.filetype
        .. "/"
        .. user_options.file_name
        .. ".lua"
    local old_lines = vim.fn.readfile(file_path)
    local regex = vim.regex(user_options.regex)
    local target_line

    for line_number, line in ipairs(old_lines) do
        if regex:match_str(line) then
            target_line = line_number
            break
        end
    end

    if target_line then
        local new_lines = {}

        for i, line in ipairs(old_lines) do
            if i == target_line then
                -- TODO: might want to insert empty lines here

                for _, snippet_line in ipairs(vim.split(snippet_string, "\n")) do
                    table.insert(new_lines, snippet_line)
                end
            end

            table.insert(new_lines, line)
        end

        vim.fn.writefile(new_lines, file_path)
        require("luasnip.loaders").reload_file(vim.fn.expand(file_path)) -- hot reloading with LuaSnip
    end
end

M.finalize_snippet = function()
    if current_session then
        -- TODO: move this somewhere else cleaner
        user_options.filetype = vim.bo.ft

        vim.ui.input({ prompt = "Please enter Trigger for this Snippet" }, function(trigger)
            if trigger then
                current_session:set_trigger(trigger)

                local snippet_string = current_session:produce_final_snippet()
                write_snippet_to_file(snippet_string)

                current_session = nil
            end
        end)
    end
end

M.setup = function(opts)
    user_options = vim.tbl_deep_extend("force", user_options, opts)
end

return M

-- {{{nvim-execute-on-save}}}
