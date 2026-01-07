# Import BurnToast
Import-Module -Name BurntToast, Microsoft.WinGet.Client

# Load assemblies for Windows Forms, drawing and theme
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type @"
using System;
using System.Runtime.InteropServices;

// Dark context menu
public class UxTheme
{
	[DllImport("UxTheme.dll", EntryPoint = "#135")]
	public static extern int SetPreferredAppMode([In] int preferredAppMode);

	[DllImport("UxTheme.dll", EntryPoint = "#136")]
	public static extern void FlushMenuThemes();
}

// Dark title bar and backdrop
public class DwmApi
{
	[StructLayout(LayoutKind.Sequential)]
	public struct MARGINS
	{
		public int cxLeftWidth;
		public int cxRightWidth;
		public int cyTopHeight;
		public int cyBottomHeight;
	};

	[DllImport("DwmApi.dll")]
	public static extern int DwmExtendFrameIntoClientArea(
		[In] IntPtr hwnd, [In] ref MARGINS marginsInset);

	public static int ExtendFrame(IntPtr hwnd)
	{
		MARGINS inset = new MARGINS()
		{
			cxLeftWidth = -1,
			cxRightWidth = -1,
			cyTopHeight = -1,
			cyBottomHeight = -1,
		};
		return DwmExtendFrameIntoClientArea(hwnd, ref inset);
	}

	[DllImport("DwmApi.dll")]
	public static extern int DwmSetWindowAttribute(
		[In] IntPtr hwnd, [In] int dwAttribute, [In] ref int pvAttribute, [In] int cbAttribute);

	public static int SetDwmAttrib(IntPtr hwnd, int attrib, int flag)
	{
		return DwmSetWindowAttribute(hwnd, attrib, ref flag, Marshal.SizeOf(flag));
	}
}
"@

# Set context menu mode
$PREFERRED_APPMODE_ALLOWDARK = 1;
[UxTheme]::SetPreferredAppMode($PREFERRED_APPMODE_ALLOWDARK) | Out-Null
[UxTheme]::FlushMenuThemes() | Out-Null

# Define icon paths
$defaultIconPath = "$PSScriptRoot\up-to-date.ico"
$updateIconPath = "$PSScriptRoot\updates-available.ico"
$failedIconPath = "$PSScriptRoot\failed.ico"
$json = "$PSScriptRoot\settings.json"

# Define settings
if (-not (Test-Path $json)) {

	# Define default settings as a hashtable
	$defaultSettings = @{
		interval = 2
		backdrop = 2
		chocolatey = $false
		winget = $true
		scoop = $true
	}

	$jsonContent = $defaultSettings | ConvertTo-Json
	$jsonContent | Out-File -FilePath $json -Encoding UTF8
}
$settingsJson = Get-Content -Path $json | ConvertFrom-Json

# Timer interval between checks (hours to milliseconds)
$timerInterval = $settingsJson.interval*60*60*1000

# Create and configure the NotifyIcon object
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($defaultIconPath)

# Initialize Script variables
$Script:State = @{
	"ChocoAvailableUpdates" = @()
	"WingetAvailableUpdates" = @()
	"ScoopAvailableUpdates" = @()
	"ChocoPinnedUpdates" = @()
	"WingetPinnedUpdates" = @()
	"ScoopPinnedUpdates" = @()
	"ScoopFailedInstalls" = @()
}
$Script:update = @()
$Script:count = 0

