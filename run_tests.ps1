# -----------
# Classes
# -----------

Class SettingsFile
{
	$fileName
	$settings

	SettingsFile($path)
	{
		$this.fileName = Split-Path $path -leaf
		$this.settings = [System.Collections.ArrayList]::new()
	}

	Add($setting)
	{
		$this.settings.Add($setting) > $null
	}

	[String] FindValue($key)
	{
		$result = $this.settings | Where-Object { $_.key -eq $key }
		if ($result -eq $null) 
		{
			return $null
		} 
		else
		{
			return $result[0].value
		}
	}

	[System.Collections.ArrayList] FindMultipleValue($key)
	{
		$result = $this.settings | Where-Object { $_.key -eq $key } | ForEach-Object { $_.value }
		if ($result.Count -eq 1) {
			return ,$result
		}
		return $result
	}
}

Class Setting
{
	$key
	$value

	Setting($key, $value)
	{
		$this.key = $key
		$this.value = $value
	}
}

# -----------
# General Functions
# -----------

function ReadSettings($path)
{
	$settingsFile = [SettingsFile]::new($path)
	Get-Content $path | ForEach-Object {
		$line = $_
		if ($line.Trim().Length -ne 0 -and (-not $line.Trim().StartsWith("#")))
		{
			$splitted = $line -split "=",2
			$settingsFile.Add([Setting]::new($splitted[0], $splitted[1])) > $null
		}
	}
	$settingsFile
}

function BringWindowToFront($ProcessName)
{
	$process = Get-Process | Where-Object { $_.MainWindowTitle -like $ProcessName }
	$procId = $process.Id
	$null = (New-Object -ComObject WScript.Shell).AppActivate($procId)
}

function GetWindowRect($h)
{
	Try { 
		[void][Window]
	} Catch {
		Add-Type @"
			using System;
			using System.Runtime.InteropServices;
			public class Window {
			[DllImport("user32.dll")]
			[return: MarshalAs(UnmanagedType.Bool)]
			public static extern bool GetWindowRect(
				IntPtr hWnd, out RECT lpRect);

			[DllImport("user32.dll")]
			[return: MarshalAs(UnmanagedType.Bool)]
			public extern static bool MoveWindow( 
				IntPtr handle, int x, int y, int width, int height, bool redraw);

			[DllImport("user32.dll")] 
			[return: MarshalAs(UnmanagedType.Bool)]
			public static extern bool ShowWindow(
				IntPtr handle, int state);
			}
			public struct RECT
			{
				public int Left;        // x position of upper-left corner
				public int Top;         // y position of upper-left corner
				public int Right;       // x position of lower-right corner
				public int Bottom;      // y position of lower-right corner
			}
"@
	}

	$rect = New-Object RECT
	$res = [Window]::GetWindowRect($h, [ref]$rect)
	
	$l = [int]$rect.Left
	$t = [int]$rect.Top
	$w = $rect.Right - $rect.Left
	$h = $rect.Bottom - $rect.Top
	
	return @($l, $t, $w, $h)
}

function SaveScreenshot($path, $processName)
{
	[Reflection.Assembly]::LoadWithPartialName("System.Drawing") > $null
	$h = Get-Process | Where-Object {$_.MainWindowTitle -like $processName} | Select-Object -ExpandProperty MainWindowHandle
	$l, $t, $w, $h = GetWindowRect $h
	$bitmap = New-Object System.Drawing.Bitmap $w, $h
	$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphic.CopyFromScreen($l, $t, 0, 0, $bitmap.Size)
	$bitmap.Save($path)
}

function SaveScreenshotViaSim($path, $name, $shortcutAddressBar, $shortcutSaveAsName, $shortcutFileType, $simName, $changeFolder)
{
	BringWindowToFront $simName
	
	# https://stackoverflow.com/questions/19824799/how-to-send-ctrl-or-alt-any-other-key
	# SHIFT  +
	# CTRL   ^
	# ALT    %

	$wshell = New-Object -ComObject wscript.shell;
	$wshell.SendKeys('%')
	$wshell.SendKeys('F')
	$wshell.SendKeys('S')
	
	Start-Sleep -s 1
	
	if ($changeFolder)
	{
		$wshell.SendKeys($shortcutAddressBar)
		$wshell.SendKeys($path)
		$wshell.SendKeys("{ENTER}")

		Start-Sleep -s 1
	}

	$wshell.SendKeys($shortcutFileType)
	$wshell.SendKeys($shortcutSaveAsName)
	$wshell.SendKeys($name)
	$wshell.SendKeys("{ENTER}")

	Start-Sleep -s 1
}

function DeleteFile($path)
{
	if (Test-Path $path)
	{
		Remove-Item $path
	}
}

function DeleteFolder($path)
{
	if (Test-Path $path)
	{
		Remove-Item $path -Recurse
	}
}

function CreateFolder($path)
{
	if (-not (Test-Path $path))
	{
		New-Item -ItemType Directory -Force -Path $path > $null
	}
}

function WaitForUserInput()
{
	Write-Host "Press any key to continue..."
	$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
}

