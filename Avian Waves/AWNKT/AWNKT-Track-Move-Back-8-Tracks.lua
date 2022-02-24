--
-- Avian Waves NK2 Toolkit for Script-Based MIDI Control Surface (AWNKT)
--
-- Author: Avian Waves, LLC
-- Website: https://www.avianwaves.com
-- Project Repository: https://github.com/AvianWaves/AWNKT
-- License: Apache License, 2.0 - https://opensource.org/licenses/Apache-2.0
-- 

local LastInteractedTrack = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "LastInteractedTrack"))
if LastInteractedTrack ~= nil and LastInteractedTrack > 0 then
  local destinationTrack = LastInteractedTrack - 8
  local totalTracks = reaper.CountTracks(0)

  if destinationTrack < 1 then
    destinationTrack = 1
  end

  local track = reaper.GetTrack(0, destinationTrack - 1)    -- Note how we have to conver to zero-based index for GetTrack()
  if track ~= nil then
    reaper.SetOnlyTrackSelected(track)
  end
end

