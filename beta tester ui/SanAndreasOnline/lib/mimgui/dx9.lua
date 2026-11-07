-- This file is part of mimgui project
-- Licensed under the MIT License
-- Copyright (c) 2018, FYP <https://github.com/THE-FYP>

local imgui = require 'mimgui.imgui'
local win32 = require 'mimgui.win32'
local lib = imgui.lib
local ffi = require 'ffi'
-- (San Andreas Online: its frames drawn safely - sao.screenpos; without it, as mimgui always drew)
local okSP, SP = pcall(require, 'sao.screenpos')
if okSP and type(SP) ~= 'table' then okSP = false end

ffi.cdef [[
typedef struct IDirect3DDevice9 *LPDIRECT3DDEVICE9, *PDIRECT3DDEVICE9;
typedef struct IDirect3DVertexBuffer9 *LPDIRECT3DVERTEXBUFFER9, *PDIRECT3DVERTEXBUFFER9;
typedef struct IDirect3DIndexBuffer9 *LPDIRECT3DINDEXBUFFER9, *PDIRECT3DINDEXBUFFER9;
typedef struct IDirect3DTexture9 *LPDIRECT3DTEXTURE9, *PDIRECT3DTEXTURE9;
typedef struct ImGui_ImplDX9_Context
{
	LPDIRECT3DDEVICE9        pd3dDevice;
	LPDIRECT3DVERTEXBUFFER9  pVB;
	LPDIRECT3DINDEXBUFFER9   pIB;
	LPDIRECT3DTEXTURE9       FontTexture;
	int                      VertexBufferSize;
	int                      IndexBufferSize;
} ImGui_ImplDX9_Context;

bool ImGui_ImplWin32_Init(HWND hwnd, INT64* ticksPerSecond, INT64* time);
void ImGui_ImplWin32_NewFrame(HWND hwnd, INT64 ticksPerSecond, INT64* time);
LRESULT ImGui_ImplWin32_WndProcHandler(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

ImGui_ImplDX9_Context* ImGui_ImplDX9_Init(LPDIRECT3DDEVICE9 device);
void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context);
void ImGui_ImplDX9_NewFrame(ImGui_ImplDX9_Context* context);
void ImGui_ImplDX9_RenderDrawData(ImGui_ImplDX9_Context* context, ImDrawData* draw_data);
void ImGui_ImplDX9_InvalidateDeviceObjects(ImGui_ImplDX9_Context* context);

bool ImGui_ImplDX9_CreateFontsTexture(ImGui_ImplDX9_Context* context); // replaces ImGui_ImplDX9_CreateDeviceObjects since they are the same
void ImGui_ImplDX9_InvalidateFontsTexture(ImGui_ImplDX9_Context* context);

LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFile(LPDIRECT3DDEVICE9 device, LPCTSTR path);
LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFileInMemory(LPDIRECT3DDEVICE9 device, LPCVOID src, UINT size);
void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);

int __stdcall MultiByteToWideChar(UINT CodePage, unsigned long dwFlags, const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
]]

local ImplDX9 = {}
function ImplDX9.new(device, hwnd)
    -- ImGui_ImplDX9_Context* ImGui_ImplDX9_Init(LPDIRECT3DDEVICE9 device);
    local obj = {}
    local d3dcontext = lib.ImGui_ImplDX9_Init(device)
    if d3dcontext == nil then
        return nil
    end
    local context = imgui.CreateContext()
    obj.ticksPerSecond = ffi.new('INT64[1]', 0)
    obj.time = ffi.new('INT64[1]', 0)
    imgui.SetCurrentContext(context)
    local imio = imgui.GetIO()
    imio.BackendRendererName = 'imgui_impl_dx9_lua'
    imio.BackendFlags = bit.bor(imio.BackendFlags, lib.ImGuiBackendFlags_RendererHasVtxOffset) -- We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
    -- bool ImGui_ImplWin32_Init(HWND hwnd, INT64* ticksPerSecond, INT64* time);
    if not lib.ImGui_ImplWin32_Init(hwnd, obj.ticksPerSecond, obj.time) then
        -- void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context);
        lib.ImGui_ImplDX9_Shutdown(d3dcontext)
        imgui.DestroyContext(context)
        return nil
    end
    obj.context = context
    obj.d3dcontext = d3dcontext
    obj.d3ddevice = device
    obj.hwnd = hwnd
    obj.dpiscale = win32.GetDpiScaleForWindow(hwnd)
    -- set finalizer
    ffi.gc(d3dcontext, function(cd)
        imgui.SetCurrentContext(context)
        -- void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context);
        lib.ImGui_ImplDX9_Shutdown(cd)
        imgui.DestroyContext(context)
    end)
    return setmetatable(obj, {__index = ImplDX9})
end

function ImplDX9:SwitchContext()
    imgui.SetCurrentContext(self.context)
end

function ImplDX9:NewFrame()
    self:SwitchContext()
    -- (San Andreas Online: fonts rebuilt for a new size, between two frames - the atlas is unlocked here)
    if self.fontsHook then
        local f = self.fontsHook
        self.fontsHook = nil
        pcall(f)
    end
    -- void ImGui_ImplDX9_NewFrame(ImGui_ImplDX9_Context* context);
    lib.ImGui_ImplDX9_NewFrame(self.d3dcontext)
    -- void ImGui_ImplWin32_NewFrame(HWND hwnd, INT64 ticksPerSecond, INT64* time);
    lib.ImGui_ImplWin32_NewFrame(self.hwnd, self.ticksPerSecond[0], self.time)
    -- (San Andreas Online: a zoomed window sees the mouse in its own unzoomed coordinates - see zoomHook)
    if self.mouseHook then pcall(self.mouseHook, imgui.GetIO()) end
    imgui.NewFrame()
