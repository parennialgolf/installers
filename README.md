# Bay Management Installer

Run this from **Windows Command Prompt** to install the latest Bay Management release.

```bat
set "PG_TOKEN=YOUR_GITHUB_TOKEN"
curl -fL -o bay-management.ps1 https://raw.githubusercontent.com/parennialgolf/installers/refs/heads/main/bay-management.ps1 && powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File bay-management.ps1 -Token "%PG_TOKEN%"
```

Token requirements:
- Must have access to the Bay Management releases repo (default in script: `parennialgolf/dotnet`)
- Fine-grained (`github_pat_...`) or classic (`ghp_...`) both work
- If your org uses SSO/SAML, the token must be authorized
