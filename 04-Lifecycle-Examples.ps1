<#
  04-Lifecycle-Examples.ps1
  Run on : CRF-DC01 (PowerShell as Administrator)
  Purpose: PowerShell versions of the Joiner / Mover / Leaver steps from Section 8.
           Run ONE block at a time (do not run the whole file at once).
#>
Import-Module ActiveDirectory
$domain = Get-ADDomain
$root   = "OU=CobaltRidge,$($domain.DistinguishedName)"

# ===== JOINER: new hire Jordan Maddox, Finance ==================================
$tempPassword = Read-Host -Prompt "Temporary password (12+ characters)" -AsSecureString
New-ADUser -Name "Jordan Maddox" -GivenName "Jordan" -Surname "Maddox" -SamAccountName "jmaddox" -UserPrincipalName "jmaddox@$($domain.DNSRoot)" -Title "Junior Accountant" -Department "Finance" -Path "OU=Finance,$root" -AccountPassword $tempPassword -ChangePasswordAtLogon $true -Enabled $true
Add-ADGroupMember -Identity "FIN-Staff" -Members "jmaddox"

# ===== MOVER: Nolan Pierce moves from Finance to IT =============================
# Order matters: remove the OLD access first, then add the NEW access.
Remove-ADGroupMember -Identity "FIN-Staff" -Members "npierce" -Confirm:$false
Add-ADGroupMember    -Identity "IT-Staff"  -Members "npierce"
Get-ADUser "npierce" | Move-ADObject -TargetPath "OU=IT,$root"
Set-ADUser "npierce" -Department "IT" -Title "Systems Analyst"

# ===== LEAVER: Talia Whitmore resigns ===========================================
Disable-ADAccount -Identity "twhitmore"
Get-ADPrincipalGroupMembership "twhitmore" | Where-Object Name -ne "Domain Users" |
    ForEach-Object { Remove-ADGroupMember -Identity $_ -Members "twhitmore" -Confirm:$false }
Set-ADUser "twhitmore" -Description "Disabled $(Get-Date -Format yyyy-MM-dd) - resigned"
Get-ADUser "twhitmore" | Move-ADObject -TargetPath "OU=Disabled-Users,$root"

# ===== CHECK ====================================================================
Get-ADUser "twhitmore" -Properties Enabled, Description | Select-Object SamAccountName, Enabled, Description, DistinguishedName
Get-ADPrincipalGroupMembership "twhitmore" | Select-Object Name
