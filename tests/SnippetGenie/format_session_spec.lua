local module = require("SnippetGenie.format_session")
local helper = require("SnippetGenie.test_lib.helpers")

describe("format_session", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    local original_content = [[
The sun rises in the east.
I love to drink coffee.

Hello Venus,
Welcome Mars. ]]

    it(
        "can initiate new FormatSession instance, add holes to it and produce snippet result",
        function()
            helper.set_lines(original_content)
            vim.cmd("norm! 3jVG")

            -- session creation process --
            local session = module.FormatSession:new()
            local expected_content = [[
Hello Venus,
Welcome Mars. ]]
            local expected_row_offset = 4

            assert.equals(expected_content, session.original_content)
            assert.equals(expected_row_offset, session.row_offset)
            vim.cmd("norm! ")

            -- first hole
            vim.cmd("norm! k0ve")
            session:add_hole()

            assert.equals("Hello", session.holes[1].content)
            assert.same({ 1, 1, 1, 5 }, session.holes[1].range)
            vim.cmd("norm! ")

            -- second hole
            vim.cmd("norm! j0vee")
            session:add_hole()

            assert.equals("Welcome Mars", session.holes[2].content)
            assert.same({ 2, 1, 2, 12 }, session.holes[2].range)

            -- produce snippet result --
            local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
{} Venus,
{}. 
]=],
        {
            i(1, "Hello"),
            i(2, "Welcome Mars"),
        }
),
    target_table = snippets,
})
]]
            assert.equals(expected_final_snippet, session:produce_final_snippet())
        end
    )

    it("does all of the above, with visual selection spans across multiple lines", function()
        helper.set_lines(original_content)
        vim.cmd("norm! 3jVG")
        local session = module.FormatSession:new({ trigger = "customTrigger" })

        vim.cmd("norm! k0wvj0e")
        session:add_hole()

        assert.equals("Venus,\nWelcome", session.holes[1].content)
        assert.same({ 1, 7, 2, 7 }, session.holes[1].range)
        vim.cmd("norm! ")

        local expected_final_snippet = [[
cs({
    trigger = "customTrigger",
    nodes = fmt(
        [=[
Hello {} Mars. 
]=],
        {
            i(1, { "Venus,", "Welcome" }),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)
end)
