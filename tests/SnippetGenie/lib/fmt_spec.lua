-- Copied from https://github.com/L3MON4D3/LuaSnip/blob/master/tests/unit/fmt_spec.lua with minor modifications

-- Original Tests --
local fmt = require("SnippetGenie.lib.fmt")

local works = function(msg, str, args, expected, opts)
    it(msg, function()
        local result = fmt(str, args, opts)
        assert.are.same(expected, result)
    end)
end

local fails = function(msg, str, args, opts)
    it(msg, function()
        assert.has_error(function()
            fmt(str, args, opts)
        end)
    end)
end

describe("fmt.interpolate", function()
    after_each(function()
        vim.api.nvim_buf_delete(0, { force = true })
    end)

    works("expands with no numbers", "a{}b{}c{}d", { 4, 5, 6 }, "a4b5c6d")

    works("expands with explicit numbers", "a{2}b{1}c{3}d", { 4, 5, 6 }, "a5b4c6d")

    works("expands with mixed numbering", "a{}b{3}c{}d{2}e", { 1, 2, 3, 4 }, "a1b3c4d2e")

    works("expands named placeholders", "a{A}b{B}c{C}d", { A = 1, B = 2, C = 3 }, "a1b2c3d")

    works(
        "expands all mixed",
        "a {A} b {} c {3} d {} e {B} f {A} g {2} h",
        { 1, 2, 3, 4, A = 10, B = 20 },
        "a 10 b 1 c 3 d 4 e 20 f 10 g 2 h"
    )

    works("current index changed by numbered nodes", "{} {} {1} {} {}", { 1, 2, 3 }, "1 2 1 2 3")

    works("excludes trailing text", "{}abcd{}", { 1, 2 }, "1abcd2")

    works("escapes empty double-braces", "a{{}}b{}c{{}}d{}e", { 2, 4 }, "a{}b2c{}d4e")

    works("escapes non-empty double-braces", "a{{d}}b{}c", { 2 }, "a{d}b2c")

    works(
        "do not trim placeholders with whitespace",
        "a{ something}b{}c",
        { 2, [" something"] = 1 },
        "a1b2c"
    )

    works("replaces nested escaped braces", "a{{{{}}}}b{}c{{ {{ }}}}d", { 2 }, "a{{}}b2c{ { }}d")

    works("replaces umatched escaped braces", "a{{{{b{}c", { 2 }, "a{{b2c")

    works(
        "replaces in braces inside escaped braces",
        "a{{{}}}b{{ {}}}c{{{} }}d{{ {} }}e",
        { 1, 2, 3, 4 },
        "a{1}b{ 2}c{3 }d{ 4 }e"
    )

    fails("fails for unbalanced braces", "a{b", {})

    fails("fails for nested braces", "a{ { } }b", {})

    works(
        "can use different delimiters",
        "foo() { return <>; };",
        { 10 },
        "foo() { return 10; };",
        { delimiters = "<>" }
    )

    local delimiters = { "()", "[]", "<>", "%$", "#@", "?!" }
    for _, delims in ipairs(delimiters) do
        local left, right = delims:sub(1, 1), delims:sub(2, 2)
        describe("can use custom delimiters", function()
            works(
                delims,
                string.format("{ return %s%s; };", left, right),
                { 10 },
                "{ return 10; };",
                { delimiters = delims }
            )
        end)
    end

    works(
        "can escape custom delimiters",
        "foo((x)) { return x + (); };",
        { 10 },
        "foo(x) { return x + 10; };",
        { delimiters = "()" }
    )

    works(
        "can use named placeholders with custom delimiters",
        "foo(x) { return x + [y]; };",
        { y = 10 },
        "foo(x) { return x + 10; };",
        { delimiters = "[]" }
    )

    fails("dissallows unused list args", "a {} b {} c", "{ 1, 2, 3 }")

    fails("dissallows unused map args", "a {A} b {B} c {} d", { 1, A = 10, B = 20, C = 30 })

    works(
        "allows unused with strict=false",
        "a {A} b {B} c {} d",
        { 1, 2, A = 10, B = 20, C = 30 },
        "a 10 b 20 c 1 d",
        { strict = false }
    )
end)

-- More verbose examples --

describe("fmt demonstration", function()
    it("works with 1 slot", function()
        local placeholder = "Hello {}"
        local slots = { "Venus" }

        local want = "Hello Venus"
        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)

    it("works with 2 slots", function()
        local placeholder = "Hello {}, {}"
        local slots = { "Venus", "how are you?" }

        local want = "Hello Venus, how are you?"
        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)

    it("works with multi-line string", function()
        local placeholder = [[
Hello {}!
{}
        ]]
        local slots = { "Venus", "How are you?" }

        local want = [[
Hello Venus!
How are you?
        ]]
        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)

    it("works with multi-line string, with indentation", function()
        local placeholder = [[
Hello {}!
    {}
        ]]
        local slots = { "Venus", "How are you?" }

        local want = [[
Hello Venus!
    How are you?
        ]]
        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)

    it("works with named placeholders", function()
        local placeholder = [[
Hello {name}!
    {msg}
        ]]
        local slots = { msg = "How are you?", name = "Venus" }

        local want = [[
Hello Venus!
    How are you?
        ]]
        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)

    it("works with multi lines body", function()
        local placeholder = [[
Hello {name}!
    {msg}
        ]]
        local slots = { msg = "How are you?\nWhere are you from?", name = "Venus" }

        local want = [[
Hello Venus!
    How are you?
    Where are you from?
        ]]

        local got = fmt(placeholder, slots)

        assert.are.same(want, got)
    end)
end)
