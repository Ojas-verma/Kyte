param(
    [string]$ProjectId = "relationshit-mapping",
    [string]$ApiKey = "AIzaSyDxQBrDbY7vBRi02lXoWrqPg3RlQpB5YWQ",
    [string]$Database = "(default)",
    [string]$Collection = "members"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToFirestoreValue {
    param([object]$Value)

    if ($null -eq $Value) {
        return @{ nullValue = $null }
    }

    if ($Value -is [bool]) {
        return @{ booleanValue = $Value }
    }

    if ($Value -is [int] -or $Value -is [long]) {
        return @{ integerValue = "$Value" }
    }

    if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
        return @{ doubleValue = [double]$Value }
    }

    return @{ stringValue = [string]$Value }
}

function Convert-ToFirestoreFields {
    param([hashtable]$Data)

    $fields = @{}
    foreach ($key in $Data.Keys) {
        $fields[$key] = Convert-ToFirestoreValue -Value $Data[$key]
    }

    return @{ fields = $fields }
}

$members = @(
    @{ id = "ceo-001"; name = "Ava Chen"; role = "Engineering Manager"; department = "Engineering"; team = "Leadership"; managerId = $null; photoUrl = $null },
    @{ id = "product-001"; name = "Leo Martin"; role = "Product Manager"; department = "Product"; team = "Core"; managerId = "ceo-001"; photoUrl = $null },
    @{ id = "eng-mgr-001"; name = "Nora Patel"; role = "Engineering Manager"; department = "Engineering"; team = "Platform"; managerId = "ceo-001"; photoUrl = $null },
    @{ id = "eng-001"; name = "Ibrahim Khan"; role = "SDE III"; department = "Engineering"; team = "Platform"; managerId = "eng-mgr-001"; photoUrl = $null },
    @{ id = "eng-002"; name = "Mei Lin"; role = "SDE II"; department = "Engineering"; team = "Platform"; managerId = "eng-mgr-001"; photoUrl = $null },
    @{ id = "eng-003"; name = "Sofia Rossi"; role = "SDE I"; department = "Engineering"; team = "Platform"; managerId = "eng-001"; photoUrl = $null },
    @{ id = "hr-001"; name = "Daniel Kim"; role = "Technical Consultant"; department = "HR"; team = "People Ops"; managerId = "ceo-001"; photoUrl = $null },
    @{ id = "ops-001"; name = "Priya Singh"; role = "DevOps Engineer"; department = "Operations"; team = "SRE"; managerId = "eng-mgr-001"; photoUrl = $null },
    @{ id = "qa-001"; name = "Olivia Brown"; role = "QA / Test Engineer"; department = "Engineering"; team = "Quality"; managerId = "eng-mgr-001"; photoUrl = $null },
    @{ id = "marketing-001"; name = "Noah Garcia"; role = "Senior Software Engineer"; department = "Marketing"; team = "Growth"; managerId = "product-001"; photoUrl = $null }
)

$base = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/$Database/documents/$Collection"

Write-Host "Seeding $($members.Count) members into project '$ProjectId'..."

$created = 0
foreach ($member in $members) {
    $docId = $member.id
    $uri = "${base}/${docId}?key=${ApiKey}"
    $payload = Convert-ToFirestoreFields -Data $member
    $json = $payload | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Method Patch -Uri $uri -ContentType "application/json" -Body $json | Out-Null
    $created++
}

Write-Host "Done. Upserted $created members into '$Collection'."
