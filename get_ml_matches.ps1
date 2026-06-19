$ideoText = Get-Content "C:\Users\labib\.gemini\antigravity\scratch\leftvalues\ideologies.js" -Raw
$matches = [regex]::Matches($ideoText, '"([^"]+)":\s*\{([^}]+)\}')
$ideoData = [ordered]@{}
foreach ($m in $matches) {
    $name = $m.Groups[1].Value
    $body = $m.Groups[2].Value
    $vec = @{}
    foreach ($ax in @('a1','a2','a3','a4','a5','a6','a8')) {
        $pattern = $ax + ':\s*\[([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\]'
        if ($body -match $pattern) {
            $vec[$ax] = @([double]$Matches[1], [double]$Matches[2], [double]$Matches[3])
        }
    }
    if ($body -match "a7:\s*([\d\.]+)") {
        $vec['a7'] = [double]$Matches[1]
    }
    $ideoData[$name] = $vec
}

$ml = $ideoData["National Bolshevism"]
$results = @{}
foreach ($name in $ideoData.Keys) {
    if ($name -eq "National Bolshevism") { continue }
    $d = 0.0
    foreach ($ax in @('a1','a2','a3','a4','a5','a6','a8')) {
        for ($k = 0; $k -lt 3; $k++) {
            $d += [Math]::Pow($ml[$ax][$k] - $ideoData[$name][$ax][$k], 2)
        }
    }
    $d += [Math]::Pow($ml["a7"] - $ideoData[$name]["a7"], 2)
    $results[$name] = [Math]::Round([Math]::Sqrt($d), 1)
}
$results.GetEnumerator() | Sort-Object Value | Select-Object -First 5 | ForEach-Object { "$($_.Name): $($_.Value)" }
