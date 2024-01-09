param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $false)]
    [string]$SmbConfFilePath = "/etc/samba/smb.conf",
    [Parameter(Mandatory = $false)]
    [switch]$ValidateSmbConf = $false,
    [Parameter(Mandatory = $false)]
    [switch]$NoExit = $false,
    [Parameter(Mandatory = $false)]
    [switch]$StartSambaServer = $false
)

Import-Module powershell-yaml

Write-Host "Reading configuration from $FilePath"
[string]$yaml = [System.IO.File]::ReadAllText($FilePath)

$configuration = ConvertFrom-Yaml $yaml

$file = [System.IO.StreamWriter]::new($SmbConfFilePath)

if ($configuration.Keys -Contains "Users") {

    foreach ($user in $configuration["Users"]) {
        Write-Host "Creating system user $($user.name)"
        useradd $user.name

        Write-Host "Creating samba user for $($user.name)"
        ./AddSambaUser.sh $user.name $user.password
    }
}

if ($configuration.Keys -Contains "Global") {
    $global = $configuration["Global"]

    $file.WriteLine("[Global]")

    foreach ($key in $global.Keys) {
        $value = $global[$key]
        $file.WriteLine("  $key = $value")
    }

    $file.WriteLine()
}

if ($configuration.Keys -Contains "Shares") {

    foreach ($share in $configuration["Shares"]) {
        Write-Host "Adding share $($share.name)"

        $file.WriteLine("[$($share.name)]")

        foreach ($key in $share.Keys) {
            if ($key -ne "name") {
                $value = $share[$key]
                $file.WriteLine("  $key = $value")
            }
        }
    }
}

$file.Close()

if ($ValidateSmbConf) {
    testparm -s $SmbConfFilePath

    if ($LASTEXITCODE -ne 0) {
        throw "smb.conf is invalid!"
    }
    else {
        Write-Host "smb.conf is valid"
    }
}

if ($StartSambaServer) {
    service smbd start
}

if ($NoExit) {
    tail -f /dev/null
}
