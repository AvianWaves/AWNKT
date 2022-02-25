--
-- Avian Waves NK2 Toolkit for Script-Based MIDI Control Surface (AWNKT)
--
-- Author: Avian Waves, LLC
-- Website: https://www.avianwaves.com
-- Project Repository: https://github.com/AvianWaves/AWNKT
-- License: Apache License, 2.0 - https://opensource.org/licenses/Apache-2.0
-- 
-- See __inifile.lua for additional licensing for the inifile project.  https://github.com/bartbes/inifile
--

-- Load dependency library (search based on current script path)
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
require("__AWNKT-Lib")
local inifile = require("__inifile")

----------------------
-- GLOBAL VARIABLES --
----------------------

-- GLOBAL STATE --
DEBUG = 0                 		-- Set to "1" to enable debug console
TickCount = 0             		-- Used run the main defer code slower by doing it ever 'n' ticks.
TicksPerStateScan = 3     		-- Number of ticks to lapse before running state tracking code.
LastInteractedTrack = 1   		-- Tracks the last track that the user actually interacted with.  Should also be the same as the track the user last clicked or arrowed, excluding multi-selections and deselections.
ScriptDuration = 5            -- Time in seconds CC assigned scripts can stay running
LastTrackCount = 0        		-- The total number of tracks, last checked.
TrackRoot = 1             		-- The track that refers to "Track 1" on the nanoKontrol
NK2MidiDeviceID = 0         	-- The hardware ID of the NK2
LastMouseModifierState = 0    -- Tracks the mouse modifier value (raw) to limit executions on each tick for mouse state
ShowWindow = 1								-- Show the track status window

-- GRAPHICS STATE --		
GfxDoDraw = false							-- Signals a forced graphics update on the next timer tick
FontWin = "Calibri"						-- Font to use in Windows
FontMac = "Helvetica"					-- Font to use in MacOS
FontOther = "Arial"						-- Font to use for other
FontSize = 20									-- Point size of font for track number
FontGamma = 1.8           		-- Multiply the font color by this amount
VolGamma = 0.8            		-- Multiply the background color by this amount for the volume
VolMuteRedGamma = 1.4     		-- Multiply the volume color's red component by this value (and G/B by the inverse)
TextSoloYellowGamma = 1.5 		-- Multiply the volume text's G/B component by this value (and R by the inverse)
ActiveTrackGamma = 0.5    		-- Multiple the text color by this amount 
GfxColorBGRed = 0							-- Background RGB
GfxColorBGGreen = 0
GfxColorBGBlue = 0
GfxColorTextRed = 1						-- Text Normal RGB
GfxColorTextGreen = 1		
GfxColorTextBlue = 1		
GfxColorTextSoloRed = 0				-- Text Solo RGB
GfxColorTextSoloGreen = 0		
GfxColorTextSoloBlue = 0		
GfxColorVolRed = 0						-- Volume Bar RGB
GfxColorVolGreen = 0		
GfxColorVolBlue = 0		
GfxColorVolMuteRed = 0				-- Volume Muted RGB
GfxColorVolMuteGreen = 0
GfxColorVolMuteBlue = 0
GfxColorActiveTrackRed = 0		-- Active Track Border RGB
GfxColorActiveTrackGreen = 0
GfxColorActiveTrackBlue = 0
GfxLastX = 0									-- Last Window X
GfxLastY = 0									-- Last Window X
GfxLastW = 0									-- Last Window Width
GfxLastH = 0									-- Last Window Height

TrackForceRefreshLEDs = true  -- Forces a full resend of all MIDI LED control messages
TrackMuteState = {}						-- Track the mute state of the current 8 tracks in view
TrackSoloState = {}						-- Track the solo state of the current 8 tracks in view
TrackRecordState = {}					-- Track the record arm state of the current 8 tracks in view
TrackVolume = {}							-- Track the volume of the current 8 tracks in view
for i = 0, 7, 1 do						-- Set the above arrays to initialized values of 0 and array length of 8
  TrackMuteState[i] = 0
  TrackSoloState[i] = 0
  TrackRecordState[i] = 0
  TrackVolume[i] = 0
end

TransportPlaying = 0					-- Transport is currently in playing state
TransportRecording = 0				-- Transport is currently in recording state

