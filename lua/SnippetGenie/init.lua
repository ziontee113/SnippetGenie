local M = {}

local module = require("SnippetGenie.format_session")

local current_session

local create_new_snippet_or_add_placeholder = function()
    if not current_session then
        current_session = module.FormatSession:new()
    else
        current_session:add_hole()
    end
end

local finalize_snippet = function()
    if current_session then
        vim.ui.input({ prompt = "Please enter Trigger for this Snippet" }, function(trigger)
            if trigger then
                current_session:set_trigger(trigger)

                local final_snippet = current_session:produce_final_snippet()
                N(final_snippet)

                -- TODO: write final_snippet to file

                current_session = nil
            end
        end)
    end
end

vim.keymap.set("x", "<CR>", function()
    create_new_snippet_or_add_placeholder()

    vim.cmd("norm! ")
end, {})

vim.keymap.set("n", "<CR>", function()
    finalize_snippet()
end, {})

return M

-- {{{nvim-execute-on-save}}}
