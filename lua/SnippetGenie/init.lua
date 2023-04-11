local M = {}

local module = require("SnippetGenie.format_session")
local fmt = require("SnippetGenie.lib.fmt")

local current_session
local user_options = {
    regex = [[-\+ Snippets goes here]],
    snippets_directory = "/home/ziontee113/.config/nvim/snippets/",
    file_name = "generated",
    parameters = { "trigger" },
    parameters_hl_groups = { "@annotation" },
    parameters_skeletons = { "" },
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

M.neo_finalize_snippet = function()
    local file_extension = vim.fn.expand("%:e")

    if current_session then
        user_options.filetype = vim.bo.ft
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, "filetype", "snippet_genie_prompt")
        vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

        local augroup = vim.api.nvim_create_augroup("test_augroup", { clear = true })
        vim.api.nvim_create_autocmd({ "CursorMoved", "TextChanged", "TextChangedI" }, {
            buffer = buf,
            group = augroup,
            callback = function()
                local ns = vim.api.nvim_create_namespace("test_ns")
                vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

                for i, param in ipairs(user_options.parameters) do
                    local ok, _ = pcall(vim.api.nvim_buf_set_extmark, buf, ns, i - 1, 0, {
                        virt_text = { { param, user_options.parameters_hl_groups[i] or "Normal" } },
                        virt_text_pos = "eol",
                    })

                    if ok and i == 3 then
                        vim.api.nvim_buf_set_lines(buf, 2, -1, false, { "*." .. file_extension })
                        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
                            virt_text = {
                                { param, user_options.parameters_hl_groups[i] or "Normal" },
                            },
                            virt_text_pos = "eol",
                        })
                    end
                end
            end,
        })

        local open_win_opts = {
            relative = "cursor",
            width = 40,
            col = 0,
            row = 0,
            style = "minimal",
            height = #user_options.parameters,
            border = "single",
        }

        local win = vim.api.nvim_open_win(buf, true, open_win_opts)
        vim.api.nvim_input("i")

        vim.keymap.set("n", "<CR>", function()
            local parameters_with_values = {}

            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, param in ipairs(user_options.parameters) do
                local parameter_value = ""

                if lines[i] then
                    parameter_value = fmt(
                        user_options.parameters_skeletons[i] or "{}",
                        { lines[i] },
                        {}
                    )
                end

                parameters_with_values[param] = parameter_value
            end

            local snippet_string = current_session:neo_produce_final_snippet(parameters_with_values)
            write_snippet_to_file(snippet_string)
            current_session = nil
            vim.api.nvim_win_close(win, true)
        end, { buffer = buf, silent = true })
    end
end

M.setup = function(opts)
    user_options = vim.tbl_deep_extend("force", user_options, opts)
end

return M

-- {{{nvim-execute-on-save}}}