TrackSoloBaseCC = 32       		-- Solo LED Base CC (range from CC to Base+7 CC)
TrackMuteBaseCC = 48       		-- Mute LED Base CC (range from CC to Base+7 CC)
TrackRecordBaseCC = 64    		-- Record LED Base CC (range from CC to Base+7 CC)

TransportTrackPrevCC = 58			-- Track Previous CC
TransportTrackNextCC = 59			-- Track Next CC
TransportCycleCC = 46					-- Cycle CC
TransportMarkerSetCC = 60			-- Marker Set CC
TransportMarkerPrevCC = 61		-- Marker Previous CC
TransportMarkerNextCC = 62		-- Marker Next CC

TransportRewindCC = 43				-- Rewind CC
TransportForwardCC = 44				-- Forward CC
TransportPlayingCC = 41				-- Play CC
TransportStopCC = 42					-- Stop CC
TransportRecordingCC = 45			-- Record CC




-----------
-- DEBUG --
-----------
function DebugMsg(msg)
  if DEBUG == 1 then
    reaper.ShowConsoleMsg(msg)
  end
end




----------------------
-- TRACK MANAGEMENT --
----------------------

function TrackSelectionState()
  local tracksSelected = reaper.CountSelectedTracks()
  
  if tracksSelected == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    if track ~= nil then
      local curTrack = reaper.CSurf_TrackToID(track, false)
      if (curTrack ~= LastInteractedTrack) then
        LastInteractedTrack = curTrack
        GfxDoDraw = true
        reaper.SetExtState("AvianWaves.AWNKT", "LastInteractedTrack", LastInteractedTrack, false)
        
        local newTrackRoot = (math.floor((LastInteractedTrack - 1) / 8) * 8) + 1
        if (newTrackRoot ~= TrackRoot) then
          TrackRoot = newTrackRoot
          TrackForceRefreshLEDs = true
          GfxDoDraw = true
          reaper.SetExtState("AvianWaves.AWNKT", "TrackRoot", TrackRoot, false)
        end
        
        DebugMsg("TRACK: " .. LastInteractedTrack .. ", ROOT: " .. TrackRoot .. "\n")
      end
    end
  end
end

function TrackActivePropertyState()
	-- Set the MIDI Device ID which is the reported device ID in Reaper + 16 (by API definition)
  local midiDeviceID = NK2MidiDeviceID + 16
  
	-- Check the track count to see if it has changed, which would require a redraw of the window
  local trackCount = reaper.CountTracks(0)
  if trackCount ~= LastTrackCount then
    LastTrackCount = trackCount
    GfxDoDraw = true
  end
  
	-- Iterate through the current 8 tracks and send necessary LED update MIDI CC messages (or send all messages if TrackForceRefreshLEDs is set)
  for i = 0, 7, 1 do
    local track = reaper.GetTrack(0, (TrackRoot + i) - 1)
    if track ~= nil then
      -- MUTE STATE
      local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
      if TrackForceRefreshLEDs or mute ~= TrackMuteState[i] then
        TrackMuteState[i] = mute
        DebugMsg("Track " .. TrackRoot + i .. " Mute LED: " .. mute .. "\n")
        if mute == 1 then
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackMuteBaseCC + i, 127)
        else
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackMuteBaseCC + i, 0)
        end
        GfxDoDraw = true   -- A change in MUTE state requires a window redraw
      end

      -- SOLO STATE
      local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
      if TrackForceRefreshLEDs or solo ~= TrackSoloState[i] then
        TrackSoloState[i] = solo
        DebugMsg("Track " .. TrackRoot + i .. " Solo LED: " .. solo .. "\n")
        if solo >= 1 then
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackSoloBaseCC + i, 127)
        else
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackSoloBaseCC + i, 0)
        end
        GfxDoDraw = true   -- A change in SOLO state requires a window redraw
      end
      
      -- RECORD STATE
      local record = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
      if TrackForceRefreshLEDs or record ~= TrackRecordState[i] then
        TrackRecordState[i] = record
        DebugMsg("Track " .. TrackRoot + i .. " Record LED: " .. record .. "\n")
        if record >= 1 then
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackRecordBaseCC + i, 127)
        else
          reaper.StuffMIDIMessage(midiDeviceID, 176, TrackRecordBaseCC + i, 0)
        end
      end
      
      -- VOLUME
      local volume = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
      if volume ~= TrackVolume[i] then
        TrackVolume[i] = volume
        GfxDoDraw = true		-- A change in volume requires a window redraw
      end
    else -- No tracks here, reset the LED state
      reaper.StuffMIDIMessage(midiDeviceID, 176, TrackMuteBaseCC + i, 0)
      reaper.StuffMIDIMessage(midiDeviceID, 176, TrackSoloBaseCC + i, 0)
      reaper.StuffMIDIMessage(midiDeviceID, 176, TrackRecordBaseCC + i, 0)
    end
  end
  
  -- After we complete sending LED updates, reset the flag to false
  TrackForceRefreshLEDs = false
