# Mini-WinPs-Sudo
# Copyright (c) 2025 BossK73
# Licensed under the MIT License
# 
# 用于在 Windows 10 与 Windows 11 中以类 Linux 平台 Sudo 体验提升运行单条用户命令的 Windows PowerShell 5.1 脚本。
#
# 在命令提示符中不起作用。将代码复制到 Windows PowerShell 5.1 的配置文件中，并允许 PowerShell 执行本地脚本，执行 sudo 即可。
#
# 配置文件中的 sudo 优先级高于 Windows PowerShell 中的 Sudo-for-Windows，但对命令提示符中的 Sudo-for-Windows 无影响。
#
# 警告：这将会导致之后的 PowerShell 会话中存在 sudo 函数及相关变量，可能与之后用户输入的内容重名。
# 
# 有关配置文件和执行策略的描述，请参阅以下链接：
# https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1
# https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1 
# 
# V0.0.2
# 2025年9月20日
# 放弃上传先前存档的旧版本，在原型基础上彻底重构。移除有关 CMD 的无用代码，提高代码模块化程度，增加帮助、版本、查询、保持新窗口等共计4个参数，改变命令为空时的行为，增加ASCII字符画上色输出特性并优化显示速度

# Main Function
function Invoke-ElevatedCommand {
    [CmdletBinding(DefaultParameterSetName = "CommandSet")]
    [Alias("sudo")]
    param(
        # Help
        [Parameter(ParameterSetName = "HelpSet", Mandatory = $false)]
        [Alias("h")]
        [switch]$Help,
        # Version
        [Parameter(ParameterSetName = "HelpSet", Mandatory = $false)]
        [Alias("v")]
        [switch]$Version,
        # List
        [Parameter(ParameterSetName = "HelpSet", Mandatory = $false)]
        [Alias("l")]
        [switch]$List,
        # Command
        [Parameter(ParameterSetName = "CommandSet", Mandatory = $false, ValueFromRemainingArguments = $true,  Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Command,
        # KeepNewWindow
        [Parameter(ParameterSetName = "CommandSet", Mandatory = $false)]
        [Alias("k")]
        [switch]$KeepNewWindow
    )

    # Show Sudo CurrentVersion
    function Show-SudoCurrentVersion {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$false)]
            [Alias("S")]
            [switch]$Silent
        )
        $script:SudoCurrentSudoVerion = "V0.0.2 by BossK73@Github"
        if ($Silent) {
            return $script:SudoCurrentSudoVerion
        } else {
            Write-Host $script:SudoCurrentSudoVerion
        }
    }

    # Get Sudo Current Admin Role
    function Get-SudoCurrentAdminRole {
        if (-not (Get-Variable -Name "isSudoRunningAsAdminChecked" -Scope Global -ErrorAction SilentlyContinue)) {
            $global:isSudoRunningAsAdminChecked = $false
            $global:isSudoRunningAsAdmin = $false
        }
        if (-not $global:isSudoRunningAsAdminChecked) {
            $global:isSudoRunningAsAdmin = (
                [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator
            )
            $global:isSudoRunningAsAdminChecked = $true
        }
        return $global:isSudoRunningAsAdmin
    }

    # Get Sudo Ascii Art Script
    function Get-SudoAsciiArtScript {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $false)]
            [ConsoleColor]$BaseColor,
            [Parameter(Mandatory = $false)]
            [ConsoleColor]$TopColor,
            [Parameter(Mandatory = $false)]
            [ConsoleColor]$BottomColor,
            [Parameter(Mandatory = $false)]
            [ConsoleColor]$LeftColor
        )
        # Slant Relief Style
        $slantReliefStyleSudoAsciiArt = @'
_____/\\\\\\\\\\\____/\\\________/\\\__/\\\\\\\\\\\\__________/\\\\\______
 ___/\\\/////////\\\_\/\\\_______\/\\\_\/\\\////////\\\______/\\\///\\\____
  __\//\\\______\///__\/\\\_______\/\\\_\/\\\______\//\\\___/\\\/__\///\\\__
   ___\////\\\_________\/\\\_______\/\\\_\/\\\_______\/\\\__/\\\______\//\\\_
    ______\////\\\______\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_______\/\\\_
     _________\////\\\___\/\\\_______\/\\\_\/\\\_______\/\\\_\//\\\______/\\\__
      __/\\\______\//\\\__\//\\\______/\\\__\/\\\_______/\\\___\///\\\__/\\\____
       _\///\\\\\\\\\\\/____\///\\\\\\\\\/___\/\\\\\\\\\\\\/______\///\\\\\/_____
        ___\///////////________\/////////_____\////////////__________\/////_______
