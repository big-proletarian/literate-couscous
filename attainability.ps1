# Attainability Analysis
# For each axis sub-score, compute the achievable min/max from the quiz.
# Then compute the achievable min/max for each ternary percentage.
# Then, for each ideology, check if it can ever be the closest match.

# Step 1: Parse questions.js to get all question targets
$questionsText = Get-Content "C:\Users\labib\.gemini\antigravity\scratch\leftvalues\questions.js" -Raw
$qMatches = [regex]::Matches($questionsText, '\{ text: "(.*?)", targets: \{ (.*?) \} \}')

$allKeys = @("a1a","a1b","a1c","a2a","a2b","a2c","a3a","a3b","a3c","a4a","a4b","a4c","a5a","a5b","a5c","a6a","a6b","a6c","a7","a8a","a8b","a8c")

# maxScores[key] = sum of abs(weight) across all questions for that key
$maxScores = @{}
foreach ($k in $allKeys) { $maxScores[$k] = 0.0 }

# For each question, store the targets
$parsedQ = @()
foreach ($m in $qMatches) {
    $targetsStr = $m.Groups[2].Value
    $targets = @{}
    foreach ($t in ($targetsStr -split ',')) {
        if ($t -match '([a-z0-9]+):\s*([0-9\.\-]+)') {
            $key = $Matches[1]
            $val = [double]$Matches[2]
            $targets[$key] = $val
            $maxScores[$key] += [Math]::Abs($val)
        }
    }
    $parsedQ += ,$targets
}

Write-Host "Total questions parsed: $($parsedQ.Count)"
Write-Host ""

# Step 2: For each sub-score key, compute min and max achievable raw score
# Each question can be answered with multiplier in {-1, -0.5, 0, 0.5, 1}
# raw_score[key] = sum over questions of (multiplier * target_weight)
# To maximize: if target_weight > 0, use multiplier=1; if < 0, use multiplier=-1
# To minimize: if target_weight > 0, use multiplier=-1; if < 0, use multiplier=1

# But questions affect MULTIPLE keys simultaneously, so the min/max for each key
# independently is an UPPER BOUND on what's achievable.
# The ACTUAL achievable range is constrained by the fact that one answer affects multiple axes.

# Let's first compute independent min/max (upper bound)
$indepMin = @{}
$indepMax = @{}
foreach ($k in $allKeys) {
    $minVal = 0.0; $maxVal = 0.0
    for ($q = 0; $q -lt $parsedQ.Count; $q++) {
        if ($parsedQ[$q].ContainsKey($k)) {
            $w = $parsedQ[$q][$k]
            # To maximize this key: if w>0, use mult=1; if w<0, use mult=-1 => contribution = |w|
            $maxVal += [Math]::Abs($w)
            # To minimize this key: if w>0, use mult=-1; if w<0, use mult=1 => contribution = -|w|
            $minVal -= [Math]::Abs($w)
        }
    }
    $indepMin[$k] = $minVal
    $indepMax[$k] = $maxVal
}

# Step 3: Convert raw scores to percentages using normalize function
# normalize(raw, max) = (max + raw) / (2 * max) * 100
# For ternary: na, nb, nc = normalized values, then pctA = na/(na+nb+nc)*100 etc.

# The key insight: independently maximizing a1a while minimizing a1b and a1c
# is NOT always possible because some questions affect multiple sub-keys of the same axis.

# Let's compute what percentage ranges are ACTUALLY achievable per axis
# by trying extreme answer profiles

