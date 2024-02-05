-- The `run_cmd_with_count` function enables a user to execute a command with
-- count values in keymaps. This is particularly useful for `yarepl.nvim`,
-- which heavily uses count values as the identifier for REPL IDs.
local function run_cmd_with_count(cmd)
    return function()
        vim.cmd(string.format('%d%s', vim.v.count, cmd))
    end
end

-- The `partial_cmd_with_count_expr` function enables users to enter partially
-- complete commands with a count value, and specify where the cursor should be
-- placed. This function is mainly designed to bind `REPLExec` command into a
-- keymap.
local function partial_cmd_with_count_expr(cmd)
    return function()
        -- <C-U> is equivalent to \21, we want to clear the range before next input
        -- to ensure the count is recognized correctly.
        return ':\21' .. vim.v.count .. cmd
    end
end

local keymap = vim.api.nvim_set_keymap
local bufmap = vim.api.nvim_buf_set_keymap
local autocmd = vim.api.nvim_create_autocmd

-- <Leader>ps will be equivalent to `REPLStart aichat`
-- 2<Leader>ps will be equivalent to `2REPLStart aichat`, etc.
keymap('n', '<Leader>ps', '', {
    callback = run_cmd_with_count 'REPLStart aichat',
    desc = 'Start an Aichat REPL',
})
-- <Leader>pf will be equivalent to `REPLFocus aichat`
-- 2<Leader>pf will be equivalent to `2REPLFocus aichat`, etc.
keymap('n', '<Leader>pf', '', {
    callback = run_cmd_with_count 'REPLFocus aichat',
    desc = 'Focus on Aichat REPL',
})
keymap('n', '<Leader>ph', '', {
    callback = run_cmd_with_count 'REPLHide aichat',
    desc = 'Hide Aichat REPL',
})
keymap('v', '<Leader>pr', '', {
    callback = run_cmd_with_count 'REPLSendVisual aichat',
    desc = 'Send visual region to Aichat',
})
keymap('n', '<Leader>prr', '', {
    callback = run_cmd_with_count 'REPLSendLine aichat',
    desc = 'Send current line to Aichat',
})
-- `<Leader>prap` will send a paragraph to the first aichat REPL.
-- `2<Leader>prap` will send a paragraph to the second aichat REPL. Note that
-- `ap` is just an example and can be replaced with any text object or motion.
keymap('n', '<Leader>pr', '', {
    callback = run_cmd_with_count 'REPLSendOperator aichat',
    desc = 'Operator to Send text to Aichat',
})
keymap('n', '<Leader>pq', '', {
    callback = run_cmd_with_count 'REPLClose aichat',
    desc = 'Quit Aichat',
})
keymap('n', '<Leader>pc', '<CMD>REPLCleanup<CR>', {
    desc = 'Clear aichat REPLs.',
})

-- `<Leader>pe How to current win id in neovim?`: This keymap executes a
-- command in `aichat` with the specified count value.
keymap('n', '<Leader>pe', '', {
    callback = partial_cmd_with_count_expr 'REPLExec $aichat ',
    desc = 'Execute command in aichat',
    expr = true,
})

local ft_to_repl = {
    r = 'radian',
    rmd = 'radian',
    quarto = 'radian',
    markdown = 'radian',
    ['markdown.pandoc'] = 'radian',
    python = 'ipython',
    sh = 'bash',
    REPL = '',
}

autocmd('FileType', {
    pattern = { 'quarto', 'markdown', 'markdown.pandoc', 'rmd', 'python', 'sh', 'REPL' },
    desc = 'set up REPL keymap',
    callback = function()
        local repl = ft_to_repl[vim.bo.filetype]
        bufmap(0, 'n', '<LocalLeader>rs', '', {
            callback = run_cmd_with_count('REPLStart ' .. repl),
            desc = 'Start an REPL',
        })
        bufmap(0, 'n', '<LocalLeader>rf', '', {
            callback = run_cmd_with_count 'REPLFocus',
            desc = 'Focus on REPL',
        })
        bufmap(0, 'n', '<LocalLeader>rv', '<CMD>Telescope REPLShow<CR>', {
            desc = 'View REPLs in telescope',
        })
        bufmap(0, 'n', '<LocalLeader>rh', '', {
            callback = run_cmd_with_count 'REPLHide',
            desc = 'Hide REPL',
        })
        bufmap(0, 'v', '<LocalLeader>s', '', {
            callback = run_cmd_with_count 'REPLSendVisual',
            desc = 'Send visual region to REPL',
        })
        bufmap(0, 'n', '<LocalLeader>ss', '', {
            callback = run_cmd_with_count 'REPLSendLine',
            desc = 'Send current line to REPL',
        })
        -- `<LocalLeader>sap` will send the current paragraph to the
        -- buffer-attached REPL, or REPL 1 if there is no REPL attached.
        -- `2<Leader>sap` will send the paragraph to REPL 2. Note that `ap` is
        -- just an example and can be replaced with any text object or motion.
        bufmap(0, 'n', '<LocalLeader>s', '', {
            callback = run_cmd_with_count 'REPLSendOperator',
            desc = 'Operator to send to REPL',
        })
        bufmap(0, 'n', '<LocalLeader>rq', '', {
            callback = run_cmd_with_count 'REPLClose',
            desc = 'Quit REPL',
        })
        bufmap(0, 'n', '<LocalLeader>rc', '<CMD>REPLCleanup<CR>', {
            desc = 'Clear REPLs.',
        })
        bufmap(0, 'n', '<LocalLeader>rS', '<CMD>REPLSwap<CR>', {
            desc = 'Swap REPLs.',
        })
        bufmap(0, 'n', '<LocalLeader>r?', '', {
            callback = run_cmd_with_count 'REPLStart',
            desc = 'Start an REPL from available REPL metas',
        })
        bufmap(0, 'n', '<LocalLeader>ra', '<CMD>REPLAttachBufferToREPL<CR>', {
            desc = 'Attach current buffer to a REPL',
        })
        bufmap(0, 'n', '<LocalLeader>rd', '<CMD>REPLDetachBufferToREPL<CR>', {
            desc = 'Detach current buffer to any REPL',
        })
        -- `3<LocalLeader>re df.describe()`: This keymap executes the specified
        -- command in REPL 3.
        bufmap(0, 'n', '<LocalLeader>re', '', {
            callback = partial_cmd_with_count_expr 'REPLExec ',
            desc = 'Execute command in REPL',
            expr = true,
        })
    end,
})
