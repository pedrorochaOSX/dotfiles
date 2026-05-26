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
        { import = "lazyvim.plugins.extras.editor.snacks_picker" },

        { "ellisonleao/gruvbox.nvim" },
        {
            "LazyVim/LazyVim",
            opts = {
                colorscheme = "catppuccin",
            },
        },
    },
    defaults = {
        lazy = false,
        version = false,
    },
    install = { colorscheme = { "catppuccin" } },
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
vim.opt.clipboard = "unnamedplus"
vim.o.autoread = true
vim.opt.spell = false

vim.g.lazyvim_picker = "snacks"
EOF

cat << 'EOF' > ~/.config/nvim/lua/config/autocmds.lua
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
EOF

cat <<'EOF' > ~/.config/nvim/lua/config/keymaps.lua
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

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

vim.keymap.set("n", "<S-A-h>", ":BufferLineMovePrev<CR>", { silent = true, desc = "Move buffer left" })
vim.keymap.set("n", "<S-A-l>", ":BufferLineMoveNext<CR>", { silent = true, desc = "Move buffer right" })

vim.keymap.set("n", "<leader>cp", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied: "' .. path .. '" to clipboard', vim.log.levels.INFO)
end, { desc = "Copy full path to clipboard" })

vim.keymap.set("n", "<leader>bu", function()
    local current_buf = vim.api.nvim_get_current_buf()
    local bufs = vim.tbl_filter(function(buf)
        return buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= ""
    end, vim.api.nvim_list_bufs())
    local buf_names = vim.tbl_map(function(buf)
        return { buf = buf, name = vim.api.nvim_buf_get_name(buf) }
    end, bufs)
    if #buf_names == 0 then
        vim.notify("No other buffers to diff with", vim.log.levels.WARN)
        return
    end
    vim.ui.select(buf_names, {
        prompt = "Select buffer to diff with:",
        format_item = function(item)
            return item.name
        end,
    }, function(choice)
        if choice then
            vim.cmd("split " .. vim.fn.fnameescape(choice.name))
            vim.cmd("diffthis")
            vim.cmd("wincmd p")
            vim.cmd("diffthis")
            vim.cmd("setlocal diffopt+=context:0")
        end
    end)
end, { desc = "Inline diff with another buffer" })

vim.keymap.set("n", "<leader>bU", function()
    local current_buf = vim.api.nvim_get_current_buf()
    local bufs = vim.tbl_filter(function(buf)
        return buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= ""
    end, vim.api.nvim_list_bufs())
    local buf_names = vim.tbl_map(function(buf)
        return { buf = buf, name = vim.api.nvim_buf_get_name(buf) }
    end, bufs)
    if #buf_names == 0 then
        vim.notify("No other buffers to diff with", vim.log.levels.WARN)
        return
    end
    vim.ui.select(buf_names, {
        prompt = "Select buffer to diff with:",
        format_item = function(item)
            return item.name
        end,
    }, function(choice)
        if choice then
            vim.cmd("vert diffsplit " .. vim.fn.fnameescape(choice.name))
        end
    end)
end, { desc = "Side by side diff with another buffer" })
EOF

cat << 'EOF' > ~/.config/nvim/lua/plugins/full-path-line.lua
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

cat <<'EOF' > ~/.config/nvim/lua/plugins/snacks-find-files.lua
return {
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                sources = {
                    files = {
                        hidden = true,
                        ignored = true,
                    },
                },
            },
        },
    },
}
EOF

cat <<'EOF' > ~/.config/nvim/lua/plugins/xml-formatter.lua
return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters = opts.formatters or {}
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters.xmllint = {
                command = "xmllint",
                args = { "--format", "-" },
            }
            opts.formatters_by_ft.xml = { "xmllint" }
        end,
        keys = {
            {
                "<leader>cx",
                function()
                    require("conform").format({ formatters = { "xmllint" }, timeout_ms = 2000 })
                end,
                desc = "Format XML (xmllint)",
            },
        },
    },
}
EOF

echo "Neovim configuration complete!"
echo "LazyVim will install plugins on first launch."
