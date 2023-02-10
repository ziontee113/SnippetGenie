local test_helpers = require("SnippetGenie.test_lib.helpers")
local lib = require("SnippetGenie.lib.visual_selection")

describe("get_selection_lines", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    it("returns selected lines", function()
        test_helpers.set_lines([[
Hello World.
Wassup Beijing.]])
        vim.cmd("norm! wvje")

        local want = { "World.", "Wassup Beijing" }
        assert.same(want, lib.get_selection_lines())
    end)
end)

describe("get_selection_text", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    it("returns selected text", function()
        test_helpers.set_lines([[
Hello World.
Wassup Beijing.]])
        vim.cmd("norm! wvje")

        local want = [[
World.
Wassup Beijing]]
        assert.same(want, lib.get_selection_text())
    end)

    it("returns full lines with V", function()
        test_helpers.set_lines([[
Hello World.
Wassup Beijing.]])
        vim.cmd("norm! Vj")

        local want = [[
Hello World.
Wassup Beijing.]]
        assert.same(want, lib.get_selection_text())
    end)

    it("keeps indents with V", function()
        test_helpers.set_lines([[
Hello World.
    Wassup Beijing.]])
        vim.cmd("norm! Vj")

        local want = [[
Hello World.
    Wassup Beijing.]]
        assert.same(want, lib.get_selection_text())
    end)

    it("handles indents with V and G", function()
        test_helpers.set_lines([[
local myfunc = function()
    -- TODO: 
end]])
        vim.cmd("norm! VG")

        local want = [[
local myfunc = function()
    -- TODO: 
end]]
        assert.same(want, lib.get_selection_text())
    end)
end)

describe("get_selection_text with dedent", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    it("dedents text", function()
        test_helpers.set_lines([[
local myfunc = function()
    -- TODO:
end]])
        vim.cmd("norm! jV")

        local want = [[
-- TODO:]]
        assert.same(want, lib.get_selection_text({ dedent = true }))
    end)
end)
