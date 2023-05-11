local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local actions_set = require('telescope.actions.set')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')


-- Dafault values
local defaults = {
  format_picker_entry = "%s (%s)",    -- HEADING (PAGE/FILENAME)
  first_upper = true,
  format_string = "[%s (%s)](%s#%s)", -- [HEADING (PAGE/FILENAME)](PATH_TO_FILE#ANCHOR),
  format_string_append = " ",         -- append space for better typography and continuous typing
  prompt_title = "Heading Finder",
  -- cwd not working_dir because telescope needs a "cwd" attribute
  working_dir = vim.fn.getcwd(),
}

local M = {}

M.setup = function(opts)
  -- merge defaults with user opts
  for k, v in pairs(opts) do defaults[k] = v end
end


local function parseRipgrepOutput(output)
  local headings = {}
  for _, res in pairs(output) do
    local t = {}
    local i = 0
    -- ripgrep information is separated by :, eg. PATH:LINE_NUMBER:MATCH
    for p in res:gmatch("([^:]+)") do
      if i == 0 then
        -- path of the file including the heading
        t.path = p
        -- first remove path, then extension to get name of page
        local page_name = p:gsub(".*/", "")
        t.page_name = page_name:gsub("%..*", "")
      elseif i == 1 then
        -- line number of the heading
        t.lnum = tonumber(p)
      else
        -- The heading starting with #+
        t.heading = p
      end
      i = i + 1
    end
    table.insert(headings, t)
  end
  return headings
end


M.link_heading = function(opts)
  -- link_heading can receive all default values but also a subset.
  local lh_opts = {}
  if opts then
    -- To work properly in the subset case, the missing default values have to be added..
    for k, v in pairs(defaults) do
      lh_opts[k] = v
    end
    -- ..i. e. overwritten by opts
    for k, v in pairs(opts) do lh_opts[k] = v end
  else
    -- link_heading was called without any argument, i. e. opts = nil
    lh_opts = defaults
  end


  -- Bare h1-headings can't be matched without side effects since # is used for comments in various languages like python and bash.
  -- Workaround: Transform # h1-heading to # h1-heading # (last # not displayed in rendered markdown output)
  local cmd = { "rg", "-n", "--no-heading", "-g", "**.md", "-e", "^##", "-e", "^# .*#$", "/home/philipp/wiki/" }
  local output = vim.fn.systemlist(cmd)
  local headings = parseRipgrepOutput(output)

  pickers
      .new(lh_opts, {
        prompt_title = lh_opts.prompt_title,
        results_title = 'Headings',
        finder = finders.new_table({
          results = headings,
          entry_maker = function(entry)
            return {
              -- TODO Exact meaning unclear, used to pass values around
              value = entry,
              -- what is displayed in the picker: HEADING (PAGE)
              display = string.format(defaults.format_picker_entry, entry.heading, entry.page_name),
              -- key for sorting, it's handy to include the page name
              -- and it's better keep logic in sync with display
              -- TODO: Maybe it makes more sence to swap heading and page_name (in display and ordinal) <12-04-2023>
              ordinal = entry.heading .. " " .. entry.page_name,
              filename = entry.path,
              -- Isolate line number of each match (contained in ripgrep output)
              -- grep_previewer can center the preview to this line number
              lnum = entry.lnum,
            }
          end,
        }),
        previewer = conf.grep_previewer(lh_opts),
        sorter = conf.file_sorter(lh_opts),
        attach_mappings = function(prompt_bufnr)
          actions_set.select:replace(function()
            actions.close(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            -- TODO Make this step obsolete by specifying riggrep argument correctly
            -- transform to relative path
            local wiki_path = entry.filename:gsub("/home/philipp/wiki", "")
            local page_name = entry.value.page_name
            -- remove all preceding #, i. e. match pure heading name
            -- local anchor = entry.value.heading:match("%a.*")
            local anchor = entry.value.heading:gsub("^#+ ", "")
            -- heading without all #
            local raw_heading = anchor
            -- anchor = anchor:gsub("& ", "")
            anchor = anchor:gsub("%s", "-")

            -- Insert formatted link to heading
            vim.api.nvim_put({
              string.format(defaults.format_string, raw_heading, page_name, wiki_path, anchor)
            }, "", false, true)
          end)
          return true
        end,
      })
      :find()
end

return M
