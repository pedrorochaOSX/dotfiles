#!/usr/bin/env sh

echo "Configuring Neovim with LazyVim..."

mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

cat << 'EOF' > ~/.config/nvim/init.lua
-- Bootstrap lazy.nvim
require("config.lazy")
EOF

cat << 'EOF' > ~/.config/nvim/lua/config/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },

    { "ellisonleao/gruvbox.nvim" },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "retrobox",
      },
    },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "retrobox" } },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF

cat << 'EOF' > ~/.config/nvim/lua/config/options.lua
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "unnamedplus"
vim.o.autoread = true
vim.opt.spell = false
EOF

cat << 'EOF' > ~/.config/nvim/lua/config/autocmds.lua
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable LazyVim's default spell checking autocmd
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
EOF

cat <<'EOF' > ~/.config/nvim/lua/config/keymaps.lua
-- Normal mode: move current line up or down
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })

-- Visual mode: move selected block up or down
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

-- Next buffer
vim.keymap.set("n", "<C-]>", ":bnext<CR>", { silent = true, desc = "Next buffer" })

-- Previous buffer
vim.keymap.set("n", "<C-[>", ":bprevious<CR>", { silent = true, desc = "Previous buffer" })

-- Custom buffer write keymaps
vim.keymap.set("n", "<Leader>bw", ":w<CR>", { silent = true, desc = "Write current buffer" })
vim.keymap.set("n", "<Leader>bW", ":wa<CR>", { silent = true, desc = "Write all buffers" })

vim.keymap.set("n", "<leader>r", function()
    local reloaded = 0

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("edit!")
            end)
            reloaded = reloaded + 1
        end
    end

    vim.notify(("Force-reloaded %d buffers from disk (discarded unsaved edits)"):format(reloaded), vim.log.levels.WARN)
end, { desc = "Force reload all buffers from disk (discard edits)" })

-- Reorder buffers
vim.keymap.set("n", "<S-A-h>", ":BufferLineMovePrev<CR>", { silent = true, desc = "Move buffer left" })
vim.keymap.set("n", "<S-A-l>", ":BufferLineMoveNext<CR>", { silent = true, desc = "Move buffer right" })
EOF

cat << 'EOF' > ~/.config/nvim/lua/plugins/neo-tree.lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      window = { position = "right" },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    buffers = {
      window = { position = "right" },
    },
    git_status = {
      window = { position = "right" },
    },
  },
}
EOF

cat << 'EOF' > ~/.config/nvim/lua/plugins/no-autoformat.lua
return {
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = false,
      format_after_save = false,
    },
  },
}
EOF

cat <<'EOF' > ~/.config/nvim/lua/plugins/no-autoformat-sh.lua
return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters = opts.formatters or {}
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters["shfmt"] = nil
            opts.formatters_by_ft.sh = {}
            opts.format_on_save = opts.format_on_save or {}
            opts.format_on_save.sh = false
        end,
    },
}
EOF

cat << 'EOF' > ~/.config/nvim/lua/plugins/no-animations.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      animate = { enabled = false },
      scroll = { enabled = false },
    },
  },
}
EOF

echo "Neovim configuration complete!"
echo "LazyVim will install plugins on first launch."
