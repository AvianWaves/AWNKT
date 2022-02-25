# Avian Waves NK2 Toolkit for Reaper (Script-Based MIDI Control Surface)
A ReaScript (LUA) and MIDI CC based approach for connecting the Korg NanoKontrol 2 to Reaper DAW to use as a control surface. *Note: this is project is in beta and requires a fair amount of setup and knowledge of Reaper.*

# Summary
Reaper DAW has support for numerous control surfaces, but not the Korg NanoKontrol 2 natively.  Putting the NK2 into SONAR mode allows you to use the Mackie Control Universal setting in Reaper, but the results leave a lot to be desired.  The interface is sluggish and Reaper gets bogged down to the point of sometimes crashing if you move multiple faders at the same time.

I wondered if there was a way to do this just using ReaScript (LUA) and responding directly to control messages.  It turns out, it is, and the results are fantastic with speedy fader and knob response, full LED support, and customizable actions.  Introducing: the Avian Waves NK2 Toolkit for Reaper!

# Usage
After installation the NK2 will control track volume using faders, track pan using the knobs, and solo/mute/record arm using the buttons.  The transport buttons light up based on if a song is playing, paused, or stopped.  The tracks will automatically correspond to groups of 8 tracks depending on the current active (last touched) track.  This means that depending on what part of your project has focus, the NK2's 8 track sections will automatically correspond to Reaper tracks 1-8, 9-16, 10-24, 25-32, etc.

# Installation
1. Using the Korg Kontrol Editor, put your NanoKontrol 2 into CC control mode with LED Mode set to EXTERNAL.  Set the global MIDI channel to 1.
2. In Reaper, under MIDI Devices, set the NaonKontrol 2 to "Enable input for control messages."  It is also recommended to disable "Enable input" so there isn't interference with instruments or plugins when moving the NK2's faders and knobs.  For the MIDI output, make sure that is enabled.
3. Before closing the preferences, take note of the device ID for the NK2.  You'll need this later.
4. Download the entire AWNKT project.
5. Create the folder structure for the scripts.  Since I may make other scripts in the future, I recommend making this two folders deep.  Under Windows that would making Avian Waves folder and AWNKT subfolder under %appdata%\REAPER\Scripts.  In the end you would then have a folder structure like this: C:\Users\<your name>\AppData\Roaming\REAPER\Scripts\Avian Waves\AWNKT
6. Copy all the script files (lua and ini) into that new folder.  There are many files!
7. Edit the AWNKT.ini file.
8. Under the NK2 section, edit the "MidiDeviceID" to the device ID noted from step 13 above.  I would recommend not changing any other settings until you test to make sure the defaults work.
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
