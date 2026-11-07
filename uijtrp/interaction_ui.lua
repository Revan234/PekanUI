return function(imgui, V2, color, sendChat, inventoryUI, isPlayerUiReady)
    local state = {
        target = nil,
        menuTarget = nil,
        menuOpen = false,
        payAmount = imgui.new.int(100),
        scanAt = 0,
    }
    local frame

    local function distanceBetween(x1, y1, z1, x2, y2, z2)
        return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
    end

    local function getPlayerTarget()
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local closest, closestDistance

        for playerId = 0, 999 do
            local ok, ped = sampGetCharHandleBySampPlayerId(playerId)
            if ok and ped ~= PLAYER_PED and doesCharExist(ped) then
                local x, y, z = getCharCoordinates(ped)
                local distance = distanceBetween(px, py, pz, x, y, z)
                if distance <= 2.5 and (not closestDistance or distance < closestDistance) then
                    local screenX, screenY = convert3DCoordsToScreen(x, y, z + 1.0)
                    if screenX and screenY then
                        closest = {
                            kind = "player",
                            id = playerId,
                            name = sampGetPlayerNickname(playerId),
                            x = x,
                            y = y,
                            z = z,
                            screenX = screenX,
                            screenY = screenY,
                            distance = distance,
                        }
                        closestDistance = distance
                    end
                end
            end
        end
        return closest
    end

    local function getVehicleTarget()
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local closest, closestDistance
        for vehicleId = 0, 1999 do
            if sampIsVehicleDefined(vehicleId) then
                local ok, vehicle = sampGetCarHandleBySampVehicleId(vehicleId)
                if ok and doesVehicleExist(vehicle) then
                    local x, y, z = getCarCoordinates(vehicle)
                    local distance = distanceBetween(px, py, pz, x, y, z)
                    if distance <= 4.0 and (not closestDistance or distance < closestDistance) then
                        local screenX, screenY = convert3DCoordsToScreen(x, y, z + 1.2)
                        if screenX and screenY then
                            closest = {
                                kind = "vehicle",
                                id = vehicleId,
                                x = x,
                                y = y,
                                z = z,
                                screenX = screenX,
                                screenY = screenY,
                                distance = distance,
                            }
                            closestDistance = distance
                        end
                    end
                end
            end
        end
        return closest
    end

    local function sameTarget(first, second)
        return first and second and first.kind == second.kind and first.id == second.id
    end

    local function update(enabled)
        enabled = enabled and isPlayerUiReady()
        if not enabled then
            state.target = nil
            state.menuTarget = nil
            state.menuOpen = false
            if frame then frame.HideCursor = true end
            return
        end

        local now = os.clock()
        if now >= state.scanAt then
            state.scanAt = now + 0.12
            local playerTarget = getPlayerTarget()
            local vehicleTarget = getVehicleTarget()
            if playerTarget and vehicleTarget then
                state.target = playerTarget.distance <= vehicleTarget.distance and playerTarget or vehicleTarget
            else
                state.target = playerTarget or vehicleTarget
            end
        end

        if state.menuOpen and not sameTarget(state.target, state.menuTarget) then
            state.menuOpen = false
            state.menuTarget = nil
        end

        if state.menuOpen then
            if wasKeyPressed(0x1B) then
                state.menuOpen = false
                state.menuTarget = nil
            end
            return
        end

        if frame then frame.HideCursor = true end
        if state.target and not sampIsChatInputActive() and not sampIsDialogActive() then
            local key = state.target.kind == "player" and 0x12 or 0x46
            if wasKeyPressed(key) then
                state.menuTarget = state.target
                state.menuOpen = true
                state.payAmount[0] = 100
                if frame then frame.HideCursor = false end
            end
        end
    end

    local function drawEye(drawList, x, y)
        local points = {}
        for index = 0, 8 do
            local t = index / 8
            points[index + 1] = V2(x - 9 + t * 18, y - 5 + math.sin(t * math.pi) * 5)
        end
        for index = 1, 8 do
            drawList:AddLine(points[index], points[index + 1], color(0.94, 0.96, 1.0, 1), 1.7)
            local lowerA = V2(points[index].x, y + 5 - (points[index].y - (y - 5)))
            local lowerB = V2(points[index + 1].x, y + 5 - (points[index + 1].y - (y - 5)))
            drawList:AddLine(lowerA, lowerB, color(0.94, 0.96, 1.0, 1), 1.7)
        end
        drawList:AddCircleFilled(V2(x, y), 3.2, color(0.94, 0.96, 1.0, 1), 16)
        drawList:AddCircleFilled(V2(x, y), 1.4, color(0.10, 0.12, 0.16, 1), 12)
    end

    local function drawPrompt(drawList, target)
        local label = target.kind == "player" and "ALT  Interaksi" or "F  Interaksi"
        local textSize = imgui.CalcTextSize(label)
        local width, height = textSize.x + 54, 30
        local x, y = target.screenX - width / 2, target.screenY - height - 12
        drawList:AddRectFilled(V2(x + 2, y + 3), V2(x + width + 2, y + height + 3),
            color(0, 0, 0, 0.32), 8)
        drawList:AddRectFilled(V2(x, y), V2(x + width, y + height),
            color(0.035, 0.045, 0.065, 0.92), 8)
        drawList:AddRect(V2(x, y), V2(x + width, y + height),
            color(0.86, 0.12, 0.16, 0.82), 8, 0, 1)
        drawEye(drawList, x + 17, y + 15)
        drawList:AddText(V2(x + 32, y + (height - textSize.y) / 2),
            color(0.95, 0.96, 1.0, 1), label)
        drawList:AddLine(V2(target.screenX, y + height), V2(target.screenX, target.screenY - 5),
            color(0.86, 0.12, 0.16, 0.8), 1.2)
    end

    local function sendPlayerAction(command)
        if not state.menuTarget or state.menuTarget.kind ~= "player" then return end
        sendChat(command)
        state.menuOpen = false
        state.menuTarget = nil
    end

    local function drawMenu(display)
        local target = state.menuTarget
        if not state.menuOpen or not target then return end

        local width, height = target.kind == "player" and 300 or 240, 240
        local x = math.max(12, math.min(display.x - width - 12, target.screenX + 18))
        local y = math.max(12, math.min(display.y - height - 12, target.screenY - 20))
        imgui.SetNextWindowPos(V2(x, y), imgui.Cond.Always)
        imgui.SetNextWindowSize(V2(width, height), imgui.Cond.Always)
        local flags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse
            + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoScrollbar
        if not imgui.Begin("Interaksi##PBRP_context", nil, flags) then
            imgui.End()
            return
        end

        if target.kind == "player" then
            imgui.TextColored(imgui.ImVec4(0.96, 0.45, 0.48, 1), target.name .. "  [ID " .. target.id .. "]")
            imgui.Separator()
            imgui.InputInt("Jumlah bayar", state.payAmount, 100, 1000)
            if imgui.Button("Bayar##context_pay", V2(-1, 30)) then
                if state.payAmount[0] > 0 then
                    sendPlayerAction(string.format("/pay %d %d", target.id, state.payAmount[0]))
                end
            end
            if imgui.Button("Minta gendong##context_carry", V2(-1, 30)) then
                sendPlayerAction("/carry " .. target.id)
            end
            if imgui.Button("Bagikan item##context_give", V2(-1, 30)) then
                inventoryUI.openForPlayer(target.id)
                state.menuOpen = false
                state.menuTarget = nil
            end
            if imgui.Button("Bersalaman##context_handshake", V2(-1, 30)) then
                sendPlayerAction("/rpui_handshake " .. target.id)
            end
        else
            imgui.TextColored(imgui.ImVec4(0.96, 0.45, 0.48, 1), "INTERAKSI KENDARAAN")
            imgui.Separator()
            if imgui.Button("Buka / tutup hood##context_hood", V2(-1, 36)) then
                sendChat("/rpui_vehicle hood " .. target.id)
                state.menuOpen = false
                state.menuTarget = nil
            end
            if imgui.Button("Buka / tutup trunk##context_trunk", V2(-1, 36)) then
                sendChat("/rpui_vehicle trunk " .. target.id)
                state.menuOpen = false
                state.menuTarget = nil
            end
        end

        if imgui.Button("Tutup##context_close", V2(-1, 28)) then
            state.menuOpen = false
            state.menuTarget = nil
        end
        imgui.End()
    end

    frame = imgui.OnFrame(
        function()
            return isPlayerUiReady() and (state.target ~= nil or state.menuOpen)
        end,
        function()
            local display = imgui.GetIO().DisplaySize
            local flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings
                + imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoBackground
            imgui.SetNextWindowPos(V2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(display, imgui.Cond.Always)
            imgui.Begin("##PBRP_interaction_overlay", nil, flags)
            local drawList = imgui.GetWindowDrawList()
            if state.target and not state.menuOpen then
                drawPrompt(drawList, state.target)
            end
            imgui.End()
            drawMenu(display)
        end
    )
    frame.HideCursor = false

    return {
        update = update,
        isOpen = function() return state.menuOpen end,
    }
end
