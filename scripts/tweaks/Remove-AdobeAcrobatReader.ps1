#description: Removes policies that Adobe Acrobat into read-only mode so that it runs as Reader
#execution mode: Combined
#tags: Adobe, Acrobat, PDF

# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html
reg delete "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /f | Out-Null
reg delete "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /f | Out-Null
reg delete "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /f | Out-Null
