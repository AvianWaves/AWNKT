# Avian Waves NK2 Toolkit for Reaper (Script-Based MIDI Control Surface)
A ReaScript (LUA) and MIDI CC based approach for connecting the Korg NanoKontrol 2 to Reaper DAW to use as a control surface. *Note: this is project is in beta and requires a fair amount of setup and knowledge of Reaper.*

# Summary
Reaper DAW has support for numerous control surfaces, but not the Korg NanoKontrol 2 natively.  Putting the NK2 into SONAR mode allows you to use the Mackie Control Universal setting in Reaper, but the results leave a lot to be desired.  The interface is sluggish and Reaper gets bogged down to the point of sometimes crashing if you move multiple faders at the same time.

I wondered if there was a way to do this just using ReaScript (LUA) and responding directly to control messages.  It turns out, it is, and the results are fantastic with speedy fader and knob response, full LED support, and customizable actions.  Introducing: the Avian Waves NK2 Toolkit for Reaper!

# Usage
After installation the NK2 will control track volume using faders, track pan using the knobs, and solo/mute/record arm using the buttons.  The transport buttons light up based on if a song is playing, paused, or stopped.  The tracks will automatically correspond to groups of 8 tracks depending on the current active (last touched) track.  This means that depending on what part of your project has focus, the NK2's 8 track sections will automatically correspond to Reaper tracks 1-8, 9-16, 10-24, 25-32, etc.  The window will show you which tracks are currently assigned to the NK2.

