local lib_strings = require("SnippetGenie.lib.strings")

describe("if_string_empty()", function()
    it("returns true for empty strings", function()
        assert.is_true(lib_strings.if_string_empty(""))
        assert.is_true(lib_strings.if_string_empty("    "))
        assert.is_true(lib_strings.if_string_empty("\t"))
        assert.is_true(lib_strings.if_string_empty("  \n  \t   "))
    end)

    it("returns false for non-empty strings", function()
        assert.is_false(lib_strings.if_string_empty("ching cheng han ji"))
        assert.is_false(lib_strings.if_string_empty("tom cat"))
        assert.is_false(lib_strings.if_string_empty("jerry"))
    end)
end)

describe("dedent()", function()
    it("removes leading whitespaces from a single line string", function()
        local input = "    Hello"
        local expected = "Hello"

        local result = lib_strings.dedent(input)

        assert.equals(expected, result)
    end)

    it("removes leading whitespaces from a multi-line string", function()
        local input = [[
    Hello
        Venus]]
        local expected = [[
Hello
    Venus]]

        local result = lib_strings.dedent(input)

        assert.equals(expected, result)
    end)

    it("handles leading whitespaces for strings in a table", function()
        local input = { "    -- TODO:" }
        local expected = { "-- TODO:" }

        local result = lib_strings.dedent(input)
        assert.same(expected, result)
    end)
end)

describe("replace_range()", function()
    it("replaces a range in a single-line string", function()
        local input = "hello venus"
        local range = { 1, 1, 1, 5 }

        local expected = "welcome venus"
        local result = lib_strings.replace_range(input, "welcome", range)

        assert.same(expected, result)
    end)

    it("replaces a range in a multi-line string", function()
        local input = [[
local name = function()
    local x = 10
end
]]
        local range = { 1, 7, 1, 10 }

        local expected = [[
local {} = function()
    local x = 10
end
]]
        local result = lib_strings.replace_range(input, "{}", range)

        assert.same(expected, result)
    end)

    it("replaces a range in a multi-line string across different lines", function()
        local input = [[
local name = function()
    local x = 10
end]]
        local range = { 1, 14, 3, 3 }

        local expected = [[
local name = {}]]
        local result = lib_strings.replace_range(input, "{}", range)

        assert.are.same(expected, result)
    end)
end)

describe("convert_4d_range_to_2d_range", function()
    it("handles range within a single line", function()
        local input = "Hello World"
        local range = { 1, 1, 1, 5 }
        local got = lib_strings.convert_4d_range_to_2d_range(input, range)
        local start_pos, end_pos = unpack(got)

        local want = { 1, 5 }
        assert.same(want, got)

        local substring = string.sub(input, start_pos, end_pos)
        assert.equals("Hello", substring)
    end)

    it("handles range that spans across multiple lines", function()
        local input = [[
Hello World
Welcome Venus]]
        local range = { 1, 1, 2, 7 }
        local got = lib_strings.convert_4d_range_to_2d_range(input, range)
        local start_pos, end_pos = unpack(got)

        local want = { 1, 19 }
        assert.same(want, got)

        local substring = string.sub(input, start_pos, end_pos)
        assert.equals("Hello World\nWelcome", substring)
    end)
end)
