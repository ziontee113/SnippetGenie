local module = require("SnippetGenie.format_session")
local helper = require("SnippetGenie.test_lib.helpers")

describe("format_session", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    it("can initiate new FormatSession instance and add holes to it", function()
        local original_content = [[
The sun rises in the east.
I love to drink coffee.

Hello Venus,
Welcome Mars. ]]
        helper.set_lines(original_content)
        vim.cmd("norm! 3jVG")

        -- session creation process
        local session = module.FormatSession:new()

        local expected_content = [[
Hello Venus,
Welcome Mars. ]]
        local expected_row_offset = 4

        assert.equals(expected_content, session.original_content)
        assert.equals(expected_row_offset, session.row_offset)

        vim.cmd("norm! ")

        -- add_hole process
        vim.cmd("norm! k0ve")
        session:add_hole()
        assert.equals("Hello", session.holes[1].content)
        assert.are.same({ 1, 1, 1, 5 }, session.holes[1].range)
    end)
end)
