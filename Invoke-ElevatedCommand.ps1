# Mini-WinPs-Sudo
# Copyright (c) 2025 BossK73
# Licensed under the MIT License
# 
# 用于在 Windows 10 与 Windows 11 中以类 Linux 平台 Sudo 体验提升运行单条用户命令的轻量级 Windows PowerShell 5.1 脚本。在命令提示符中不起作用。
# 
# 将代码复制到 Windows PowerShell 5.1 的配置文件中，并允许 Windows PowerShell 执行本地脚本，在新的 Windows PowerShell 会话中运行 sudo -h 获取使用帮助。
# 
# 如果遭遇显示乱码，可尝试以 UTF8-BOM 编码重新保存 Windows PowerShell 的配置文件。
# 
# 提示：配置文件中的 sudo 优先级高于 Windows PowerShell 中的 Sudo-for-Windows，但对命令提示符中的 Sudo-for-Windows 无影响。
# 
# 警告：这将会导致之后的 PowerShell 会话中存在别名为 sudo 的 Invoke-ElevatedCommand 函数及相关变量，可能与之后用户输入的内容重名。
# 
# 有关配置文件和执行策略的描述，请参阅以下链接：
# https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1
# https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1 

# V0.0.3
# 2025年9月22日
# 增强代码安全性，减少多处代码的条件判断开销；同时启用-h与-v时忽略-v；添加用于在管理员权限下手动清理临时脚本的-c参数

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
        # Clean
        [Parameter(ParameterSetName = "HelpSet", Mandatory = $false)]
        [Alias("c")]
        [switch]$Clean,
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
        [string]$script:SudoCurrentVersion = "V0.0.3 by BossK73@Github"
        Write-Output $script:SudoCurrentVersion
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
        $SudoAsciiArtScriptBuilder = New-Object System.Text.StringBuilder(8192) # Number 7886 was calculated again by Gemini 2.5 Flash
        $null = $SudoAsciiArtScriptBuilder.Append("Write-Host '`n';")
        $lines = $slantReliefStyleSudoAsciiArt -split "`n"
        foreach ($line in $lines) {
            $charColorMap = [System.Collections.Generic.List[PSCustomObject]]::new(128) # Number 73 was calculated by Gemini 2.5 Flash
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
                # "_\/\"
                } elseif ($i + 3 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '\' -and $line[$i+2] -eq '/' -and $line[$i+3] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i]; Color = $BaseColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+1]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+2]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+3]; Color = $TopColor})
                    ($i..($i+3)) | ForEach-Object { $processed[$_] = $true }
                    $i += 4
                    continue
                # "_/\"
                } elseif ($i + 2 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '/' -and $line[$i+2] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i]; Color = $BaseColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+1]; Color = $LeftColor})
                    $charColorMap.Add([PSCustomObject]@{Char = $line[$i+2]; Color = $TopColor})
                    ($i..($i+2)) | ForEach-Object { $processed[$_] = $true }
                    $i += 3
                    continue
                # Others
                } else {
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
            # Merge Consecutive Characters With The Same Color 
            [ConsoleColor]$currentGroupColor = [ConsoleColor]::Black
            $currentGroupText = [System.Text.StringBuilder]::new(16) # Number 12 was calculated by Gemini 2.5 Flash
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
        # Check ASCII Art Cache
        if (-not (Get-Variable -Name "isSudoAsciiArtScriptBuilt" -Scope Global -ErrorAction SilentlyContinue)) {
            [bool]$global:isSudoAsciiArtScriptBuilt = $false
            [string]$global:SudoAsciiArtScript = $null
        }
        # Check Current Role
        if (Get-SudoCurrentAdminRole) {
            $sudoHelpHeaderColor = $AdminSudoAsciiArtTopColor
            $sudoHelpAdminStatus = "已"
        } else {
            $sudoHelpHeaderColor = $UserSudoAsciiArtTopColor
            $sudoHelpAdminStatus = "未"
        }
        if (-not $global:isSudoAsciiArtScriptBuilt) {
            # $global:isSudoRunningAsAdmin = $(Get-SudoCurrentAdminRole)
            if ($global:isSudoRunningAsAdmin) {
                $global:SudoAsciiArtScript = (Get-SudoAsciiArtScript -BaseColor $AdminSudoAsciiArtBaseColor -TopColor $AdminSudoAsciiArtTopColor -BottomColor $AdminSudoAsciiArtBottomColor -LeftColor $AdminSudoAsciiArtLeftColor)
            } else {
                $global:SudoAsciiArtScript = (Get-SudoAsciiArtScript -BaseColor $UserSudoAsciiArtBaseColor -TopColor $UserSudoAsciiArtTopColor -BottomColor $UserSudoAsciiArtBottomColor -LeftColor $UserSudoAsciiArtLeftColor)
            }
            $global:isSudoAsciiArtScriptBuilt = $true
        }
        Invoke-Expression $global:SudoAsciiArtScript
        # Show Sudo Current Status
        Write-Host "适用于 Windows PowerShell 5.1 的 Sudo $(Show-SudoCurrentVersion)`n可以从本地非管理员会话启动新窗口以提升执行单条用户命令，请确保您要执行的命令安全可信"
        Write-Host "Sudo is tested only on Chinese locale systems.`nIf text appears garbled, try resaving your PowerShell profile with UTF8-BOM encoding"
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
            Write-Warning "Sudo 正运行在未经测试的 Shell 中，可能引发未知错误"
        }
        # Show Sudo Current User
        Write-Host "当前会话$($sudoHelpAdminStatus)取得管理员权限" -ForegroundColor $sudoHelpHeaderColor
        # Show Sudo Usage
        Write-Host "用法" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Write-Host "  sudo [-h] [-v] [-l] [-c] [-k] [Command]"
        Write-Host "参数" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Write-Host "  -h   获取帮助"
        Write-Host "      -v   显示Sudo的版本号"
        Write-Host "      -l   列出所有由Sudo静默提升且目前仍在后台运行的任务"
        Write-Host "      -c   手动清理在Sudo静默提升用户命令时创建的临时脚本"
        Write-Host "      -k   保持提升后的新命令行界面，未启用则静默提升`n           启用 -k 参数提升时，Sudo将不会生成临时脚本`n           请为交互式命令启用 -k 参数，避免其提升后一直在后台等待用户输入"
        Write-Host "示例" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Write-Host "  sudo notepad %SystemRoot%\system32\drivers\etc\hosts`n" 
    }

    # Cteate Unique Sudo Temp File
    function Get-SudoTempScriptFilePath {
        $initialTempFilePath = $null
        $finalPs1Path = $null
        try {
            $initialTempFilePath = [System.IO.Path]::GetTempFileName()
            Write-Verbose "已创建初始临时文件: $initialTempFilePath"
            $tempDir = [System.IO.Path]::GetDirectoryName($initialTempFilePath)
            $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($initialTempFilePath)
            $targetPs1Path = [System.IO.Path]::Combine($tempDir, "${fileNameWithoutExt}_sudo_.ps1")
            try {
                [System.IO.File]::Move($initialTempFilePath, $targetPs1Path)
                $finalPs1Path = $targetPs1Path
                Write-Verbose "已成功将临时文件重命名为: $finalPs1Path"
                return $finalPs1Path
            } catch {
                Write-Warning "重命名临时文件 '$initialTempFilePath' 到 '$targetPs1Path' 失败：$($_.Exception.Message)。尝试回退，构建新的临时文件..."
            }
            if ($null -ne $initialTempFilePath -and [System.IO.File]::Exists($initialTempFilePath)) {
                try {
                    [System.IO.File]::Delete($initialTempFilePath)
                    Write-Verbose "已清理因重命名失败而留下的原始临时文件: $initialTempFilePath"
                } catch {
                    Write-Warning "无法清理可能残留的原始临时文件 '$initialTempFilePath'：$($_.Exception.Message)。可能存在残留"
                }
            }
            $newGuid = New-Guid
            $fallbackPs1FileName = "${newGuid}_sudo_.ps1"
            $fallbackPs1Path = [System.IO.Path]::Combine($tempDir, $fallbackPs1FileName)
            try {
                [System.IO.File]::WriteAllText($fallbackPs1Path, "")
                $finalPs1Path = $fallbackPs1Path
                Write-Verbose "已通过回退机制创建临时文件: $finalPs1Path"
                return $finalPs1Path
            } catch {
                Write-Error "通过回退机制创建临时文件 '$fallbackPs1Path' 失败：$($_.Exception.Message)"
                throw "无法获取可用的 sudo 临时脚本文件路径"
            }
        } catch {
            Write-Error "获取 sudo 临时脚本文件路径的最终尝试失败：$($_.Exception.Message)"
            throw $_
        } finally {
            if ($null -ne $initialTempFilePath -and [System.IO.File]::Exists($initialTempFilePath) -and $initialTempFilePath -ne $finalPs1Path) {
                try {
                    [System.IO.File]::Delete($initialTempFilePath)
                    Write-Verbose "在 finally 块中清理了原始临时文件: $initialTempFilePath"
                } catch {
                    Write-Warning "在 finally 块中无法删除原始临时文件 '$initialTempFilePath'：$($_.Exception.Message)。请手动检查并清理"
                }
            }
        }
    }

    # Remove Sudo Temp Script File
    function Remove-SudoTempScriptFile {
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

    # Remove Sudo Temp Script File Under Admin
    function Remove-SudoTempScriptFileUnderAdmin {
        $tempDir = [System.IO.Path]::GetTempPath()
        $sudoTempFiles = Get-ChildItem -Path $tempDir -Filter "*_sudo_*.ps1" -ErrorAction SilentlyContinue
        $deletedCount = 0
        $errorCount = 0
        if ($sudoTempFiles.Count -eq 0) {
            Write-Host "目前未发现由Sudo创建的临时脚本"
            return
        }
        Write-Host "正在清理由Sudo创建的临时脚本..."
        foreach ($file in $sudoTempFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deletedCount++
                Write-Verbose "已成功删除临时文件: $($file.FullName)"
            } catch {
                $errorCount++
                Write-Error "无法删除临时文件 '$($file.FullName)': $($_.Exception.Message)"
            }
        }
        if ($deletedCount -gt 0) {
            Write-Host "已清理 $deletedCount 个由Sudo创建的临时脚本" -ForegroundColor Green
        }
        if ($errorCount -gt 0) {
            Write-Warning "有 $errorCount 个由Sudo创建的临时脚本未被删除，请进入'$TEMP'手动处理"
        }
    }

    # Get Sudo Running Elevated Process Background Under Admin
    function Get-SudoRunningElevatedProcessBackgroundUnderAdmin {
        try {
            $wqlGuidPattern = "________-____-____-____-____________"
            $wqlFilter = "Name='powershell.exe' AND CommandLine LIKE '%--SudoTag-$wqlGuidPattern%'"
            $powershellProcesses = Get-CimInstance Win32_Process -Filter $wqlFilter -ErrorAction Stop
        } catch {
            Write-Error "无法获取进程信息，请检查WMI服务是否可用。 $($_.Exception.Message)"
            return
        }
        $guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
        $sudoTagPattern = "--SudoTag-$guidRegex"
        $results = @()
        foreach ($process in $powershellProcesses) {
            if ($process.CommandLine -match "(?i)($sudoTagPattern)") {
                $sudoTag = $Matches[1]
                $results += [PSCustomObject]@{
                    PID = $process.ProcessId
                    SudoTag = $sudoTag
                    StartTime = $process.CreationDate
                    # CommandLine = $process.CommandLine # Optinal For Debug
                }
            }
        }
        if ($results.Count -eq 0) {
            Write-Host "目前未发现由Sudo静默提升且目前仍在后台运行的任务"
            return
        }
        Write-Host "找到以下由Sudo静默提升且目前仍在后台运行的任务：" -ForegroundColor Yellow
        $results | Format-Table -AutoSize
        Write-Host "可以执行 Stop-Process -Id <PID> 命令终止这些进程" -ForegroundColor DarkGray
    }

    # Start
    # HelpSet
    if ($PSCmdlet.ParameterSetName -eq "HelpSet" ) {
        if ($Help) {
            Show-SudoHelpInformation
        } elseif ($Version) {
            Show-SudoCurrentVersion
        }
        if ($List -or $Clean) {
            if (-not (Get-SudoCurrentAdminRole)) {
                Write-Host "等待用户批准管理员权限以继续查询或清理操作" -ForegroundColor Yellow
                Start-Sleep -Milliseconds 500 # Make Sure the user will see this message
                $sudoHelpSetElevatedArgs = New-Object System.Collections.Generic.List[string]
                $sudoHelpSetElevatedArgs.Add("-NoExit")
                $sudoHelpSetElevatedArgs.Add("-Command")
                $sudoHelpSetElevatedArgs.Add("Invoke-ElevatedCommand")
                if ($List) { $sudoHelpSetElevatedArgs.Add("-List") }
                if ($Clean) { $sudoHelpSetElevatedArgs.Add("-Clean") }
                try {
                    Start-Process -FilePath "powershell.exe" -ArgumentList $sudoHelpSetElevatedArgs.ToArray() -Verb RunAs
                } catch {
                    Write-Error "操作失败: $($_.Exception.Message)"
                }
            } else {
                if ($List) {
                    Get-SudoRunningElevatedProcessBackgroundUnderAdmin
                }
                if ($Clean) {
                    Remove-SudoTempScriptFileUnderAdmin
                }
            }
        }
    # CommandSet
    } else {
        # Get Current Working Directory
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
                        Write-Warning "回退至powershell.exe执行，等待用户重新批准" 
                        Start-Sleep -Milliseconds 500 # Make Sure the user will see this message
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
                } catch {
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
                        $tempScriptPath = Get-SudoTempScriptFilePath
                        $tempScriptContent = @"
param(
    [string]`$SudoTag,
    [string]`$EncodedUserCommandBase64,
    [string]`$WorkingDirectory,
    [string]`$ScriptPath
)
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    function Remove-SudoTempScriptFileInternal {
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
    Remove-SudoTempScriptFileInternal -Path `$ScriptPath
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
                            Write-Error "创建临时脚本 '$tempScriptPath' 时出错: $($_.Exception.Message)"
                            Remove-SudoTempScriptFile -Path $tempScriptPath -Silent
                            Write-Host "运行 sudo -c 清理所有残留的临时脚本" -ForegroundColor Yellow
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
                        Write-Host "PID为 $($process.Id) 的进程已被提升，标记为 '$processTag'`n"
                        Register-ObjectEvent -InputObject $process -EventName Exited -Action {
                            param($source, $eventArgsParam)
                            $exitCode = $source.ExitCode
                            Write-Host "PID为 $($source.Id) 的被提升进程已退出，退出代码为 $exitCode`n"
                            Unregister-Event -SourceIdentifier $event.SourceIdentifier
                            Remove-Job -Name $event.SourceIdentifier -Force
                        } -SourceIdentifier $jobName
                    }
                } catch {
                    Write-Error "提升powershell.exe时出错: $($_.Exception.Message)"
                    Remove-SudoTempScriptFile -Path $tempScriptPath -Silent
                    Write-Host "运行 sudo -c 清理所有残留的临时脚本" -ForegroundColor Yellow
                }
            }
        }
    }
}