end




--------------------
-- PLAYBACK STATE --
--------------------
function PlaybackState()
	-- Set the MIDI Device ID which is the reported device ID in Reaper + 16 (by API definition)
  local midiDeviceID = NK2MidiDeviceID + 16
	
	-- playback state is a bitfield
  local playstate = reaper.GetPlayState()

	-- Fetch the true/false (0/1) values out of the bitfield
  newTransportPlaying = playstate & 1
  newTransportPaused = playstate & 2
  newTransportRecording = playstate & 4

	-- If the playing/paused state has changed, update the playback LEDs
  if newTransportPlaying ~= TransportPlaying or newTransportPaused ~= TransportPaused then
    TransportPlaying = newTransportPlaying
    TransportPaused = newTransportPaused
    
    if TransportPlaying > 0 then
			-- PLAYING = Play lit, Stop unlit
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportPlayingCC, 127)
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportStopCC, 0)
      DebugMsg("[Playback: Playing]\n")
      TrackForceRefreshLEDs = true  -- to fix up some issues with some LEDs turning off during playing state transition, also force a track LED refresh
    elseif TransportPaused > 0 then
			-- PAUSED = Play lit, Stop lit
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportPlayingCC, 127)
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportStopCC, 127)
      DebugMsg("[Playback: Paused]\n")
      TrackForceRefreshLEDs = true  -- to fix up some issues with some LEDs turning off during playing state transition, also force a track LED refresh
    else
			-- STOPPED = Play unlit, Stop unlit
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportPlayingCC, 0)
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportStopCC, 0)
      DebugMsg("[Playback: Stopped]\n")
      TrackForceRefreshLEDs = true  -- to fix up some issues with some LEDs turning off during playing state transition, also force a track LED refresh
    end
  end
  
	-- Update the recording LED based on the recording state
  if newTransportRecording ~= TransportRecording then
    TransportRecording = newTransportRecording

    if TransportRecording == 4 then
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportRecordingCC, 127)
      DebugMsg("[Recording: Start]\n")
    else
      reaper.StuffMIDIMessage(midiDeviceID, 176, TransportRecordingCC, 0)
      DebugMsg("[Recording: End]\n")
    end
  end
end





----------
-- Main --
----------

DebugMsg("<< AWNKT Service Starting... >>\n")

-- Turn all LEDs off by MIDI CCs
function MIDICCReset()
  local midiDeviceID = NK2MidiDeviceID + 16

  for i = 0, 7, 1 do
    reaper.StuffMIDIMessage(midiDeviceID, 176, TrackSoloBaseCC + i, 0)
    reaper.StuffMIDIMessage(midiDeviceID, 176, TrackMuteBaseCC + i, 0)
    reaper.StuffMIDIMessage(midiDeviceID, 176, TrackRecordBaseCC + i, 0)
  end

  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportTrackPrevCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportTrackNextCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportCycleCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportMarkerSetCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportMarkerPrevCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportMarkerNextCC, 0)

  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportRewindCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportForwardCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportPlayingCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportStopCC, 0)
  reaper.StuffMIDIMessage(midiDeviceID, 176, TransportRecordingCC, 0)
end

