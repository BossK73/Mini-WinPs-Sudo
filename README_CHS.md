# Mini-WinPs-Sudo  
[English](https://github.com/BossK73/Mini-WinPs-Sudo/blob/main/README.md)
## 简介
用于在 Windows 10 与 Windows 11 中以类 Linux 平台 Sudo 体验提升运行单条用户命令的 Windows PowerShell 5.1 脚本。

无法在命令提示符中使用。

## 用法
更改执行策略以允许 Windows PowerShell 执行脚本，将`Invoke-ElevatedCommand.ps1`的内容复制到 Windows PowerShell 5.1 的配置文件中。

在新的 Windows PowerShell 会话中执行`sudo`命令。

## 与 Sudo-for-Windows 共存
Mini-WinPs-Sudo 将在 Windows PowerShell 上覆盖同名的 Sudo-for-Windows，但由于无法在命令提示符上运行，其对命令提示符中的 Sudo-for-Windows 无影响。

你可以继续在命令提示符中使用 Sudo-for-Windows。

## 版本更新说明
[V0.0.1](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.1) 从本地上传已废弃的首个功能测试原型。

## 参考资料
[about_profiles - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)

[about_execution_policies - Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)

## 许可
Mini-WinPs-Sudo 采用 MIT 许可。

## AI 辅助编码说明
本项目的某些组成部分已经或将会由包括但不限于 Gemini Flash、Github Copilot、Deepseek Reasoner 及 Doubao Seed Thinking 等大语言模型及 Agent 辅助编码。