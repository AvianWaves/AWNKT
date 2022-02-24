--
-- Avian Waves NK2 Toolkit for Script-Based MIDI Control Surface (AWNKT)
--
-- Author: Avian Waves, LLC
-- Website: https://www.avianwaves.com
-- Project Repository: https://github.com/AvianWaves/AWNKT
-- License: Apache License, 2.0 - https://opensource.org/licenses/Apache-2.0
-- 

local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
require("AWNKT-Lib")

local trackNum = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "TrackRoot"))
AWNKT_CycleTrackRecArm(trackNum)
