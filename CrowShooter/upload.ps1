# Upload CROWui to GitHub - run this anytime you want to push changes
# Usage: .\upload.ps1  or  .\upload.ps1 "Your commit message"

$msg = if ($args[0]) { $args[0] } else { "Update CROWui" }
Set-Location $PSScriptRoot
git add -A
git status
git commit -m $msg
git push
