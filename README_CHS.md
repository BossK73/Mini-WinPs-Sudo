# Mini-WinPs-Sudo  
[English](https://github.com/BossK73/Mini-WinPs-Sudo/blob/main/README.md)

## 简介
用于在 Windows 10 与 Windows 11 中以类 Linux 平台 Sudo 体验提升运行单条用户命令的轻量级 Windows PowerShell 5.1 脚本。

无法在命令提示符中使用。

## 用法
更改执行策略以允许 Windows PowerShell 执行脚本，将`Invoke-ElevatedCommand.ps1`的内容复制到 Windows PowerShell 5.1 的配置文件中。

在新的 Windows PowerShell 会话中执行`sudo`命令。

运行`sudo -h`获取更多帮助。

目前仅在中文系统上测试过Sudo，如果遇到显示乱码问题，请尝试以`UTF8-BOM`编码重新保存 Windows PowerShell 的配置文件。

## 与 Sudo-for-Windows 共存
Mini-WinPs-Sudo 将在 Windows PowerShell 上覆盖同名的 Sudo-for-Windows，但由于无法在命令提示符上运行，其对命令提示符中的 Sudo-for-Windows 无影响。

因此，你可以继续在命令提示符中使用 Sudo-for-Windows，同时在 Windows PowerShell 中使用 Mini-WinPs-Sudo。

## 版本更新说明
[V0.0.1](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.1) 从本地上传已废弃的首个功能测试原型。

[V0.0.2](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.2) 重构代码，完成功能框架。移除有关命令提示符的无用代码，提高代码模块化程度，增加帮助`-h`、版本`-v`、查询`-l`、保持新窗口`-k`等共计4个参数，改变命令为空时的行为，增加ASCII字符画上色输出特性并优化显示速度。

[V0.0.3](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.3) 增强安全性，减少条件判断开销，新增用于手动清理临时文件的`-c`参数。

[V0.0.4](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.4) 向部分帮助信息添加实验性的中英双语显示特性，暂无向系统路径含特殊字符的区域格式如日语、朝鲜语添加支持的计划。

## 参考资料
[about_profiles - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)

[about_execution_policies - Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)

## 许可
Mini-WinPs-Sudo 采用 MIT 许可。

## AI 辅助编码说明
本项目的某些组成代码及工作流程已经或将会由包括但不限于 Gemini 2.5 Flash、Github Copilot、Deepseek Reasoner 及 Doubao Seed Thinking 等大语言模型及 Agent 辅助。