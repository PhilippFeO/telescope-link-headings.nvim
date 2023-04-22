# telescope-link-headings.nvim #
Add links to headings to your files, f. i. headings to other pages in your wiki or sections in the `README.md`.

## Usage
By using the function `link_heading` via
```vim
:Telescope link_headings link_heading
```
a telescope file picker opens an lets you choose the heading you want to link. After hitting `<CR>` a string according to `format_string` (default is `"[%s # %s](%s#%s)"` for `md` files) is added to your document, for example: [telescope-link-headings.nvim # Setup](./README.md#setup).

There might be scenarios, where you have to prepend `./` or `/` to the path string, i. e. using `"[%s # %s](./%s#%s)"` instead of `"[%s # %s](%s#%s)"`.

## Installation
### Lazy.nvim
```lua
'PhilippFeO/telescope-link-headings.nvim'
```
### packer
```lua
use { 'PhilippFeO/telescope-link-headings.nvim' }
```

## Setup
```lua
require('telescope').load_extension('link_headings')
local link_headings = require('telescope').extensions['link_headings']
link_headings.setup({
    -- s. section 'Options'
})
```
It probably makes sense to create a keybinding, for instance
```lua
vim.keymap.set('n', '<Leader>lk', link_headings.link_heading, { desc = 'Link heading' })
```

### Options
The following options (with their defaults) are currently availabe:
```lua
-- The working directory to search for files.
-- Set to your wiki directory to create links (further examples below)
working_dir = vim.fn.getcwd(),
-- First letter in display name upper or lower case, i.e. `[Plugins](…)`
-- or `[plugins](…)`
first_upper = true,
-- Format string for inserting file links. Default is Markdown syntax.
-- When you are using some wiki syntax, change it to its syntax.
-- Lua regex is used. Formatting only works when there are exactly two
-- `%s`. Currently, no checks for a proper Lua regex are performed, so
-- keep an eye on having exactly four `%s` and nothing else/more.
format_string = '[%s # %s](%s#%s)', -- [PAGE # HEADING](PATH_TO_PAGE#ANCHOR)
-- Append space to format_string for better typography and continuous typing
format_string_append = " ",
-- Title for the telescope prompt
prompt_title = 'Heading Finder',
-- Some link schemes like Wiki, Orgmode or AsciiDoc expect the URL first
-- and the displayed text second. Markdown's order is vice versa. By
-- setting to true URL first schemes are enabled.
url_first = false
```

#### Options for `link_heading` (the function)
The function `link_heading` takes a table as input where you can overwrite the default values. This might be useful when you want to use the plugin in additional contexts, for instance for writing `README.md` files, s. [Usecase besides wiki contexts](#usecase-besides-wiki-contexts).

# Examples
## Configuration
```lua
link_heading.setup({
    working_dir = '~/Documents/wiki'
    prompt_title = 'Wiki Heading Finder' 
})
```

## Usecase besides wiki contexts
You can use the picker to create links in any other directory. For this purpose leave the `working_dir` unchanged. An example usecase where this might be useful is the following: You have set up `telescope-link-headings.nvim` for your wiki with the keymap shown above. Because you are a highly productive open source developer, you write regularly to `md` files like a `README.md`. With the following keymap
```lua
vim.keymap.set('n', '<Leader>lh', function()
  filelinks.make_filelink({
    working_dir = vim.fn.getcwd(),
    format_string = '[%s # %s](%s#%s)',
  })
end, { desc = '[l]ink [h]eading in current dir' })
```
you can easily add file links to the `README.md` although you might have defined another format string for your wiki in the `setup` function.
