$questionsText = Get-Content "C:\Users\labib\.gemini\antigravity\scratch\leftvalues\questions.js" -Raw
$qMatches = [regex]::Matches($questionsText, '\{ text: "(.*?)", targets: \{ (.*?) \} \}')

$parsedQ = @()
foreach ($m in $qMatches) {
    $targetsStr = $m.Groups[2].Value
    $targets = @{}
    foreach ($t in ($targetsStr -split ',')) {
        if ($t -match '([a-z0-9]+):\s*([0-9\.\-]+)') {
            $targets[$Matches[1]] = [double]$Matches[2]
        }
    }
    $parsedQ += ,@{ text = $m.Groups[1].Value; targets = $targets }
}

$allKeys = @("a1a","a1b","a1c","a2a","a2b","a2c","a3a","a3b","a3c","a4a","a4b","a4c","a5a","a5b","a5c","a6a","a6b","a6c","a7","a8a","a8b","a8c")
$maxScores = @{}
foreach ($k in $allKeys) { $maxScores[$k] = 0.0 }
foreach ($q in $parsedQ) {
    foreach ($k in $q.targets.Keys) {
        $maxScores[$k] += [Math]::Abs($q.targets[$k])
    }
}

function Compute-Profile {
    param([double[]]$answers)
    $scores = @{}
    foreach ($k in $allKeys) { $scores[$k] = 0.0 }
    for ($q = 0; $q -lt $parsedQ.Count; $q++) {
        foreach ($k in $parsedQ[$q].targets.Keys) {
            $scores[$k] += $answers[$q] * $parsedQ[$q].targets[$k]
        }
    }
    $result = @{}
    $axes = @("a1","a2","a3","a4","a5","a6","a8")
    foreach ($ax in $axes) {
        $na = if ($maxScores["$($ax)a"] -gt 0) { ($maxScores["$($ax)a"] + $scores["$($ax)a"]) / (2 * $maxScores["$($ax)a"]) * 100 } else { 50 }
        $nb = if ($maxScores["$($ax)b"] -gt 0) { ($maxScores["$($ax)b"] + $scores["$($ax)b"]) / (2 * $maxScores["$($ax)b"]) * 100 } else { 50 }
        $nc = if ($maxScores["$($ax)c"] -gt 0) { ($maxScores["$($ax)c"] + $scores["$($ax)c"]) / (2 * $maxScores["$($ax)c"]) * 100 } else { 50 }
        $total = $na + $nb + $nc
        if ($total -eq 0) { $na = 33.3; $nb = 33.3; $nc = 33.4; $total = 100 }
        $pctA = [Math]::Round($na / $total * 100, 1)
        $pctB = [Math]::Round($nb / $total * 100, 1)
        $pctC = [Math]::Round(100 - $pctA - $pctB, 1)
        $result[$ax] = @($pctA, $pctB, $pctC)
    }
    $result["a7"] = [Math]::Round(($maxScores["a7"] + $scores["a7"]) / (2 * $maxScores["a7"]) * 100, 1)
    return $result
}

function Compute-Distance {
    param($profile, $ideoVec)
    $dist = 0.0
    foreach ($ax in @("a1","a2","a3","a4","a5","a6","a8")) {
        for ($i = 0; $i -lt 3; $i++) {
            $dist += [Math]::Pow($profile[$ax][$i] - $ideoVec[$ax][$i], 2)
        }
    }
    $dist += [Math]::Pow($profile["a7"] - $ideoVec["a7"], 2)
    return $dist
}

