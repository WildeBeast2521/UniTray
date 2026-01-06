<p align="center">
  <img alt="UniTray" src="./updates-available.ico" width="64">
<h1 align="center">UniTray</h1>
<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-PowerShell-blue?style=for-the-badge&logo=powershell">
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white">
</p>
<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge&logo=github">
</p>

## Table of Contents
<!-- vim-markdown-toc GFM -->
* [About](#-about)
* [Features](#-features)
* [Prerequisites](#-prerequisites)
* [Installation](#-installation)
* [Usage](#%EF%B8%8F-usage)
* [Acknowledgements](#-acknowledgements)
* [Contributing](#-contributing)
* [License](#-license)
<!-- vim-markdown-toc GFM -->

<h2>❔ About</h2>
<p>
  UniTray is a lightweight PowerShell tray application that helps you monitor and update <a href="https://scoop.sh">Scoop</a>, <a href="https://chocolatey.org/">Chocolatey</a> and <a href="https://github.com/microsoft/winget-cli">WinGet</a> packages effortlessly, all from one simple application.<br>
  It runs in the background, checks for updates, and notifies you when new versions are available.
</p>
<h2>🚀 Features</h2>
<p>
  <details>
    <summary>
      Periodically checks for updates, with a one-click update option in the context menu
    </summary>
    <table>
      <tr>
        <td align="center">
          <a title="Context Menu">
            <img src="./images/contextmenu.png" alt="Context Menu"/><br>
            <b>Context Menu</b>
          </a>
        </td>
      </tr>
    </table>
  </details>
  <details>
    <summary>
      Runs in the system tray for easy access, with tooltip information
    </summary>
    <table>
      <tr>
        <td align="center">
          <a title="Tooltip">
            <img src="./images/tooltip.png" alt="Tooltip"/><br>
            <b>Tooltip</b>
          </a>
        </td>
      </tr>
    </table>
  </details>
  <details>
    <summary>Supports selective updates</summary>
    <table>
      <tr>
        <td align="center">
          <a title="Updates">
            <img src="./images/mica-dark.png" alt="Updates"/><br>
            <b>Updates</b>
          </a>
        </td>
      </tr>
    </table>
  </details>
  <details>
    <summary>
      Terminates<sup><a href="#terminates">[1]</a></sup> package applications to allow updates
    </summary>
    <table>
      <tr>
        <td align="center">
          <a title="Termination">
            <img src="./images/termination.png" alt="Termination"/><br>
            <b>Termination</b>
          </a>
        </td>
      </tr>
    </table>
  </details>
  <details>
    <summary>
      Sends failure notifications using <a href="https://github.com/Windos/BurntToast">BurntToast</a>
    </summary>
    <table>
      <tr>
        <td align="center">
          <a title="Failure">
            <img src="./images/burnttoast-failure.png" alt="Failure"/><br>
            <b>Failure</b>
          </a>
        </td>
        <td align="center">
          <a title="Error">
            <img src="./images/burnttoast-error.png" alt="Error"/><br>
            <b>Error</b>
          </a>
        </td>
      </tr>
    </table>
  </details>
  <details>
    <summary>
      Supports backdrop and dark mode integrations
    </summary>
    <table>
      <tr>
        <td colspan="3" align="center">
          <b>Backdrop</b>
        </td>
      </tr>
      <tr>
        <th align="center">
          <b>Type</b>
        </th>
        <th align="center">
          <b>Light</b>
        </th>
        <th align="center">
          <b>Dark</b>
        </th>
      </tr>
      <tr>
        <td align="center">
          <a title="Acrylic">
            Acrylic
          </a>
        </td>
        <td align="center">
          <a title="Acrylic Light">
            <img src="./images/acrylic-light.png" alt="Acrylic Light"/><br>
          </a>
        </td>
        <td align="center">
          <a title="Acrylic Dark">
            <img src="./images/acrylic-dark.png" alt="Acrylic Dark"/><br>
          </a>
        </td>
      </tr>
      <tr>
        <td align="center">
          <a title="Mica">
            Mica
            <b>(Default)</b>
          </a>
        </td>
        <td align="center">
          <a title="Mica Light">
            <img src="./images/mica-light.png" alt="Mica Light"/><br>
          </a>
        </td>
        <td align="center">
          <a title="Mica Dark">
            <img src="./images/mica-dark.png" alt="Mica Dark"/><br>
          </a>
        </td>
      </tr>
      <tr>
        <td align="center">
          <a title="Mica Alt">
            Mica Alt
          </a>
        </td>
        <td align="center">
          <a title="Mica Alt Light">
            <img src="./images/mica-alt-light.png" alt="Mica Alt Light"/><br>
          </a>
        </td>
        <td align="center">
          <a title="Mica Alt Dark">
            <img src="./images/mica-alt-dark.png" alt="Mica Alt Dark"/><br>
          </a>
        </td>
      </tr>
    </table>
    <br>
    <table>
      <tr>
        <td colspan="2" align="center">
          <b>Theme</b>
        </td>
      </tr>
      <tr>
        <th align="center">
          <b>Light</b>
        </th>
        <th align="center">
          <b>Dark</b>
        </th>
      </tr>
      <tr>
        <td align="center">
          <a title="Light">
            <img src="./images/light.png" alt="Light"/><br>
          </a>
        </td>
        <td align="center">
          <a title="Dark">
            <img src="./images/dark.png" alt="Dark"/><br>
          </a>
        </td>
      </tr>
    </table>
  </details>
</p>

> [!NOTE]  
> Backdrop and dark mode integrations are only supported on Windows builds 22000+

<p id="terminates">
  <strong>[1]</strong>
  <br>
    To allow Scoop package updates, applications currently in use must be closed. It is highly recommended to ensure programs are idle and that no unsaved progress exists before termination.
  <br>
    If you prefer to close applications manually, do so before running updates.
</p>

<h2>📚 Prerequisites</h2>
<p>
  <ul>
    <li>
      A Package Manager (<a href="https://scoop.sh">Scoop</a>, <a href="https://chocolatey.org/">Chocolatey</a> or/and <a href="https://github.com/microsoft/winget-cli">WinGet</a>)
    </li>
    <li>
      <a href="https://github.com/Windos/BurntToast">BurntToast</a>
    </li>
    <li>
      <a href="https://www.powershellgallery.com/packages/Microsoft.WinGet.Client">Microsoft.WinGet.Client</a>
    </li>
  </ul>
  To install BurntToast and <code>Microsoft.WinGet.Client</code>, run the following command in PowerShell:
  <pre><code>Install-Module -Name BurntToast, Microsoft.WinGet.Client</code></pre>
</p>

<h2>📥 Installation</h2>
<p>
  To start using UniTray:
  <ol>
    <li>
      Clone the repository:
      <pre><code>git clone https://github.com/WildeBeast2521/UniTray.git</code></pre>
    </li>
    <li>
      Run the following command in Command Prompt (CMD) to start UniTray:
      <pre><code>PowerShell.exe -ExecutionPolicy Bypass -File UniTray.ps1</code></pre>
    </li>
  </ol>
</p>

<h2>🛠️ Usage</h2>
<p>
  Timer interval and backdrops can be set in the <code>settings.json</code> file created on initial start.
  <h3>Timer Interval</h3>
  The default check interval is set to <b>2 hours</b>. To customize it, set the <code>interval</code> value in settings.

  <h3>Backdrop</h3>
  The default backdrop is set to <b>Mica</b>. To customize it, set the <code>backdrop</code> value in the settings with the appropriate constant. <a href="https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/ne-dwmapi-dwm_systembackdrop_type">Constants</a> for backdrops are defined below:
  <table>
    <tr>
      <th align="center">
        <b>Backdrop</b>
      </th>
      <th align="center">
        <b>Constant</b>
      </th>
    </tr>
    <tr>
      <td align="center">
        <a title="Mica">
          Mica <b>(Default)</b>
        </a>
      </td>
      <td align="center">
        <a title="Mica_Constant">
          <code>2</code>
        </a>
      </td>
    </tr>
    <tr>
      <td align="center">
        <a title="Acrylic">
          Acrylic
        </a>
      </td>
      <td align="center">
        <a title="Acrylic_Constant">
          <code>3</code>
        </a>
      </td>
    </tr>
    <tr>
      <td align="center">
        <a title="Mica Alt">
          Mica Alt
        </a>
      </td>
      <td align="center">
        <a title="MicaAlt_Constant">
          <code>4</code>
        </a>
      </td>
    </tr>
  </table>
</p>

<h2>🙌 Acknowledgements</h2>
<p>
  UniTray has evolved through a lot of edits, from a simple tray application into a customizable update manager, with help from various sources:
  <ol>
    <li>
      <a href="https://github.com/dongle-the-gadget/SystemBackdropTypes">dongle-the-gadget/SystemBackdropTypes</a> / <a href="https://tvc-16.science/mica-wpf.html">Apply Mica to a WPF app on Windows 11</a> for backdrop integration
    </li>
    <li>
      <a href="https://gist.github.com/rounk-ctrl/b04e5622e30e0d62956870d5c22b7017">Win32 Dark Mode</a> / <a href="https://www.wxwidgets.org/wxWidgets/src/msw/darkmode.cpp">Support for dark mode in wxMSW</a> for Dark mode support
    </li>
  </ol>
  And more!
</p>

<h2>🔧 Contributing</h2>
<p>
  Pull requests are welcome - check out <a href="https://github.com/WildeBeast2521/UniTray/blob/main/CONTRIBUTING.md">CONTRIBUTING</a> for more information
</p>

<h2>📄 License</h2>
<p>
  This project is licensed under the MIT License - see the <a href="./LICENSE">MIT License</a> file for details.
</p>