-- Paint the AWNKT status window
function DrawWindow()
	if ShowWindow > 0 then
		local str
		
		-- Fill the background
		gfx.set(GfxColorBGRed, GfxColorBGGreen, GfxColorBGBlue)
		gfx.rect(0, 0, gfx.w, gfx.h)

		for i = 0, 7, 1 do
			if TrackRoot + i <= LastTrackCount then
				-- Draw the channel volume
				if TrackMuteState[i] > 0 then
					gfx.set(GfxColorVolMuteRed, GfxColorVolMuteGreen, GfxColorVolMuteBlue)
				else
					gfx.set(GfxColorVolRed, GfxColorVolGreen, GfxColorVolBlue)
				end
			
				local vol = TrackVolume[i]
				if vol > 1 then
					vol = 1
				end
				vol = vol ^ (1/3)
		
				local sectionWidth = gfx.w / 8
				local barWidth = gfx.w / 10
				
				gfx.rect(sectionWidth * i + ((sectionWidth - barWidth) / 2) + 1, gfx.h - (gfx.h * vol), barWidth, gfx.h)
			
				-- Draw the channel numbers
				if TrackSoloState[i] > 0 then
					gfx.set(GfxColorTextSoloRed, GfxColorTextSoloGreen, GfxColorTextSoloBlue)
				else
					gfx.set(GfxColorTextRed, GfxColorTextGreen, GfxColorTextBlue)
				end
				
				gfx.x = (gfx.w / 8) * i
				gfx.y = gfx.h / 10
				if gfx.y > 10 then
					gfx.y = 10
				end
				str = tostring(TrackRoot + i)
				gfx.drawstr(str, 1, (gfx.w / 8) * (i + 1), gfx.h)

				-- Draw a rectangle around the track if it's the active track
				gfx.set(GfxColorActiveTrackRed, GfxColorActiveTrackGreen, GfxColorActiveTrackBlue)
				if LastInteractedTrack == TrackRoot + i then
					gfx.rect((gfx.w / 8) * i + 1, 1, sectionWidth - 2, gfx.h - 1, false)
				end
			end
		end
		
		gfx.update()
	end
end

-- Stores the last window state, including if docked and docking position so when it is reopened it starts out where it was left off
function SaveWindowState()
	if ShowWindow > 0 then
		local gDock, gX, gY, gW, gH = gfx.dock(-1, 0, 0, 0, 0)
		reaper.SetExtState("AvianWaves.AWNKT", "G_Dock", gDock, 1)
		reaper.SetExtState("AvianWaves.AWNKT", "G_X", gX, 1)
		reaper.SetExtState("AvianWaves.AWNKT", "G_Y", gY, 1)
		reaper.SetExtState("AvianWaves.AWNKT", "G_W", gW, 1)
		reaper.SetExtState("AvianWaves.AWNKT", "G_H", gH, 1)
	end
end

-- Code to execute when defer ticks
function OnDeferTick()
  TickCount = TickCount + 1

	if gfx.mouse_cap ~= LastMouseModifierState then
		LastMouseModifierState = gfx.mouse_cap

		if gfx.mouse_cap & 3 > 0 then  -- 1 = left mouse, 2 = right mouse, 3 = both
			-- Kludge: since OnExit() does not always run, for example when Reaper is closed, save the window state any time the window is clicked on.  
			SaveWindowState()
		end
		
		if gfx.mouse_cap & 2 == 2 then
			-- Show the dock/undock menu
			local gDock, gX, gY, gW, gH = gfx.dock(-1, 0, 0, 0, 0)
			local menuStr

			gfx.x = gfx.mouse_x
			gfx.y = gfx.mouse_y

			if gDock > 0 then
				menuStr = "!Dock AWKNT window in docker"
			else
				menuStr = "Dock AWKNT Window in docker"
			end

			if gfx.showmenu(menuStr) == 1 then
				if gDock > 0 then
					gfx.dock(0)  -- undock
				else
					gfx.dock(1)  -- dock
				end
			end
		end
	end
  
	-- Execute the state inspectors and LED and window updates every n ticks
  if TickCount > TicksPerStateScan then
    TickCount = 0
    TrackSelectionState()
    PlaybackState()
    TrackActivePropertyState()
  end

	-- Fetch the current window position if it's changed and signal a new draw cycle
  if gfx.x ~= GfxLastX or gfx.y ~= GfxLastY or gfx.w ~= GfxLastW or gfx.h ~= GfxLastH then
    GfxDoDraw = true
    GfxLastX = gfx.x
    GfxLastY = gfx.y
    GfxLastW = gfx.w
    GfxLastH = gfx.h
  end

	-- execute a draw cycle if indicated
  if GfxDoDraw then
    DrawWindow()
    GfxDoDraw = false
  end

	-- Tell Reaper to run this function again on the next tick
  reaper.defer(OnDeferTick)
end

