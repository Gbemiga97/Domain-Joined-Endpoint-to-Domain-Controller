<#
  02-Create-Users-and-Groups.ps1
  Run on : CRF-DC01 (PowerShell as Administrator)
  Purpose: Create the four security groups and the six starting employees.
           Safe to re-run: it skips anything that already exists, so it is fine
           if you already created one user by hand.
  NOTE   : The temporary password is typed at a prompt. It is never stored in this file.
#>
Import-Module ActiveDirectory

$domain = Get-ADDomain
$root   = "OU=CobaltRidge,$($domain.DistinguishedName)"

$tempPassword = Read-Host -Prompt "Temporary password for new users (12+ characters)" -AsSecureString

# ---- Groups -----------------------------------------------------------------
"FIN-Staff","HR-Staff","IT-Staff","FIN-ReadOnly" | ForEach-Object {
    if (-not (Get-ADGroup -Filter "Name -eq '$_'")) {
        New-ADGroup -Name $_ -GroupScope Global -GroupCategory Security -Path "OU=Groups,$root"
    }
}

# Which group each department's staff belong to
$groupFor = @{ Finance = "FIN-Staff"; HR = "HR-Staff"; IT = "IT-Staff" }

# ---- Users ------------------------------------------------------------------
$users = @(
    @{ First = "Avery";  Last = "Brooks";    Sam = "abrooks";    Dept = "Finance"; Title = "Financial Analyst" }
    @{ First = "Nolan";  Last = "Pierce";    Sam = "npierce";    Dept = "Finance"; Title = "Accounts Payable Lead" }
    @{ First = "Marcus"; Last = "Ellery";    Sam = "mellery";    Dept = "HR";      Title = "HR Manager" }
    @{ First = "Talia";  Last = "Whitmore";  Sam = "twhitmore";  Dept = "HR";      Title = "HR Generalist" }
    @{ First = "Elias";  Last = "Brandt";    Sam = "ebrandt";    Dept = "IT";      Title = "Help Desk Technician" }
    @{ First = "Imani";  Last = "Okafor";    Sam = "iokafor";    Dept = "IT";      Title = "Compliance Auditor" }
)

foreach ($u in $users) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'")) {
        $params = @{
            Name                  = "$($u.First) $($u.Last)"
            GivenName             = $u.First
            Surname               = $u.Last
            SamAccountName        = $u.Sam
            UserPrincipalName     = "$($u.Sam)@$($domain.DNSRoot)"
            Title                 = $u.Title
            Department            = $u.Dept
            Path                  = "OU=$($u.Dept),$root"
            AccountPassword       = $tempPassword
            ChangePasswordAtLogon = $true
            Enabled               = $true
        }
        New-ADUser @params
    }
    Add-ADGroupMember -Identity $groupFor[$u.Dept] -Members $u.Sam -ErrorAction SilentlyContinue
}

# The auditor also gets read-only access to the Finance share (set up in Section 5)
Add-ADGroupMember -Identity "FIN-ReadOnly" -Members "iokafor" -ErrorAction SilentlyContinue

# ---- Check ------------------------------------------------------------------
Get-ADUser -Filter * -SearchBase $root -Properties Department, Title |
    Select-Object SamAccountName, Department, Title | Sort-Object Department, SamAccountName
