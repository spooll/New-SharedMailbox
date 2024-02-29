# DESCRIPTION
This function creates Shared mailbox with Access groups (fullacces and sendas), add provided users into both, and grant permissions for this groups.
Groups will be hidden from address book, because its service.

The only points, where you should edit this script to get it works in your Enterprise:

$exch= (Get-ADComputer -Filter "name -like 's-ex-0*'").name| Get-Random  #Change to your mask of Exchange servers

Set-ADServerSettings -PreferredServer s-ad-rwdc11.domain.ru              #Change to your Preffered domain controller

$Db = "UnlimDB01", "UnlimDB02", "UnlimDB03"                              #Change to desired Databases

$OUForGroups="OU=MailBoxes Access,DC=domain,DC=ru"                       #Change to Access Group Location

$OUForMailbox="OU=SharedMailboxes,DC=domain,DC=ru"                       #Change to Shared mailboxes location 

All parameters are Mandatory
## PARAMETER Name
The name of shared mailbox

## PARAMETER AccessGroup
Name of access groups, the access group will named with mb_<YourGroupName>, and send As group will be send_<YourGroupName>

## PARAMETER AccessGroupMembers
Users SamaccountName or email separated with commas
 
## EXAMPLE
```powershell
New-SharedMailbox -Name Test -AccessGroup Test -AccessGroupMembers MyUser, NotMyUser
```
Shared Mailbox Test, with groups mb_Test, Send_Test (Hidden) and members: MyUser, NotMyUser
