# Mini-WinPs-Sudo  
[简体中文](https://github.com/BossK73/Mini-WinPs-Sudo/blob/main/README_CHS.md)

## Introduction
A lightweight Linux-sudo-like Windows PowerShell 5.1 script getting elevated privileges for one command each time in Windows 10 and Windows 11.

Unavailable for Command Prompt.

## Uasge
Change execution policy to allow Windows PowerShell script, then copy the content of `Invoke-ElevatedCommand.ps1` to your Windows PowerShell profile.

Start one command with `sudo` in a new Windows PowerShell session.

Run `sudo -h` for more information.

Sudo is tested only on Chinese locale systems. If text appears garbled, try resaving your PowerShell profile with UTF8-BOM encoding.

## Coexist with Sudo-for-Windows
Mini-WinPs-Sudo will override Sudo-for-Windows in Windows PowerShell due to the same command name, but has no influence on Sudo-for-Windows in Command Prompt since it does NOT work in Command Prompt. 

Therefore, you can use Sudo-for-Windows in Command Prompt as usual and use Mini-WinPs-Sudo in Windows PowerShell at the same time.

## Version Update Information
[V0.0.1](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.1) Upload the first functional test prototype that has been discarded.

[V0.0.2](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.2) Refactor code and complete the functional framework. Remove redundant CMD-related code, improve code modularity, add four new parameters including help `-h`, version `-v`, list `-l` and keep new window `-k`, modify the default behavior when no command is provided, and introduce colored ASCII art output with optimized rendering speed.

[V0.0.3](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.3) Enhance security, reduce conditional judgment overhead and add the `-c` parameter to manually clean up temporary files.

[V0.0.4](https://github.com/BossK73/Mini-WinPs-Sudo/releases/tag/V0.0.4) Introduce experimental Chinese and English bilingual dispaly feature for certain help information. There are currently no plans to add support for locale formats with special characters in their system paths such as Japanese and Korean.

## Reference
[about_profiles - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)

[about_execution_policies - Microsoft Learn](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)

## License
Mini-WinPs-Sudo project is licensed under the MIT License.

## AI-assisted Coding
Certain components and workflows of this project have been or will be assisted by large language models and agents, including but not limited to Gemini 2.5 Flash, GitHub Copilot, Deepseek Reasoner, and Doubao Seed Thinking.