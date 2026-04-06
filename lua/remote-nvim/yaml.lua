local M = {}

---Parse a minimal YAML file (only supports top-level keys and string lists)
---@param file_path string Path to the yaml file
---@return table|nil result Parsed YAML table containing APT, CONDA, PIP keys, or nil if error
function M.parse_minimal_yaml(file_path)
  local file, err = io.open(file_path, "r")
  if not file then
    require("remote-nvim.utils").get_logger().error("Could not read YAML file: " .. tostring(err))
    return nil
  end

  local result = {
    APT = {},
    CONDA = {},
    PIP = {}
  }
  
  local current_section = nil
  for line in file:lines() do
    -- Remove trailing comments and whitespace
    line = line:gsub("#.*$", "")
    -- Trim whitespace
    local trimmed = line:match("^%s*(.-)%s*$")
    
    if trimmed ~= "" then
      -- Match section headers like APT:, CONDA:, PIP:
      local section_match = trimmed:match("^([A-Za-z0-9_]+):$")
      if section_match then
        current_section = section_match:upper()
        if not result[current_section] then
          result[current_section] = {}
        end
      else
        -- Match list items like "- package_name"
        local item_match = line:match("^%s*-%s+(.+)$")
        -- Also try to match simple string if no leading dash but trimmed has content
        if not item_match and trimmed:match("^-") then
           item_match = trimmed:match("^-%s*(.+)$")
        end
        if item_match and current_section then
          -- strip potential quotes
          item_match = item_match:gsub("^['\"]", ""):gsub("['\"]$", "")
          table.insert(result[current_section], item_match)
        end
      end
    end
  end

  file:close()
  return result
end

return M