end

function ImplDX9:EndFrame()
    self:SwitchContext()
    imgui.Render()
    local dd = imgui.GetDrawData()
    -- (San Andreas Online: the interface size - some windows are laid out small and enlarged here, as a whole)
    if self.zoomHook then pcall(self.zoomHook, dd) end
    -- (San Andreas Online, #59 black flashes: the game draws with Direct3D's clipping off and this ImGui never turns it
    -- on - a shape far off the screen was undefined there, a triangle across the whole screen on AMD cards. Drawn with
    -- clipping on and the few states this ImGui leaves to chance set, the game's own given back after; a vertex that is
    -- not a number made harmless first - sao.screenpos)
    if okSP then
        pcall(SP.drawData, dd)
        SP.drawSafe(self.d3dcontext.pd3dDevice, lib.ImGui_ImplDX9_RenderDrawData, self.d3dcontext, dd)
        return
    end
    -- void ImGui_ImplDX9_RenderDrawData(ImGui_ImplDX9_Context* context, ImDrawData* draw_data);
    lib.ImGui_ImplDX9_RenderDrawData(self.d3dcontext, dd)
end

jit.off(ImplDX9.EndFrame)

pcall(ffi.cdef, 'int IsDBCSLeadByte(uint8_t b);')
function ImplDX9:WindowMessage(msg, wparam, lparam)
    self:SwitchContext()
    if msg == 0x0102 then -- WM_CHAR
        -- (San Andreas Online: the game's window is not Unicode - its characters come in the PC's code page; Chinese,
        -- Japanese, Korean come as TWO messages, the lead byte then the trail byte: joined before the conversion)
        if wparam < 256 then
            if self.leadByte then
                local char = ffi.new('char[2]', self.leadByte, wparam)
                self.leadByte = nil
                local wchar = ffi.new('wchar_t[1]', 0)
                if ffi.C.MultiByteToWideChar(0, 0, char, 2, wchar, 1) > 0 then wparam = wchar[0] else return 0 end
            elseif wparam >= 0x80 and ffi.C.IsDBCSLeadByte(wparam) ~= 0 then
                self.leadByte = wparam
                return 0
            else
                local char = ffi.new('char[1]', wparam)
                local wchar = ffi.new('wchar_t[1]', 0)
                if ffi.C.MultiByteToWideChar(0, 0, char, 1, wchar, 1) > 0 then
                    wparam = wchar[0]
                end
            end
        end
    elseif msg == 0x0286 then -- WM_IME_CHAR: one double-byte character (lead << 8 | trail) from the input method
        if wparam > 0xFF then
            local char = ffi.new('char[2]', math.floor(wparam / 256) % 256, wparam % 256)
            local wchar = ffi.new('wchar_t[1]', 0)
            if ffi.C.MultiByteToWideChar(0, 0, char, 2, wchar, 1) > 0 then
                return lib.ImGui_ImplWin32_WndProcHandler(self.hwnd, 0x0102, wchar[0], lparam)
            end
            return 0
        end
        msg = 0x0102
    end
    -- LRESULT ImGui_ImplWin32_WndProcHandler(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    return lib.ImGui_ImplWin32_WndProcHandler(self.hwnd, msg, wparam, lparam)
end

function ImplDX9:InvalidateDeviceObjects()
    self:SwitchContext()
    -- void ImGui_ImplDX9_InvalidateDeviceObjects(ImGui_ImplDX9_Context* context);
    lib.ImGui_ImplDX9_InvalidateDeviceObjects(self.d3dcontext)
end

function ImplDX9:CreateTextureFromFile(path)
	-- LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFile(LPDIRECT3DDEVICE9 device, LPCTSTR path);
	local tex = lib.ImGui_ImplDX9_CreateTextureFromFile(self.d3ddevice, path)
	if tex == nil then
		return nil
	end
    -- void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);
    return ffi.gc(tex, lib.ImGui_ImplDX9_ReleaseTexture)
end

function ImplDX9:CreateTextureFromFileInMemory(src, size)
	-- LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFileInMemory(LPDIRECT3DDEVICE9 device, LPCVOID src, UINT size);
	if type(src) == 'number' then
		src = ffi.cast('LPCVOID', src)
	end
	local tex = lib.ImGui_ImplDX9_CreateTextureFromFileInMemory(self.d3ddevice, src, size)
	if tex == nil then
		return nil
	end
    -- void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);
    return ffi.gc(tex, lib.ImGui_ImplDX9_ReleaseTexture)
end

function ImplDX9:ReleaseTexture(tex)
    ffi.gc(tex, nil)
    lib.ImGui_ImplDX9_ReleaseTexture(tex)
end

function ImplDX9:CreateFontsTexture()
    self:SwitchContext()
    -- bool ImGui_ImplDX9_CreateFontsTexture(ImGui_ImplDX9_Context* context);
    return lib.ImGui_ImplDX9_CreateFontsTexture(self.d3dcontext)
end

function ImplDX9:InvalidateFontsTexture()
    self:SwitchContext()
    -- void ImGui_ImplDX9_InvalidateFontsTexture(ImGui_ImplDX9_Context* context);
    lib.ImGui_ImplDX9_InvalidateFontsTexture(self.d3dcontext)
end

return ImplDX9
