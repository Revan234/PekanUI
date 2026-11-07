-- ============================================================
--  PBRP/PKU UI - Loading Screen (versi premium)
-- ============================================================
local CONNECT_DURATION = 32
local OBJECT_DURATION  = 12
local FADE_IN          = 0.9     -- detik
local FADE_OUT         = 0.9     -- detik
local OBJECT_FINISH    = 0.8     -- detik animasi 100% saat object selesai
local BRAND            = "PEKANBARU ROLEPLAY"

local CONNECT_STAGES = {
    { 0.00, "MENGHUBUNGKAN KE SERVER",  "Membuat koneksi yang aman..." },
    { 0.18, "AUTENTIKASI AKUN",         "Memverifikasi data karakter kamu..." },
    { 0.38, "MENGUNDUH DATA DUNIA",     "Menyinkronkan kendaraan, properti, dan bisnis..." },
    { 0.62, "MEMUAT LINGKUNGAN KOTA",   "Menyiapkan object map dan tekstur..." },
    { 0.85, "FINALISASI",               "Hampir selesai, bersiap masuk ke kota..." },
}

local OBJECT_STAGES = {
    { 0.00, "MEMUAT OBJECT DUNIA",      "Memuat object map..." },
    { 0.30, "MENYIAPKAN KOTA",          "Menyiapkan lingkungan kota..." },
    { 0.60, "MENYINKRONKAN DUNIA",      "Menyinkronkan dunia roleplay..." },
    { 0.90, "MERAPIKAN DETAIL",         "Sentuhan terakhir sebelum masuk..." },
}

local LOADING_INFO = {
    "Selamat datang di PekanBaru Roleplay, kota roleplay Indonesia.",
    "Server Development by PekanTeam Dev.",
    "Lead Developer: Ryvann.",
    "Made by PekanCommunity.",
    "Gunakan /help untuk melihat panduan dan command server.",
    "Gunakan /report untuk meminta bantuan admin.",
    "Utamakan roleplay yang realistis dan saling menghargai.",
    "Hindari metagaming dan powergaming.",
    "Jaga komunikasi yang baik dengan pemain lain.",
    "Pahami peraturan faction sebelum bergabung.",
    "Jangan bagikan data akun kepada siapa pun.",
    "Semoga nyaman ber-roleplay di PekanBaru!",
}

