local QBCore = exports['qb-core']:GetCoreObject()

local cooldown = 0
local ispriority = false
local ishold = false

QBCore.Players = {}
QBCore.Commands = {}
QBCore.Commands.List = {}
QBCore.Commands.IgnoreList = { -- Ignore old perm levels while keeping backwards compatibility
    ['god'] = true,            -- We don't need to create an ace because god is allowed all commands
    ['police'] = true,
    ['user'] = true            -- We don't need to create an ace because builtin.everyone
}


function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
  local restricted = true                                  -- Default to restricted for all commands
  if not permission then permission = 'user' end           -- some commands don't pass permission level
  if permission == 'user' then restricted = false end      -- allow all users to use command

  RegisterCommand(name, function(source, args, rawCommand) -- Register command within fivem
      if argsrequired and #args < #arguments then
          return TriggerClientEvent('chat:addMessage', source, {
              color = { 255, 0, 0 },
              multiline = true,
              args = { 'System', 'error.missing_args2' }
          })
      end
      callback(source, args, rawCommand)
  end, restricted)

  local extraPerms = ... and table.pack(...) or nil
  if extraPerms then
      extraPerms[extraPerms.n + 1] = permission -- The `n` field is the number of arguments in the packed table
      extraPerms.n += 1
      permission = extraPerms
      for i = 1, permission.n do
          if not QBCore.Commands.IgnoreList[permission[i]] then -- only create aces for extra perm levels
              ExecuteCommand(('add_ace qbcore.%s command.%s allow'):format(permission[i], name))
          end
      end
      permission.n = nil
  else
      permission = tostring(permission:lower())
      if not QBCore.Commands.IgnoreList[permission] then -- only create aces for extra perm levels
          ExecuteCommand(('add_ace qbcore.%s command.%s allow'):format(permission, name))
      end
  end

  QBCore.Commands.List[name:lower()] = {
      name = name:lower(),
      permission = permission,
      help = help,
      arguments = arguments,
      argsrequired = argsrequired,
      callback = callback
  }
end




RegisterNetEvent('UpdateCooldown')
AddEventHandler('UpdateCooldown', function(newCooldown)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    cooldown = newCooldown
end)

RegisterNetEvent('UpdatePriority')
AddEventHandler('UpdatePriority', function(newispriority)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    ispriority = newispriority
end)

RegisterNetEvent('UpdateHold')
AddEventHandler('UpdateHold', function(newishold)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    ishold = newishold
end)

local prevtime = GetGameTimer()
local prevframes = GetFrameCount()
local fps = -1

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) or not NetworkIsSessionStarted() do         
        Wait(500)
        prevframes = GetFrameCount()
        prevtime = GetGameTimer()            
    end

    while true do         
        curtime = GetGameTimer()
        curframes = GetFrameCount()       

        if((curtime - prevtime) > 1000) then
            fps = (curframes - prevframes) - 1                
            prevtime = curtime
            prevframes = curframes
        end      
        Wait(350)
    end    
end)



QBCore.Commands.Add('cooldown', "Starts a cooldown timer", { { name = 'minutes', help = 'Enter the number of minutes for the cooldown' } }, false, function(source, args, rawCommand)
  local min = tonumber(args[1])
  
  local Player = QBCore.Functions.GetPlayerData()
  print(Player.job.name)
  if Player and Player.job.name == "police" then
      if not min or min <= 0 then
          QBCore.Functions.Notify("Invalid input. Please enter a valid number of minutes.", "error")
          return
      end

      ishold = true
      cooldown = min * 60

      while cooldown > 0 do
          Citizen.Wait(1000)
          cooldown = cooldown - 1
          -- Update the cooldown on the server
          if cooldown > 0 then
              TriggerServerEvent("UpdateCooldown", cooldown)
          end
      end
  else
    QBCore.Functions.Notify("This command is only for Police.", "error")
    return
  end
end, 'admin')


RegisterCommand("cancelcooldown", function(source)
  
  local Player = QBCore.Functions.GetPlayerData()
  if Player.job.name == "police" then
    cooldown = 0
    TriggerServerEvent("UpdateCooldown", cooldown)
  else
    QBCore.Functions.Notify("this Command only for Police.", "error")
    return
  end
end, 'admin')


local curPing = 0

Citizen.CreateThread(function()
    local src = PlayerPedId()
    local player = PlayerPedId()
    local id = GetPlayerServerId(PlayerId())
    local code = GetStreetNameFromHashKey(GetStreetNameAtCoord(table.unpack(GetEntityCoords(player))))
    while true do
        Citizen.Wait(0)
        if ishold == false then
            DrawText2("~p~City RolePlay ~w~ 🐱‍👤 ~b~ Priority Cooldown: ~p~is Off ")
        elseif ishold == true then
            local minutes = math.floor(cooldown / 60)
            local seconds = cooldown % 60
            if seconds <= 0 then
                DrawText2("~p~City RolePlay ~w~ 🐱‍👤 ~b~ Priority Cooldown: ~g~is Off  ")
            else
                DrawText2(" ~p~City RolePlay  ~w~ | Priority Cooldown timer: ~r~" .. string.format("~r~%02d MIN %02d SEC", minutes, seconds))
            end
        else
            DrawText2(" ~p~City RolePlay  ~w~ 🐱‍👤 ~b~ Priority Cooldown timer: ~r~offline ")
        end
    end
end)

function DrawText2(text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.30)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.60, 0.97)
end