$ideoData = [ordered]@{
    "ML" = @{ a1=@(55,25,20); a2=@(70,5,25); a3=@(40,45,15); a4=@(45,40,15); a5=@(75,15,10); a6=@(60,15,25); a7=65; a8=@(40,15,45) }
    "Trot-Orth" = @{ a1=@(45,40,15); a2=@(80,5,15); a3=@(10,30,60); a4=@(85,5,10); a5=@(70,15,15); a6=@(50,20,30); a7=75; a8=@(90,5,5) }
    "Trot-Cliff" = @{ a1=@(70,10,20); a2=@(75,5,20); a3=@(40,50,10); a4=@(95,0,5); a5=@(60,20,20); a6=@(40,25,35); a7=80; a8=@(85,10,5) }
    "Trot-Shacht" = @{ a1=@(30,50,20); a2=@(65,10,25); a3=@(10,30,60); a4=@(70,10,20); a5=@(55,25,20); a6=@(35,30,35); a7=80; a8=@(70,10,20) }
    "LC-Bordigist" = @{ a1=@(80,10,10); a2=@(85,10,5); a3=@(75,15,10); a4=@(85,10,5); a5=@(85,5,10); a6=@(50,20,30); a7=60; a8=@(80,10,10) }
    "LC-ICT" = @{ a1=@(80,5,15); a2=@(85,5,10); a3=@(15,50,35); a4=@(90,5,5); a5=@(55,10,35); a6=@(30,40,30); a7=80; a8=@(85,5,10) }
    "CouncilCom" = @{ a1=@(75,5,20); a2=@(70,10,20); a3=@(5,40,55); a4=@(75,5,20); a5=@(10,15,75); a6=@(35,25,40); a7=75; a8=@(85,5,10) }
    "Communisation" = @{ a1=@(80,5,15); a2=@(65,15,20); a3=@(5,15,80); a4=@(65,5,30); a5=@(5,10,85); a6=@(15,30,55); a7=85; a8=@(80,5,15) }
    "Autonomism" = @{ a1=@(55,10,35); a2=@(50,15,35); a3=@(5,20,75); a4=@(50,10,40); a5=@(10,20,70); a6=@(15,30,55); a7=85; a8=@(70,15,15) }
    "AnCom" = @{ a1=@(55,5,40); a2=@(25,45,30); a3=@(5,10,85); a4=@(60,5,35); a5=@(5,20,75); a6=@(15,40,45); a7=90; a8=@(75,10,15) }
    "InsurrAnarch" = @{ a1=@(80,5,15); a2=@(15,60,25); a3=@(5,5,90); a4=@(40,10,50); a5=@(5,10,85); a6=@(20,35,45); a7=85; a8=@(70,10,20) }
    "AnSynd" = @{ a1=@(50,10,40); a2=@(20,20,60); a3=@(5,15,80); a4=@(65,5,30); a5=@(5,75,20); a6=@(35,30,35); a7=80; a8=@(75,10,15) }
    "Syndicalism" = @{ a1=@(45,20,35); a2=@(20,15,65); a3=@(10,30,60); a4=@(55,15,30); a5=@(10,70,20); a6=@(45,25,30); a7=70; a8=@(65,15,20) }
    "NatSynd" = @{ a1=@(50,20,30); a2=@(10,30,60); a3=@(35,40,25); a4=@(5,80,15); a5=@(20,65,15); a6=@(55,20,25); a7=20; a8=@(15,30,55) }
    "Fascism" = @{ a1=@(55,15,30); a2=@(5,55,40); a3=@(50,40,10); a4=@(5,85,10); a5=@(60,25,15); a6=@(60,20,20); a7=5; a8=@(5,25,70) }
    "Maoism" = @{ a1=@(70,10,20); a2=@(55,15,30); a3=@(35,40,25); a4=@(35,40,25); a5=@(65,15,20); a6=@(55,20,25); a7=65; a8=@(50,20,30) }
    "DemSoc" = @{ a1=@(15,65,20); a2=@(25,30,45); a3=@(35,30,35); a4=@(45,30,25); a5=@(55,25,20); a6=@(25,35,40); a7=80; a8=@(45,25,30) }
    "SocDem" = @{ a1=@(5,80,15); a2=@(15,20,65); a3=@(50,30,20); a4=@(35,45,20); a5=@(60,25,15); a6=@(25,40,35); a7=75; a8=@(20,30,50) }
    "Eurocom" = @{ a1=@(15,65,20); a2=@(45,10,45); a3=@(35,35,30); a4=@(40,40,20); a5=@(60,20,20); a6=@(30,35,35); a7=75; a8=@(35,25,40) }
    "EcoSoc" = @{ a1=@(30,30,40); a2=@(40,25,35); a3=@(10,25,65); a4=@(50,10,40); a5=@(20,30,50); a6=@(10,55,35); a7=85; a8=@(55,20,25) }
    "AnPrim" = @{ a1=@(60,5,35); a2=@(10,65,25); a3=@(5,5,90); a4=@(15,5,80); a5=@(5,5,90); a6=@(5,80,15); a7=50; a8=@(50,25,25) }
    "LibSoc" = @{ a1=@(40,15,45); a2=@(30,30,40); a3=@(5,15,80); a4=@(45,10,45); a5=@(10,30,60); a6=@(20,35,45); a7=85; a8=@(65,15,20) }
    "Mutualism" = @{ a1=@(15,25,60); a2=@(15,30,55); a3=@(5,10,85); a4=@(20,10,70); a5=@(5,40,55); a6=@(30,30,40); a7=75; a8=@(35,45,20) }
    "GuildSoc" = @{ a1=@(15,40,45); a2=@(15,25,60); a3=@(15,25,60); a4=@(25,35,40); a5=@(10,65,25); a6=@(40,30,30); a7=60; a8=@(40,40,20) }
    "UtopSoc" = @{ a1=@(10,30,60); a2=@(5,70,25); a3=@(10,15,75); a4=@(25,15,60); a5=@(10,15,75); a6=@(15,45,40); a7=75; a8=@(30,35,35) }
    "ReligSoc" = @{ a1=@(15,40,45); a2=@(10,60,30); a3=@(20,25,55); a4=@(30,30,40); a5=@(20,20,60); a6=@(20,45,35); a7=35; a8=@(30,30,40) }
}

