local module = require("SnippetGenie.format_session")
local helper = require("SnippetGenie.test_lib.helpers")

local user_opts = {
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

describe("format_session", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    it("initiate new FormatSession, add holes, output snippet", function()
        local content = [[
The sun rises in the east.
I love to drink coffee.

Hello Venus,
Welcome Mars. ]]
        helper.set_lines(content)
        vim.cmd("norm! 3jVG")

        -- session creation process --
        local session = module.FormatSession:new(user_opts)
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
    end)

    it("all above, with visual selection spans across multiple lines", function()
        local content = [[
The sun rises in the east.
I love to drink coffee.

Hello Venus,
Welcome Mars. ]]
        helper.set_lines(content)
        vim.cmd("norm! 3jVG")
        local session = module.FormatSession:new(user_opts)

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
        session:set_trigger("customTrigger")
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)

    it("all above, with visual selection spans across multiple lines, with curly braces", function()
        local content = [[
{ The sun rises in the east. }
I love to drink coffee.]]

        helper.set_lines(content)
        vim.cmd("norm! ggVG")
        local session = module.FormatSession:new(user_opts)

        vim.cmd("norm! gg0fTve")
        session:add_hole()

        assert.equals("The", session.holes[1].content)
        assert.same({ 1, 3, 1, 5 }, session.holes[1].range)
        vim.cmd("norm! ")

        local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
{{ {} sun rises in the east. }}
I love to drink coffee.
]=],
        {
            i(1, "The"),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)

    it("initial visual selection is `v` and does not start at start of line", function()
        local content = [[
{ The sun rises in the east. }
I love to drink coffee.]]

        helper.set_lines(content)

        -- new FormatSession with `The sun` as content
        vim.cmd("norm! fTvee") -- select `The sun`
        local session = module.FormatSession:new(user_opts)

        -- add `sun` as a placeholder (hole)
        vim.cmd("norm! 0fsve") -- select `sun`
        session:add_hole()

        assert.equals("sun", session.holes[1].content)
        assert.same({ 1, 5, 1, 7 }, session.holes[1].range)
        vim.cmd("norm! ")

        local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
The {}
]=],
        {
            i(1, "sun"),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)

    it("initial `v`, does not start at start of line, spans across multiple lines", function()
        local content = [[
function myfunc()
    if condition then
        action
    end
end
]]
        helper.set_lines(content)

        -- new FormatSession with if statement as content
        vim.cmd("norm! j0wvjj0fd")
        local session = module.FormatSession:new(user_opts)

        -- add `condition` as a placeholder (hole)
        vim.cmd("norm! kk0fcve") -- select `condition`
        session:add_hole()

        assert.equals("condition", session.holes[1].content)
        assert.same({ 1, 4, 1, 12 }, session.holes[1].range)
        vim.cmd("norm! ")

        -- add `action` as a placeholder (hole)
        vim.cmd("norm! j0fave") -- select `action`
        session:add_hole()

        assert.equals("action", session.holes[2].content)
        assert.same({ 2, 9, 2, 14 }, session.holes[2].range)
        vim.cmd("norm! ")

        local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
if {} then
    {}
end
]=],
        {
            i(1, "condition"),
            i(2, "action"),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)

    it("escapes backslashes and double quotes", function()
        local content = [[
function myfunc()
    if name == "John" then
        -- \testing backslashes\
    end
end
]]
        helper.set_lines(content)

        vim.cmd("norm! ggjVjj")
        local session = module.FormatSession:new(user_opts)

        -- add `John` as a placeholder (hole)
        vim.cmd('norm! ggj0f"vf"') -- select `John`
        session:add_hole()

        assert.equals('"John"', session.holes[1].content)
        vim.cmd("norm! ")

        -- add `-- \testing backslashes\` as a placeholder (hole)
        vim.cmd("norm! j0f-vf\\;")
        session:add_hole()

        assert.equals([[-- \testing backslashes\]], session.holes[2].content)
        vim.cmd("norm! ")

        local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
if name == {} then
    {}
end
]=],
        {
            i(1, "\"John\""),
            i(2, "-- \\testing backslashes\\"),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)

    it("works on this case ........", function()
        local content = [[
local function my_func()
    if self.initial_mode == "v" then
        local lines = vim.split(snippet_body, "\n")
        local first_line = table.remove(lines, 1)

        local dedented_lines = lib_strings.dedent(lines)

        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(dedented_lines, 1, first_line)

        ---@diagnostic disable-next-line: param-type-mismatch
        snippet_body = table.concat(dedented_lines, "\n")
    end
end
]]
        helper.set_lines(content)

        vim.cmd("norm! ggjVG2k")
        local session = module.FormatSession:new(user_opts)

        vim.cmd("norm! gg7jV")
        session:add_hole()
        assert.equals(
            "        ---@diagnostic disable-next-line: param-type-mismatch",
            session.holes[1].content
        )

        vim.cmd("norm! G4kV")
        session:add_hole()

        assert.equals(
            "        ---@diagnostic disable-next-line: param-type-mismatch",
            session.holes[2].content
        )

        local expected_final_snippet = [[
cs({
    trigger = "myTrigger",
    nodes = fmt(
        [=[
if self.initial_mode == "v" then
    local lines = vim.split(snippet_body, "\n")
    local first_line = table.remove(lines, 1)

    local dedented_lines = lib_strings.dedent(lines)

{}
    table.insert(dedented_lines, 1, first_line)

{}
    snippet_body = table.concat(dedented_lines, "\n")
end
]=],
        {
            i(1, "    ---@diagnostic disable-next-line: param-type-mismatch"),
            i(2, "    ---@diagnostic disable-next-line: param-type-mismatch"),
        }
),
    target_table = snippets,
})
]]
        assert.equals(expected_final_snippet, session:produce_final_snippet())
    end)
end)