function ReplaceInXMLFile($file, $properties)
{
	# 1) split up properties - it's holding a csv style data string
	# e.g. data1=1;data2=2;data3=3
	$props = @()
	$properties -split ";" | ForEach {
		$props += ,@($_ -split '=')
	}

	$regexs = @()

	foreach ($p in $props)
	{
		$regexs += ,@($_ -split '=')
	}

	$out = "$file.tmp"
	$regex = "<property id=`"$key`" type=`"(?<Type>.+)`">(?<Value>.+)</property>"
	Get-Content $file | Foreach-Object {
		#  <property id="data1" type="number">1</property>

		$replaced = $null
		foreach ($p in $props)
		{
			$regex = "<property id=`"$($p[0])`" type=`"(?<Type>.+)`">(?<Value>.+)</property>"
			if($_.Trim() -match $regex)
			{
				$replaced = "<property id=`"$($p[0])`" type=`"$($Matches.Type)`">$($p[1])</property>"
				break
			}
		}

		if($replaced -ne $null)
		{
			$replaced
		}
		else
		{
			$_
		}
	} | Set-Content $out
	Remove-Item $file
	Rename-Item -Path $out -NewName $file
}

# -----------
# SIM Functions
# -----------

function ResetSim()
{
	# https://stackoverflow.com/questions/19824799/how-to-send-ctrl-or-alt-any-other-key
	# SHIFT  +
	# CTRL   ^
	# ALT    %
	
	$wshell = New-Object -ComObject wscript.shell;
	$wshell.SendKeys('%')
	$wshell.SendKeys('F')
	$wshell.SendKeys('D')

	Start-Sleep -s 1
}

function StartSim($sdkath)
{
	Start-Process -WindowStyle hidden -FilePath "$sdkath\connectiq"
	Start-Sleep -s 3
}

# -----------
# Functions
# -----------

function PrepareTest($projectDirectory, $projectName, $tmpPath, $dependencies)
{
	# a folder without whitespaces
	if ($tmpPath.Contains(" "))
	{
		throw "Temp. path must NOT contain whitespaces because this is not compatible with the SIM!"
	}

	# 1) delele old tmp folder
	DeleteFolder $tmpPath

	# 2) Copy project to tmp. folder
	Copy-Item -Path $projectDirectory -Destination "$tmpPath\$projectName" -Recurse -Force

	#3) Copy all relative folders
	if ($dependencies -ne $null)
	{
		foreach ($dependency in $dependencies)
		{
			Copy-Item -Path $dependency -Destination "$tmpPath\$projectName\$dependency" -Recurse -Force
		}
	}
}