$names = @($ideoData.Keys)
$n = $names.Count

# Compute optimal answer arrays for each ideology
$optimalAnswers = @{}
$multipliers = @(-1.0, -0.5, 0.0, 0.5, 1.0)

foreach ($name in $names) {
    $targetVec = $ideoData[$name]
    $bestAnswers = New-Object 'double[]' $parsedQ.Count
    for ($q = 0; $q -lt $parsedQ.Count; $q++) { $bestAnswers[$q] = 0.0 }
    
    for ($round = 0; $round -lt 3; $round++) {
        for ($q = 0; $q -lt $parsedQ.Count; $q++) {
            $bestMult = 0.0
            $bestDistVal = [double]::MaxValue
            foreach ($mult in $multipliers) {
                $bestAnswers[$q] = $mult
                $profile = Compute-Profile $bestAnswers
                $d = Compute-Distance $profile $targetVec
                if ($d -lt $bestDistVal) {
                    $bestDistVal = $d
                    $bestMult = $mult
                }
            }
            $bestAnswers[$q] = $bestMult
        }
    }
    $optimalAnswers[$name] = $bestAnswers
}

# Distance matrix based on the 89-dimensional answer vectors
# Euclidean distance between answer profiles
$dist = New-Object 'double[,]' $n,$n
for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        $d = 0.0
        for ($q = 0; $q -lt $parsedQ.Count; $q++) {
            $d += [Math]::Pow($optimalAnswers[$names[$i]][$q] - $optimalAnswers[$names[$j]][$q], 2)
        }
        $d = [Math]::Sqrt($d)
        $dist[$i,$j] = $d
        $dist[$j,$i] = $d
    }
}

# MDS logic exactly as before
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

for ($i = 0; $i -lt $n; $i++) {
    if ($i -eq $p1 -or $i -eq $p2) { continue }
    $d1 = $dist[$i,$p1]
    $d2 = $dist[$i,$p2]
    $x = ($d1*$d1 - $d2*$d2 + $maxD*$maxD) / (2*$maxD)
    $ySq = $d1*$d1 - $x*$x
    if ($ySq -lt 0) { $ySq = 0 }
    $y = [Math]::Sqrt($ySq)
    if ($i % 2 -eq 0) { $y = -$y }
    $posX[$i] = $x
    $posY[$i] = $y
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
            $gx += $diff * ($dx / $d2d)
            $gy += $diff * ($dy / $d2d)
        }
        $posX[$i] -= $lr * $gx
        $posY[$i] -= $lr * $gy
    }
    if ($iter % 100 -eq 99) { $lr *= 0.7 }
}

$minX = ($posX | Measure-Object -Minimum).Minimum
$maxX = ($posX | Measure-Object -Maximum).Maximum
$minY = ($posY | Measure-Object -Minimum).Minimum
$maxY = ($posY | Measure-Object -Maximum).Maximum
$rangeX = $maxX - $minX; if ($rangeX -eq 0) { $rangeX = 1 }
$rangeY = $maxY - $minY; if ($rangeY -eq 0) { $rangeY = 1 }

$margin = 80
$w = 900
$h = 700

for ($i = 0; $i -lt $n; $i++) {
    $posX[$i] = $margin + ($posX[$i] - $minX) / $rangeX * ($w - 2*$margin)
    $posY[$i] = $margin + ($posY[$i] - $minY) / $rangeY * ($h - 2*$margin)
}

