# Usage (from the repo root, in PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\scripts\push_to_github.ps1
# Before running: create an EMPTY repo named melbourne-rainfall-prediction on github.com
# (do NOT tick "Add a README file").
$ErrorActionPreference = "Stop"
$repoUrl = "https://github.com/sumitgawande3112-cmd/melbourne-rainfall-prediction.git"

git init
git config user.name "Sumit Gawande"
git config user.email "sumitgawande3112@gmail.com"
git add .
git commit -m "Melbourne rainfall prediction: full PACE project"
git branch -M main
if (git remote) { git remote set-url origin $repoUrl } else { git remote add origin $repoUrl }
git push -u origin main --force
Write-Host "Done. Open https://github.com/sumitgawande3112-cmd/melbourne-rainfall-prediction"
