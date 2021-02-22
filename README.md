# GarminUITestScript
Powershell Scripts to test garmin devices on windows

# Run the demo

After downloading or cloning this repo you must do following to run the tests on the demo app:

* **test_demo.dat**
  * change the value of *projectDirectory*  to point to the demo project directory
* **settings.dat**
  * change the value of *pathSDK* to point to your local CIQ SDK path
  * change the value of *pathScreenshots* to point to a path where you want to save the screenshots
  * change the value of *devKey* to point to your CIQ developer key file
  * change the value of *tmpPath* to point to an unused temp. folder - this folder will be deleted and recreated on each test run_tests
  * SPECIAL (% = alt key)
    * change the value of *shortcutAddressBar* to the keyboard shortcut that puts the cursor in a save as dialog into the address bar - should be *%E* in a german setup and *%D* in an english setup
    * change the value of *shortcutSaveAsName* to the keyboard shortcut that puts the cursor in a save as dialog into the file name field - should be *%N* in german and english
    * change the value of *shortcutFileType* to the keyboard shortcut that puts the cursor in a save as dialog into the file type field - should be *%T* in german and english

Those special keys are used to save the screenshots in the correct location.

After this you are done and trying the demo by running *run_tests.ps1* should already create 6 screenshots inside the defined screenshot folder.

# General Usage

### Step 1

Adjust the settings.dat

  - **pathSDK**... must point to the CIQ SDK
  - **pathScreenshots**... must point to a folder in which the screenshots will be saved
  - **devKey**... must point to the garmin iq developer key shortcutFileType
  - **tmpPath**... this path will be deleted and recreated on each run - projects will be copied to this path and only the copy will be adjusted

### Step 2

Put as many *.dat files in the root folder as desired. All but the *settings.dat* files will be considered to be a test file.

A test file can have following unique entries:

  - **empty lines / whitespace only lines**... those line will be skipped
  - **lines beginning with '#'**... those lines are ignored as well, use them for your comments
  - **projectName=VALUE**... project name
  - **projectDirectory=VALUE**... root directory of the project to test
  - **dependencies=VALUE**... an array of relative included paths (e.g. *..\shared\some-resources*) - can be empty as well if you don't use such paths
  - **version=VALUE**... SDK Version (e.g. *3.2.0*)

  - **devices=VALUE**... Devices to test (e.g. *fenix6xpro;fenix5plus*)

And following non unique entries

  - **properties=VALUE**... a CSV string containing mappings of property ids to values (e.g. *data1=1;data2=2;data3=3*)

### Step 3

Run the tests via *run_tests.ps1*. This will run *ALL* test files.

If you want to run a single test file only and have multiple ones defines, simply pass the test file as first command line argument to *run_tests.ps1* like *run_tests.ps1 test_demo.bat*

# IMPORTANT NOTES

- this script can be used as is
- attributions are always welcome
- there are *no error checks* in this script - this is something that could be improved
- make sure no file is opened in an editor during TESTS
- don't click around during tests - some UI tests (making a screenshot) do depend on focus windows

I could only test this on my machine, maybe small adjustments are necessary on your device
