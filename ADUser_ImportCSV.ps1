<#
.SYNOPSIS
    Imports a CSV from Fake Name Generator to create test AD User accounts.
.DESCRIPTION
    Imports a CSV from Fake Name Generator to create test AD User accounts. 
    It will create OUs per country under the Users OU. Bulk generated accounts 
    from fakenamegenerator.com must have as fields:
    * GivenName, Surname, StreetAddress, City, Title, Username, Password, 
    * Country, TelephoneNumber, Occupation
.EXAMPLE
    C:\PS> Import-LabADUser -Path .\unique.csv -OU THLAB
#>
function Import-LabADUser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to CSV file.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        [Parameter(Mandatory=$true,
                   position=1,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Organizational Unit to save users.")]
        [String]
        [Alias('OU')]
        $OrganizationalUnit
    )
    
    begin {
        if (-not (Get-Module -Name 'ActiveDirectory')) {
            Import-Module -Name ActiveDirectory -ErrorAction Stop
        }
    }
    
    process {
        $DomDN = (Get-ADDomain).DistinguishedName
        $forest = (Get-ADDomain).Forest
        
        # Get or create parent OU
        $parentOU = Get-ADOrganizationalUnit -Filter "name -eq '$($OrganizationalUnit)'" -ErrorAction SilentlyContinue
        if($parentOU -eq $null) {
            New-ADOrganizationalUnit -Name "$($OrganizationalUnit)" -Path $DomDN
            $parentOU = Get-ADOrganizationalUnit -Filter "name -eq '$($OrganizationalUnit)'"
        }
        
        # Get or create Users OU under parent OU
        $usersOU = Get-ADOrganizationalUnit -Filter "name -eq 'Users'" -SearchBase $parentOU.DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue
        if($usersOU -eq $null) {
            New-ADOrganizationalUnit -Name "Users" -Path $parentOU.DistinguishedName
            $usersOU = Get-ADOrganizationalUnit -Filter "name -eq 'Users'" -SearchBase $parentOU.DistinguishedName -SearchScope OneLevel
        }

        Import-Csv -Path $Path | ForEach-Object -Process {
            # Check for duplicate user
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($_.Username)'" -ErrorAction SilentlyContinue
            if ($existingUser) {
                Write-Warning "User $($_.Username) already exists. Skipping..."
                return
            }

            # Get or create Country OU under Users OU
            $countryOU = Get-ADOrganizationalUnit -Filter "name -eq '$($_.Country)'" -SearchBase $usersOU.DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue
            if($countryOU -eq $null) {
                New-ADOrganizationalUnit -Name $_.Country -Path $usersOU.DistinguishedName
                $countryOU = Get-ADOrganizationalUnit -Filter "name -eq '$($_.Country)'" -SearchBase $usersOU.DistinguishedName -SearchScope OneLevel
            }

            try {
                # Create the user directly in Country OU
                New-ADUser `
                    -Name "$($_.Surname), $($_.GivenName)" `
                    -SamAccountName $_.Username `
                    -GivenName $_.GivenName `
                    -Surname $_.Surname `
                    -City $_.City `
                    -AccountPassword (ConvertTo-SecureString -Force -AsPlainText $_.Password) `
                    -Enabled $true `
                    -UserPrincipalName "$($_.Username)@$forest" `
                    -DisplayName "$($_.Surname), $($_.GivenName)" `
                    -StreetAddress $_.StreetAddress `
                    -EmailAddress "$($_.Username)@$forest" `
                    -Country $_.Country `
                    -OfficePhone $_.TelephoneNumber `
                    -Title $_.Occupation `
                    -PasswordNeverExpires $true `
                    -Path $countryOU.DistinguishedName
                
                Write-Host "Created user: $($_.Username) in $($_.Country)" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create user $($_.Username): $_"
            }
        }
    }    
    end {}
}
