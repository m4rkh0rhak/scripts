Import-Module ActiveDirectory

# Path to your CSV file
$Users = Import-Csv -Path "C:\Users\Administrator\Downloads\adusers.csv"

# Base OU path
$BaseOU = "OU=Users,OU=THLAB,DC=cyb3rr00kie,DC=lab"

foreach ($User in $Users) {
    $Name = "$($User.GivenName) $($User.Surname)"
    $UserPrincipalName = $User.Username + "@cyb3rr00kie.lab"
    $Password = (ConvertTo-SecureString $User.Password -AsPlainText -Force)
    
    # Construct OU path based on Country column (CA, DE, GB, or US)
    $UserOU = "OU=$($User.Country),$BaseOU"
    
    New-ADUser `
        -Name $Name `
        -GivenName $User.GivenName `
        -Surname $User.Surname `
        -SamAccountName $User.Username `
        -UserPrincipalName $UserPrincipalName `
        -AccountPassword $Password `
        -Enabled $true `
        -Path $UserOU `
        -StreetAddress $User.StreetAddress `
        -City $User.City `
        -Title $User.Title `
        -Country $User.Country `
        -OfficePhone $User.TelephoneNumber `
        -Description $User.Occupation
}
