## SnippetGenie: Snippet generation tool for Neovim

Work in Progress

## Installation

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
