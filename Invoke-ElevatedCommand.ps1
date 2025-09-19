# Mini-WinPs-Sudo
# Copyright (c) 2025 BossK73
# Licensed under the MIT License
# 用于在 Windows 10 与 Windows 11 中以类 Linux 平台 Sudo 体验提升运行单条用户命令的 Windows PowerShell 5.1 脚本。在命令提示符中不起作用。将代码复制到 Windows PowerShell 5.1 的配置文件中，并允许 PowerShell 执行本地脚本，执行 sudo即可。配置文件中的 sudo 优先级高于 Windows PowerShell 中的 Sudo-for-Windows，但对命令提示符中的 Sudo-for-Windows 无影响。警告：这将会导致之后的 PowerShell 会话中存在 sudo 函数，可能与之后输入的命令重名。有关配置文件和执行策略的描述，请参阅以下链接：
# https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1
#https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1 
# V0.0.1
# 2025年9月20日
# 从本地上传已废弃的首个功能测试原型

function Invoke-ElevatedCommand {
    [CmdletBinding()]
    [Alias("sudo")]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Command
    )
    
    # 检测当前 PowerShell 版本
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
        Write-Error "当前会话处于不受支持的Shell中，操作取消"
        return
    }
    
    # 检测当前宿主程序
    $hostProcessName = (Get-Process -Id $PID).ProcessName
    $isCmdHost = $hostProcessName -eq "cmd" -or $hostProcessName -eq "conhost"
    $isPowerShellHost = $hostProcessName -eq "powershell" -or $hostProcessName -eq "powershell_ise"
    
    if (-not $isCmdHost -and -not $isPowerShellHost) {
        Write-Error "当前会话处于不受支持的Shell中，操作取消"
        return
    }
    
    # 检测管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # 如果没有提供命令，输出当前状态
    if ($Command.Count -eq 0) {
        if ($isCmdHost) {
            Write-Host "当前Shell类型为: 命令提示符"
        } else {
            Write-Host "当前Shell类型为: Windows PowerShell 5.1"
        }
        Write-Host "当前管理员权限: $isAdmin"
        return
    }
    
    # 合并命令为字符串
    $commandString = $Command -join " "
    
    try {
        if ($isCmdHost) {
            # 在命令提示符环境中
            if ($isAdmin) {
                # 已有管理员权限，直接执行
                cmd /c $commandString
            } else {
                # 需要提升权限，启动新的cmd窗口
                Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $commandString -Verb RunAs
            }
        } else {
            # 在PowerShell环境中
            if ($isAdmin) {
                # 已有管理员权限，直接执行并捕获错误
                try {
                    Invoke-Expression -Command $commandString
                } catch {
                    Write-Error $_.Exception.Message
                    Write-Host "当前会话已取得管理员权限，但操作失败，请直接执行命令，不使用sudo" -ForegroundColor Yellow
                }
            } else {
                # 需要提升权限，启动新的PowerShell窗口
                $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($commandString))
                Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-EncodedCommand", $encodedCommand -Verb RunAs
            }
        }
    } catch {
        Write-Error "执行命令时发生错误: $($_.Exception.Message)"
    }
}