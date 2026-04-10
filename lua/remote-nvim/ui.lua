local event = require("nui.utils.autocmd").event
local M = {}

---Generate a floating window, given the window options, running the provided command
---@param cmd string Command to run in the floating window
---@param exit_cb fun(exit_code: integer) Callback called when launched program exits
---@param popup_options nui_popup_options? Configuration options for floating window
function M.float_term(cmd, exit_cb, popup_options)
  popup_options = vim.tbl_deep_extend("force", {
    enter = true,
    focusable = true,
    relative = "editor",
    border = {
      style = vim.fn.has("gui_running") == 0 and "rounded" or "none",
    },
    position = "50%",
    size = {
      width = "100%",
      height = "100%",
    },
    zindex = 100,
  }, popup_options or {})

  local popup = require("nui.popup")(popup_options)




  -- Update layout if the overall Neovim gets resized
  popup:on(event.VimResized, function()
    popup:update_layout()
  end)

  popup:mount()

  local bufnr = vim.api.nvim_get_current_buf()

  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      -- We close the pop-up if we exit successfully
      -- to avoid "Process exited with status code 0" message
      if exit_code == 0 then
        popup:unmount()
      end
      if exit_cb then
        exit_cb(exit_code)
      end
    end,
  })

  -- Mark this buffer so user keymaps can identify and exclude it
  vim.api.nvim_buf_set_var(bufnr, "remote_nvim_term", true)

  -- Override <Esc> in this terminal buffer so it reaches the remote Neovim
  -- instead of exiting the local terminal mode
  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = bufnr, nowait = true })

  vim.cmd.startinsert()
end

return M