function BuildAndRunTest($pathSDK, $pathSimTemp, $projectName, $tmpPath, $device, $version, $prop, $simName)
{
	Write-Host "      - $device => $prop"# -ForegroundColor Red

	$path = "$tmpPath\$projectName"
	$pathMonkey = "$path\monkey.jungle"
	$pathPrg = "$path\bin\tmp.prg"

	Set-Location -Path $pathSDK

	# 1) Reset SIM
	BringWindowToFront $simName
	ResetSim

	# 2) replace all properties inside the properties.xml file
	ReplaceInXMLFile "$path\resources\settings\properties.xml" $prop

	# 3) Delete old files - just to be on the save side
	DeleteFolder "$path\bin"
	DeleteFile "$pathSimTemp\tmp.PRG"
	DeleteFile "$pathSimTemp\TEMP\tmp.SET"
	
	# 4) build project (blocking)
	# monkeyc does not allow to pass the UTF-8 format like eclipse is doing it => we just use the monkeybrains like eclipse does it instead
	# .\monkeyc -d $device -f "$pathMonkey" -o "$pathPrg" -y "$devKey" -s $version
	java "-Dfile.encoding=UTF-8" "-Dapple.awt.UIElement=true" -jar $pathSDK\monkeybrains.jar -d $device -f "$pathMonkey" -o "$pathPrg" -y "$devKey" -s $version

	#5) push prg to SIM (non blocking)
	Start-Process -WindowStyle hidden -FilePath ".\monkeydo" -ArgumentList "`"$pathPrg`" $device"
	Start-Sleep -s 2

	Set-Location -Path $PSScriptRoot
}

# -----------------
# Preparation
# -----------------

# Step 1: Change settings inside the $settingsFile (settings.dat) - define SDK Path and similar in there
# Step 2: Create one or more test files (*.dat) Files defining test name and properties that needs to be changed for the test case
# Step 3: run this test file

# Following helps if you start the script in windows via double click or start with right click command
Set-Location -LiteralPath $PSScriptRoot

# Special Settings: following must be adjusted if screenshots should be taken in original resolution via the sims screenshot menu item
$makeScreenshotViaSim = $false
$shortcutAddressBar = "%E"
$shortcutSaveAsName = "%N"
$shortcutFileType = "%T"

# -------------------------------
# STEP 1 - Reading settings and test files
# -------------------------------

$singleTestFile = $args[0]

$shell = "Windows PowerShell"
$simName = "Connect IQ Device Simulator"
$pathSimTemp = '%Temp%\GARMIN\APPS'

$ext = "dat"
$settingsFile = "settings.dat"

$settings = ReadSettings $settingsFile
$testFiles = Get-ChildItem -Path "*.$ext" | Where { $_.Name -ne $settingsFile } | ForEach-Object {  ReadSettings $_.FullName }

$pathSDK = $settings.FindValue("pathSDK")
$pathScreenshots = $settings.FindValue("pathScreenshots")
$devKey = $settings.FindValue("devKey")
$tmpPath = $settings.FindValue("tmpPath")

$step = 1

Write-Host ""
Write-Host "-------------------------------"
Write-Host "- [STEP $step] Reading settings"
Write-Host "-------------------------------"
Write-Host ""
Write-Host "  - SDK Path: $pathSDK"
Write-Host "  - Screenshots Path: $pathScreenshots"
Write-Host "  - Dev Key: $devKey"
Write-Host "  - Temp. Path: $tmpPath"

$step++

# -------------------------------
# STEP 2 - Reading all test files
# -------------------------------

Write-Host ""
Write-Host "-------------------------------"
Write-Host "- [STEP $step] Reading test files"
Write-Host "-------------------------------"
Write-Host ""

$askForFile = $true
if ($singleTestFile -eq $null -or $singleTestFile -eq "")
{
	$testFiles | ForEach-Object { Write-Host "  - Test: $($_.fileName)" }
}
else
{
	Write-Host "Single Test File provided: $singleTestFile"

	$f = ReadSettings $singleTestFile
	$testFiles = @($f)
	
	$askForFile = $false
}

$step++

# -------------------------------
# STEP 3 - Ask for file
# -------------------------------

if ($askForFile )
{	
	Write-Host ""
	Write-Host "-------------------------------"
	Write-Host "- [STEP $step] Select test file(s)"
	Write-Host "-------------------------------"
	Write-Host ""
	Write-Host "  Which test do you want to start?"
	Write-Host ""
	$i = 0
	Write-Host "  - [0] ALL"
	foreach ($testFile in $testFiles)
	{
		$i++
		Write-Host "  - [$i] $($testFile.fileName)"
	}
	Write-Host ""
	
	$index = Read-Host -Prompt '  Select a test case (by index)'
	
	[int]$idx = -1
	[bool]$success = [int]::TryParse($index, [ref]$idx)
	
	if ($idx -eq 0)
	{
		# nothing to do - all test cases should be run
	}
	elseif ($idx -gt $testFiles.Count)
	{
		$invalid = $true
	}
	else
	{
		$testFiles = @($testFiles[$idx - 1])
	}

	if ($invalid)
	{
		Write-Host "Invalid input, you must input a valid number in a valid range!"
		WaitForUserInput
		return
	}
	
	
	$step++
}

# -------------------------------
# STEP 4 - Running each test
# -------------------------------

Write-Host ""
Write-Host "-------------------------------"
Write-Host "- [STEP $step] Running tests"
Write-Host "-------------------------------"
Write-Host ""

StartSim $pathSDK
DeleteFolder $pathScreenshots
CreateFolder $pathScreenshots

Read-Host -Prompt '  Change the SIM settings to your likings (simulate data, set activity monitor info, ...)'
Write-Host ""

BringWindowToFront $simName

$t = 1
foreach ($testFile in $testFiles)
{
	$projectName = $testFile.FindValue("projectName")
	$projectDirectory = $testFile.FindValue("projectDirectory")
	$dependencies = $testFile.FindValue("dependencies") -split ";"
	$properties = $testFile.FindMultipleValue("properties")
	$devices = $testFile.FindValue("devices") -split ";"
	$version = $testFile.FindValue("version")

	Write-Host "  - Test $t - '$($projectName)' ($($testFile.fileName))" -ForegroundColor Green
	Write-Host "    - # Devices:    $($devices.Count)"
	Write-Host "    - # Test Cases: $($properties.Count)"
	Write-Host "    - Tests"
	
	
	# Preparing test - this copies project + dependencies to the tmp path
	PrepareTest $projectDirectory $projectName $tmpPath $dependencies

	foreach ($device in $devices)
	{
		$i = 1
		foreach ($prop in $properties)
		{
			$screenshotName = "$($projectName)_$($device)_$($i).png"
			
			# Run tests - does following:
			# - changes the properties.xml file inside the copy inside the tmp path
			# - builds the project
			# - runs the project in the sim
			BuildAndRunTest $pathSDK $pathSimTemp $projectName $tmpPath $device $version $prop $simName

			# Make a screenshot
			if ($makeScreenshotViaSim)
			{
				$changeFolder = ($t -eq 1) -and ($i -eq 1)
				SaveScreenshotViaSim $pathScreenshots $screenshotName $shortcutAddressBar $shortcutSaveAsName $shortcutFileType $simName $changeFolder
			}
			else
			{
				SaveScreenshot "$pathScreenshots\$screenshotName" $simName
			}

			$i++
		}
	}
	$t++
}

Write-Host ""

BringWindowToFront $shell
WaitForUserInput
