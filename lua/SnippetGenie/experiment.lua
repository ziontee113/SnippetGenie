vim.keymap.set("n", "<leader>j", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

    local augroup = vim.api.nvim_create_augroup("test_augroup", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "TextChanged", "TextChangedI" }, {
        buffer = buf,
        group = augroup,
        callback = function()
            local ns = vim.api.nvim_create_namespace("test_ns")
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
                virt_text = { { "snippet name", "@attribute" } },
                virt_text_pos = "eol",
            })
            vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
                virt_text = { { "keyboard shortcut", "@field" } },
                virt_text_pos = "eol",
            })
        end,
    })

    local open_win_opts = {
        relative = "cursor",
        width = 40,
        col = 0,
        row = 0,
        style = "minimal",
        height = 2,
        border = "single",
    }

    local win = vim.api.nvim_open_win(buf, true, open_win_opts)

    vim.api.nvim_input("i")

    vim.keymap.set("n", "q", ":q!<cr>", { buffer = buf, silent = true })
end, {})

-- {{{nvim-execute-on-save}}}
