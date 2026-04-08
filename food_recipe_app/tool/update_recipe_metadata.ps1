$ErrorActionPreference = 'Stop'

$apiKey = 'AIzaSyD8uGt9jWIxqEYjQosXdxGRVQEtPPwX37g'
$project = 'food-recipe-app-33140'
$dataPath = Join-Path $PSScriptRoot 'recipe_metadata_updates.jsonl'

if (-not (Test-Path -LiteralPath $dataPath)) {
  throw "Missing data file: $dataPath"
}

$email = 'seed.metadata.' + (Get-Date -Format 'yyyyMMddHHmmss') + '@example.com'
$password = 'SeedBot#12345'
$signupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey"
$signupBody = @{
  email = $email
  password = $password
  returnSecureToken = $true
} | ConvertTo-Json

$signupResp = Invoke-RestMethod -Method Post -Uri $signupUrl -ContentType 'application/json' -Body $signupBody
$authHeader = @{ Authorization = "Bearer $($signupResp.idToken)" }

$recipes = Get-Content -LiteralPath $dataPath | Where-Object { $_.Trim() } | ForEach-Object {
  $_ | ConvertFrom-Json
}

$updated = 0
$failed = New-Object System.Collections.Generic.List[string]

foreach ($recipe in $recipes) {
  $patchUrl = "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents/recipes/$($recipe.id)?updateMask.fieldPaths=description&updateMask.fieldPaths=durationMinutes&updateMask.fieldPaths=calories&updateMask.fieldPaths=ingredients&updateMask.fieldPaths=steps"
  $body = @{
    fields = @{
      description = @{ stringValue = [string]$recipe.description }
      durationMinutes = @{ integerValue = [string]$recipe.durationMinutes }
      calories = @{ integerValue = [string]$recipe.calories }
      ingredients = @{
        arrayValue = @{
          values = @($recipe.ingredients | ForEach-Object { @{ stringValue = [string]$_ } })
        }
      }
      steps = @{
        arrayValue = @{
          values = @($recipe.steps | ForEach-Object { @{ stringValue = [string]$_ } })
        }
      }
    }
  } | ConvertTo-Json -Depth 12

  try {
    Invoke-RestMethod -Method Patch -Uri $patchUrl -Headers $authHeader -ContentType 'application/json' -Body $body | Out-Null
    $updated++
  } catch {
    $failed.Add([string]$recipe.id)
  }
}

Write-Output ("Updated: {0}" -f $updated)
Write-Output ("Failed: {0}" -f $failed.Count)
if ($failed.Count -gt 0) {
  $failed
}
