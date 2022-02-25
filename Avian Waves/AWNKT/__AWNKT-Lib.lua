--
-- Avian Waves NK2 Toolkit for Script-Based MIDI Control Surface (AWNKT)
--
-- Author: Avian Waves, LLC
-- Website: https://www.avianwaves.com
-- Project Repository: https://github.com/AvianWaves/AWNKT
-- License: Apache License, 2.0 - https://opensource.org/licenses/Apache-2.0
-- 

function AWNKT_SetTrackVolume(trackNum, volCC)
	local volChangeLogMode = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "S_VolChangeLogMode"))
	local volTopRange = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "S_VolTopRange"))
	
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local volume = volCC / 127  -- Convert the volume range from 0-127 to 0.0-1.0
		
		if volChangeLogMode == 1 then
			volume = volume ^ 3 	-- This "flattens" the existing log curve on the volume range
		end
		
		volume = volume * volTopRange  -- If the user selected to go above unity gain, this will extend the range (2.0 = 6db of additional headroom)

		reaper.SetMediaTrackInfo_Value(track, "D_VOL", volume)
	end
end

function AWNKT_SetTrackPan(trackNum, panCC)
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local pan = ((2 / 127) * panCC) - 1
		pan = math.floor(pan * 100 + 0.5) / 100  -- Round to two decimal places
		if (pan > -0.02 and pan < 0.02) then     -- Give the pot a wider zero region (it will likely just skip over 0 otherwise)
			pan = 0
		end
		
		reaper.SetMediaTrackInfo_Value(track, "D_PAN", pan)
	end
end

function AWNKT_ToggleTrackMute(trackNum)
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
		
		if mute > 0 then
			mute = 0
		else
			mute = 1
		end

		reaper.SetMediaTrackInfo_Value(track, "B_MUTE", mute)
	end
end

function AWNKT_ToggleTrackSolo(trackNum)
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
		
		if solo > 0 then
			solo = 0
		else
			solo = 1
		end

		reaper.SetMediaTrackInfo_Value(track, "I_SOLO", solo)
	end
end

function AWNKT_ToggleTrackRecArm(trackNum)
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local recArm = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
		
		if recArm > 0 then
			recArm = 0
		else
			recArm = 1
		end

		reaper.SetMediaTrackInfo_Value(track, "I_RECARM", recArm)
	end
end

function AWNKT_CycleTrackRecArm(trackNum)
	if trackNum > 0 and trackNum <= reaper.CountTracks(0) then
		local track = reaper.GetTrack(0, trackNum - 1)    -- Note how we have to convert to zero-based index for GetTrack()
		local recArm = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
		local recAuto = reaper.GetMediaTrackInfo_Value(track, "B_AUTO_RECARM")

		if recAuto > 0 then
			recArm = 0
			recAuto = 0
		elseif recArm > 0 then
			recArm = 1
			recAuto = 1
		else
			recArm = 1
			recAuto = 0
		end

		reaper.SetMediaTrackInfo_Value(track, "B_AUTO_RECARM", recAuto)
		reaper.SetMediaTrackInfo_Value(track, "I_RECARM", recArm)
	end
end

function RGBConvert(r, g, b)
	return r / 256, g / 256, b / 256
end

function TrimString(s)
   return s:match( "^%s*(.-)%s*$" )
end