$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" width="$w" height="$h" style="background:#1a1a2e;font-family:Arial,sans-serif">
<defs>
<style>
text.label { font-size: 9px; fill: #e0e0e0; text-anchor: middle; }
text.title { font-size: 16px; fill: #ffffff; text-anchor: middle; font-weight: bold; }
line.link { stroke-opacity: 0.3; }
</style>
</defs>
<text x="$($w/2)" y="30" class="title">Ideology Proximity Map (Based STRICTLY on Optimal Answers Similarity)</text>
"@

$sumD = 0; $countD = 0
for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        $sumD += $dist[$i,$j]; $countD++
    }
}
$meanD = $sumD / $countD
$threshold = $meanD * 0.85

for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i+1; $j -lt $n; $j++) {
        $d = $dist[$i,$j]
        if ($d -lt $threshold) {
            $opacity = [Math]::Round(1.0 - ($d / $threshold) * 0.7, 2)
            $thickness = [Math]::Round(3.0 - ($d / $threshold) * 2.0, 1)
            $svg += "  <line x1=`"$([Math]::Round($posX[$i],1))`" y1=`"$([Math]::Round($posY[$i],1))`" x2=`"$([Math]::Round($posX[$j],1))`" y2=`"$([Math]::Round($posY[$j],1))`" class=`"link`" stroke=`"#4a9eff`" stroke-width=`"$thickness`" stroke-opacity=`"$opacity`"/>`n"
        }
    }
}

$colors = @{
    "ML"="#e74c3c"; "Maoism"="#c0392b";
    "Trot-Orth"="#f39c12"; "Trot-Cliff"="#e67e22"; "Trot-Shacht"="#d35400";
    "LC-Bordigist"="#ff6b6b"; "LC-ICT"="#ee5a24";
    "CouncilCom"="#6c5ce7"; "Communisation"="#a55eea";
    "Autonomism"="#8e44ad"; "AnCom"="#9b59b6"; "InsurrAnarch"="#be2edd";
    "LibSoc"="#2ecc71"; "EcoSoc"="#27ae60";
    "AnSynd"="#00cec9"; "Syndicalism"="#0984e3"; "GuildSoc"="#74b9ff";
    "DemSoc"="#55efc4"; "SocDem"="#00b894"; "Eurocom"="#1abc9c";
    "Mutualism"="#fdcb6e"; "UtopSoc"="#ffeaa7"; "ReligSoc"="#dfe6e9";
    "AnPrim"="#636e72"; "NatSynd"="#b2bec3"; "Fascism"="#2d3436"
}

$fullNames = @{
    "ML"="Marxism-Leninism"; "Maoism"="Maoism";
    "Trot-Orth"="Trotskyism (Orthodox)"; "Trot-Cliff"="Trotskyism (Cliffite)"; "Trot-Shacht"="Trotskyism (Shachtmanite)";
    "LC-Bordigist"="Left-Communism (Bordigist)"; "LC-ICT"="Left-Communism (ICT)";
    "CouncilCom"="Council Communism"; "Communisation"="Communisation";
    "Autonomism"="Autonomism"; "AnCom"="Anarcho-Communism"; "InsurrAnarch"="Insurrectionary Anarchism";
    "LibSoc"="Libertarian Socialism"; "EcoSoc"="Eco-Socialism";
    "AnSynd"="Anarcho-Syndicalism"; "Syndicalism"="Syndicalism"; "GuildSoc"="Guild Socialism";
    "DemSoc"="Democratic Socialism"; "SocDem"="Social Democracy"; "Eurocom"="Eurocommunism";
    "Mutualism"="Mutualism"; "UtopSoc"="Utopian Socialism"; "ReligSoc"="Religious Socialism";
    "AnPrim"="Anarcho-Primitivism"; "NatSynd"="National Syndicalism"; "Fascism"="Fascism"
}

for ($i = 0; $i -lt $n; $i++) {
    $name = $names[$i]
    $cx = [Math]::Round($posX[$i], 1)
    $cy = [Math]::Round($posY[$i], 1)
    $col = $colors[$name]
    if (-not $col) { $col = "#888888" }
    $svg += "  <circle cx=`"$cx`" cy=`"$cy`" r=`"8`" fill=`"$col`" stroke=`"#ffffff`" stroke-width=`"1.5`"/>`n"
    $label = $fullNames[$name]
    if (-not $label) { $label = $name }
    $svg += "  <text x=`"$cx`" y=`"$($cy - 12)`" class=`"label`">$label</text>`n"
}

$svg += "</svg>"

Set-Content "C:\Users\labib\.gemini\antigravity\brain\ef751dd6-0125-4b82-be8b-e8a64a0c264d\answers_mds_map.svg" $svg -Encoding UTF8
