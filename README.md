# GarminUITestScript
Powershell Scripts to test garmin devices on windows

# Usage

**Step 1**

Adjust the settings.dat

  - *pathSDK*... must point to the CIQ SDK
  - *pathScreenshots*... must point to a folder in which the screenshots will be saved
  - *devKey*... must point to the garmin iq developer key shortcutFileType
  - *tmpPath*... this path will be deleted and recreated on each run - projects will be copied to this path and only the copy will be adjusted

**Step 2**

Put as many *.dat files in the root folder as desired. All but the *settings.dat* files will be considered to be a test file.

A test file can have following unique entries:

  - empty lines / whitespace online lines... those line will be skipped
  - lines beginning with '#'... those lines are ignored as well, use them for your comments
  - name=<VALUE>... project name - only used for printing
  - projectName=<VALUE>... project name
  - projectDirectory=<VALUE>... root directory of the project to test
  - dependencies=<VALUE>... an array of relative included paths (e.g. *..\shared\some-resources*) - can be empty as well if you don't use such paths
  - version=<VALUE>... SDK Version (e.g. *3.2.0*)

  - devices=<VALUE>... Devices to test (e.g. *fenix6xpro;fenix5plus*)

And following non unique entries

  -properties=<VALUE>... a CSV string containing mappings of property ids to values (e.g. *data1=1;data2=2;data3=3*)
