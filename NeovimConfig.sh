mkdir -p ~/.config/nvim;
cat << 'catEND' > ~/.config/nvim/init.lua
-- Move current line in Normal mode
vim.api.nvim_set_keymap("n", "<A-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-Up>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-Down>", ":m .+1<CR>==", { noremap = true, silent = true })

-- Move selected lines in Visual mode
vim.api.nvim_set_keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

-- Next buffer
vim.api.nvim_set_keymap('n', '<A-n>', ':bnext<CR>', { noremap = true, silent = true })

-- Previous buffer
vim.api.nvim_set_keymap('n', '<A-p>', ':bprevious<CR>', { noremap = true, silent = true })

-- Open a new file
vim.api.nvim_set_keymap('n', '<C-n>', ':e<Space>', { noremap = true, silent = true })
catEND

nvim +':luafile ~/.config/nvim/init.lua' +':q'
