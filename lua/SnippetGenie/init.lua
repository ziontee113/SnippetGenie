local M = {}

local module = require("SnippetGenie.format_session")

local current_session

vim.keymap.set("x", "<CR>", function()
    if not current_session then
        current_session = module.FormatSession:new()
    else
        current_session:add_hole()
    end

    vim.cmd("norm! ")
end, {})

vim.keymap.set("n", "<CR>", function()
    if current_session then
        vim.ui.input({ prompt = "Please enter Trigger for this Snippet" }, function(trigger)
            if trigger then
                current_session:set_trigger(trigger)

                local final_snippet = current_session:produce_final_snippet()
                N(final_snippet)

                current_session = nil
            end
        end)
    end
end, {})

return M

-- {{{nvim-execute-on-save}}}
