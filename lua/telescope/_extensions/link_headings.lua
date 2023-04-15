return require("telescope").register_extension {
  exports = {
    link_heading = require("link_headings").link_heading,
    setup = require("link_headings").setup,
  },
}
