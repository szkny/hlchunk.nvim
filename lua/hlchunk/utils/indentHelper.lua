local fn = vim.fn

-- get the virtual indent of the given line
---@param rows_indent table<number, number>
---@param line number
---@return number
local function get_virt_indent(rows_indent, line)
    local cur = line + 1
    while rows_indent[cur] do
        if rows_indent[cur] == 0 then
            break
        elseif rows_indent[cur] > 0 then
            return rows_indent[cur]
        end
        cur = cur + 1
    end
    return -1
end

local indentHelper = {}

---@param blank string|number a string that contains only spaces
---@param leftcol number the shadowed cols number
---@param sw number shiftwidth
---@return number render_num, number offset, number shadowed_num return the render char number and the start index of the
-- first render char, the last is shadowed char number
function indentHelper.calc(blank, leftcol, sw)
    local blankLen = type(blank) == "string" and #blank or blank --[[@as number]]
    if blankLen - leftcol <= 0 or sw <= 0 then
        return 0, 0, 0
    end
    local render_char_num = math.ceil(blankLen / sw)
    local shadow_char_num = math.ceil(leftcol / sw)
    local offset = math.min(shadow_char_num * sw, blankLen) - leftcol
    return render_char_num - shadow_char_num, offset, shadow_char_num
end

---@enum ROWS_INDENT_RETCODE
indentHelper.ROWS_INDENT_RETCODE = {
    OK = 0,
    NO_TS = 1,
}

---@param bufnr number
---@param row number 0-index
function indentHelper.get_indent(bufnr, row)
    return vim.api.nvim_buf_call(bufnr, function()
        return fn.indent(row + 1)
    end)
end

local function get_rows_indent_by_context(range)
    local begRow = range.start + 1
    local endRow = range.finish + 1

    local rows_indent = {}

    for i = endRow, begRow, -1 do
        rows_indent[i] = indentHelper.get_indent(range.bufnr, i - 1)
        if rows_indent[i] == 0 and #fn.getline(i) == 0 then
            rows_indent[i] = get_virt_indent(rows_indent, i) or -1
        end
    end

    return indentHelper.ROWS_INDENT_RETCODE.OK, rows_indent
end

local function get_rows_indent_by_treesitter(range)
    local begRow = range.start + 1
    local endRow = range.finish + 1

    local rows_indent = {}
    local ts_indent_status, ts_indent = pcall(require, "nvim-treesitter.indent")
    if not ts_indent_status then
        return indentHelper.ROWS_INDENT_RETCODE.NO_TS, {}
    end

    for i = endRow, begRow, -1 do
        rows_indent[i] = vim.api.nvim_buf_call(range.bufnr, function()
            local indent = ts_indent.get_indent(i)
            if indent == -1 then
                indent = fn.indent(i)
                if indent == 0 and #fn.getline(i) == 0 then
                    indent = get_virt_indent(rows_indent, i) or -1
                end
            end
            ---@diagnostic disable-next-line: redundant-return-value
            return indent
        end)
    end

    return indentHelper.ROWS_INDENT_RETCODE.OK, rows_indent
end

-- when virt_indent is false, there are three cases:
-- 1. the row has nothing, we set the value to -1
-- 2. the row has char however not have indent, we set the indent to 0
-- 3. the row has indent, we set its indent
--------------------------------------------------------------------------------
-- when virt_indent is true, the only difference is:
-- when the len of line val is 0, we set its indent by its context, example
-- 1. hello world
-- 2.    this is shellRaining
-- 3.
-- 4.    this is shellRaining
-- 5.
-- 6. this is shellRaining
-- the virtual indent of line 3 is 4, and the virtual indent of line 5 is 0
---@param range Scope
---@param opts? {use_treesitter: boolean, virt_indent: boolean}
---@return ROWS_INDENT_RETCODE enum
---@return table<number, number>
function indentHelper.get_rows_indent(range, opts)
    opts = opts or { use_treesitter = false, virt_indent = false }

    if opts.use_treesitter then
        return get_rows_indent_by_treesitter(range)
    else
        return get_rows_indent_by_context(range)
    end
end

return indentHelper
