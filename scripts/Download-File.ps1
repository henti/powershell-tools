# Download-File is a simple wrapper to get a file from somewhere (HTTP, SMB or local file path)
# If file is supplied, the source is assumed to be a base path. Returns -1 if does not exist,
# 0 if success. Throws error on other errors.
Function Download-File([string] $source, [string] $file, [string] $target) {
    $ErrorActionPreference = 'SilentlyContinue'

    # Ensure that all secure protocols are enabled (TLS 1.2 is not by default in some cases).
    $secureProtocols = @()
    $insecureProtocols = @([System.Net.SecurityProtocolType]::SystemDefault, [System.Net.SecurityProtocolType]::Ssl3)
    foreach ($protocol in [System.Enum]::GetValues([System.Net.SecurityProtocolType])) {
        if ($insecureProtocols -notcontains $protocol) { $secureProtocols += $protocol }
    }
    [System.Net.ServicePointManager]::SecurityProtocol = $secureProtocols

    if (($source).ToLower().StartsWith("http")) {
        if ($file -ne "") {
            $source+="/$file"
        }
        # net.webclient is WAY faster than Invoke-WebRequest
        $wc = New-Object net.webclient
        try {
            Write-Host -ForegroundColor green "INFO: Downloading $source..."
            $wc.Downloadfile($source, $target)
        }
        catch [System.Net.WebException]
        {
            $statusCode = [int]$_.Exception.Response.StatusCode
            if (($statusCode -eq 404) -or ($statusCode -eq 403)) {
                return -1
            }
            Throw ("Failed to download $source - $_")
        }
    } else {
        if ($file -ne "") {
            $source+="\$file"
        }
        if ((Test-Path $source) -eq $false) {
            return -1
        }
        $ErrorActionPreference='Stop'
        Copy-Item "$source" "$target"
    }
    $ErrorActionPreference='Stop'
    return 0
}
 
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
