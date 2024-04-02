local players = game:GetService("Players")
local textChat = game:GetService("TextChatService")
local repStorage = game:GetService("ReplicatedStorage")
local chatFolder = repStorage:FindFirstChild("DefaultChatSystemChatEvents")
local plr = players.LocalPlayer

local adminLib = {}

adminLib.New = function (options)
  local handler = {}
  local configOptions = {}
  local commandsList = {}
  if not options or not (type(options) == "table") then
    error("New options should be a valid table.")
  end
  for i, v in pairs(options) do
    configOptions[i] = v
  end
  if not configOptions.Prefix or not (type(configOptions.Prefix) == "string") then
    error("Prefix should be a valid string.")
  end
  if not configOptions.Admins or not (type(configOptions.Admins) == "table") then
    error("Admins should be a valid table.")
  end
  
  -- Commands Handler
  
  handler.RegisterCommand = function (registerOptions)
    if not registerOptions or not (type(registerOptions) == "table") then
      error("Register options should be a valid table.")
    end
    if not registerOptions.Name or not (type(registerOptions.Name) == "string") or not registerOptions.Callback or not (type(registerOptions.Callback) == "function") then
      error("Invalid Name or Callback value.")
    end
    commandsList[string.lower(registerOptions.Name)] = {
      ["NoAdmin"] = registerOptions.NoAdmin,
      ["Callback"] = registerOptions.Callback
    }
  end
  
  -- Messages Handler
  
  local function newMessage(data)
    if not data.Message or not data.AdminId then return end
    if not table.find(configOptions.Admins, data.AdminId) then return end
    local command = string.match(data.Message, "^" .. configOptions.Prefix .. "(%S+)")
    if not command then return end
    local plainArgs = string.match(data.Message, "^" .. configOptions.Prefix .. command .. "%s*(.+)")
    if not command then return end
    local findCommand = commandsList[string.lower(command)]
    if not findCommand then return end
    local adminPlr = players:GetPlayerByUserId(data.AdminId)
    if not adminPlr then return end
    if findCommand.NoAdmin and table.find(configOptions.Admins, plr.UserId) then return end
    local args = {}
    if plainArgs and #plainArgs > 0 then
      args = string.split(plainArgs, " ")
    end
    task.spawn(findCommand.Callback, {
      ["CommandName"] = command,
      ["PlainArgs"] = plainArgs,
      ["Args"] = args,
      ["Admin"] = adminPlr,
      ["Reply"] = data.Reply
    })
  end
  
  if chatFolder then
    chatFolder.OnNewMessage.OnClientEvent:Connect(function (chatData)
      if not chatData or not chatData.Message or not chatData.SpeakerUserId then return end
      newMessage({
        ["Message"] = chatData.Message,
        ["AdminId"] = chatData.SpeakerUserId,
        ["Reply"] = function (message)
          chatFolder.SayMessageRequest:FireServer(message, "All")
        end
      })
    end)
  else
    textChat.MessageReceived:Connect(function (chatData)
      if not chatData or not chatData.Text or not chatData.TextChannel or not chatData.TextSource or not chatData.TextSource.UserId then return end
      newMessage({
        ["Message"] = chatData.Text,
        ["AdminId"] = chatData.TextSource.UserId,
        ["Reply"] = function (message)
          chatData.TextChannel:SendAsync(message)
        end
      })
    end)
  end
  
  return handler
end

return adminLib