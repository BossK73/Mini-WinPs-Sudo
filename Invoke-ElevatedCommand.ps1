# Mini-WinPs-Sudo
# Copyright (c) 2025 BossK73
# Licensed under the MIT License
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
#
# V0.0.4
# 2025年9月23日
# 为部分帮助信息添加实验性的中英双语显示特性，暂无向系统路径含特殊字符的区域格式如日语、朝鲜语添加支持的计划

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
        [string]$script:SudoCurrentVersion = "V0.0.4 by BossK73@Github"
        Write-Output $script:SudoCurrentVersion
    }

    # Sudo i18n Message —— Chinese And English Bilingual Message For Help Information Currently, Japanese And Korean Are NOT Supported
    $script:SudoHelpMessages = @{
        "UsageHeader" = @{
            "zh" = "用法"
            "en" = "Usage"
        };
        "UsageSyntax" = @{
            "zh" = "  sudo [-h] [-v] [-l] [-c] [-k] [命令]"
            "en" = "      sudo [-h] [-v] [-l] [-c] [-k] [Command]"
        };
        "ParameterHeader" = @{
            "zh" = "参数"
            "en" = "Parameter"
        };
        "HelpParam" = @{
            "zh" = "  -h   获取帮助"
            "en" = "  -h   Get help"
        };
        "VersionParam" = @{
            "zh" = "      -v   显示Sudo的版本号"
            "en" = "           -v   Show Sudo version"
        };
        "ListParam" = @{
            "zh" = "      -l   列出所有由Sudo静默提升且目前仍在后台运行的任务"
            "en" = "           -l   List all background running tasks silently elevated by Sudo"
        };
        "CleanParam" = @{
            "zh" = "      -c   手动清理在Sudo静默提升用户命令时创建的临时脚本"
            "en" = "           -c   Manually clean up temporary scripts created by Sudo when silently elevating user commands"
        };
        "KeepNewWindowParam" = @{
            "zh" = "      -k   保持提升后的新命令行界面，未启用则静默提升`n           启用 -k 参数提升时，Sudo将不会生成临时脚本`n           请为交互式命令启用 -k 参数，避免其提升后一直在后台等待用户输入"
            "en" = "           -k   Keep the newly elevated CLI; elevate silently if not enabled`n                Enable -k to prevent background waits for interactive commands and temp script when elevating"
        };
        "ExampleHeader" = @{
            "zh" = "示例"
            "en" = "Example"
        };
        "ExampleCommand" = @{
            "zh" = "  sudo notepad %SystemRoot%\system32\drivers\etc\hosts`n"
            "en" = "    sudo notepad %SystemRoot%\system32\drivers\etc\hosts`n"
        }
        #;"FormatTestMessage" = @{
            #"zh" = "这是一个带参数的测试消息：{0} 和 {1}"
            #"en" = "This is a test message with arguments: {0} and {1}"
        #}
    }

    # Get Sudo Current Language
    function Get-SudoCurrentLanguage {
        if (-not (Get-Variable -Name "isSudoCurrentLanguageChecked" -Scope Global -ErrorAction SilentlyContinue)) {
            $global:isSudoCurrentLanguageChecked = $false
            $global:SudoCurrentLanguage = $null
        }
        if (-not $global:isSudoCurrentLanguageChecked) {
            if (([System.Globalization.CultureInfo]::CurrentUICulture.Name).StartsWith("zh", [System.StringComparison]::OrdinalIgnoreCase)) {
                $global:SudoCurrentLanguage = "zh"
            } else {
                try {
                    $currentUserLanguageList = Get-WinUserLanguageList -ErrorAction SilentlyContinue
                    if ($currentUserLanguageList -and $currentUserLanguageList.Count -gt 0) {
                        if (($currentUserLanguageList[0].LanguageTag).StartsWith("zh", [System.StringComparison]::OrdinalIgnoreCase)) {
                            $global:SudoCurrentLanguage = "zh"
                        }
                    } else {
                        $global:SudoCurrentLanguage = "en"
                    }
                } catch {
                    Write-Verbose "检测语言失败，将回退至英语: $($_.Exception.Message)"
                    $global:SudoCurrentLanguage = "en"
                }
            }
            $global:isSudoCurrentLanguageChecked = $true
        }
        return $global:SudoCurrentLanguage
    }

    # Show Sudo i18n Message
    function Show-SudoLocalizedMessage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string]$MessageIdentifier,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Host", "Output", "Verbose", "Warning", "Error")]
            [string]$MessageType = "Host",
            [Parameter(Mandatory = $false)]
            [ConsoleColor]$ForegroundColor,
            [Parameter(Mandatory = $false)]
            [switch]$NoNewline,
            [Parameter(Mandatory = $false)]
            [object[]]$Arguments
        )
        try {
            $messageMap = $script:SudoHelpMessages[$MessageIdentifier]
            if (-not $messageMap) {
                Write-Warning "MessageIdentifier '$MessageIdentifier' not found. Please check the code integrity of Sudo"
                return
            }
            $localizedMessage = $messageMap[$(Get-SudoCurrentLanguage)]
            if (-not $localizedMessage) {
                Write-Verbose "MessageIdentifier '$MessageIdentifier' 在当前语言 '$global:SudoCurrentLanguage' 中无翻译，回退至英语"
                $localizedMessage = $messageMap["en"]
            }
            if (-not $localizedMessage) {
                Write-Warning "MessageIdentifier '$MessageIdentifier' has no English translation. Please check the code integrity of Sudo"
                return
            }
            $needsFormatting = $localizedMessage -match '\{\d+\}'
            if ($needsFormatting) {
                if ($Arguments) {
                    try {
                        $localizedMessage = $localizedMessage -f $Arguments
                    } catch {
                        Write-Warning "MessageIdentifier '$MessageIdentifier' 的消息格式化参数不匹配。原始消息：'$localizedMessage'。错误：$($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "MessageIdentifier '$MessageIdentifier' 需要格式化参数但未提供。原始消息：'$localizedMessage'"
                }
            } elseif ($Arguments) {
                Write-Verbose "MessageIdentifier '$MessageIdentifier' 不需要格式化参数，但提供了参数，这些参数将被忽略。原始消息：'$localizedMessage'"
            }
            switch ($MessageType) {
                "Host" {
                    $hostParams = @{}
                    if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $hostParams.Add('ForegroundColor', $ForegroundColor) }
                    if ($PSBoundParameters.ContainsKey('NoNewline')) { $hostParams.Add('NoNewline', $NoNewline) }
                    Write-Host $localizedMessage @hostParams
                }
                "Output" {
                    Write-Output $localizedMessage
                }
                "Verbose" {
                    Write-Verbose $localizedMessage
                }
                "Warning" {
                    Write-Warning $localizedMessage
                }
                "Error" {
                    Write-Error $localizedMessage
                }
                default {
                    Write-Verbose "不支持的 MessageType '$MessageType'，默认回退至 Write-Host"
                    Write-Host $localizedMessage
                }
            }
        } catch {
            Write-Error "Show-SudoLocalizedMessage 出错：$($_.Exception.Message)。MessageIdentifier: '$MessageIdentifier'"
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
        $SudoAsciiArtScriptBuilder = New-Object System.Text.StringBuilder(8192) # Number 7886 Was Calculated Again By Gemini 2.5 Flash
        $null = $SudoAsciiArtScriptBuilder.Append("Write-Host '`n';")
        $lines = $slantReliefStyleSudoAsciiArt -split "`n"
        foreach ($line in $lines) {
            $charColorMap = [System.Collections.Generic.List[PSCustomObject]]::new(128) # Number 73 Was Calculated By Gemini 2.5 Flash
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
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i]; Color = $BaseColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+1]; Color = $LeftColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+2]; Color = $BottomColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+3]; Color = $BottomColor })
                    ($i..($i+3)) | ForEach-Object { $processed[$_] = $true }
                    $i += 4
                    continue
                # "_\/\"
                } elseif ($i + 3 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '\' -and $line[$i+2] -eq '/' -and $line[$i+3] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i]; Color = $BaseColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+1]; Color = $LeftColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+2]; Color = $LeftColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+3]; Color = $TopColor })
                    ($i..($i+3)) | ForEach-Object { $processed[$_] = $true }
                    $i += 4
                    continue
                # "_/\"
                } elseif ($i + 2 -lt $lineLength -and $line[$i] -eq '_' -and $line[$i+1] -eq '/' -and $line[$i+2] -eq '\') {
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i]; Color = $BaseColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+1]; Color = $LeftColor })
                    $charColorMap.Add([PSCustomObject]@{ Char = $line[$i+2]; Color = $TopColor })
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
                    $charColorMap.Add([PSCustomObject]@{ Char = $currentChar; Color = $segmentColor })
                    $processed[$i] = $true
                    $i += 1
                }
            }
            # Merge Consecutive Characters With The Same Color 
            [ConsoleColor]$currentGroupColor = [ConsoleColor]::Black
            $currentGroupText = [System.Text.StringBuilder]::new(16) # Number 12 Was Calculated By Gemini 2.5 Flash
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
        Write-Host "Sudo has been tested only on Chinese locale systems`nIf text appears garbled, try resaving your PowerShell profile with UTF8-BOM encoding" -ForegroundColor DarkGray
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
        Show-SudoLocalizedMessage -MessageIdentifier "UsageHeader" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Show-SudoLocalizedMessage -MessageIdentifier "UsageSyntax"
        Show-SudoLocalizedMessage -MessageIdentifier "ParameterHeader" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Show-SudoLocalizedMessage -MessageIdentifier "HelpParam"
        Show-SudoLocalizedMessage -MessageIdentifier "VersionParam"
        Show-SudoLocalizedMessage -MessageIdentifier "ListParam"
        Show-SudoLocalizedMessage -MessageIdentifier "CleanParam"
        Show-SudoLocalizedMessage -MessageIdentifier "KeepNewWindowParam"
        Show-SudoLocalizedMessage -MessageIdentifier "ExampleHeader" -NoNewline -ForegroundColor $sudoHelpHeaderColor
        Show-SudoLocalizedMessage -MessageIdentifier "ExampleCommand" 
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
            $fallbackPs1FileName = "$(New-Guid)_sudo_.ps1"
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
    Write-Error "Error occurred while executing the passed command sequence: `$(`$_.Exception.Message)`";
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
                Write-Verbose "Temporary files have been successfully deleted: `$Path"
            } catch {
                # Write-Warning "Unable to delete temporary files '`$Path': `$(`$_.Exception.Message)`"
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
    Write-Error "Error occurred during command sequence initialization: `$(`$_.Exception.Message)`"
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
