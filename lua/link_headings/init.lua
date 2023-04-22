local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local actions_set = require('telescope.actions.set')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')


-- Dafault values
local defaults = {
  first_upper = true,
  format_string = "[%s](%s)",
  format_string_append = " ", -- append space for better typography and continuous typing
  prompt_title = "File Finder",
  remove_extension = true,
  -- cwd not working_dir because telescope needs a cwd attribute
  working_dir = vim.fn.getcwd(),
}

local M = {}

M.setup = function(opts)
  -- defaults.working_dir = opts.working_dir or defaults.working_dir
  -- -- defaults.find_command = opts.find_command or defaults.find_command
  -- defaults.format_picker_entry = opts.format_picker_entry or defaults.format_picker_entry
  -- defaults.first_upper = opts.first_upper or defaults.first_upper
  -- defaults.format_string = opts.format_string or defaults.format_string
  -- defaults.format_string_append = opts.format_string_append or defaults.format_string_append
  -- defaults.prompt_title = opts.prompt_title or defaults.prompt_title
  -- defaults.remove_extension = opts.remove_extension or defaults.remove_extension
  for k, v in pairs(opts) do
    defaults[k] = v
  end
end

M.link_heading = function(opts)
  -- make_filelink can receive all default values but also a subset.
  local fopts = {} -- fopts = function opts
  if opts then
    -- To work properly in the subset case, the missing default values have to be added..
    for k, v in pairs(defaults) do
      fopts[k] = v
    end
    -- ..i. e. overwritten by opts
    for k, v in pairs(opts) do fopts[k] = v end
  else
    -- make_filelink was called without any argument, i. e. opts = nil
    fopts = defaults
  end

  local function parseRipgrepOutput(output)
    local headings = {}
    for _, res in pairs(output) do
      local t = {}
      local i = 0
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

  -- TODO: Currently no h1-headings are matched since the start with exactly one #. Including this pattern would result in clutter because python and sh code use this symbol as start for a comment. <12-04-2023>
  --  But since h1-heaings are used exactly once in a page right at the beginning, it doesn't make sence to link to it because it is eqaul to the file name and there is already a picker for it.
  -- Valid solution: Transform # h1-heading to # h1-heading #
  local cmd = { "rg", "-n", "--no-heading", "-g", "**.md", "-e", "^##", "-e", "^# .*#$", "/home/philipp/wiki/" }
  local output = vim.fn.systemlist(cmd)
  local headings = parseRipgrepOutput(output)

  -- n +WikiIndex '+Telescope link_headings link_heading'
  pickers
      .new(fopts, {
        prompt_title = 'Select a heading',
        results_title = 'Headings',
        finder = finders.new_table({
          results = headings,
          entry_maker = function(entry)
            return {
              -- TODO Exact meaning unclear, used to pass values around
              value = entry,
              -- what is displayed in the picker: HEADING (PAGE)
              display = entry.heading .. " (" .. entry.page_name .. ")",
              -- key for sorting, it's handy to include the page name
              -- better keep logical in sync with display
              -- TODO: Maybe it makes more sence to swap heading and page_name (in display and ordinal) <12-04-2023>
              ordinal = entry.heading .. entry.page_name,
              filename = entry.path,
              -- Isolate line number of each match (contained in ripgrep output)
              -- grep_previewer can center the preview to this line number
              lnum = entry.lnum,
            }
          end,
        }),
        previewer = conf.grep_previewer(fopts),
        sorter = conf.file_sorter(fopts),
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

            -- [PAGE # HEADING](PATH_TO_PAGE#ANCHOR)
            local format_string = "[%s # %s](%s#%s) "
            vim.api.nvim_put({
              string.format(format_string, page_name, raw_heading, wiki_path, anchor)
            }, "", false, true)
          end)
          return true
        end,
      })
      :find()
end

return M
