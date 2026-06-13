# ===== Firebase Config =====
$firebaseUrl = "https://setttingpowershell-default-rtdb.asia-southeast1.firebasedatabase.app/"

# ===== Get HWID =====
function Get-HWID {
    return (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
}

# ===== Check License =====
function Check-License {
    param($key)

    $hwid = Get-HWID
    $url  = "$firebaseUrl/licenses/$key.json"

    try {
        $data = Invoke-RestMethod -Uri $url -Method Get

        if ($null -eq $data) {
            Write-Host "Invalid Key" -ForegroundColor Red
            exit
        }

        if ($data.active -ne $true) {
            Write-Host "Invalid Key" -ForegroundColor Red
            exit
        }

        # ไม่ล็อค HWID
        if ($data.hwid -eq "any") {
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        # ผูก HWID อัตโนมัติครั้งแรก
        elseif ($null -eq $data.hwid -or $data.hwid -eq "null") {
            $body = '{"hwid":"' + $hwid + '"}'
            Invoke-RestMethod -Uri "$firebaseUrl/licenses/$key.json" `
                -Method Patch `
                -Body $body `
                -ContentType "application/json" | Out-Null
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        # HWID ตรง = ผ่าน
        elseif ($data.hwid -eq $hwid) {
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        # HWID ไม่ตรง = บล็อก
        else {
            Write-Host "HWID Invalid" -ForegroundColor Red
            exit
        }

    } catch {
        Write-Host "Cannot connect to server" -ForegroundColor Red
        exit
    }
}

# ===== Enter Key =====
Clear-Host
Write-Host "================================" -ForegroundColor Cyan
Write-Host "        Cheetos on top          " -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
$key = Read-Host "Enter License Key"

Check-License -key $key
Start-Sleep -Seconds 1

# ===== Menu =====
function Show-Menu {
    Clear-Host
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "          Setting GHETT         " -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Run - Ghett" -ForegroundColor Cyan
    Write-Host " [R] Reset - Ghett" -ForegroundColor Cyan
    Write-Host " [Q] Quit" -ForegroundColor Cyan
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Select"

    switch ($choice.ToUpper()) {
        "1" {
            Clear-Host
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host "          Setting GHETT         " -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ""

            $job = Start-Job -ScriptBlock {
                # สร้าง Restore Point ก่อน
                Checkpoint-Computer -Description "Cheetos Backup" -RestorePointType "MODIFY_SETTINGS"
                # คำสั่งปรับคอมตรงนี้
                # ===== QoS Policy FiveM =====
$fivemExe = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() |
    Where-Object { $_.DriveType -eq 'Fixed' } |
    ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe" }) `
    -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if ($fivemExe) {
    New-NetQosPolicy -Name "GGG" `
        -AppPathNameMatchCondition $fivemExe `
        -DSCPAction 46 `
        -IPProtocolMatchCondition TCP `
        -ErrorAction SilentlyContinue
}
                # Limit Reservable Bandwidth = 0%
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force

                # Set Timer Resolution = Enabled
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Multimedia" -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
                # ===== citizenFX.ini =====
    $iniPath = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.DriveType -eq 'Fixed' } | 
        ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.app\citizenFX.ini" }) `
        -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

    if ($iniPath) {
        $iniContent = @"
[Game]
IVPath=D:\GTAV\GTAV
UpdateChannel=beta
PoolSizesIncrease={"TxdStore":26000}
ReplaceExecutable=0
UpdateChannel=beta
DisableNvThreadOptimization=1
DisableHyperThreading=0
UseDirectInput=1
DisableNagleAlgorithm=1
HighPriority=1
SavedBuildNumber=2699
DisableLauncher=true
DisableCrashDump=1
DisableLogUpload=1
DisableTelemetry=1
UseHighPriorityThreads=1
UseAudioThread=1
ClearInvalidPoolCache=1
IgnoreDifferentVideoCard=1
DisableResourceTimeouts=1

[Input]
UseRawInput=1
DisableMouseSmoothing=1
DisableControllerDeadzone=1
LockMouseToWindow=1
RawInputBufferSize=512
RawInputBufferFlush=1
EnableLowLatencyInput=1
DisableKeyboardDebounce=1

[Renderer]
DisableVSync=1
ForceRenderAheadLimit=0
SwapChainUseWaitableSwapChain=1
EnableFramePacing=0
EnableTripleBuffering=0
DisableLatencyLimiter=1
WaitForVBlank=0
ReduceInputLatency=1
ImmediatePresent=1
DisableOcclusionQueries=1
DisableShadowOptimizations=false
EnablePresentationOptimizations=true
ForceRenderAheadLimit=1
DisableNvLowLatency=false
SwapChainUseWaitableSwapChain=true

[Streaming]
MaxStreamingRequests=50
MaxStreamingMemory=2000
MaxStreamingRequests=40
MaxStreamingMemory=4096
StreamerMode=0

DisableNVSP=0
DisableNvCache=0
SavedShaderCache=1
DisableAnalytics=1

net_mtu 1472
net_thread_priority 1
cl_interp_ratio 1
cl_interp 0
voice_sample_rate 24000
cl_forceStreamingPrefetch 0
r_textureStreaming 1
"@
        Set-Content -Path $iniPath -Value $iniContent -Force
    }

    # ===== FiveM.exe Properties =====
    $fivemExePath = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.DriveType -eq 'Fixed' } | 
        ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe" }) `
        -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

    if ($fivemExePath) {
        $shortcutArgs = "-nopickup -nomouselook -frameQueueLimit 1 -disableHyperthreading"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut("$env:USERPROFILE\Desktop\FiveM.lnk")
        $shortcut.TargetPath = $fivemExePath
        $shortcut.Arguments = $shortcutArgs
        $shortcut.Save()
    }
# ===== 2a_hex_ - Priority Separation =====
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x2a -Type DWord -Force

# ===== 10_Decimal_K - Keyboard Queue =====
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Value 10 -Type DWord -Force

# ===== 10_Decimal_M - Mouse Queue =====
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\mouclass\Parameters" -Name "MouseDataQueueSize" -Value 10 -Type DWord -Force

# ===== AVX =====
$avxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
Set-ItemProperty -Path $avxPath -Name "AVXTimeout" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2Timeout" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX512Timeout" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVXIsvlax" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2Threshold" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2FrequencyThreshold" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2DynamicIdlePowerPolicy" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2PriorityBoost" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2IdleFrequencyScaling" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVX2ThreadConcurrencyLimit" -Value 0x99 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVXUseLegacyROPEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVXContextSwitchDisable" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "AVXCPULoadRatio" -Value 100 -Type DWord -Force
Set-ItemProperty -Path $avxPath -Name "ProcessorIdleDisable" -Value 1 -Type DWord -Force

# ===== Cache =====
$cachePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$ffBytes = [byte[]](0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff)
Set-ItemProperty -Path $cachePath -Name "SecondLevelDataCache" -Value $ffBytes -Type Binary -Force
Set-ItemProperty -Path $cachePath -Name "ThirdLevelDataCache" -Value $ffBytes -Type Binary -Force
Set-ItemProperty -Path $cachePath -Name "ISRTimeout" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $cachePath -Name "DPCQueueDepth" -Value 100 -Type DWord -Force

# ===== Desktop Responsiveness =====
$desktopPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $desktopPath -Name "AutoEndTasks" -Value "1" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "HungAppTimeout" -Value "1000" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "MenuShowDelay" -Value "0" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "LowLevelHooksTimeout" -Value "1000" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "DisableProcessWindowsGhosting" -Value "1" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "ForegroundAutoRefresh" -Value "1" -Type String -Force
Set-ItemProperty -Path $desktopPath -Name "MaxWaitForInputIdle" -Value "1" -Type String -Force

# ===== Desktop =====
Set-ItemProperty -Path $desktopPath -Name "UseDoubleClickTimer" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $desktopPath -Name "IsClientAlwaysFirstResponse" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $desktopPath -Name "IsServerAlwaysFirstResponse" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $desktopPath -Name "ClientFastPath" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $desktopPath -Name "ServerFastPath" -Value 1 -Type DWord -Force

# ===== GPURenderAheadLimit =====
$gpuPath1 = "HKCU:\Software\Microsoft\Avalon.Graphics"
if (!(Test-Path $gpuPath1)) { New-Item -Path $gpuPath1 -Force | Out-Null }
Set-ItemProperty -Path $gpuPath1 -Name "GPURenderAheadLimit" -Value 0 -Type DWord -Force

$gpuPath2 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-ItemProperty -Path $gpuPath2 -Name "GPURenderAheadLimit" -Value 0 -Type DWord -Force

$gpuPath3 = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\DCI"
if (!(Test-Path $gpuPath3)) { New-Item -Path $gpuPath3 -Force | Out-Null }
Set-ItemProperty -Path $gpuPath3 -Name "Timeout" -Value 4 -Type DWord -Force

# ===== Graphics =====
$gdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (!(Test-Path $gdPath)) { New-Item -Path $gdPath -Force | Out-Null }
Set-ItemProperty -Path $gdPath -Name "HwSchMode" -Value 2 -Type DWord -Force

# ===== Kernel DPC Timer =====
$kernelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
if (!(Test-Path $kernelPath)) { New-Item -Path $kernelPath -Force | Out-Null }
Set-ItemProperty -Path $kernelPath -Name "DistributeTimers" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "GlobalTimerResolutionRequests" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "ThreadDpcEnable" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "SplitLargeCaches" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "DpcTimeout" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "DpcWatchdogPeriod" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "DpcWatchdogProfileOffset" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "MinimumDpcRate" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "DpcQueueDepth" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "IdealDpcRate" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "MaximumDpcQueueDepth" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $kernelPath -Name "AdjustDpcThreshold" -Value 0 -Type DWord -Force

$smPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
Set-ItemProperty -Path $smPath -Name "AlpcWakePolicy" -Value 1 -Type DWord -Force

$winPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Windows"
if (!(Test-Path $winPath)) { New-Item -Path $winPath -Force | Out-Null }
Set-ItemProperty -Path $winPath -Name "ErrorMode" -Value 2 -Type DWord -Force

# ===== LowLatency =====
$powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
Set-ItemProperty -Path $powerPath -Name "ExitLatency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "ExitLatencyCheckEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "Latency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "LatencyToleranceDefault" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "LatencyToleranceFSVP" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "LatencyTolerancePeerOverride" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "LatencyToleranceScreenOffIR" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $powerPath -Name "RtlCapabilityCheckLatency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$gpuPowerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power"
if (!(Test-Path $gpuPowerPath)) { New-Item -Path $gpuPowerPath -Force | Out-Null }
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyActivelyUsed" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyIdleLongTime" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyIdleMonitorOff" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyIdleNoContext" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyIdleShortTime" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultD3TransitionLatencyIdleVeryLongTime" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceIdle0" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceIdle0MonitorOff" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceIdle1" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceIdle1MonitorOff" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceMemory" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceNoContext" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceNoContextMonitorOff" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceOther" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultLatencyToleranceTimerPeriod" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultMemoryRefreshLatencyToleranceActivelyUsed" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultMemoryRefreshLatencyToleranceMonitorOff" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "DefaultMemoryRefreshLatencyToleranceNoContext" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "Latency" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "MaxIAverageGraphicsLatencyInOneBucket" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "MiracastPerfTrackGraphicsLatency" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "MonitorLatencyTolerance" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "MonitorRefreshLatencyTolerance" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gpuPowerPath -Name "TransitionLatency" -Value 1 -Type DWord -Force

$desktopLLPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $desktopLLPath -Name "AutoEndTasks" -Value "1" -Type String -Force
Set-ItemProperty -Path $desktopLLPath -Name "HungAppTimeout" -Value "1000" -Type String -Force
Set-ItemProperty -Path $desktopLLPath -Name "MenuShowDelay" -Value "8" -Type String -Force
Set-ItemProperty -Path $desktopLLPath -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
Set-ItemProperty -Path $desktopLLPath -Name "LowLevelHooksTimeout" -Value "1000" -Type String -Force

# ===== Misc =====
$ctrlPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
Set-ItemProperty -Path $ctrlPath -Name "NdisPacketQueueDepth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "LoadAppInit_DLLs" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "NoWaitNetIO" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "PreemptiveMultiTasking" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IRQThrottleRatio" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "CPUPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "ProcessorPStatePolicy" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IdleTimeAction" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DMABurstMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "MaxPerformance" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "LocalLoadHigh" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "KeyBoostTime" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "OptimizePerformance" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DisableBackgroundInput" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "CPUSave" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "PreemptiveYield" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "MinDelay" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DisableInputTimeout" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DisableHooksTimeout" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DisableFullScreenSync" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "DisableDelayIPC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "EsbScheduler" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "PageAlignedIo" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "SoundBuffer" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "EnhancedKeyboardBuffer" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IORate" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue

# ===== Mouse Keyboard =====
$mousePath = "HKCU:\Control Panel\Mouse"
Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0" -Type String -Force
Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0" -Type String -Force
Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0" -Type String -Force
$smoothX = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0xcc,0x0c,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
$smoothY = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe0,0x00,0x00,0x00,0x00,0x00)
Set-ItemProperty -Path $mousePath -Name "SmoothMouseXCurve" -Value $smoothX -Type Binary -Force
Set-ItemProperty -Path $mousePath -Name "SmoothMouseYCurve" -Value $smoothY -Type Binary -Force

$kbResponsePath = "HKCU:\Control Panel\Accessibility\Keyboard Response"
if (!(Test-Path $kbResponsePath)) { New-Item -Path $kbResponsePath -Force | Out-Null }
Set-ItemProperty -Path $kbResponsePath -Name "AutoRepeatDelay" -Value "500" -Type String -Force
Set-ItemProperty -Path $kbResponsePath -Name "AutoRepeatRate" -Value "20" -Type String -Force
Set-ItemProperty -Path $kbResponsePath -Name "DelayBeforeAcceptance" -Value "0" -Type String -Force
Set-ItemProperty -Path $kbResponsePath -Name "Flags" -Value "27" -Type String -Force
Set-ItemProperty -Path $kbResponsePath -Name "BounceTime" -Value "0" -Type String -Force

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseDoubleClickTimer" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$scriptPath1 = "HKCU:\Software\Microsoft\Windows Script Host\Settings"
if (!(Test-Path $scriptPath1)) { New-Item -Path $scriptPath1 -Force | Out-Null }
Set-ItemProperty -Path $scriptPath1 -Name "MaxWaitForScript" -Value 1 -Type DWord -Force

$joystickPath = "HKCU:\System\CurrentControlSet\Control\MediaProperties\PrivateProperties\Joystick\Winmm"
if (!(Test-Path $joystickPath)) { New-Item -Path $joystickPath -Force | Out-Null }
Set-ItemProperty -Path $joystickPath -Name "LatencyBuffer" -Value 1 -Type DWord -Force

# ===== PagingExecutive and LargeSystemCache =====
$memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $memPath -Name "DisablePagingExecutive" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $memPath -Name "LargeSystemCache" -Value 0 -Type DWord -Force

# ===== Scripts =====
$scriptPath2 = "HKLM:\Software\Microsoft\Windows Script Host\Settings"
if (!(Test-Path $scriptPath2)) { New-Item -Path $scriptPath2 -Force | Out-Null }
Set-ItemProperty -Path $scriptPath2 -Name "MaxWaitForScript" -Value 1 -Type DWord -Force

# ===== System =====
$pcPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
Set-ItemProperty -Path $pcPath -Name "AVX2PriorityBoost" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $pcPath -Name "Win32TimeSlice" -Value 1 -Type DWord -Force

Set-ItemProperty -Path $ctrlPath -Name "ThreadQuantum" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "BoostPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "GroupPriorityBias" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IsClientAlwaysFastPath" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IsServerAlwaysFastPath" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "IsClientAlwaysFastResponse" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "ClientFastPath" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "ServerFastPath" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ctrlPath -Name "SystemResponsiveness" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# ===== USB Power =====
$usbPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
Set-ItemProperty -Path $usbPath -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$usbFlagsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\usbflags"
if (!(Test-Path $usbFlagsPath)) { New-Item -Path $usbFlagsPath -Force | Out-Null }
Set-ItemProperty -Path $usbFlagsPath -Name "fid_D1Latency" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $usbFlagsPath -Name "fid_D2Latency" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $usbFlagsPath -Name "fid_D3Latency" -Value 0 -Type DWord -Force

# Disable USB Idle for all USB classes
$usbClassBase = "HKLM:\SYSTEM\CurrentControlSet\Services\Class\USB"
0..31 | ForEach-Object {
    $usbClassPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Class\USB{0:D4}" -f $_
    if (Test-Path $usbClassPath) {
        Set-ItemProperty -Path $usbClassPath -Name "IdleEnable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}
# ===== latency_networkx.reg =====
    $tcpipPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    Set-ItemProperty -Path $tcpipPath -Name "TcpTimedWaitDelay" -Value 0x1e -Type DWord -Force
    Set-ItemProperty -Path $tcpipPath -Name "DefaultTTL" -Value 0x40 -Type DWord -Force
    Set-ItemProperty -Path $tcpipPath -Name "EnableTCPA" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $tcpipPath -Name "EnableRSS" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $tcpipPath -Name "EnablePMTUDiscovery" -Value 1 -Type DWord -Force

    # ===== Network Adapter (Realtek 2.5GbE) =====
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    if ($adapter) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
        $adapterKey = Get-ChildItem $regPath | Where-Object {
            (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $adapter.InterfaceGuid
        }
        if ($adapterKey) {
            # Transmit Buffers = 64
            Set-ItemProperty -Path $adapterKey.PSPath -Name "*TransmitBuffers" -Value "64" -Type String -Force -ErrorAction SilentlyContinue
            # Jumbo Frame = 9014 Bytes
            Set-ItemProperty -Path $adapterKey.PSPath -Name "*JumboPacket" -Value "9014" -Type String -Force -ErrorAction SilentlyContinue
            # Shutdown Wake-On-Lan = Disabled
            Set-ItemProperty -Path $adapterKey.PSPath -Name "*WakeOnMagicPacket" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $adapterKey.PSPath -Name "*WakeOnPattern" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
            # Receive Buffers = 32
            Set-ItemProperty -Path $adapterKey.PSPath -Name "*ReceiveBuffers" -Value "32" -Type String -Force -ErrorAction SilentlyContinue
        }
    }            
            # ===== DNS 1.1.1.1 / 1.0.0.1 =====
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
    }
    # ===== TCP Global Settings =====
    $tcpCmds = @(
        "netsh int tcp set global rss=enabled",
        "netsh int tcp set global dca=enabled",
        "netsh int tcp set global netdma=enabled",
        "netsh int tcp set global chimney=disabled",
        "netsh int tcp set global rsc=disabled",
        "netsh int tcp set global ecncapability=disabled",
        "netsh int tcp set global timestamps=disabled",
        "netsh int tcp set global nonsackrttresiliency=disabled",
        "netsh int tcp set global autotuninglevel=disabled",
        "netsh int tcp set global fastopen=enabled",
        "netsh int tcp set global fastopenfallback=enabled",
        "netsh int tcp set global maxsynretransmissions=2",
        "netsh int tcp set global initialrto=2000",
        "netsh int tcp set global mincto=0",
        "netsh int tcp set global congestionprovider=ctcp",
        "netsh int tcp set supplemental congestionprovider=ctcp",
        "netsh int tcp set heuristics disabled",
        "netsh int ipv4 set glob defaultcurhoplimit=64",
        "netsh int ipv6 set glob defaultcurhoplimit=64",
        "netsh int ip set global taskoffload=enabled",
        "netsh int ip set global multicastforwarding=disabled",
        "netsh int ip set global reassemblylimit=0",
        "netsh int udp set global uro=disabled",
        "netsh int tcp set global memoryprofile=normal",
        "netsh int ipv6 set global randomizeidentifiers=disabled",
        "netsh int ipv6 set privacy state=disabled"
    )
    foreach ($cmd in $tcpCmds) {
        try { Invoke-Expression "$cmd 2>&1" | Out-Null } catch {}
    }

    # ===== Registry Interfaces =====
    $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $ifVals = [ordered]@{
        "MTU"=1500; 
        "MSS"=1460; 
        "TcpWindowSize"=65535
        "GlobalMaxTcpWindowSize"=65535; 
        "WorldMaxTcpWindowsSize"=65535
        "TcpAckFrequency"=1; 
        "TcpDelAckTicks"=0; 
        "TCPNoDelay"=1
        "TcpMaxDataRetransmissions"=3; 
        "TCPTimedWaitDelay"=30;
        "TCPInitialRtt"=300
        "TcpMaxDupAcks"=2; 
        "Tcp1323Opts"=1; 
        "SackOpts"=1
        "KeepAliveTime"=30000; 
        "KeepAliveInterval"=1000
        "MaxConnectionsPerServer"=16; 
        "MaxConnectionsPer1_0Server"=16
        "DefaultTTL"=64; 
        "EnablePMTUBHDetect"=0; 
        "EnablePMTUDiscovery"=1
        "DisableTaskOffload"=0; 
        "DisableLargeMTU"=0; 
        "IRPStackSize"=32
        "NumTcbTablePartitions"=4; 
        "MaxFreeTcbs"=65536; 
        "MaxUserPort"=65534
        "TcpMaxSendFree"=65535; 
        "MaxHashTableSize"=65536; 
        "DisableRss"=0
        "DisableTcpChimneyOffload"=1; 
        "EnableICMPRedirect"=0
        "EnableDHCP"=1; 
        "SynAttackProtect"=0
    }
    foreach ($kv in $ifVals.GetEnumerator()) {
        Set-ItemProperty -Path $ifPath -Name $kv.Key -Value $kv.Value -Type DWord -Force -ErrorAction SilentlyContinue
    }

    # ===== Registry Parameters =====
    $pPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    $pVals = [ordered]@{
        "MTU"=1500; 
        "MSS"=1460; 
        "TcpAckFrequency"=1; 
        "TcpDelAckTicks"=0
        "TCPNoDelay"=1; 
        "TcpWindowSize"=65535; 
        "GlobalMaxTcpWindowSize"=65535
        "SackOpts"=1; 
        "Tcp1323Opts"=1; 
        "TcpMaxDataRetransmissions"=3
        "TCPTimedWaitDelay"=30; 
        "IRPStackSize"=32; 
        "DefaultTTL"=64
        "KeepAliveTime"=30000; 
        "KeepAliveInterval"=1000; 
        "TCPInitialRtt"=300
        "TcpMaxDupAcks"=2; 
        "EnablePMTUBHDetect"=0; 
        "EnablePMTUDiscovery"=1
        "DisableTaskOffload"=0; 
      
        "MaxHashTableSize"=65536; 
        "MaxUserPort"=65534
        "MaxFreeTcbs"=65536; 
        "TcpMaxSendFree"=65535; 
        "DeadGWDetectDefault"=1
        "NumForwardPackets"=500; 
        "MaxNumForwardPackets"=500
        "ForwardBufferMemory"=196608; 
        "MaxForwardBufferMemory"=196608
        "SynAttackProtect"=0; 
        "EnableICMPRedirect"=0; 
        "NumTcbTablePartitions"=4
    }
    foreach ($kv in $pVals.GetEnumerator()) {
        Set-ItemProperty -Path $pPath -Name $kv.Key -Value $kv.Value -Type DWord -Force -ErrorAction SilentlyContinue
    }

    # ===== Priority Control =====
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue

    # ===== Multimedia SystemProfile =====
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    $gameProfile = "$mmPath\Tasks\Games"
    if (!(Test-Path $gameProfile)) { New-Item -Path $gameProfile -Force | Out-Null }
    Set-ItemProperty -Path $gameProfile -Name "Affinity" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "Background Only" -Value "False" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "Clock Rate" -Value 10000 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "GPU Priority" -Value 8 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "Priority" -Value 6 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "Scheduling Category" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gameProfile -Name "SFIO Priority" -Value "High" -Type String -Force -ErrorAction SilentlyContinue

    # ===== Process Priority =====
    $highList = @(
        "FiveM_b2545_GTAProcess","FiveM_b2699_GTAProcess","FiveM_b2802_GTAProcess",
        "FiveM_b2944_GTAProcess","FiveM_b3095_GTAProcess","FiveM_GTAProcess",
        "FiveM","FiveM_SteamChild","CitizenFX.Core",
        "VALORANT-Win64-Shipping","VALORANT",
        "cs2","csgo","RainbowSix","RainbowSix_BE",
        "r5apex","r5apex_dx12","EscapeFromTarkov",
        "Rust","RustClient","FortniteClient-Win64-Shipping",
        "PUBG","GenshinImpact","ZZZ","Overwatch","Overwatch_retail"
    )
    $lowList = @("steam","explorer","Discord","chrome","firefox","SearchApp","SearchHost","Widgets")

    foreach ($pn in $highList) {
        $proc = Get-Process -Name $pn -ErrorAction SilentlyContinue
        if ($proc) { try { $proc.PriorityClass = "High" } catch {} }
    }
    foreach ($pn in $lowList) {
        $proc = Get-Process -Name $pn -ErrorAction SilentlyContinue
        if ($proc) { try { $proc.PriorityClass = "BelowNormal" } catch {} }
    }

    # ===== Power / BCD =====
    try { powercfg -setactive SCHEME_MIN 2>&1 | Out-Null } catch {}
    try {
        $cpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
        if (Test-Path $cpuPath) { Set-ItemProperty -Path $cpuPath -Name "Attributes" -Value 2 -Type DWord -Force }
    } catch {}
    try { bcdedit /set useplatformclock false 2>&1 | Out-Null } catch {}
    try { bcdedit /set disabledynamictick yes 2>&1 | Out-Null } catch {}
    try { bcdedit /deletevalue useplatformhpet 2>&1 | Out-Null } catch {}

    # ===== Disable Services =====
    $svcs = @("SysMain","DiagTrack","dmwappushservice","WSearch","Fax","RemoteRegistry","RetailDemo","TabletInputService")
    foreach ($svc in $svcs) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
            }

            $spinner = @('/', '|', '\', '-')
            $i = 0
            while ($job.State -eq "Running") {
                Write-Host "`r Loading... $($spinner[$i % 4])" -NoNewline -ForegroundColor Cyan
                $i++
                Start-Sleep -Milliseconds 100
            }

            Receive-Job $job | Out-Null
            Remove-Job $job
            Write-Host "`r Done!              " -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter "
        }
        "R" {
            Clear-Host
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host "            Resetting           " -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ""

            $job = Start-Job -ScriptBlock {
                # ดึง Restore Point ที่สร้างไว้กลับมา
                $restore = Get-ComputerRestorePoint | Where-Object { $_.Description -eq "Cheetos Backup" } | Select-Object -Last 1
                if ($restore) {
                    Restore-Computer -RestorePoint $restore.SequenceNumber -Confirm:$false
                }
            }

            $spinner = @('/', '|', '\', '-')
            $i = 0
            while ($job.State -eq "Running") {
                Write-Host "`r Resetting... $($spinner[$i % 4])" -NoNewline -ForegroundColor Red
                $i++
                Start-Sleep -Milliseconds 100
            }

            Receive-Job $job | Out-Null
            Remove-Job $job
            Write-Host "`r Done!              " -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter "
        }
        "Q" {
            Write-Host "Exiting..." -ForegroundColor Gray
            Start-Sleep -Seconds 1
            exit 
        }
    }

} while ($choice.ToUpper() -ne "Q")"
$job = Start-Job -ScriptBlock 
}