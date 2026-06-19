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

$targetVec = @{ a1=@(55,20,25); a2=@(37.5,30,32.5); a3=@(45,42.5,12.5); a4=@(25,62.5,12.5); a5=@(67.5,20,12.5); a6=@(60,17.5,22.5); a7=35; a8=@(22.5,20,57.5) }

$bestAnswers = New-Object 'double[]' $parsedQ.Count
for ($q = 0; $q -lt $parsedQ.Count; $q++) { $bestAnswers[$q] = 0.0 }
$multipliers = @(-1.0, -0.5, 0.0, 0.5, 1.0)

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

$output = ""
for ($q = 0; $q -lt $parsedQ.Count; $q++) {
    $ans = "Neutral/Unsure"
    if ($bestAnswers[$q] -eq 1.0) { $ans = "Strongly Agree" }
    elseif ($bestAnswers[$q] -eq 0.5) { $ans = "Agree" }
    elseif ($bestAnswers[$q] -eq -0.5) { $ans = "Disagree" }
    elseif ($bestAnswers[$q] -eq -1.0) { $ans = "Strongly Disagree" }
    $output += "Q$($q + 1): $($parsedQ[$q].text)`n-> **$ans**`n`n"
}
Set-Content "C:\Users\labib\.gemini\antigravity\brain\ef751dd6-0125-4b82-be8b-e8a64a0c264d\nazbol_answers.md" $output -Encoding UTF8