# Show form
function Show-Form {
	param (
		[string]$title,
		[string]$text,
		[string[]]$packages
	)

	[xml]$xaml = @"
	<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
			xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
			Title="$title"
			SizeToContent="WidthAndHeight"
			ResizeMode="NoResize"
			WindowStartupLocation="CenterScreen"
			Icon="$updateIconPath"
			Background="Transparent">

		<Window.Resources>
			<Style TargetType="CheckBox">
				<Setter Property="Foreground" Value="{DynamicResource TextForegroundBrush}"/>
				<Setter Property="Template">
					<Setter.Value>
						<ControlTemplate TargetType="CheckBox">
							<StackPanel Orientation="Horizontal">
								<Border x:Name="CheckMarkBorder"
										BorderBrush="{DynamicResource TextForegroundBrush}"
										BorderThickness="1"
										Background="Transparent"
										CornerRadius="3">
									<Path x:Name="CheckMark"
										Stroke="{DynamicResource TextForegroundBrush}"
										StrokeThickness="1"
										Data="M1,8 L5,12 L13,2"
										Visibility="Hidden"/>
								</Border>
								<ContentPresenter Margin="5,0,0,0"/>
							</StackPanel>
							<ControlTemplate.Triggers>
								<Trigger Property="IsChecked" Value="True">
									<Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
								</Trigger>
								<Trigger Property="IsMouseOver" Value="True">
									<Setter TargetName="CheckMarkBorder" Property="BorderBrush" Value="Gray"/>
								</Trigger>
							</ControlTemplate.Triggers>
						</ControlTemplate>
					</Setter.Value>
				</Setter>
			</Style>

			<Style TargetType="Button">
				<Setter Property="Foreground" Value="{DynamicResource TextForegroundBrush}"/>
				<Setter Property="Template">
					<Setter.Value>
						<ControlTemplate TargetType="Button">
							<Border x:Name="ButtonBorder"
									Background="Transparent"
									BorderBrush="{DynamicResource TextForegroundBrush}"
									BorderThickness="1"
									CornerRadius="3">
								<ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
							</Border>
							<ControlTemplate.Triggers>
								<Trigger Property="IsMouseOver" Value="True">
									<Setter TargetName="ButtonBorder" Property="BorderBrush" Value="Gray"/>
								</Trigger>
								<Trigger Property="IsFocused" Value="True">
									<Setter TargetName="ButtonBorder" Property="BorderBrush" Value="Gray"/>
								</Trigger>
							</ControlTemplate.Triggers>
						</ControlTemplate>
					</Setter.Value>
				</Setter>
			</Style>

			<Style TargetType="ListBoxItem">
				<Setter Property="IsTabStop" Value="False"/>
				<Setter Property="Template">
					<Setter.Value>
						<ControlTemplate TargetType="ListBoxItem">
							<Border Padding="2">
								<ContentPresenter/>
							</Border>
						</ControlTemplate>
					</Setter.Value>
				</Setter>
			</Style>
		</Window.Resources>

		<Grid Margin="10">
			<Grid.RowDefinitions>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="*"/>
				<RowDefinition Height="Auto"/>
			</Grid.RowDefinitions>

			<TextBlock x:Name="LabelText" TextWrapping="Wrap" Foreground="{DynamicResource TextForegroundBrush}" Margin="5">$text</TextBlock>

			<ListBox x:Name="ListBoxItems" Grid.Row="1" SelectionMode="Multiple" BorderThickness="0" Padding="5" Background="Transparent">
				<ListBox.ItemTemplate>
					<DataTemplate>
						<CheckBox Content="{Binding Name}"
								IsChecked="{Binding IsChecked, Mode=TwoWay}"/>
					</DataTemplate>
				</ListBox.ItemTemplate>
			</ListBox>

			<StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="5">
				<Button x:Name="YesButton" Content="Yes" MinWidth="75" Margin="5"/>
				<Button x:Name="NoButton" Content="No" MinWidth="75" Margin="5"/>
			</StackPanel>
		</Grid>
	</Window>
"@

	$reader = New-Object System.Xml.XmlNodeReader $xaml
	$window = [Windows.Markup.XamlReader]::Load($reader)

	$window.Add_Loaded({
		# Constants
		$DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
		$DWMWA_SYSTEMBACKDROP_TYPE = 38;

		$windowsBuild = [System.Environment]::OSVersion.Version

		$theme = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"

		# Handle newlines in text
		$textBlock = $window.FindName("LabelText")
		$textBlock.Inlines.Clear()
		$lines = $text -split "`n"

		for ($i = 0; $i -lt $lines.Count; $i++) {
			$textBlock.Inlines.Add($lines[$i])
			if ($i -lt $lines.Count - 1) {
				$textBlock.Inlines.Add([System.Windows.Documents.LineBreak]::new())
			}
		}

		# Check compatibility
		if ($windowsBuild.Build -ge 22000) {
			# Get handles
			$helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
			$hwnd = $helper.Handle
			$src = [System.Windows.Interop.HwndSource]::FromHwnd($hwnd)

			# Set transparent backgrond color
			# and extend frame across entire window
			$src.CompositionTarget.BackgroundColor = [System.Windows.Media.Colors]::Transparent
			[DwmApi]::ExtendFrame($hwnd)

			# Set title bar and text color
			If ($theme.AppsUseLightTheme -eq 0) {
				$window.Resources["TextForegroundBrush"] = [System.Windows.Media.Brushes]::White
				[DwmApi]::SetDwmAttrib($hwnd, $DWMWA_USE_IMMERSIVE_DARK_MODE, $true)
			} else {
				$window.Resources["TextForegroundBrush"] = [System.Windows.Media.Brushes]::Black
			}

			# Set backdrop
			# Check compatibility
			if ($windowsBuild.Build -ge 22621) {
				[DwmApi]::SetDwmAttrib($hwnd, $DWMWA_SYSTEMBACKDROP_TYPE, $settingsJson.backdrop)
			}
		} else {
			$window.Background = [System.Windows.Media.Brushes]::White
			$window.Resources["TextForegroundBrush"] = [System.Windows.Media.Brushes]::Black
		}
	})

	$listBox = $window.FindName("ListBoxItems")
	$yesButton = $window.FindName("YesButton")
	$noButton = $window.FindName("NoButton")

	# Populate data (with data binding)
	$items = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
	foreach ($package in $packages) {
		$items.Add([PSCustomObject]@{ Name = $package; IsChecked = $true })
	}
	$listBox.ItemsSource = $items

	$yesButton.Add_Click({
		$window.DialogResult = $true
		$window.Close()
	})

	$noButton.Add_Click({
		$window.DialogResult = $false
		$window.Close()
	})

	if ($window.ShowDialog() -eq $true) {
		return $items | Where-Object { $_.IsChecked -eq $true } | ForEach-Object { $_.Name }
	}
}