function Compute-Profile {
    param([double[]]$answers)
    
    $scores = @{}
    foreach ($k in $allKeys) { $scores[$k] = 0.0 }
    
    for ($q = 0; $q -lt $parsedQ.Count; $q++) {
        foreach ($k in $parsedQ[$q].Keys) {
            $scores[$k] += $answers[$q] * $parsedQ[$q][$k]
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
    $axes = @("a1","a2","a3","a4","a5","a6","a8")
    $dist = 0.0
    foreach ($ax in $axes) {
        for ($i = 0; $i -lt 3; $i++) {
            $dist += [Math]::Pow($profile[$ax][$i] - $ideoVec[$ax][$i], 2)
        }
    }
    $dist += [Math]::Pow($profile["a7"] - $ideoVec["a7"], 2)
    return $dist
}

# Step 4: Load ideologies
$ideoData = @{
    "Marxism-Leninism" = @{ a1=@(55,25,20); a2=@(70,5,25); a3=@(40,45,15); a4=@(45,40,15); a5=@(75,15,10); a6=@(60,15,25); a7=65; a8=@(40,15,45) }
    "Trotskyism (Orthodox)" = @{ a1=@(45,40,15); a2=@(80,5,15); a3=@(10,30,60); a4=@(85,5,10); a5=@(70,15,15); a6=@(50,20,30); a7=75; a8=@(90,5,5) }
    "Trotskyism (Cliffite)" = @{ a1=@(70,10,20); a2=@(75,5,20); a3=@(40,50,10); a4=@(95,0,5); a5=@(60,20,20); a6=@(40,25,35); a7=80; a8=@(85,10,5) }
    "Trotskyism (Shachtmanite)" = @{ a1=@(30,50,20); a2=@(65,10,25); a3=@(10,30,60); a4=@(70,10,20); a5=@(55,25,20); a6=@(35,30,35); a7=80; a8=@(70,10,20) }
    "Left-Communism (Bordigist)" = @{ a1=@(80,10,10); a2=@(85,10,5); a3=@(75,15,10); a4=@(85,10,5); a5=@(85,5,10); a6=@(50,20,30); a7=60; a8=@(80,10,10) }
    "Left-Communism (ICT)" = @{ a1=@(80,5,15); a2=@(85,5,10); a3=@(15,50,35); a4=@(90,5,5); a5=@(55,10,35); a6=@(30,40,30); a7=80; a8=@(85,5,10) }
    "Council Communism" = @{ a1=@(75,5,20); a2=@(70,10,20); a3=@(5,40,55); a4=@(75,5,20); a5=@(10,15,75); a6=@(35,25,40); a7=75; a8=@(85,5,10) }
    "Communisation" = @{ a1=@(80,5,15); a2=@(65,15,20); a3=@(5,15,80); a4=@(65,5,30); a5=@(5,10,85); a6=@(15,30,55); a7=85; a8=@(80,5,15) }
    "Autonomism" = @{ a1=@(55,10,35); a2=@(50,15,35); a3=@(5,20,75); a4=@(50,10,40); a5=@(10,20,70); a6=@(15,30,55); a7=85; a8=@(70,15,15) }
    "Anarcho-Communism" = @{ a1=@(55,5,40); a2=@(25,45,30); a3=@(5,10,85); a4=@(60,5,35); a5=@(5,20,75); a6=@(15,40,45); a7=90; a8=@(75,10,15) }
    "Insurrectionary Anarchism" = @{ a1=@(80,5,15); a2=@(15,60,25); a3=@(5,5,90); a4=@(40,10,50); a5=@(5,10,85); a6=@(20,35,45); a7=85; a8=@(70,10,20) }
    "Anarcho-Syndicalism" = @{ a1=@(50,10,40); a2=@(20,20,60); a3=@(5,15,80); a4=@(65,5,30); a5=@(5,75,20); a6=@(35,30,35); a7=80; a8=@(75,10,15) }
    "Syndicalism" = @{ a1=@(45,20,35); a2=@(20,15,65); a3=@(10,30,60); a4=@(55,15,30); a5=@(10,70,20); a6=@(45,25,30); a7=70; a8=@(65,15,20) }
    "National Syndicalism" = @{ a1=@(50,20,30); a2=@(10,30,60); a3=@(35,40,25); a4=@(5,80,15); a5=@(20,65,15); a6=@(55,20,25); a7=20; a8=@(15,30,55) }
    "Fascism" = @{ a1=@(55,15,30); a2=@(5,55,40); a3=@(50,40,10); a4=@(5,85,10); a5=@(60,25,15); a6=@(60,20,20); a7=5; a8=@(5,25,70) }
    "Maoism" = @{ a1=@(70,10,20); a2=@(55,15,30); a3=@(35,40,25); a4=@(35,40,25); a5=@(65,15,20); a6=@(55,20,25); a7=65; a8=@(50,20,30) }
    "Democratic Socialism" = @{ a1=@(15,65,20); a2=@(25,30,45); a3=@(35,30,35); a4=@(45,30,25); a5=@(55,25,20); a6=@(25,35,40); a7=80; a8=@(45,25,30) }
    "Social Democracy" = @{ a1=@(5,80,15); a2=@(15,20,65); a3=@(50,30,20); a4=@(35,45,20); a5=@(60,25,15); a6=@(25,40,35); a7=75; a8=@(20,30,50) }
    "Eurocommunism" = @{ a1=@(15,65,20); a2=@(45,10,45); a3=@(35,35,30); a4=@(40,40,20); a5=@(60,20,20); a6=@(30,35,35); a7=75; a8=@(35,25,40) }
    "Eco-Socialism" = @{ a1=@(30,30,40); a2=@(40,25,35); a3=@(10,25,65); a4=@(50,10,40); a5=@(20,30,50); a6=@(10,55,35); a7=85; a8=@(55,20,25) }
    "Anarcho-Primitivism" = @{ a1=@(60,5,35); a2=@(10,65,25); a3=@(5,5,90); a4=@(15,5,80); a5=@(5,5,90); a6=@(5,80,15); a7=50; a8=@(50,25,25) }
    "Libertarian Socialism" = @{ a1=@(40,15,45); a2=@(30,30,40); a3=@(5,15,80); a4=@(45,10,45); a5=@(10,30,60); a6=@(20,35,45); a7=85; a8=@(65,15,20) }
    "Mutualism" = @{ a1=@(15,25,60); a2=@(15,30,55); a3=@(5,10,85); a4=@(20,10,70); a5=@(5,40,55); a6=@(30,30,40); a7=75; a8=@(35,45,20) }
    "Guild Socialism" = @{ a1=@(15,40,45); a2=@(15,25,60); a3=@(15,25,60); a4=@(25,35,40); a5=@(10,65,25); a6=@(40,30,30); a7=60; a8=@(40,40,20) }
    "Utopian Socialism" = @{ a1=@(10,30,60); a2=@(5,70,25); a3=@(10,15,75); a4=@(25,15,60); a5=@(10,15,75); a6=@(15,45,40); a7=75; a8=@(30,35,35) }
    "Religious Socialism" = @{ a1=@(15,40,45); a2=@(10,60,30); a3=@(20,25,55); a4=@(30,30,40); a5=@(20,20,60); a6=@(20,45,35); a7=35; a8=@(30,30,40) }
}

# Step 5: Compute achievable ranges
# For each axis, try to maximize/minimize each sub-component
# by greedily choosing the best answer per question for that sub-component
# while accepting whatever happens to other sub-components

$output = ""
$output += "# ACHIEVABLE AXIS RANGES`n`n"
$output += "For each ternary axis, the min/max percentage achievable by a quiz-taker:`n`n"

$axes = @("a1","a2","a3","a4","a5","a6","a8")
$subLabels = @("a","b","c")

foreach ($ax in $axes) {
    $output += "### Axis $ax`n"
    foreach ($sub in $subLabels) {
        $key = "$($ax)$sub"
        # To maximize pctA of axis a1: maximize a1a while minimizing a1b and a1c
        # But this is coupled. Let's try a greedy approach:
        # For each question, pick the multiplier that maximizes the ratio na/(na+nb+nc)
        
        # Actually, let's just try to independently maximize/minimize the raw score
        $minRaw = -$maxScores[$key]
        $maxRaw = $maxScores[$key]
        $minNorm = ($maxScores[$key] + $minRaw) / (2 * $maxScores[$key]) * 100
        $maxNorm = ($maxScores[$key] + $maxRaw) / (2 * $maxScores[$key]) * 100
        $output += "  $key raw range: [$minRaw, $maxRaw], normalized: [$minNorm, $maxNorm]`n"
    }
    $output += "`n"
}
$output += "a7 raw range: [-$($maxScores['a7']), $($maxScores['a7'])], normalized: [0, 100]`n`n"

# Step 6: Monte Carlo - generate many random answer profiles and see which ideologies get matched
Write-Host "Running Monte Carlo simulation with 100000 random profiles..."
$matchCounts = @{}
foreach ($name in $ideoData.Keys) { $matchCounts[$name] = 0 }

$rng = New-Object System.Random
$multipliers = @(-1.0, -0.5, 0.0, 0.5, 1.0)
$numTrials = 100000

for ($trial = 0; $trial -lt $numTrials; $trial++) {
    $answers = New-Object 'double[]' $parsedQ.Count
    for ($q = 0; $q -lt $parsedQ.Count; $q++) {
        $answers[$q] = $multipliers[$rng.Next(5)]
    }
    
    $profile = Compute-Profile $answers
    
    $bestName = ""
    $bestDist = [double]::MaxValue
    foreach ($name in $ideoData.Keys) {
        $d = Compute-Distance $profile $ideoData[$name]
        if ($d -lt $bestDist) {
            $bestDist = $d
            $bestName = $name
        }
    }
    $matchCounts[$bestName]++
}

$output += "# MONTE CARLO ATTAINABILITY TEST ($numTrials random profiles)`n`n"
$output += "| Ideology | Times Matched | Percentage | Status |`n"
$output += "|---|---:|---:|---|`n"

$sorted = $matchCounts.GetEnumerator() | Sort-Object -Property Value -Descending
foreach ($entry in $sorted) {
    $pct = [Math]::Round($entry.Value / $numTrials * 100, 2)
    $status = if ($entry.Value -eq 0) { "UNATTAINABLE" } elseif ($entry.Value -lt 100) { "VERY RARE" } else { "OK" }
    $output += "| $($entry.Key) | $($entry.Value) | $pct% | $status |`n"
}

$output += "`n"

# Step 7: For each ideology, compute the MINIMUM possible distance from any answer profile
# Use greedy optimization: for each ideology target, pick answers that minimize distance
Write-Host "`nComputing greedy minimum distances..."

$output += "# GREEDY MINIMUM DISTANCE TO EACH IDEOLOGY`n`n"
$output += "For each ideology, the minimum Euclidean distance achievable by optimally answering every question.`n"
$output += "High minimum distance = harder or impossible to reach.`n`n"
$output += "| Ideology | Min Distance (greedy) | Closest Rival at that profile | Rival Distance | Can Win? |`n"
$output += "|---|---:|---|---:|---|`n"

foreach ($targetName in ($ideoData.Keys | Sort-Object)) {
    $targetVec = $ideoData[$targetName]
    
    # Greedy: for each question, try all 5 multipliers, pick the one that results in
    # the profile closest to the target ideology
    $bestAnswers = New-Object 'double[]' $parsedQ.Count
    
    # Initialize with neutral answers
    for ($q = 0; $q -lt $parsedQ.Count; $q++) { $bestAnswers[$q] = 0.0 }
    
    # Iterate: for each question, try all 5 multipliers and pick best
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
    
    $optimalProfile = Compute-Profile $bestAnswers
    $distToTarget = [Math]::Round([Math]::Sqrt((Compute-Distance $optimalProfile $targetVec)), 1)
    
    # Now check: at this optimal profile, is the target ideology actually the closest?
    $closestRival = ""
    $closestRivalDist = [double]::MaxValue
    foreach ($rivalName in $ideoData.Keys) {
        if ($rivalName -eq $targetName) { continue }
        $rivalDist = Compute-Distance $optimalProfile $ideoData[$rivalName]
        if ($rivalDist -lt $closestRivalDist) {
            $closestRivalDist = $rivalDist
            $closestRival = $rivalName
        }
    }
    $closestRivalDist = [Math]::Round([Math]::Sqrt($closestRivalDist), 1)
    $targetDistSq = Compute-Distance $optimalProfile $targetVec
    $rivalDistSq = $closestRivalDist * $closestRivalDist
    
    $canWin = if ($targetDistSq -le ($closestRivalDist * $closestRivalDist)) { "YES" } else { "NO - $closestRival is closer" }
    
    $output += "| $targetName | $distToTarget | $closestRival | $closestRivalDist | $canWin |`n"
}

Set-Content -Path "C:\Users\labib\.gemini\antigravity\brain\ef751dd6-0125-4b82-be8b-e8a64a0c264d\attainability_analysis.txt" -Value $output -Encoding UTF8
Write-Host "`nDone! Output written."
