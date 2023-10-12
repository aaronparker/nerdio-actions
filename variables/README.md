# Example Variable

Files are are example variable data used by some scripts.

To format the JSON data for pasting into the Nerdio Manager secure variables  values, use the following to compress the JSON.

```powershell
Get-Content -Path ./locale.json | ConvertFrom-Json | ConvertTo-Json -Compress | Set-Clipboard
```
