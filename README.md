# Mini-WinPs-Sudo  
[简体中文](https://github.com/BossK73/Mini-WinPs-Sudo/blob/main/README_CHS.md)
## Introduction
A Linux-sudo-like Windows PowerShell 5.1 script getting elevated privileges for one command each time in Windows 10 and Windows 11.

Unavailable for Command Prompt.

## Uasge
Change execution policy to allow Windows PowerShell script, then copy the content of `Invoke-ElevatedCommand.ps1` to your Windows PowerShell profile.

Start one command with `sudo` in a new Windows PowerShell session.

Run `sudo -h` for more information.

## Coexist with Sudo-for-Windows
Mini-WinPs-Sudo will override Sudo-for-Windows in Windows PowerShell due to the same command name, but has no influence on Sudo-for-Windows in Command Prompt since it does NOT work in Command Prompt.

You can use Sudo-for-Windows in Command Prompt.

## Version Update Information
[V0.0.1](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.1) Upload the first functional test prototype that has been discarded.

[V0.0.2](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.2) Refactor code and complete the functional framework. Remove redundant CMD-related code, improve code modularity, add four new parameters including help `-h`, version `-V`, list `-l` and keep new window `-K`, modify the default behavior when no command is provided, and introduce colored ASCII art output with optimized rendering speed. Very close to being a release version.

## Reference
[about_profiles - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)

[about_execution_policies - Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)

## License
Mini-WinPs-Sudo project is licensed under the MIT License.

## AI-assisted Coding
Certain components of this project have been or will be developed with the assistance of large language models and agents, including but not limited to Gemini Flash, GitHub Copilot, Deepseek Reasoner, and Doubao Seed Thinking.