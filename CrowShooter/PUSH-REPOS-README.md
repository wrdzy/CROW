# Push CROWui-deepwoken & CROWUI to GitHub

## One-time: log in to GitHub

Open **PowerShell** and run:

```powershell
gh auth login
```

- Choose **GitHub.com**
- Choose **HTTPS**
- Choose **Login with a web browser** (easiest)
- Copy the code, press Enter, paste the code in the browser, approve

## Push both repos

From the **CROWui-main** folder:

```powershell
cd "c:\Users\wrdyz\Documents\Robloxstuff\CROWui-main"
.\push-repos.ps1
```

Or from anywhere:

```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\wrdyz\Documents\Robloxstuff\CROWui-main\push-repos.ps1"
```

The script will:

1. Use GitHub CLI (`gh`) — or install it if missing  
2. Create **wrdyz/CROWui-deepwoken** and **wrdyz/CROWUI** on GitHub (private) if they don’t exist  
3. Add `origin` and push **main** for both

## Result

- https://github.com/wrdyz/CROWui-deepwoken  
- https://github.com/wrdyz/CROWUI  

## Later: push updates

From each folder:

```powershell
cd "c:\Users\wrdyz\Documents\Robloxstuff\CROWui-deepwoken"
git add .
git commit -m "Your message"
git push
```

Same for `CROWUI` when you change those files.