-- Clean-up when service exits
function OnExit()
  SaveWindowState()
  gfx.quit()
  MIDICCReset()
  DebugMsg("<< AWNKT Service Terminated >>\n")
end

-- Load settings
DebugMsg("Loading Settings...\n")
local settings = inifile.parse(path .. "AWNKT.ini")

TicksPerStateScan = settings['General']['TicksPerStateScan']
VolChangeLogMode = settings['General']['VolChangeLogMode']
VolTopRange = settings['General']['VolTopRange']
ControlScriptDuration = settings['General']['ControlScriptDuration']
ShowWindow = settings['General']['ShowWindow']

NK2MidiDeviceID = settings['NK2']['MidiDeviceID']
TrackSoloBaseCC = settings['NK2']['TrackSoloBaseCC']
TrackMuteBaseCC = settings['NK2']['TrackMuteBaseCC']
TrackRecordBaseCC = settings['NK2']['TrackRecordBaseCC']
TransportTrackPrevCC = settings['NK2']['TransportTrackPrevCC']
TransportTrackNextCC = settings['NK2']['TransportTrackNextCC']
TransportCycleCC = settings['NK2']['TransportCycleCC']
TransportMarkerSetCC = settings['NK2']['TransportMarkerSetCC']
TransportMarkerPrevCC = settings['NK2']['TransportMarkerPrevCC']
TransportMarkerNextCC = settings['NK2']['TransportMarkerNextCC']
TransportRewindCC = settings['NK2']['TransportRewindCC']
TransportForwardCC = settings['NK2']['TransportForwardCC']
TransportPlayingCC = settings['NK2']['TransportPlayingCC']
TransportStopCC = settings['NK2']['TransportStopCC']
TransportRecordingCC = settings['NK2']['TransportRecordingCC']

FontWin = TrimString(settings['Graphics']['FontWin'])
FontMac = TrimString(settings['Graphics']['FontMac'])
FontOther = TrimString(settings['Graphics']['FontOther'])
FontSize = settings['Graphics']['FontSize']
FontGamma = settings['Graphics']['FontGamma']
VolGamma = settings['Graphics']['VolGamma']
VolMuteRedGamma = settings['Graphics']['VolMuteRedGamma']
TextSoloYellowGamma = settings['Graphics']['TextSoloYellowGamma']
ActiveTrackGamma = settings['Graphics']['ActiveTrackGamma']

DebugMsg("TicksPerStateScan = " .. TicksPerStateScan .. "\n")
DebugMsg("VolChangeLogMode = " .. VolChangeLogMode .. "\n")
DebugMsg("VolTopRange = " .. VolTopRange .. "\n")
DebugMsg("ControlScriptDuration = " .. ControlScriptDuration .. "\n")

DebugMsg("TrackSoloBaseCC = " .. TrackSoloBaseCC .. "\n")
DebugMsg("TrackMuteBaseCC = " .. TrackMuteBaseCC .. "\n")
DebugMsg("TrackRecordBaseCC = " .. TrackRecordBaseCC .. "\n")
DebugMsg("TransportTrackPrevCC = " .. TransportTrackPrevCC .. "\n")
DebugMsg("TransportTrackNextCC = " .. TransportTrackNextCC .. "\n")
DebugMsg("TransportCycleCC = " .. TransportCycleCC .. "\n")
DebugMsg("TransportMarkerSetCC = " .. TransportMarkerSetCC .. "\n")
DebugMsg("TransportMarkerPrevCC = " .. TransportMarkerPrevCC .. "\n")
DebugMsg("TransportMarkerNextCC = " .. TransportMarkerNextCC .. "\n")
DebugMsg("TransportRewindCC = " .. TransportRewindCC .. "\n")
DebugMsg("TransportForwardCC = " .. TransportForwardCC .. "\n")
DebugMsg("TransportPlayingCC = " .. TransportPlayingCC .. "\n")
DebugMsg("TransportStopCC = " .. TransportStopCC .. "\n")
DebugMsg("TransportRecordingCC = " .. TransportRecordingCC .. "\n")

