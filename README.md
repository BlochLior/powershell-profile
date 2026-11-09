# PowerShell Developer Profile

A modular, highly customized PowerShell profile featuring a fast Git prompt, execution timers, modern file listing (`eza`), and quick-launch templates for full-stack projects.

## ⚠️ Prerequisites

To render the icons in the prompt and file lists correctly, you **must** use a [Nerd Font](https://www.nerdfonts.com/) in your terminal (e.g., *CaskaydiaCove Nerd Font* or *FiraCode Nerd Font*).

### Required CLI Tools
This profile relies on the following tools being installed on your system path. (The profile will still load gracefully if they are missing, but features will be disabled).

* [Scoop](https://scoop.sh/) - Used for package management and Java JDK switching.
* [eza](https://github.com/eza-community/eza) - A modern, colorized replacement for `ls`.
  * `scoop install eza`
* [fnm](https://github.com/Schniz/fnm) - Fast Node Manager.
  * `scoop install fnm`

## 🚀 Installation

1. Clone this repository.
2. Open PowerShell and find your profile path by typing: `$PROFILE`
3. If the file doesn't exist, create it: `New-Item -Type File -Force $PROFILE`
4. Copy the contents of `Microsoft.PowerShell_Profile.ps1` into your `$PROFILE`.
5. Restart PowerShell. The script will automatically prompt you if you are missing necessary PowerShell modules.

### PowerShell Modules Used
The profile will attempt to load these automatically. If you don't have them, install them via the PowerShell Gallery:
```powershell
Install-Module posh-git -Scope CurrentUser
Install-Module Terminal-Icons -Scope CurrentUser