'@
        # Coloring
        $SudoAsciiArtScriptBuilder = New-Object System.Text.StringBuilder(5000) # Number 4357 was calculated by Gemini 2.5 Flash and revised by Deepseek Reasoner
        $null = $SudoAsciiArtScriptBuilder.Append("Write-Host '`n';")
        $lines = $slantReliefStyleSudoAsciiArt -split "`n"
        foreach ($line in $lines) {
            $charColorMap = [System.Collections.Generic.List[PSCustomObject]]::new(100) # Number 73 was calculated by Gemini 2.5 Flash
            $i = 0
            $lineLength = $line.Length
            $processed = [bool[]]::new($lineLength)
            while ($i -lt $lineLength) {
                if ($processed[$i]) {
                    $i++
                    continue
                }
                # "_\//"
                if ($i + 3 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '\' -and $line[$i+2] -eq '/' -and $line[$i+3] -eq '/') {
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i]; Color = $BaseColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+1]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+2]; Color = $BottomColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+3]; Color = $BottomColor})
                    ($i..($i+3)) | ForEach-Object { $processed[$_] = $true }
                    $i += 4
                    continue
                }
                # "_\/\"
                elseif ($i + 3 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '\' -and $line[$i+2] -eq '/' -and $line[$i+3] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i]; Color = $BaseColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+1]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+2]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+3]; Color = $TopColor})
                    ($i..($i+3)) | ForEach-Object { $processed[$_] = $true }
                    $i += 4
                    continue
                }
                # "_/\"
                elseif ($i + 2 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '/' -and $line[$i+2] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i]; Color = $BaseColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+1]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+2]; Color = $TopColor})
                    ($i..($i+2)) | ForEach-Object { $processed[$_] = $true }
                    $i += 3
                    continue
                }
                # Others
                else {
                    $currentChar = $line[$i]
                    [ConsoleColor]$segmentColor = [ConsoleColor]::Black
                    if ($currentChar -eq '_') {
                        $segmentColor = $BaseColor
                    } elseif ($currentChar -eq '\') {
                        $segmentColor = $TopColor
                    } elseif ($currentChar -eq '/') {
                        $segmentColor = $BottomColor
                    } else {
                        $segmentColor = [ConsoleColor]::Black
                    }
                    $charColorMap.Add([PSCustomObject]@{Char = $currentChar; Color = $segmentColor})
                    $processed[$i] = $true
                    $i += 1
                }
            }
            # Merge
            [ConsoleColor]$currentGroupColor = [ConsoleColor]::Black
            $currentGroupText = [System.Text.StringBuilder]::new()
            foreach ($charInfo in $charColorMap) {
                if ($currentGroupText.Length -eq 0) {
                    $null = $currentGroupText.Append($charInfo.Char)
                    $currentGroupColor = $charInfo.Color
                } elseif ($charInfo.Color -eq $currentGroupColor) {
                    $null = $currentGroupText.Append($charInfo.Char)
                } else {
                    if ($currentGroupText.Length -gt 0) {
                        $textToPrint = $currentGroupText.ToString()
                        $colorName = $currentGroupColor.ToString()
                        $null = $SudoAsciiArtScriptBuilder.Append("Write-Host -NoNewline '$textToPrint' -ForegroundColor $colorName;")
                    }
                    $null = $currentGroupText.Clear()
                    $null = $currentGroupText.Append($charInfo.Char)
                    $currentGroupColor = $charInfo.Color
                }
            }
            if ($currentGroupText.Length -gt 0) {
                $textToPrint = $currentGroupText.ToString()
                $colorName = $currentGroupColor.ToString()
                $null = $SudoAsciiArtScriptBuilder.Append("Write-Host -NoNewline '$textToPrint' -ForegroundColor $colorName;")
            }
            $null = $SudoAsciiArtScriptBuilder.Append("Write-Host '';")
        }
        $null = $SudoAsciiArtScriptBuilder.Append("Write-Host '`n';")
        return $SudoAsciiArtScriptBuilder.ToString()
    }

    # Show Sudo Help Information
    function Show-SudoHelpInformation {
        # Show Sudo Ascii Art
        # Admin Color
        $AdminSudoAsciiArtBaseColor = [ConsoleColor]::DarkBlue
        $AdminSudoAsciiArtTopColor = [ConsoleColor]::Yellow
        $AdminSudoAsciiArtBottomColor = [ConsoleColor]::DarkYellow
        $AdminSudoAsciiArtLeftColor = [ConsoleColor]::DarkRed
        # User Color
        $UserSudoAsciiArtBaseColor = [ConsoleColor]::DarkYellow
        $UserSudoAsciiArtTopColor = [ConsoleColor]::Cyan
        $UserSudoAsciiArtBottomColor = [ConsoleColor]::Blue
        $UserSudoAsciiArtLeftColor = [ConsoleColor]::DarkBlue
        # Check Cache
        if (-not (Get-Variable -Name "isSudoAsciiArtScriptBuilt" -Scope Global -ErrorAction SilentlyContinue)) {
            [bool]$global:isSudoAsciiArtScriptBuilt = $false
            [string]$global:SudoAsciiArtScript = $null
        }
        if (-not $global:isSudoAsciiArtScriptBuilt) {
            # Check Role
            if (Get-SudoCurrentAdminRole) {
                $global:SudoAsciiArtScript = (Get-SudoAsciiArtScript -BaseColor $AdminSudoAsciiArtBaseColor -TopColor $AdminSudoAsciiArtTopColor -BottomColor $AdminSudoAsciiArtBottomColor -LeftColor $AdminSudoAsciiArtLeftColor)
            } else {
                $global:SudoAsciiArtScript = (Get-SudoAsciiArtScript -BaseColor $UserSudoAsciiArtBaseColor -TopColor $UserSudoAsciiArtTopColor -BottomColor $UserSudoAsciiArtBottomColor -LeftColor $UserSudoAsciiArtLeftColor)
            }
            $global:isSudoAsciiArtScriptBuilt = $true
        }
        Invoke-Expression $global:SudoAsciiArtScript
        # Show Sudo Current Status
        Write-Host "适用于 Windows PowerShell 5.1 的 Sudo" -NoNewline; Write-Host " $(Show-SudoCurrentVersion -S)"
        Write-Host "可以从本地非管理员会话启动新窗口以提升执行单条用户命令"
        # Get Sudo Running Platform Compatibility
        if (-not (Get-Variable -Name "isSudoRunningOnTargetPlatformChecked" -Scope Global -ErrorAction SilentlyContinue)) {
            $global:isSudoRunningOnTargetPlatformChecked = $false
            $global:isSudoRunningOnTargetPlatform = $false
        }
        if (-not $global:isSudoRunningOnTargetPlatformChecked) {
            $global:isSudoRunningOnTargetPlatform = (
                $PSVersionTable.PSVersion.Major -eq 5 -and
                $PSVersionTable.PSVersion.Minor -eq 1 -and 
                $PSVersionTable.PSEdition -eq "Desktop"
            )
            $global:isSudoRunningOnTargetPlatformChecked = $true
        }
        if (-not $global:isSudoRunningOnTargetPlatform) {
            Write-Host "Sudo 正运行在未经测试的 Shell 中，可能引发未知错误"
        }
        # Show Sudo Current User
        if (Get-SudoCurrentAdminRole) {
            Write-Host "当前会话已取得管理员权限" -ForegroundColor $AdminSudoAsciiArtTopColor
        } else {
            Write-Host "当前会话未取得管理员权限" -ForegroundColor $UserSudoAsciiArtTopColor
        }
        # Show Sudo Usage
        Write-Host "用法" -NoNewline -ForegroundColor Green
        Write-Host "  sudo [-h] [-v] [-l] [-k] [Command]"
        Write-Host "参数" -NoNewline -ForegroundColor Green
        Write-Host "  -h   获取帮助"
        Write-Host "      -v   显示Sudo的版本号"
        Write-Host "      -l   列出由Sudo静默提升且目前仍在后台运行的任务"
        Write-Host "      -k   保持提升后的新命令行界面，请为交互式命令启用此选项"
        Write-Host "示例" -NoNewline -ForegroundColor Green
        Write-Host "  sudo notepad %SystemRoot%\system32\drivers\etc\hosts`n" 
    }

    # Get Sudo Temp Script Path
    function Get-SudoTempScriptPath {
        [CmdletBinding()]
        param()
        $tempFileName = [System.IO.Path]::GetTempFileName()
        $ps1Path = [System.IO.Path]::ChangeExtension($tempFileName, ".ps1")
        return $ps1Path
    }

    # Remove Sudo Temp File
    function Remove-SudoTempFile {
        [CmdletBinding(DefaultParameterSetName="Path")]
        param(
            [Parameter(Mandatory=$true, ParameterSetName="Path")]
            [string]$Path,
            [Parameter(Mandatory=$false, ParameterSetName="Path")]
            [switch]$Silent
        )
        if (Test-Path -Path $Path) {
            try {
                Remove-Item -Path $Path -Force -ErrorAction Stop
                if (-not $Silent) {
                    Write-Verbose "已成功删除临时文件: $Path"
                }
            } catch {
                if (-not $Silent) {
                    Write-Warning "无法删除临时文件 '$Path': $($_.Exception.Message)"
                }
            }
        }
    }

    # Get Sudo Running Elevated Process Background
    function Get-SudoRunningElevatedProcessBackground {
        try {
            # Need Admin Role
            $powershellProcesses = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction Stop
        }
        catch {
            Write-Error "无法获取进程信息，请检查WMI服务是否可用。 $($_.Exception.Message)"
            return
        }
        $guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
        $sudoTagPattern = "--SudoTag-$guidRegex"
        $foundProcesses = $powershellProcesses | Where-Object { $_.CommandLine -match "(?i)$sudoTagPattern" }
        if ($foundProcesses.Count -eq 0) {
            Write-Host "目前未发现由 sudo 启动的隐藏提升进程"
            return
        }
        $results = @()
        foreach ($process in $foundProcesses) {
            $commandLine = $process.CommandLine
            if ($commandLine -match "(?i)($sudoTagPattern)") {
                $sudoTag = $Matches[1]
                $results += [PSCustomObject]@{
                    PID = $process.ProcessId
                    SudoTag = $sudoTag
                    StartTime = $process.CreationDate
                }
            }
        }
        if ($results.Count -eq 0) {
            Write-Host "目前未发现由Sudo启动的后台提升进程"
        } else {
            Write-Host "找到以下由Sudo启动的后台提升进程：" -ForegroundColor Yellow
            $results | Format-Table -AutoSize
            Write-Host "`可以使用 'Stop-Process -Id <PID>' 终止这些进程" -ForegroundColor DarkGray
        }
    }

    # HelpSet
    if ($PSCmdlet.ParameterSetName -eq "HelpSet" ) {
        if ($Help) {
            Show-SudoHelpInformation
        }
        if ($Version) {
            Show-SudoCurrentVersion
        }
        if ($List) {
            if (-not (Get-SudoCurrentAdminRole)) {
                Write-Host "查询由Sudo启动且未退出的已提升后台进程需要管理员权限，等待用户批准" -ForegroundColor Yellow
                try {
                    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit -Command Invoke-ElevatedCommand -List" -Verb RunAs -Wait
                } catch {
                    Write-Error "查询失败: $($_.Exception.Message)"
                }
            } else {
                Get-SudoRunningElevatedProcessBackground
            } 
        }
    # CommandSet
    } else {
        # Get Location
        $currentWorkingDirectory = (Get-Location | Select-Object -ExpandProperty Path)
        # Null Command
        if ([string]::IsNullOrWhiteSpace($Command)) {
            # Admin
            if (Get-SudoCurrentAdminRole) {
                Show-SudoHelpInformation
            # Not Admin
            } else {
                # Search Windows Terminal
                if (-not (Get-Variable -Name "isSudoWindowsTerminalExistenceChecked" -Scope Global -ErrorAction SilentlyContinue)) {
                    $global:isSudoWindowsTerminalExistenceChecked = $false
                    $global:isSudoWindowsTerminalExisted = $false
                }
                if (-not $global:isSudoWindowsTerminalExistenceChecked) {
                    $global:isSudoWindowsTerminalExisted = (Get-Command "wt.exe" -ErrorAction SilentlyContinue)
                    $global:isSudoWindowsTerminalExistenceChecked = $true
                }
                # Start Windows Terminal if existed
                if ($global:isSudoWindowsTerminalExisted) {
                    try {
                        Start-Process -Verb RunAs wt.exe -ArgumentList "-p `"Windows PowerShell`" -d `"$currentWorkingDirectory`""
                    # Fallback to Windows Powershell
                    } catch {
                        Write-Error "提升Windows终端时出错: $($_.Exception.Message)"
                        $global:isSudoWindowsTerminalExisted = $false
                        Write-Warning "回退至powershell.exe执行，等待用户重新批准" -ForegroundColor Yellow 
                        Start-Sleep -Milliseconds 500
                        Start-Process -Verb RunAs powershell.exe -ArgumentList "-NoExit -Command Set-Location -Path '$currentWorkingDirectory'"
                    }
                # Start Windows Powershell
                } else {
                    Start-Process -Verb RunAs powershell.exe -ArgumentList "-NoExit -Command Set-Location -Path '$currentWorkingDirectory'"
                }
            }
        # Not Null Command
        } else {
            # Admin
            if (Get-SudoCurrentAdminRole) {
                try {
                    Invoke-Expression ([System.Environment]::ExpandEnvironmentVariables($Command))
                }
                catch {
                    Write-Error "执行当前命令时出错: $($_.Exception.Message)"
                }
            # Not Admin
            } else {
                $encodedUserCommandBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Command))
                try {
                    # Keep New Window
                    if ($KeepNewWindow) {
                        $scriptBlockToEncode = @"
Set-Location -Path '$currentWorkingDirectory';
try {
`$decodedUserCommand = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('$encodedUserCommandBase64'));
Invoke-Expression ([System.Environment]::ExpandEnvironmentVariables(`$decodedUserCommand));
} catch {
Write-Error "执行传递的命令序列时出错: `$(`$_.Exception.Message)`";
exit 1;
}
"@
                        $encodedScriptBlock = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptBlockToEncode))
                        Start-Process -Verb RunAs powershell.exe -ArgumentList @(
                            "-NoExit",
                            "-EncodedCommand", $encodedScriptBlock
                        )
                    # Hidden Window
                    } else {
                        $processTag = "--SudoTag-$(New-Guid)"
                        $tempScriptPath = Get-SudoTempScriptPath
                        $tempScriptContent = @"
param(
[string]`$SudoTag,
[string]`$EncodedUserCommandBase64,
[string]`$WorkingDirectory,
[string]`$ScriptPath
)
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
function Remove-SudoTempFileInternal {
param([string]`$Path)
if (Test-Path -Path `$Path) {
try {
    Remove-Item -Path `$Path -Force -ErrorAction SilentlyContinue
    Write-Verbose "已成功删除临时文件: `$Path"
} catch {
    # Write-Warning "无法删除临时文件 '`$Path': `$(`$_.Exception.Message)`"
}
}
}
Remove-SudoTempFileInternal -Path `$ScriptPath
Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue | Out-Null
} -ErrorAction SilentlyContinue | Out-Null
Set-Location -Path `$WorkingDirectory;
try {
`$decodedUserCommand = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$EncodedUserCommandBase64));
Invoke-Expression ([System.Environment]::ExpandEnvironmentVariables(`$decodedUserCommand));
} catch {
Write-Error "初始化命令序列时出错: `$(`$_.Exception.Message)`"
exit 1;
}
"@
                        try {
                            Set-Content -Path $tempScriptPath -Value $tempScriptContent -Encoding UTF8 -ErrorAction Stop
                        } catch {
                            Write-Error "创建临时脚本文件 '$tempScriptPath' 时出错: $($_.Exception.Message)"
                            Remove-SudoTempFile -Path $tempScriptPath -Silent
                            return
                        }
                        $psi = New-Object System.Diagnostics.ProcessStartInfo
                        $psi.FileName = "powershell.exe"
                        $psi.Arguments = @(
                            "-WindowStyle", "Hidden",
                            "-ExecutionPolicy", "Bypass",
                            "-File", $tempScriptPath,
                            "-SudoTag", $processTag,
                            "-EncodedUserCommandBase64", $encodedUserCommandBase64,
                            "-WorkingDirectory", $currentWorkingDirectory,
                            "-ScriptPath", $tempScriptPath
                        )
                        $psi.Verb = "RunAs"
                        $psi.UseShellExecute = $true
                        $psi.CreateNoWindow = $true
                        $process = [System.Diagnostics.Process]::Start($psi)
                        $jobName = "SudoSilently_$(Get-Date -Format 'yyyyMMddHHmmssfff')_PID$($process.Id)"
                        Write-Host "PID为 $($process.Id) 的被提升进程启动，标记为 '$processTag'"
                        Register-ObjectEvent -InputObject $process -EventName Exited -Action {
                            param($source, $eventArgsParam)
                            $exitCode = $source.ExitCode
                            Write-Host "PID为 $($source.Id) 的被提升进程已退出，退出代码为 $exitCode"
                            Unregister-Event -SourceIdentifier $event.SourceIdentifier
                            Remove-Job -Name $event.SourceIdentifier -Force
                        } -SourceIdentifier $jobName
                    }
                }
                catch {
                    Write-Error "提升powershell.exe时出错: $($_.Exception.Message)"
                    Remove-SudoTempFile -Path $tempScriptPath -Silent
                }

            }
        }
    }
}
