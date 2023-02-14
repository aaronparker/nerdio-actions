#description: Forces Adobe Acrobat into read-only mode so that it runs as Reader
#execution mode: Combined
#tags: Adobe, Acrobat, PDF

# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f | Out-Null
