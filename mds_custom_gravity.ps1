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

$names = @($ideoData.Keys)
$n = $names.Count
$axes = @("a1","a2","a3","a4","a5","a6","a8")

$dist = New-Object 'double[,]' $n,$n
for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        $d = 0.0
        foreach ($ax in $axes) {
            for ($k = 0; $k -lt 3; $k++) {
                $d += [Math]::Pow($ideoData[$names[$i]][$ax][$k] - $ideoData[$names[$j]][$ax][$k], 2)
            }
        }
        $d += [Math]::Pow($ideoData[$names[$i]]["a7"] - $ideoData[$names[$j]]["a7"], 2)
        $d = [Math]::Sqrt($d)
        
        # Apply custom gravity
        $isTrotI = $names[$i] -match "Trotskyism"
        $isTrotJ = $names[$j] -match "Trotskyism"
        
        $rightWing = @("Fascism", "National Syndicalism", "National Bolshevism", "Strasserism")
        $isRightI = $rightWing -contains $names[$i]
        $isRightJ = $rightWing -contains $names[$j]
        
        if ($isTrotI -and $isTrotJ) {
            $d = $d * 0.2  # Force them 5x closer mathematically
        }
        if ($isRightI -and $isRightJ) {
            $d = $d * 0.2  # Force them 5x closer mathematically
        }
        
        $dist[$i,$j] = $d
        $dist[$j,$i] = $d
    }
}

$posX = New-Object 'double[]' $n
$posY = New-Object 'double[]' $n

$maxD = 0; $p1 = 0; $p2 = 1
for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        if ($dist[$i,$j] -gt $maxD) { $maxD = $dist[$i,$j]; $p1 = $i; $p2 = $j }
    }
}
$posX[$p1] = 0; $posY[$p1] = 0
$posX[$p2] = $maxD; $posY[$p2] = 0

$rng = New-Object System.Random
for ($i = 0; $i -lt $n; $i++) {
    if ($i -eq $p1 -or $i -eq $p2) { continue }
    $d1 = $dist[$i,$p1]
    $d2 = $dist[$i,$p2]
    $x = ($d1*$d1 - $d2*$d2 + $maxD*$maxD) / (2*$maxD)
    $ySq = $d1*$d1 - $x*$x
    if ($ySq -lt 0) { $ySq = 0 }
    $y = [Math]::Sqrt($ySq)
    if ($i % 2 -eq 0) { $y = -$y }
    # add a tiny bit of noise to prevent exact overlapping of identical points
    $posX[$i] = $x + ($rng.NextDouble() - 0.5) * 5
    $posY[$i] = $y + ($rng.NextDouble() - 0.5) * 5
}

$lr = 0.01
for ($iter = 0; $iter -lt 500; $iter++) {
    for ($i = 0; $i -lt $n; $i++) {
        $gx = 0.0; $gy = 0.0
        for ($j = 0; $j -lt $n; $j++) {
            if ($i -eq $j) { continue }
            $dx = $posX[$i] - $posX[$j]
            $dy = $posY[$i] - $posY[$j]
            $d2d = [Math]::Sqrt($dx*$dx + $dy*$dy)
            if ($d2d -lt 0.001) { $d2d = 0.001 }
            $target = $dist[$i,$j]
            $diff = ($d2d - $target) / $target
            
            # Anti-squashing force: if they are mathematically very far apart (>120) 
            # but getting squashed together on the 2D plane (<100), repel them strongly!
            if ($target -gt 120 -and $d2d -lt 100) {
                $diff -= 10.0 * ((100 - $d2d) / 100)
            }

            $gx += $diff * ($dx / $d2d)
            $gy += $diff * ($dy / $d2d)
        }
        $posX[$i] -= $lr * $gx
        $posY[$i] -= $lr * $gy
    }
    if ($iter % 100 -eq 99) { $lr *= 0.8 }
}

$minX = ($posX | Measure-Object -Minimum).Minimum
$maxX = ($posX | Measure-Object -Maximum).Maximum
$minY = ($posY | Measure-Object -Minimum).Minimum
$maxY = ($posY | Measure-Object -Maximum).Maximum
$rangeX = $maxX - $minX; if ($rangeX -eq 0) { $rangeX = 1 }
$rangeY = $maxY - $minY; if ($rangeY -eq 0) { $rangeY = 1 }

