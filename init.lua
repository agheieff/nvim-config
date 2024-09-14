vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.tabstop = 8
vim.opt.shiftwidth = 8
vim.opt.expandtab = false
vim.opt.spell = true
vim.opt.timeoutlen = 300
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.cmd([[
augroup fourSpacesIndent
    autocmd!
    autocmd FileType html,xml,ui setlocal shiftwidth=4 tabstop=4 expandtab=false
augroup END
]])

vim.opt.cursorline = true
vim.opt.scrolloff = 3

vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
