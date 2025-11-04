# generate-config.ps1 (GitHub Copilot)
# Script để tự động thay thế placeholders từ file .env

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  GitHub Copilot Config Generator" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptDir ".env"

# Check if .env exists
if (-not (Test-Path $envPath)) {
    Write-Host "`nError: .env file not found!" -ForegroundColor Red
    Write-Host "Please copy .env.example to .env first:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .env.example .env" -ForegroundColor Cyan
    exit 1
}

# Load .env file
Write-Host "`nLoading: $envPath" -ForegroundColor Cyan
$envVars = @{}
$content = Get-Content $envPath -Encoding UTF8

foreach ($line in $content) {
    $line = $line.Trim()

    # Skip empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
        continue
    }

    # Parse KEY=VALUE
    $parts = $line.Split('=', 2)
    if ($parts.Length -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        # Remove quotes if present
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        if ($value.StartsWith("'") -and $value.EndsWith("'")) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $envVars[$key] = $value
    }
}

Write-Host "Loaded $($envVars.Count) environment variables" -ForegroundColor Green

# Find all markdown files in current directory and subdirectories
Write-Host "`nSearching for markdown files..." -ForegroundColor Cyan
$markdownFiles = Get-ChildItem -Path $scriptDir -Filter "*.md" -Recurse

$totalReplacements = 0
$filesProcessed = 0

foreach ($file in $markdownFiles) {
    $relativePath = $file.FullName.Substring($scriptDir.Length + 1)
    Write-Host "`nProcessing: $relativePath" -ForegroundColor Cyan

    # Read file content
    $fileContent = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $fileContent

    # Replace placeholders
    foreach ($key in $envVars.Keys) {
        $placeholder = "[$key]"
        $value = $envVars[$key]
        $fileContent = $fileContent.Replace($placeholder, $value)
    }

    # Count replacements
    $replacementCount = 0
    foreach ($key in $envVars.Keys) {
        $placeholder = "[$key]"
        $matches = ([regex]::Matches($originalContent, [regex]::Escape($placeholder))).Count
        $replacementCount += $matches
    }

    if ($replacementCount -gt 0) {
        # Save file
        $fileContent | Out-File $file.FullName -Encoding UTF8 -NoNewline
        Write-Host "  -> Replaced $replacementCount placeholders" -ForegroundColor Green
        $totalReplacements += $replacementCount
        $filesProcessed++
    }
    else {
        Write-Host "  -> No placeholders found" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
if ($totalReplacements -gt 0) {
    Write-Host "Configuration generated successfully!" -ForegroundColor Green
    Write-Host "  Files processed: $filesProcessed" -ForegroundColor White
    Write-Host "  Total replacements: $totalReplacements" -ForegroundColor White
}
else {
    Write-Host "Configuration already complete!" -ForegroundColor Green
    Write-Host "  No placeholders found to replace." -ForegroundColor White
}
Write-Host "=====================================" -ForegroundColor Cyan
