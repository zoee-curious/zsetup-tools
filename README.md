# zsetup-tools (Zoee Setup Tools) 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%20PowerShell-0078D4.svg)](https://microsoft.com/powershell)
[![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-brightgreen.svg)](# open-source-ecosystem)

**zsetup-tools** (_Zoee Setup Tools_, alias `zst`) is a lightweight, zero-dependency package manager and setup automation tool for Windows powered entirely by PowerShell. Designed with total isolation and simplicity in mind, `zsetup-tools` lets you run quick cloud-based app installers or manage local portable packages effortlessly—even on a freshly installed OS.

---

## ✨ Features

- ⚡ **Zero Setup Required**: Works straight out of the box on clean Windows installations.
- 🌐 **Instant Cloud Execution**: Run one-liner PowerShell commands directly from the browser (`irm zoee.fun/install/<app> | iex`) without installing the package manager first.
- 📦 **100% Isolated Environment**: All binaries, apps, configurations, and downloaded data reside strictly inside `$HOME\zsetup`. Zero system bloat, zero messy registry entries.
- 🚀 **Intuitive CLI (`zst`)**: Simple, memorizable commands to install, manage, and self-update packages.
- 🧹 **Trivial Uninstallation**: Want to completely erase everything? Just delete the `$HOME\zsetup` folder. That's it!
- 🔓 **Fully Open Source**: Everything—from PowerShell execution logic and backend routing to app manifests—is open source and hosted in this repository.

---

## 🚀 Getting Started

### Prerequisites

Ensure PowerShell execution policy allows local scripts to run (for CurrentUser):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Option 1: Quick App Install (No CLI Installation Needed)

You don't need to install `zsetup-tools` to use its package manifests! You can execute installation scripts remotely in one line:

```powershell
# Syntax
irm zoee.fun/install/<app-name> | iex

# Example: Install aria2 directly
irm zoee.fun/install/aria2 | iex
```

---

### Option 2: Install `zsetup-tools` CLI (`zst`)

To get the full CLI experience and manage applications locally:

1. Open PowerShell and run:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm zoee.fun/install | iex
   ```

2. Once installed, the `zst` command alias will be available in your terminal.

---

## 💻 CLI Usage (`zst`)

Manage packages locally using the `zst` binary alias:

### Basic Command Syntax

```powershell
zst <action> <name>
```

### Examples

- **Install an application**:

  ```powershell
  zst install aria2
  ```

- **Update `zsetup-tools` itself**:
  ```powershell
  zst install update
  ```

---

## 📂 Isolated Directory Structure

Unlike traditional installer frameworks that scatter files across `C:\Program Files`, `AppData`, or the Windows Registry, `zsetup-tools` keeps everything isolated inside a single directory:

```text
$HOME\zsetup\
├── apps\              # Isolated portable application binaries
|── cache\             # A small cache from this tool
|── scripts\           # Main logic scripts
├── shims\             # Executable shims & CLI aliases (zst)
├── temp\              # Temporary installer cache
```

---

## 🗑️ Complete Uninstallation

Because everything is contained inside `$HOME\zsetup`, uninstalling `zsetup-tools` and all packages installed through it requires no special uninstallers or registry cleaning tools.

Simply open PowerShell or File Explorer and delete the directory:

```powershell
Remove-Item -Recurse -Force "$HOME\zsetup"
```

Once deleted, your system returns to its original state.

---

## 🌐 Open Source Ecosystem

This repository hosts the complete source code for `zsetup-tools`:

1. **PowerShell Logic**: Execution engine, path handling, and CLI command router.
2. **Backend API**: The endpoint router powering short links like `zoee.fun/install/<app>`.
3. **App Manifests**: Community-driven installer manifests and application specifications.

---

## 🤝 Contributing

Contributions are welcome! You can contribute by:

- Adding or updating application manifests under `/manifests`.
- Improving PowerShell installation scripts under `/scripts`.
- Reporting bugs or suggesting new feature enhancements via GitHub Issues.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
