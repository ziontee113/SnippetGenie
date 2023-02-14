## SnippetGenie: Snippet generation tool for Neovim

Work in Progress

## Installation

`Lazy.nvim` example:

```lua
return {
    "ziontee113/SnippetGenie",
    config = function()
        require("SnippetGenie").setup({
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
    end,
}
```