# Update the state
function Update-State {
	param (
		[string]$outputChoco,
		[object]$outputWinget,
		[object]$outputScoopStatus
	)

	# Chocolatey
	if ($settingsJson.chocolatey) {
		$text = $outputChoco -split "`n"
		$updateLines = $text | Where-Object { $_.Trim() -ne "" }
		$availableUpdates = $updateLines | Where-Object {
			$_ -match '^\s*[^|]+\|[^|]+\|[^|]+\|(?:true|false)\s*$'
		}
		$structuredUpdates = $availableUpdates | ForEach-Object {
			$parts = $_ -split '\|'
			[PSCustomObject]@{
				Id = $parts[0].Trim()
				Pinned = $parts[3].Trim()
			}
		}
		$availableUpdates = @($structuredUpdates | Where-Object {
			$_.Pinned -ne 'true'
		})
		$pinnedUpdates = $structuredUpdates | Where-Object {
			$_.Pinned -eq 'true'
		}
		$Script:State["ChocoPinnedUpdates"] = $pinnedUpdates.Id

		if ($availableUpdates.Count -gt 0) {
			$Script:State["ChocoAvailableUpdates"] = $availableUpdates.Id
		}
	}

	# Winget
	if ($settingsJson.winget) {
		$id = $outputWinget | Where-Object { $_.IsUpdateAvailable -eq $true } | Select-Object -ExpandProperty Id

		if ($id.Count -gt 0) {
			$Script:State["WingetAvailableUpdates"] = $id
		}
	}

	# Scoop
	if ($settingsJson.scoop) {
		$Script:State["ScoopAvailableUpdates"] = $outputScoopStatus | Where-Object { $_ -notmatch "Held package" -and $_ -notmatch "Install failed" } | Select-Object -ExpandProperty Name
		$Script:State["ScoopPinnedUpdates"] = $outputScoopStatus | Where-Object { $_ -match "Held package" } | Select-Object -ExpandProperty Name
		$Script:State["ScoopFailedInstalls"] = $outputScoopStatus | Where-Object { $_ -match "Install failed" } | Select-Object -ExpandProperty Name
	}
}

# Clean up failed installs
function Remove-FailedInstall {
	if ($Script:State["ScoopFailedInstalls"].Count -gt 0) {
		$failedPackages = $Script:State["ScoopFailedInstalls"] -join ' '

		$outputScoopCleanup = scoop cleanup $failedPackages
	}
}

# Initialize the HashSet with the list
function Initialize-HashSet {
	param (
		[string[]]$list
	)
	return [System.Collections.Generic.HashSet[string]]::new($list)
}