# Installation
1. Using the Korg Kontrol Editor, put your NanoKontrol 2 into CC control mode with LED Mode set to EXTERNAL.  Set the global MIDI channel to 1.
2. In Reaper, under MIDI Devices, set the NaonKontrol 2 to "Enable input for control messages."  It is also recommended to disable "Enable input" so there isn't interference with instruments or plugins when moving the NK2's faders and knobs.  For the MIDI output, make sure that is enabled.
3. Before closing the preferences, __take note of the device ID for the NK2__.  You'll need this later.
4. Download the entire AWNKT project.
5. Create the folder structure for the scripts.  Since I may make other scripts in the future, I recommend making this two folders deep.  Under Windows that would making Avian Waves folder and AWNKT subfolder under %appdata%\REAPER\Scripts.  In the end you would then have a folder structure like this: C:\Users\<your name>\AppData\Roaming\REAPER\Scripts\Avian Waves\AWNKT
6. Copy all the script files (lua and ini) into that new folder.  There are many files!
7. Edit the AWNKT.ini file.
8. Under the NK2 section, edit the "MidiDeviceID" to the device ID noted from step 3 above.  I would recommend not changing any other settings until you test to make sure the defaults work.
9. Save the INI file.
10. In Reaper, open the Action window.
11. Click on "New action..." and "Load ReaScript..."
12. Select all of the AWNKT scripts *except* the ones that begin with two underscores.  (It won't hurt if you import them but they aren't meant to be run manually so won't really do anything.)
13. Run the AWNKT-Service.lua script from the action menu.  This starts the background service required for AWNKT to work.  *Note: this will need to be run each time you start Reaper.  This can automatically be set to run using instructions further down.  For now, run it manually.*
14. The AWNKT window will appear.  It can be resized and docked.  If you don't want it, just close it.  You can stop it from reopening by editing the AWNKT.ini file and setting ShowWindow = 0.
15. Now you need to assign NK2 knobs, faders, and buttons to shortcuts of all the AWNKT-Track-????? actions.  These are dynamic actions that, as explained above, automatically allow the NK2 to adjust settings on groups of 8 tracks (Reaper tracks 1-8, 9-16, 10-24, 25-32, etc.) depending on which track is active (last touched).  When you do it's important to correctly set ABSOLUTE or RELATIVE 1 MIDI CC mode.  See the table below for suggested mapping and modes.
16. Assign the transport controls to built-in Reaper actions.  See the table below for suggested mapping and modes.

# Automatically Starting AWNKT-Service.lua When Reaper Starts
1.  In the Reaper Scripts folder, create or edit a file called __\_\_startup.lua__
2.  It's important that it is spelled exactly like that.  Reaper automatically runs this file at Reaper startup.  Note it has two underscores.
3.  Add one line: __reaper.Main_OnCommand(reaper.NamedCommandLookup("\_RS6b2f3bf07c6b0fd49229d3b382e2d39522d46757"), -1)__
4.  Replace "\_RS6b2f3bf07c6b0fd49229d3b382e2d39522d46757" with the Command ID of AWNKT-Service.lua as shown in the Action Window.

# Suggested Mappings and Modes
| __Reaper Action__ | __Built-in/Script__ | __NK2 Control__ | __NK2 MIDI__ | __MIDI CC Mode__ | 
| --- | --- | --- | --- | --- |
| Script: AWNKT-Track-Move-Backup-8-Tracks.lua | Script | Track Prev | MIDI Chan 1 CC 58 | Relative 1 | 
| Script: AWNKT-Track-Move-Forward-8-Tracks.lua | Script | Track Next | MIDI Chan 1 CC 59 | Relative 1 | 
| | | | | |
| Options: Cycle ripple editing mode | Built-in | Cycle | MIDI Chan 1 CC 46 | Relative 1 | 
| Markers: Insert marker at current position | Built-in | Market Set | MIDI Chan 1 CC 60 | Relative 1 | 
| SWS: Goto/select previous marker/region | SWS | Marker Prev | MIDI Chan 1 CC 61 | Relative 1 | 
| SWS: Goto/select next marker/region | SWS | Marker Next | MIDI Chan 1 CC 62 | Relative 1 | 
| | | | | |
| Transport: Rewind a little bit | Built-in | Rewind | MIDI Chan 1 CC 43 | Relative 1 | 
| Transport: Fast forward a little bit | Built-in | Forward | MIDI Chan 1 CC 44 | Relative 1 | 
| Transport: Stop | Built-in | Stop | MIDI Chan 1 CC 42 | Relative 1 | 
| Transport: Play/pause | Built-in | Play | MIDI Chan 1 CC 41 | Relative 1 | 
| Transport: Record | Built-in | Record | MIDI Chan 1 CC 45 | Relative 1 | 
| | | | | |
| AWNKT-Track-Volume-1-9-17-etc.lua | Script | Fader 1 | MIDI Chan 1 CC 0 | Absolute | 
| AWNKT-Track-Volume-2-10-18-etc.lua | Script | Fader 2 | MIDI Chan 1 CC 1 | Absolute | 
| AWNKT-Track-Volume-3-11-19-etc.lua | Script | Fader 3 | MIDI Chan 1 CC 2 | Absolute | 
| AWNKT-Track-Volume-4-12-20-etc.lua | Script | Fader 4 | MIDI Chan 1 CC 3 | Absolute | 
| AWNKT-Track-Volume-5-13-21-etc.lua | Script | Fader 5 | MIDI Chan 1 CC 4 | Absolute | 
| AWNKT-Track-Volume-6-14-22-etc.lua | Script | Fader 6 | MIDI Chan 1 CC 5 | Absolute | 
| AWNKT-Track-Volume-7-15-23-etc.lua | Script | Fader 7 | MIDI Chan 1 CC 6 | Absolute | 
| AWNKT-Track-Volume-8-16-24-etc.lua | Script | Fader 8 | MIDI Chan 1 CC 7 | Absolute | 
| | | | | |
| AWNKT-Track-Pan-1-9-17-etc.lua | Script | Knob 1 | MIDI Chan 1 CC 16 | Absolute | 
| AWNKT-Track-Pan-2-10-18-etc.lua | Script | Knob 2 | MIDI Chan 1 CC 17 | Absolute | 
| AWNKT-Track-Pan-3-11-19-etc.lua | Script | Knob 3 | MIDI Chan 1 CC 18 | Absolute | 
| AWNKT-Track-Pan-4-12-20-etc.lua | Script | Knob 4 | MIDI Chan 1 CC 19 | Absolute | 
| AWNKT-Track-Pan-5-13-21-etc.lua | Script | Knob 5 | MIDI Chan 1 CC 20 | Absolute | 
| AWNKT-Track-Pan-6-14-22-etc.lua | Script | Knob 6 | MIDI Chan 1 CC 21 | Absolute | 
| AWNKT-Track-Pan-7-15-23-etc.lua | Script | Knob 7 | MIDI Chan 1 CC 22 | Absolute | 
| AWNKT-Track-Pan-8-16-24-etc.lua | Script | Knob 8 | MIDI Chan 1 CC 23 | Absolute | 
| | | | | |
| AWNKT-Track-ToggleSolo-1-9-17-etc.lua | Script | Solo 1 | MIDI Chan 1 CC 32 | Relative 1 | 
| AWNKT-Track-ToggleSolo-2-10-18-etc.lua | Script | Solo 2 | MIDI Chan 1 CC 33 | Relative 1 | 
| AWNKT-Track-ToggleSolo-3-11-19-etc.lua | Script | Solo 3 | MIDI Chan 1 CC 34 | Relative 1 | 
| AWNKT-Track-ToggleSolo-4-12-20-etc.lua | Script | Solo 4 | MIDI Chan 1 CC 35 | Relative 1 | 
| AWNKT-Track-ToggleSolo-5-13-21-etc.lua | Script | Solo 5 | MIDI Chan 1 CC 36 | Relative 1 | 
| AWNKT-Track-ToggleSolo-6-14-22-etc.lua | Script | Solo 6 | MIDI Chan 1 CC 37 | Relative 1 | 
| AWNKT-Track-ToggleSolo-7-15-23-etc.lua | Script | Solo 7 | MIDI Chan 1 CC 38 | Relative 1 | 
| AWNKT-Track-ToggleSolo-8-16-24-etc.lua | Script | Solo 8 | MIDI Chan 1 CC 39 | Relative 1 | 
| | | | | |
| AWNKT-Track-ToggleMute-1-9-17-etc.lua | Script | Mute 1 | MIDI Chan 1 CC 48 | Relative 1 | 
| AWNKT-Track-ToggleMute-2-10-18-etc.lua | Script | Mute 2 | MIDI Chan 1 CC 49 | Relative 1 | 
| AWNKT-Track-ToggleMute-3-11-19-etc.lua | Script | Mute 3 | MIDI Chan 1 CC 50 | Relative 1 | 
| AWNKT-Track-ToggleMute-4-12-20-etc.lua | Script | Mute 4 | MIDI Chan 1 CC 51 | Relative 1 | 
| AWNKT-Track-ToggleMute-5-13-21-etc.lua | Script | Mute 5 | MIDI Chan 1 CC 52 | Relative 1 | 
| AWNKT-Track-ToggleMute-6-14-22-etc.lua | Script | Mute 6 | MIDI Chan 1 CC 53 | Relative 1 | 
| AWNKT-Track-ToggleMute-7-15-23-etc.lua | Script | Mute 7 | MIDI Chan 1 CC 54 | Relative 1 | 
| AWNKT-Track-ToggleMute-8-16-24-etc.lua | Script | Mute 8 | MIDI Chan 1 CC 55 | Relative 1 | 
| | | | | |
| AWNKT-Track-CycleRecArm-1-9-17-etc.lua | Script | Record 1 | MIDI Chan 1 CC 64 | Relative 1 | 
| AWNKT-Track-CycleRecArm-2-10-18-etc.lua | Script | Record 2 | MIDI Chan 1 CC 65 | Relative 1 | 
| AWNKT-Track-CycleRecArm-3-11-19-etc.lua | Script | Record 3 | MIDI Chan 1 CC 66 | Relative 1 | 
| AWNKT-Track-CycleRecArm-4-12-20-etc.lua | Script | Record 4 | MIDI Chan 1 CC 67 | Relative 1 | 
| AWNKT-Track-CycleRecArm-5-13-21-etc.lua | Script | Record 5 | MIDI Chan 1 CC 68 | Relative 1 | 
| AWNKT-Track-CycleRecArm-6-14-22-etc.lua | Script | Record 6 | MIDI Chan 1 CC 69 | Relative 1 | 
| AWNKT-Track-CycleRecArm-7-15-23-etc.lua | Script | Record 7 | MIDI Chan 1 CC 70 | Relative 1 | 
| AWNKT-Track-CycleRecArm-8-16-24-etc.lua | Script | Record 8 | MIDI Chan 1 CC 71 | Relative 1 | 