$margin = 120
$w = 1600
$h = 1200

for ($i = 0; $i -lt $n; $i++) {
    $posX[$i] = $margin + ($posX[$i] - $minX) / $rangeX * ($w - 2*$margin)
    $posY[$i] = $margin + ($posY[$i] - $minY) / $rangeY * ($h - 2*$margin)
}

$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" width="$w" height="$h" style="background:#1a1a2e;font-family:Arial,sans-serif">
<defs>
<style>
text.label { font-size: 13px; fill: #e0e0e0; text-anchor: middle; font-weight: bold; }
text.title { font-size: 24px; fill: #ffffff; text-anchor: middle; font-weight: bold; }
line.link { stroke-opacity: 0.3; }
</style>
</defs>
<text x="$($w/2)" y="40" class="title">Ideology Proximity Map (With Artificial Category Gravity)</text>
"@

for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        # Restore raw distance for drawing lines so we don't draw artificially thick lines
        $d = 0.0
        foreach ($ax in $axes) {
            for ($k = 0; $k -lt 3; $k++) {
                $d += [Math]::Pow($ideoData[$names[$i]][$ax][$k] - $ideoData[$names[$j]][$ax][$k], 2)
            }
        }
        $d += [Math]::Pow($ideoData[$names[$i]]["a7"] - $ideoData[$names[$j]]["a7"], 2)
        $d = [Math]::Sqrt($d)
        
        if ($d -lt 80) {
            $opacity = [Math]::Round(1.0 - ($d / 80.0) * 0.7, 2)
            $thickness = [Math]::Round(3.0 - ($d / 80.0) * 2.0, 1)
            $svg += "  <line x1=`"$([Math]::Round($posX[$i],1))`" y1=`"$([Math]::Round($posY[$i],1))`" x2=`"$([Math]::Round($posX[$j],1))`" y2=`"$([Math]::Round($posY[$j],1))`" class=`"link`" stroke=`"#4a9eff`" stroke-width=`"$thickness`" stroke-opacity=`"$opacity`"/>`n"
        }
    }
}

$colors = @{
    "Marxism-Leninism"="#e74c3c"; "Maoism"="#c0392b";
    "Trotskyism (Orthodox)"="#f39c12"; "Trotskyism (Cliffite)"="#e67e22"; "Trotskyism (Shachtmanite)"="#d35400";
    "Left-Communism (Bordigist)"="#ff6b6b"; "Left-Communism (ICT)"="#ee5a24";
    "Council Communism"="#6c5ce7"; "Communisation"="#a55eea";
    "Autonomism"="#8e44ad"; "Anarcho-Communism"="#9b59b6"; "Insurrectionary Anarchism"="#be2edd";
    "Libertarian Socialism"="#2ecc71"; "Eco-Socialism"="#27ae60";
    "Anarcho-Syndicalism"="#00cec9"; "Syndicalism"="#0984e3"; "Guild Socialism"="#74b9ff";
    "Democratic Socialism"="#55efc4"; "Social Democracy"="#00b894"; "Eurocommunism"="#1abc9c";
    "Mutualism"="#fdcb6e"; "Utopian Socialism"="#ffeaa7"; "Religious Socialism"="#dfe6e9";
    "Anarcho-Primitivism"="#636e72"; "National Syndicalism"="#b2bec3"; "Fascism"="#2d3436";
    "National Bolshevism"="#833471"; "Strasserism"="#b33939"
}

for ($i = 0; $i -lt $n; $i++) {
    $name = $names[$i]
    $cx = [Math]::Round($posX[$i], 1)
    $cy = [Math]::Round($posY[$i], 1)
    $col = $colors[$name]
    if (-not $col) { $col = "#888888" }
    $svg += "  <circle cx=`"$cx`" cy=`"$cy`" r=`"10`" fill=`"$col`" stroke=`"#ffffff`" stroke-width=`"2`"/>`n"
    $svg += "  <text x=`"$cx`" y=`"$($cy - 16)`" class=`"label`">$name</text>`n"
}

$svg += "</svg>"

Set-Content "C:\Users\labib\.gemini\antigravity\brain\ef751dd6-0125-4b82-be8b-e8a64a0c264d\custom_gravity_map.svg" $svg -Encoding UTF8
