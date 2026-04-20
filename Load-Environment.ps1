param(
    [Parameter()]
    [string]$EnvFile = ".env"
)

Write-Verbose "Loading environment variables from $EnvFile" -Verbose:$true
$content = (Get-Content -Path $EnvFile -Encoding UTF8) -replace '"',''

ForEach($line in $content) {
    $varName, $varValue = $line -split '=', 2;
    [System.Environment]::SetEnvironmentVariable($varName, $varValue, [System.EnvironmentVariableTarget]::Process)
    Write-Verbose "Loaded `$env:$varName to $varValue" -Verbose:$true
}