DebugMsg("FontWin = " .. FontWin .. "\n")
DebugMsg("FontMac = " .. FontMac .. "\n")
DebugMsg("FontOther = " .. FontOther .. "\n")
DebugMsg("FontSize = " .. FontSize .. "\n")
DebugMsg("FontGamma = " .. FontGamma .. "\n")
DebugMsg("VolGamma = " .. VolGamma .. "\n")
DebugMsg("VolMuteRedGamma = " .. VolMuteRedGamma .. "\n")
DebugMsg("TextSoloYellowGamma = " .. TextSoloYellowGamma .. "\n")
DebugMsg("ActiveTrackGamma = " .. ActiveTrackGamma .. "\n")

-- Set global state for settings other scripts may need
reaper.SetExtState("AvianWaves.AWNKT", "S_VolChangeLogMode", VolChangeLogMode, false)
reaper.SetExtState("AvianWaves.AWNKT", "S_VolTopRange", VolTopRange, false)
reaper.SetExtState("AvianWaves.AWNKT", "S_ScriptDuration", ControlScriptDuration, false)
reaper.SetExtState("AvianWaves.AWNKT", "S_NK2MidiDeviceID", NK2MidiDeviceID, false)

-- Bootstrap the service
reaper.SetExtState("AvianWaves.AWNKT", "LastInteractedTrack", LastInteractedTrack, false)
reaper.SetExtState("AvianWaves.AWNKT", "TrackRoot", TrackRoot, false)
reaper.defer(OnDeferTick)
reaper.atexit(OnExit)

-- Zero out the LEDs before the first state scan begins
MIDICCReset()

-- Create window
if ShowWindow > 0 then
	DebugMsg("Initializing window.\n")

	if reaper.HasExtState("AvianWaves.AWNKT", "G_Dock") then
		local gDock = reaper.GetExtState("AvianWaves.AWNKT", "G_Dock")
		local gX = reaper.GetExtState("AvianWaves.AWNKT", "G_X")
		local gY = reaper.GetExtState("AvianWaves.AWNKT", "G_Y")
		local gW = reaper.GetExtState("AvianWaves.AWNKT", "G_W")
		local gH = reaper.GetExtState("AvianWaves.AWNKT", "G_H")
		gfx.init("AWNKT", gW, gH, gDock, gX, gY)
	else
		gfx.init("AWNKT", 500, 200, false)
	end

	-- Set font
	local operatingSystem = reaper.GetOS()
	if string.find(operatingSystem, "Win") then
		gfx.setfont(1, FontWin, FontSize)
	elseif string.find(operatingSystem, "Mac") then
		gfx.setfont(1, FontMac, FontSize)
	else
		gfx.setfont(1, FontOther, FontSize)
	end

	-- Set the colors
	GfxColorBGRed, GfxColorBGGreen, GfxColorBGBlue = RGBConvert(reaper.ColorFromNative(reaper.GetThemeColor("col_main_bg2", 0)))
	GfxColorTextRed, GfxColorTextGreen, GfxColorTextBlue = RGBConvert(reaper.ColorFromNative(reaper.GetThemeColor("col_main_text2", 0)))
	GfxColorTextRed = GfxColorTextRed * FontGamma
	GfxColorTextGreen = GfxColorTextGreen * FontGamma
	GfxColorTextBlue = GfxColorTextBlue * FontGamma
	GfxColorTextSoloRed = GfxColorTextRed * TextSoloYellowGamma
	GfxColorTextSoloGreen = GfxColorTextGreen * TextSoloYellowGamma
	GfxColorTextSoloBlue = GfxColorTextBlue * (1 / TextSoloYellowGamma)
	GfxColorVolRed = GfxColorBGRed * VolGamma
	GfxColorVolGreen = GfxColorBGGreen * VolGamma
	GfxColorVolBlue = GfxColorBGBlue * VolGamma
	GfxColorVolMuteRed = GfxColorVolRed * VolMuteRedGamma
	GfxColorVolMuteGreen = GfxColorVolGreen * (1 / VolMuteRedGamma)
	GfxColorVolMuteBlue = GfxColorVolBlue * (1 / VolMuteRedGamma)
	GfxColorActiveTrackRed = GfxColorTextRed * ActiveTrackGamma
	GfxColorActiveTrackGreen = GfxColorTextGreen * ActiveTrackGamma
	GfxColorActiveTrackBlue = GfxColorTextBlue * ActiveTrackGamma

	-- Draw the initial window
	DrawWindow()

	-- Signal we are ready for drawing on next tick
	GfxDoDraw = true
end

DebugMsg("<< AWNKT Service Started >>\n")
