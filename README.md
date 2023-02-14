## SnippetGenie: Snippet creation tool for Neovim

A Neovim plugin that aims to simplify the process of creating LuaSnip Snippets.
<!-- Say goodbye to manually creating snippets and hello to increased productivity. -->
<!-- Get started with the easy-to-use plugin today. -->

## Installation:

`Lazy.nvim` example:

```lua
return {
    "ziontee113/SnippetGenie",
    config = function()
        local genie = require("SnippetGenie")

        genie.setup({
            -- SnippetGenie will use this regex to find the pattern in your snippet file,
            -- and insert the newly generated snippet there.
            regex = [[-\+ Snippets goes here]],
            -- A line that matches this regex looks like:
            ------------------------------------------------ Snippets goes here

            -- this must be configured
            snippets_directory = "/path/to/my/LuaSnip/snippet/folder/",

            -- let's say you're creating a snippet for Lua,
            -- SnippetGenie will look for the file at `/path/to/my/LuaSnip/snippet/folder/lua/generated.lua`
            -- and add the new snippet there.
            file_name = "generated",

            -- SnippetGenie was designed to generate LuaSnip's `fmt()` snippets.
            -- here you can configure the generated snippet's "skeleton" / "template" according to your use case
            snippet_skeleton = [[
s(
    "{trigger}",
    fmt([=[
{body}
]=], {{
        {nodes}
    }})
),
]],
        })

        -- SnippetGenie doesn't map any keys by default.
        -- Here're the suggested mappings:
        vim.keymap.set("x", "<CR>", function()
            genie.create_new_snippet_or_add_placeholder()
            vim.cmd("norm! ") -- exit Visual Mode, go back to Normal Mode
        end, {})

        vim.keymap.set("n", "<CR>", function()
            genie.finalize_snippet()
        end, {})
    end,
}
```

## Example Usage:

Let's say you want to create a snippet for Lua. We have this example Lua buffer:

```lua
local module = require("module")

local function my_func()
    local x = 10
    local y = 100
end
```

1. Make sure that `/path/to/my/LuaSnip/snippet/folder/lua/generated.lua` file exists with required boilerplate already in place.

For example:

```lua
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node

local snippets = {
  s(
  "my_snippet",
    fmt([=[
Hello {}
]=], { i(1, "World") })
  ),

  ------------------------------------------------------ Snippets goes here
}

local autosnippets = {}

return snippets, autosnippets
```
2. We select the content of the snippet we want to create. In this example, we `jj` to line 3, use `V` then `G` to
select the entire function. Then we press `<CR>` (as we mapped for SnippetGenie) to initiate the snippet creation process,
and send us back to Normal Mode.

3. We navigate to line 3 `my_func`, select it with Visual Mode, and press `<CR>` to add a `placeholder`.
Then we go to line 4, select `10`, press `<CR>` to add the 2nd placeholder.
Then we go to line 5, select `100`, press `<CR>` to add the 3rd placeholder.

4. After we selected our initial snippet content and our placeholders, in Normal Mode, we press `<CR>` to finalize the
snippet creation process. You will be prompted to enter the trigger for the snippet, let's enter `testing`.
After entering the trigger, press `<CR>`, the snippet will be added to the proper snippet file and will be instantly loaded.

5. Enter the trigger for the snippet you just created to test it out.

The file `/path/to/my/LuaSnip/snippet/folder/lua/generated.lua` should now look something like:

```lua
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node

local snippets = {
    s(
        "my_snippet",
        fmt([=[
            Hello {}
        ]=], { i(1, "World") })
    ),

    s(
        "testing",
        fmt([=[
local function {}()
    local x = {}
    local y = {}
end
        ]=], {
            i(1, "my_func"),
            i(2, "10"),
            i(3, "100"),
        })
    ),

  ------------------------------------------------------ Snippets goes here
}

local autosnippets = {}

return snippets, autosnippets
```

## Get involved in the development process 

Feedback is always appreciated. If you encounter any issues or have suggestions for improving the plugin,
please feel free to open an issue or pull request. One of the key goals is to make the plugin as user-friendly as possible.
