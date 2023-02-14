## SnippetGenie: Snippet generation tool for Neovim

Work in Progress

## Installation

```lua
return {
    "ziontee113/SnippetGenie",
    config = function()
        require("SnippetGenie").setup({
            regex = [[-\+ Snippets goes here]],
            snippets_directory = "/home/username/.config/nvim/snippets/",
            file_name = "generated",
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