return function(imgui, V2, imagePath, pbrpLogoPath, communityLogoPath)
    local objectLoading = false
    local objectStart = 0
    local finishAt = 0
    local finishUntil = 0
    local finishFrom = 0
    local startedAt = 0
    local connectionLoading = false
    local texture
    local pbrpLogoTexture
    local communityLogoTexture
    local objectFinishRequested = false
    local master = 1 -- alpha global per-frame

    imgui.OnInitialize(function()
        local function loadTexture(path, label)
            if not path or not doesFileExist(path) then
                print("[PBRP/PKU UI] Gambar " .. label .. " tidak ditemukan: " .. tostring(path))
                return nil
            end
            local ok, loadedTexture = pcall(imgui.CreateTextureFromFile, path)
            if ok and loadedTexture then
                return loadedTexture
            end
            print("[PBRP/PKU UI] Gagal memuat gambar " .. label .. ": " .. tostring(loadedTexture))
            return nil
        end

        texture = loadTexture(imagePath, "loading")
        pbrpLogoTexture = loadTexture(pbrpLogoPath, "logo PekanBaru")
        communityLogoTexture = loadTexture(communityLogoPath, "logo PekanCommunity")
    end)

    local function startConnection()
        startedAt = os.clock()
        objectStart = startedAt
        finishUntil = 0
        objectLoading = false
        objectFinishRequested = false
        connectionLoading = true
    end

    local function finishConnection()
        if not connectionLoading and not objectLoading then
            return
        end
        local now = os.clock()
        if objectLoading and now - objectStart < OBJECT_DURATION then
            objectFinishRequested = true
            return
        end
        local progressStart = objectLoading and objectStart or startedAt
        local elapsed = math.max(0, now - progressStart)
        if objectLoading then
            finishFrom = 0.96 * math.min(elapsed / OBJECT_DURATION, 1)
        else
            finishFrom = math.min(0.96, 0.96 * (1 - math.exp(-elapsed / 8)))
        end
        finishAt = now
        finishUntil = now + OBJECT_FINISH + FADE_OUT
        connectionLoading = false
        objectLoading = false
        objectFinishRequested = false
    end

    local function cancelConnection()
        connectionLoading = false
        objectLoading = false
        objectFinishRequested = false
        finishUntil = 0
    end

    local function onServerMessage(text)
        if text == "@PBRPUI:CONNECT:LOADING" then
            startConnection()
            return true
        end
        if text == "@PBRPUI:OBJECTS:LOAD:BEGIN" then
            if not connectionLoading then
                startedAt = os.clock()
                connectionLoading = true
            end
            objectLoading = true
            objectStart = os.clock()
            objectFinishRequested = false
            finishUntil = 0
            return true
        end
        if text == "@PBRPUI:OBJECTS:LOAD:END" then
            finishConnection()
            return true
        end
        return false
    end

    local function isActive()
        local now = os.clock()
        return connectionLoading or objectLoading or now < finishUntil
    end

    ---------------------------------------------------------------- helpers
    local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
    local function frac(x) return x - math.floor(x) end
    local function smooth(t) t = clamp(t, 0, 1); return t * t * (3 - 2 * t) end
    local function lerp(a, b, t) return a + (b - a) * t end

    local function col(r, g, b, a)
        return imgui.GetColorU32Vec4(imgui.ImVec4(r, g, b, (a or 1) * master))
    end

    local function textC(dl, text, cx, y, color, scale, shadow)
        imgui.SetWindowFontScale(scale or 1)
        local s = imgui.CalcTextSize(text)
        local x = cx - s.x / 2
        if shadow then
            dl:AddText(V2(x + 1.5, y + 1.5), col(0, 0, 0, 0.65), text)
        end
        dl:AddText(V2(x, y), color, text)
        imgui.SetWindowFontScale(1)
        return s
    end

    local function arc(dl, cx, cy, r, a0, a1, color, thick)
        local steps = math.max(2, math.floor((a1 - a0) / (math.pi * 2) * 90))
        local px, py = cx + math.cos(a0) * r, cy + math.sin(a0) * r
        for i = 1, steps do
            local a = a0 + (a1 - a0) * (i / steps)
            local x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            dl:AddLine(V2(px, py), V2(x, y), color, thick)
            px, py = x, y
        end
    end

    local function stageFor(list, p)
        local idx = 1
        for i = 1, #list do
            if p >= list[i][1] then idx = i end
        end
        return idx, list[idx]
    end

    ---------------------------------------------------------------- frame
    local frame
    frame = imgui.OnFrame(
        function()
            return isActive()
        end,
        function()
            local now = os.clock()
            if objectLoading and objectFinishRequested
                and now - objectStart >= OBJECT_DURATION then
                finishConnection()
            end
            frame.LockPlayer = isActive()

            -- tentukan mode, progress, dan alpha global
            local mode, progress, elapsed
            master = 1
            if objectLoading then
                mode = "object"
                elapsed = now - objectStart
                progress = 0.96 * clamp(elapsed / OBJECT_DURATION, 0, 1)
                master = 1
            elseif connectionLoading then
                mode = "connect"
                elapsed = now - startedAt
                progress = math.min(0.96, 0.96 * (1 - math.exp(-elapsed / 8)))
                master = smooth(elapsed / FADE_IN)
            else
                mode = "finish"
                elapsed = now - objectStart
                local ft = now - finishAt
                progress = lerp(finishFrom, 1, smooth(ft / OBJECT_FINISH))
                master = smooth((finishUntil - now) / FADE_OUT)
            end
            master = clamp(master, 0, 1)

            local display = imgui.GetIO().DisplaySize
            local W, H = display.x, display.y
            local cx = W / 2
            local flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove
                + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoInputs
            imgui.SetNextWindowPos(V2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(display, imgui.Cond.Always)
            imgui.SetNextWindowBgAlpha(master)
            imgui.Begin("##PBRP_object_loading", nil, flags)

            local dl = imgui.GetWindowDrawList()

            -- ===== latar belakang (zoom pelan ala Ken Burns) =====
            local zoom = 1 + 0.035 * clamp(elapsed / CONNECT_DURATION, 0, 1.2)
            if texture then
                local dx, dy = W * (zoom - 1) / 2, H * (zoom - 1) / 2
                dl:AddImage(texture, V2(-dx, -dy), V2(W + dx, H + dy),
                    V2(0, 0), V2(1, 1), col(1, 1, 1, 1))
            else
                dl:AddRectFilledMultiColor(V2(0, 0), V2(W, H),
                    col(0.08, 0.015, 0.02, 1), col(0.14, 0.02, 0.025, 1),
                    col(0.02, 0.01, 0.01, 1), col(0.03, 0.01, 0.01, 1))
            end

            -- vignette atas & bawah
            dl:AddRectFilledMultiColor(V2(0, 0), V2(W, 190),
                col(0.01, 0.005, 0.005, 0.85), col(0.01, 0.005, 0.005, 0.85),
                col(0.01, 0.005, 0.005, 0), col(0.01, 0.005, 0.005, 0))
            dl:AddRectFilledMultiColor(V2(0, H - 300), V2(W, H),
                col(0.01, 0.005, 0.005, 0), col(0.01, 0.005, 0.005, 0),
                col(0.01, 0.005, 0.005, 0.95), col(0.01, 0.005, 0.005, 0.95))

            -- ===== partikel melayang =====
            for i = 1, 38 do
                local sx = frac(math.sin(i * 12.9898) * 43758.5453)
                local sy = frac(math.sin(i * 78.233) * 12345.6789)
                local speed = 10 + frac(math.sin(i * 3.17) * 999.1) * 26
                local size = 1 + frac(math.sin(i * 5.71) * 321.7) * 2.2
                local px = sx * W + math.sin(now * 0.6 + i) * 14
                local py = (sy * H - now * speed) % H
                local tw = 0.35 + 0.65 * (math.sin(now * 1.6 + i * 1.7) + 1) / 2
                dl:AddCircleFilled(V2(px, py), size * 2.6,
                    col(0.90, 0.08, 0.10, 0.07 * tw), 12)
                dl:AddCircleFilled(V2(px, py), size,
                    col(1.00, 0.72, 0.25, 0.55 * tw), 10)
            end

            -- ===== brand di atas =====
            local pulse = (math.sin(now * 2.4) + 1) / 2
            textC(dl, BRAND, cx, 36, col(1.00, 0.75, 0.28, 1), 1.9, true)
            local lineW = math.min(160, W * 0.14)
            local lineY = 36 + 40
            local gapHalf = 150
            dl:AddRectFilledMultiColor(V2(cx - gapHalf - lineW, lineY), V2(cx - gapHalf, lineY + 2),
                col(0.90, 0.12, 0.12, 0), col(0.90, 0.12, 0.12, 0.9),
                col(0.90, 0.12, 0.12, 0.9), col(0.90, 0.12, 0.12, 0))
            dl:AddRectFilledMultiColor(V2(cx + gapHalf, lineY), V2(cx + gapHalf + lineW, lineY + 2),
                col(0.90, 0.12, 0.12, 0.9), col(0.90, 0.12, 0.12, 0),
                col(0.90, 0.12, 0.12, 0), col(0.90, 0.12, 0.12, 0.9))
            textC(dl, "Selamat datang di dunia roleplay", cx, lineY - 8,
                col(1.00, 0.82, 0.48, 0.85 + pulse * 0.15), 1.0, true)

            -- ===== logo dan kredit server =====
            local logoY = 92
            local logoSize = 58
            if pbrpLogoTexture then
                dl:AddImage(pbrpLogoTexture, V2(cx - 76, logoY),
                    V2(cx - 76 + logoSize, logoY + logoSize),
                    V2(0, 0), V2(1, 1), col(1, 1, 1, 1))
            end
            if communityLogoTexture then
                dl:AddImage(communityLogoTexture, V2(cx + 18, logoY),
                    V2(cx + 18 + logoSize, logoY + logoSize),
                    V2(0, 0), V2(1, 1), col(1, 1, 1, 1))
            end
            textC(dl, "Server Development by PekanTeam Dev", cx, 158,
                col(0.94, 0.88, 0.78, 1), 0.95, true)
            textC(dl, "Lead Developer: Ryvann  |  Made by PekanCommunity", cx, 179,
                col(0.76, 0.70, 0.82, 1), 0.9, true)

            -- ===== ring progres =====
            local ringX, ringY = cx, H - 218
            local R = 40
            local glow = 0.08 + pulse * 0.07
            dl:AddCircleFilled(V2(ringX, ringY), R + 22 + pulse * 5,
                col(0.82, 0.06, 0.08, glow), 56)
            dl:AddCircleFilled(V2(ringX, ringY), R + 6,
                col(0.04, 0.025, 0.02, 0.85), 56)
            arc(dl, ringX, ringY, R, 0, math.pi * 2, col(0.34, 0.24, 0.12, 0.55), 4)

            local start = -math.pi / 2
            local sweep = math.pi * 2 * clamp(progress, 0, 1)
            if sweep > 0.02 then
                arc(dl, ringX, ringY, R, start, start + sweep, col(0.90, 0.08, 0.10, 0.22), 11)
                arc(dl, ringX, ringY, R, start, start + sweep, col(0.98, 0.24, 0.18, 0.55), 6)
                arc(dl, ringX, ringY, R, start, start + sweep, col(1.00, 0.78, 0.30, 0.95), 3)
                local ha = start + sweep
                local hx, hy = ringX + math.cos(ha) * R, ringY + math.sin(ha) * R
                dl:AddCircleFilled(V2(hx, hy), 8, col(1.00, 0.62, 0.18, 0.30), 20)
                dl:AddCircleFilled(V2(hx, hy), 4, col(1, 0.92, 0.68, 1), 16)
            end

            -- titik orbit di luar ring
            for d = 0, 2 do
                local a = now * (1.1 + d * 0.35) + d * 2.09
                local rr = R + 13 + d * 3
                dl:AddCircleFilled(V2(ringX + math.cos(a) * rr, ringY + math.sin(a) * rr),
                    2.4 - d * 0.4, col(1.00, 0.72, 0.25, 0.85 - d * 0.2), 12)
            end

            textC(dl, string.format("%d%%", math.floor(progress * 100 + 0.0001)),
                ringX, ringY - 12, col(1, 0.97, 1, 1), 1.55, true)

            -- ===== judul tahap & deskripsi =====
            local list = (mode == "connect") and CONNECT_STAGES or OBJECT_STAGES
            local sIdx, stage = stageFor(list, progress)
            if mode == "finish" then
                stage = { 1, "SELESAI", "Selamat bermain!" }
            end
            local sinceStage = clamp((progress - stage[1]) / 0.05, 0, 1)
            local ta = smooth(sinceStage) * 0.4 + 0.6
            textC(dl, stage[2], cx, H - 160, col(0.97, 0.94, 1, ta), 1.35, true)
            textC(dl, stage[3], cx, H - 132, col(0.80, 0.74, 0.92, ta), 1.0, true)

            -- ===== progress bar =====
            local barW = math.min(560, W - 80)
            local barX = (W - barW) / 2
            local barY = H - 104
            local barH = 8
            -- glow track
            dl:AddRectFilled(V2(barX - 2, barY - 2), V2(barX + barW + 2, barY + barH + 2),
                col(0.55, 0.20, 0.95, 0.10 + pulse * 0.05), 7)
            dl:AddRectFilled(V2(barX, barY), V2(barX + barW, barY + barH),
                col(0.20, 0.12, 0.07, 0.95), 5)

            local fillW = barW * clamp(progress, 0, 1)
            if fillW > 1 then
                dl:AddCircleFilled(V2(barX + 4, barY + barH / 2), barH / 2,
                    col(0.86, 0.10, 0.12, 1), 14)
                dl:AddRectFilledMultiColor(V2(barX + 4, barY), V2(barX + fillW, barY + barH),
                    col(0.86, 0.10, 0.12, 1), col(1.00, 0.72, 0.22, 1),
                    col(1.00, 0.72, 0.22, 1), col(0.86, 0.10, 0.12, 1))
                -- shimmer
                local sw = 70
                local sx = barX - sw + ((now * 0.55) % 1) * (fillW + sw)
                local s0, s1 = math.max(sx, barX + 4), math.min(sx + sw, barX + fillW)
                if s1 > s0 then
                    dl:AddRectFilled(V2(s0, barY), V2(s1, barY + barH), col(1, 1, 1, 0.22))
                end
                -- cahaya di ujung
                local hx = barX + fillW
                dl:AddCircleFilled(V2(hx, barY + barH / 2), 11, col(1.00, 0.66, 0.18, 0.20 + pulse * 0.10), 20)
                dl:AddCircleFilled(V2(hx, barY + barH / 2), 5, col(1, 0.92, 0.68, 1), 16)
            end

            -- info persen & sisa waktu
            imgui.SetWindowFontScale(0.95)
            local leftTxt = string.format("%d%%", math.floor(progress * 100 + 0.0001))
            dl:AddText(V2(barX, barY + 16), col(0.78, 0.70, 0.92, 1), leftTxt)
            local rightTxt
            if mode == "connect" then
                rightTxt = string.format("%d detik memuat", math.floor(elapsed))
            elseif mode == "object" then
                rightTxt = string.format("%d / %d detik", math.min(OBJECT_DURATION, math.floor(elapsed)), OBJECT_DURATION)
            else
                rightTxt = "Selesai"
            end
            local rs = imgui.CalcTextSize(rightTxt)
            dl:AddText(V2(barX + barW - rs.x, barY + 16), col(0.78, 0.70, 0.92, 1), rightTxt)
            imgui.SetWindowFontScale(1)

            -- ===== info server dan tips berganti setiap detik =====
            local infoIdx = math.floor(elapsed) % #LOADING_INFO + 1
            local infoPhase = elapsed - math.floor(elapsed)
            local infoAlpha = math.min(smooth(infoPhase / 0.12), smooth((1 - infoPhase) / 0.12))
            textC(dl, string.format("INFO SERVER | %02d / %02d", infoIdx, #LOADING_INFO),
                cx, H - 70, col(1.00, 0.75, 0.28, infoAlpha), 0.85, true)
            textC(dl, LOADING_INFO[infoIdx], cx, H - 44,
                col(0.82, 0.77, 0.90, infoAlpha), 1.0, true)

            -- garis aksen paling bawah
            dl:AddRectFilledMultiColor(V2(0, H - 3), V2(W / 2, H),
                col(0.90, 0.12, 0.12, 0), col(0.90, 0.12, 0.12, 0.9),
                col(0.90, 0.12, 0.12, 0.9), col(0.90, 0.12, 0.12, 0))
            dl:AddRectFilledMultiColor(V2(W / 2, H - 3), V2(W, H),
                col(0.90, 0.12, 0.12, 0.9), col(0.90, 0.12, 0.12, 0),
                col(0.90, 0.12, 0.12, 0), col(0.90, 0.12, 0.12, 0.9))

            imgui.End()
        end
    )
    frame.HideCursor = true
    frame.LockPlayer = false

    return {
        startConnection = startConnection,
        finishConnection = finishConnection,
        cancelConnection = cancelConnection,
        onServerMessage = onServerMessage,
        isActive = isActive
    }
end
