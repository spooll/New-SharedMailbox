function global:New-SharedMailbox {
    param (
        [Parameter(Mandatory=$true,Position=0)] $Name,
        [Parameter(Mandatory=$true,Position=1)] $AccessGroup,
        [Parameter(Mandatory=$true,Position=2)] [object[]]$AccessGroupMembers
    )

    while (-Not(Get-PSSession|Where-Object ConfigurationName -eq "Microsoft.Exchange")) {
        $exch= (Get-ADComputer -Filter "name -like 's-ex-0*'").name| Get-Random        #Change to your template
        $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$exch/Powershell" -Authentication Kerberos
        Import-PSSession $session -DisableNameChecking -AllowClobber | out-null
        Write-Host Exchange PSSession loaded successfully! -ForegroundColor magenta
    }

    Set-ADServerSettings -PreferredServer s-ad-rwdc11.domain.ru #Change to your Preffered domain controller
    $Db = "UnlimDB01", "UnlimDB02", "UnlimDB03"                 #Change to desired Databases
    $OUForGroups="OU=MailBoxes Access,DC=domain,DC=ru"          #Change to Access Group Location
    $OUForMailbox="OU=SharedMailboxes,DC=domain,DC=ru"          #Change to Shared mailboxes location
    $NewGroupMembers = @()

    While (!$Name){
        Write-Host "Name can not be empty, enter name" -ForegroundColor Red
        $Name=Read-Host
    }

    $aduser = Get-ADUser -Filter 'samaccountname -eq $Name'
    if ($aduser) {
        Write-host "Name $Name already exist, provide the new one" -ForegroundColor Red
        $Name = $null        
        While (!$Name){
            $Name=Read-Host "New Name"
        }
    }

    foreach ($us in $AccessGroupMembers){
            if (Get-ADUser -Filter 'UserPrincipalName -eq $us -or Samaccountname -eq $us'){
                ""
                Write-Host "$us found in AD and will be added in group" -ForegroundColor Green
                $NewGroupMembers += $us  
            }
            Else {
                ""
                Write-Host "$us not found in AD and will be removed from queue" -ForegroundColor Red
                ""
            }
    }
    If ($NewGroupMembers.count -eq 0){
        Write-Error "No match users in AD. Access Group can not be empty"
        Break
    }
    ""
    Write-Host "Creating Shared Mailbox $Name..." -ForegroundColor Yellow
    New-Mailbox $Name -Shared -Database (Get-Random $Db) -OrganizationalUnit $OUForMailbox -Alias $Name -SamAccountName $Name | Out-Null
    Start-Sleep 7
    ""
    Write-Host "Creating FullAccess and SendAS Group..." -ForegroundColor Yellow
    
    $MbGroup="mb_$AccessGroup"
    New-DistributionGroup -Type security -Name $MbGroup -DisplayName $MbGroup -OrganizationalUnit $OUForGroups -Alias $MbGroup -SamAccountName $MbGroup -Members $NewGroupMembers  
    Set-DistributionGroup $MbGroup -HiddenFromAddressListsEnabled $true

    $SendGroup= "send_$AccessGroup"
    New-DistributionGroup -Type security -Name $SendGroup -DisplayName $SendGroup -OrganizationalUnit $OUForGroups -Alias $SendGroup -Members $NewGroupMembers -SamAccountName $SendGroup
    Set-DistributionGroup $SendGroup -HiddenFromAddressListsEnabled $true
    Start-Sleep 10
    ""
    Write-Host "Assigning FullAccess and SendAs permissions..." -ForegroundColor Yellow
    ""
    Add-MailboxPermission -Identity $Name -User $MbGroup -AccessRights FullAccess  | Out-Null    
    Get-Mailbox -Identity $name | Add-ADPermission -AccessRights ExtendedRight -ExtendedRights "Send As" -User $SendGroup  | Out-Null
    Start-Sleep 10

    $done1= Get-DistributionGroup $MbGroup 
    $done2= Get-DistributionGroup $SendGroup 
    $mail = Get-Mailbox $Name
    
    Write-Host `
    "Well Done! `nYou have created groups:" -ForegroundColor Green
    ""
    $done1.name
    $done2.name
    ""
    Write-Host "and " -ForegroundColor Green -NoNewline
    Write-host "Mailbox " -NoNewline -ForegroundColor Green
    Write-host $mail.name -NoNewline -ForegroundColor Red
    Write-host " in " -NoNewline -ForegroundColor Green
    Write-host $mail.database  -NoNewline -ForegroundColor red
    Write-host " Database, with " -NoNewline  -ForegroundColor Green
    Write-host $mail.WindowsEmailAddress -NoNewline -ForegroundColor Red
    Write-host " address" -ForegroundColor Green
    ""
    Write-Host "Assigned Permissions:" -ForegroundColor Green

    Start-Sleep 10
    $perm = Get-MailboxPermission $name  | Where-Object user -Like "*$MbGroup*" | Select-Object User, AccessRights
    $perm | Out-String
    $SendAs = Get-Mailbox -Identity $Name | Get-ADPermission | Where-Object { $_.ExtendedRights -like "*send*" -and -not ($_.User -match "NT AUTHORITY")} | Select-Object User,ExtendedRights 
    $SendAs | Out-String
}