# Get process matching udpate list
function Get-RunningProcess {
	param (
		[string[]]$selectedPackages
	)

	# Initialize the HashSet
	$updateHashSet = Initialize-HashSet -list $selectedPackages

	# Get the list of running processes with command line arguments
	$processes = Get-CimInstance -ClassName Win32_Process | ForEach-Object {
		$path = $_.ExecutablePath
		if ($path -and $path -like (Join-Path $env:USERPROFILE "\scoop\apps\*")) {
			$package = ($path -split [regex]::Escape("\scoop\apps\"))[1] -split '\\' | Select-Object -First 1
			[PSCustomObject]@{
				Id			= $_.ProcessId
				ProcessName	= $_.Name
				Path		= $path
				Package		= $package.ToLower()
				CommandLine	= $_.CommandLine
			}
		}
	}

	# Find matches between running processes and update list
	$matchingProcesses = @($processes | Where-Object {
		$updateHashSet.Contains($_.Package) -and $selectedPackages.Contains($_.Package)
	})

	if ($matchingProcesses.Count -gt 0) {
		$message = "Do you want to terminate the following processes that are running and match the update list:"
		$title = "Termination"

		$result = Show-Form -title $title -text $message -packages $matchingProcesses.ProcessName

		if ($result) {
			# Store the command lines of the matching processes
			$commandLine = $matchingProcesses | ForEach-Object { $_.CommandLine }

			# Terminate the matching processes
			$matchingProcesses | ForEach-Object {
				Stop-Process -Id $_.Id -Force
			}
			return $commandLine
		} else {
			return $false
		}
	}
}

# Update packages
function Update-Package {
	param (
		[string]$manager,
		[string[]]$package
	)

	if ($manager -in @("choco", "winget")) {
		$package | ForEach-Object {
			Start-Process "cmd.exe" -ArgumentList "/c $manager upgrade $_" -WindowStyle Minimized -Wait
		}
	}
	elseif ($manager -eq "scoop") {
		$package | ForEach-Object {
			Start-Process "cmd.exe" -ArgumentList "/c scoop update $_" -WindowStyle Minimized -Wait
		}
		scoop cleanup * -k
	}
}

# Restart terminated processes
function Restart-TerminatedProcess {
	param (
		[string[]]$process
	)

	foreach ($commandLine in $process) {
		# Split the command line into the executable path and arguments
		$commandLine -match '^"([^"]+)"\s*(.*)'
		$path = $matches[1]
		$arguments = $matches[2]

		# Determine if the process should be restarted
		if ($arguments) {
			Start-Process -FilePath $path -ArgumentList $arguments
		} else {
			Start-Process -FilePath $path
		}
	}
}

# Set the NotifyIcon tooltip text with a character limit
function Set-NotifyIconTooltip {
	param (
		[string]$fullText
	)
	$characterLimit = 59

	if ($fullText.Length -gt $characterLimit) {
		$lastSpaceIndex = $fullText.LastIndexOf(' ', $characterLimit)
		$tooltipText = $fullText.Substring(0, $lastSpaceIndex) + " ..."
	} else {
		$tooltipText = $fullText
	}
	$notifyIcon.Text = $tooltipText
}

# Check for updates, update the icon and tooltip
function Update-NotifyIcon {
	$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($defaultIconPath)
	Set-NotifyIconTooltip -fullText 'Checking for updates...'

	if (-not (Test-Connection github.com -Count 1 -Quiet)) {
		Set-NotifyIconTooltip -fullText "Error: Check internet connection"
		New-BurntToastNotification -Text Error, "Check internet connection" -AppLogo $defaultIconPath
	} else {
		if ($settingsJson.choco) {
			$outputChoco = choco outdated
		}

		if ($settingsJson.winget) {
			$outputWinget = Get-WinGetPackage
		}

		if ($settingsJson.scoop) {
			scoop update
			$outputScoopStatus = scoop status
		}

		# Reset the state
		$Script:State["ChocoAvailableUpdates"] = @()
		$Script:State["WingetAvailableUpdates"] = @()
		$Script:State["ScoopAvailableUpdates"] = @()
		$Script:State["ChocoPinnedUpdates"] = @()
		$Script:State["WingetPinnedUpdates"] = @()
		$Script:State["ScoopPinnedUpdates"] = @()
		$Script:State["ScoopFailedInstalls"] = @()
		$Script:count = 0
		$Script:update = @()

		if ($outputChoco) {
			Update-State -outputChoco $outputChoco
			Write-Output "Pinned Packages: $($Script:State["ChocoPinnedUpdates"] -join ", ")"
			Write-Output "Available Updates: $($Script:State["ChocoAvailableUpdates"] -join ", ")"

			if ($Script:State["ChocoAvailableUpdates"].Count -gt 0) {
				$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($updateIconPath)
				$Script:count += $Script:State["ChocoAvailableUpdates"].Count
				$Script:update += $Script:State["ChocoAvailableUpdates"]
			}
		}

		if ($outputWinget) {
			Update-State -outputWinget $outputWinget
			Write-Output "Pinned Packages: $($Script:State["WingetPinnedUpdates"] -join ", ")"
			Write-Output "Available Updates: $($Script:State["WingetAvailableUpdates"] -join ", ")"

			if ($Script:State["WingetAvailableUpdates"].Count -gt 0) {
				$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($updateIconPath)
				$Script:count += $Script:State["WingetAvailableUpdates"].Count
				$Script:update += $Script:State["WingetAvailableUpdates"]
			}
		}

		if ($outputScoopStatus) {
			Update-State -outputScoopStatus $outputScoopStatus
			Write-Output "Held Packages: $($Script:State["ScoopPinnedUpdates"] -join ", ")"
			Write-Output "Available Updates: $($Script:State["ScoopAvailableUpdates"] -join ", ")"

			if ($Script:State["ScoopAvailableUpdates"].Count -gt 0) {
				$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($updateIconPath)
				$Script:count += $Script:State["ScoopAvailableUpdates"].Count
				$Script:update += $Script:State["ScoopAvailableUpdates"]
			}

			if ($Script:State["ScoopFailedInstalls"].Count -gt 0) {
				$failedList = $Script:ScoopState["FailedInstalls"] -join ', '
				New-BurntToastNotification -Text "Install failed, cleaned up", "$failedList" -AppLogo $failedIconPath
				Remove-FailedInstall
			}
		}

		if ($Script:count -gt 0) {
			$Script:update = $Script:update -join ', '
			Set-NotifyIconTooltip -fullText "$Script:count update(s) available:`n$Script:update"
			New-BurntToastNotification -Text "Updates Available", "$Script:count update(s) available:`n$Script:update" -AppLogo $updateIconPath
		} else {
			$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($defaultIconPath)
			Set-NotifyIconTooltip -fullText 'All applications are up to date'
			$Script:update = ""
		}
	}
}

# Helper function to create a menu item
function New-MenuItem {
	param (
		[string]$text,
		$action,
		[bool]$isEnabled = $true
	)
	$menuItem = New-Object System.Windows.Forms.MenuItem
	$menuItem.Text = $text
	$menuItem.Enabled = $isEnabled
	if ($action) {
		$menuItem.Add_Click($action)
	}
	return $menuItem
}

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenu
$contextMenu.MenuItems.Add((New-MenuItem -text 'UniTray' -action $null -isEnabled $false)) | Out-Null # Header
$contextMenu.MenuItems.Add((New-MenuItem -text '-')) | Out-Null # Separator
$contextMenu.MenuItems.Add((New-MenuItem -text 'Check for updates' -action { Update-NotifyIcon })) | Out-Null
$contextMenu.MenuItems.Add((New-MenuItem -text 'Update all' -action {
	if ($Script:count -gt 0) {
		$message = "Are you sure you want to update all?`nThe following updates are available:"

		if ($Script:State["ChocoAvailableUpdates"]) {
			$resultChoco = Show-Form -title "Chocolatey" -text $message -packages $Script:State["ChocoAvailableUpdates"]
		}
		
		if ($Script:State["WingetAvailableUpdates"]) {
			$resultWinget = Show-Form -title "Winget" -text $message -packages $Script:State["WingetAvailableUpdates"]
		}
		
		if ($Script:State["ScoopAvailableUpdates"]) {
			$resultScoop = Show-Form -title "Scoop" -text $message -packages $Script:State["ScoopAvailableUpdates"]
		}

		if ($resultChoco) {
			Update-Package -manager "choco" -package $resultChoco
		}
		
		if ($resultWinget) {
			Update-Package -manager "winget" -package $resultWinget
		}
		
		if ($resultScoop) {
			$terminatedProcesses = Get-RunningProcess -selectedPackages $resultScoop
			if ($terminatedProcesses -eq $false) {
				return
			} elseif ($terminatedProcesses -ne $null) {
				Update-Package -manager "scoop" -package $resultScoop
				Restart-TerminatedProcess -process $terminatedProcesses
			} else {
				# If no processes to terminate, proceed with the update
				Update-Package -manager "scoop" -package $resultScoop
			}
		} else {
			return
		}

		if ($resultChoco -or $resultWinget -or $resultScoop) {
			Update-NotifyIcon
		}
	}
})) | Out-Null
$contextMenu.add_Popup({
	$menuItem = $contextMenu.MenuItems | Where-Object { $_.Text -eq 'Update all' }
	if ($menuItem) {
		$menuItem.Enabled = $Script:count -gt 0
	}
})
$contextMenu.MenuItems.Add((New-MenuItem -text 'Exit' -action { $notifyIcon.Visible = $false; [System.Windows.Forms.Application]::Exit() })) | Out-Null

# Assign the context menu to the NotifyIcon
$notifyIcon.ContextMenu = $contextMenu

# Timer setup to check for updates periodically
$timer = New-Object System.Windows.Forms.Timer -Property @{ Interval = $timerInterval; Enabled = $true }
$timer.Add_Tick({ Update-NotifyIcon })
$timer.Start()

# Initial check for updates and keep the script running
Update-NotifyIcon
[System.GC]::Collect()
[void] [System.Windows.Forms.Application]::Run()
