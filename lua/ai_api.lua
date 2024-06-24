local M = {}

M.OUTPUT_MODE = {
  CONSOLE = 0,
  AT_CURSOR = 1,
}

M.config = {
  output_mode = M.OUTPUT_MODE.AT_CURSOR,
}

SYSTEM_PROMPT = [[
You are an AI programming assistant embedded in a text editor. You possess expert-level programming knowledge across all topics. Your task is to assist users with their programming queries and requests.

Key points:
- Use the naming conventions for variables, functions, and classes that you already see in the code.
- Same applies to the formatting and syntax, like indentation and semicolons.
- Write no more than what is asked by the user (e. g. a single function, a single loop)
- Your code will be placed exactly after the one you received, so don't repeat any input, just what would follow after it
- Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
- Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step-by-step.
- Spot potential bugs and logical errors. Alert the user and suggest fixes.
- Upon request, add helpful comments explaining complex or unclear code.
- Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
- Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
- If answering in text, be concise and use markdown.
- When asked to create code, only generate the code. No bugs. If you add any message for the user, make it a comment in the code.
- Think step by step

]]

local function getContentUntilCursor()
  local cursorPos = vim.api.nvim_win_get_cursor(0)
  local currentLine = cursorPos[1]
  local currentColumn = cursorPos[2]

  local lines = vim.api.nvim_buf_get_lines(0, 0, currentLine, false)

  if #lines > 0 then
    lines[#lines] = lines[#lines]:sub(1, currentColumn + 1)
  end

  local contentUntilCursor = table.concat(lines, '\n')
  return contentUntilCursor
end

local function convertJSON(str)
  return str:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t'):gsub('\b', '\\b'):gsub('\f', '\\f'):gsub("'", '’')
end

local function compileRequest(userPrompt)
  local request = [[
    curl -s -N -X POST https://api.anthropic.com/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d '{
      "model": "claude-3-5-sonnet-20240620",
      "messages": [
        {
          "role": "user",
          "content": "%s"
        }
      ],
      "max_tokens": 1024,
      "stream": true
    }'
  ]]
  local fullPrompt = convertJSON(SYSTEM_PROMPT) .. convertJSON(userPrompt)
  local command = string.format(request, fullPrompt)
  return command
end

local function sendRequest(command)
  return io.popen(command, 'r')
end

local function streamEnd(json)
  if json.type == 'message_delta' and json.delta and json.delta.stop_reason == 'end_turn' then
    return true
  end
  return false
end

local function processLine(line)
  if line:sub(1, 6) ~= 'data: ' then
    return nil, false
  end

  local content = line:sub(7)
  if content == '' then
    return nil, false
  end

  local success, json = pcall(vim.fn.json_decode, content)
  if success and json then
    if json.type == 'content_block_delta' and json.delta and json.delta.type == 'text_delta' then
      return json.delta.text, false
    end
    if streamEnd(json) then
      return nil, true
    end
  end
end

local function processStream(handle)
  local buffer = ''
  local output = ''
  local finished = false

  while not finished do
    local chunk = handle:read(1024)
    if not chunk then
      break
    end
    buffer = buffer .. chunk

    while true do
      local lineend = buffer:find '\n'
      if not lineend then
        break
      end

      local line = buffer:sub(1, lineend - 1)
      buffer = buffer:sub(lineend + 1)

      local text, isend = processLine(line)
      if text then
        output = output .. text
      end
      if isend then
        finished = true
        break
      end
    end
  end

  handle:close()
  return output
end

local function outputCommand(response)
  print(response)
end

local function outputAtCursor(response)
  local lines = vim.split(response, '\n')
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_lines(0, row + i - 1, row + i - 1, false, { line })
  end
  vim.api.nvim_win_set_cursor(0, { row + #lines, #lines[#lines] })
end

function M.askAI()
  local command = compileRequest(getContentUntilCursor())
  local handle = sendRequest(command)
  if handle then
    local response = processStream(handle)
    if M.config.output_mode == M.OUTPUT_MODE.CONSOLE then
      outputCommand(response)
    elseif M.config.output_mode == M.OUTPUT_MODE.AT_CURSOR then
      outputAtCursor(response)
    end
  else
    print 'Failed to make request'
  end
end

return M
