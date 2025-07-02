using namespace system.collections.generic

#
# QUERY META SCHEMA
#

enum MetaSchemaFields {
    MetaSchemaVersion
    QueryName
    Intent
    Platform
    SecurityProfile
    Author
    Reference
    QueryVersion
    QueryDate
    Verbosity
    Requirements
    Tag
    RequiresAudit
    RequiredSettings
    Description
}

enum MetaSchemaIntentFields {
    Primary
    Secondary
}

enum MetaSchemaAuthorFields {
    Name
    Alias
    Resource
}


enum SupportedPlatforms {
    WIN7
    WIN8
    WIN10
    WIN11
    WIN2008
    WIN2012
    WIN2016
    WIN2019
    WIN2022
    WIN2025
}

enum SecurityProfiles {
    Workstation
    Member_Server
    Domain_Controller
    Other
}

enum Levels {
    Low
    Medium
    High
}

enum TagKeys {
    Technique
    Category
    Subcategory
    Action
    Criticality
    Source
    Misc
}

enum AuthorResourceTypes {
    Github
    URL
    Other
}

enum YesNo {
    Yes
    No
}

# Compound fields
class IntentField {

    hidden [ValidateNotNullOrEmpty()][string]$Primary       # Unique, mandatory
    hidden [list[string]]$Secondary                         # Non-unique, optional

    # Constructor
    IntentField([string]$PrimaryIntent) {
        $this.Primary = $PrimaryIntent
        $this.Secondary = [list[string]]::new()
    }

    IntentField([string]$PrimaryIntent, [list[string]]$SecondaryIntent) {
        $this.Primary = $PrimaryIntent.Trim()
        $this.Secondary = [list[string]]::new()
        if ($SecondaryIntent) { $SecondaryIntent.CopyTo($this.Secondary) }
    }

    # Public methods
    [void] SetSecondaryIntent([list[string]]$SecondaryIntent) {
        $SecondaryIntent.CopyTo($this.Secondary)
    }

    [void] AddSecondaryIntent([list[string]]$SecondaryIntent) {
        $this.Secondary.Add($SecondaryIntent)
    }

    [string] GetPrimaryIntent() {
        return $this.Primary
    }

    [list[string]] GetSecondaryIntent() {
        return $this.Secondary
    }
}

class ResourceField {
    hidden [AuthorResourceTypes]$ResourceKey
    hidden [string]$ResourceValue

    # Public Methods
    [void] ParseAndSetResource($InputResource) {

        $parts = $InputResource -split '/', 2
        $Type = $parts[0].Trim()
        $Value = $parts[1].Trim()

        if (-not $Type -and -not $Value) { throw "[-] Invalid input for ResourceField: $InputResource" }
        try {
            $this.ResourceKey = [AuthorResourceTypes]$Type
        }
        catch {
            Write-Host "[!] Invalid resource key: '$Type'. Must be one of: $([Enum]::GetNames([AuthorResourceTypes]) -join ', '). Resource skipped." -ForegroundColor Yellow
            return
        }
        $this.ResourceValue = $Value
    }

    [string] GetResourceString() {
        return $this.ResourceKey.ToString() + '/' + $this.ResourceValue
    }

    [object] GetResourceObject() {
        return [ordered]@{
            ResourceKey   = $this.ResourceKey
            ResourceValue = $this.ResourceValue
        }
    }
}

class AuthorOrReferenceField {

    [string]$AuthorName
    [string]$AuthorAlias
    [list[ResourceField]]$Resources

    # Public methods
    [void] SetAuthorName([string]$AuthorName) {
        $this.AuthorName = $AuthorName.Trim()
    }

    [void] SetAuthorAlias([string]$AuthorAlias) {
        $this.AuthorAlias = $AuthorAlias.Trim()
    }

    [void] AddAuthorResource([string]$RawResource) {
        if (-not $this.Resources) { $this.Resources = [list[ResourceField]]::new() }
        $NewResource = [ResourceField]::new()
        $NewResource.ParseAndSetResource($RawResource)
        $this.Resources.Add($NewResource)
    }

    [object] GetAuthorOrReferenceDetails() {
        return [ordered]@{
            Name      = $this.AuthorName
            Alias     = $this.AuthorAlias
            Resources = $this.Resources
        }
    }
}

class TagField {
    hidden [TagKeys]$TagKey
    hidden [list[string]]$TagValues

    [bool]$isTagValid = $true

    # Constructor
    TagField([string]$rawTag) {
        $this.TagValues = [list[string]]::new()

        if (-not $rawTag -or ($rawTag -notmatch '/')) {
            throw "[-] Invalid Tag format. Expected 'Key/Value'. Got '$rawTag'"
        }

        $parts = $rawTag -split '/', 2
        $key = $parts[0].Trim()
        $values = $parts[1].Trim()

        try {
            $this.TagKey = [TagKeys]$key
        }
        catch {
            Write-Host "[!] Invalid TagKey type: '$key'. Valid: $([Enum]::GetNames([TagKeys]) -join ', '). Skipped." -ForegroundColor Yellow
            $this.isTagValid = $false
            return
        }

        $values -split ',' | ForEach-Object {
            $this.TagValues.Add($_.Trim())
        }
    }

    # Public Methods
    [string] GetTagKey() {
        return $this.TagKey.ToString()
    }

    [string] GetTagValue() {
        return $this.TagValues
    }

    [string] GetTag() {
        return ($this.GetTagKey() + '/' + ($this.GetTagValue() -join ',') )
    }
}

class RequiredSettings {
    hidden [list[string]]$Lines

    RequiredSettings($rawContent) {
        $this.Lines = [list[string]]::new()
        if ($rawContent) {
            $rawContent -split "`n" | ForEach-Object {
                $this.Lines.Add($_.Trim())
            }
        }
    }

    [list[string]] GetSettingsLines() {
        return $this.Lines
    }
}

# Main class
class QueryMetadataSchema {
    static [string] $SCHEMA_META_VERSION = '1.0'

    # Mandatory fields
    [ValidateNotNullOrEmpty()][string]$QueryName
    [ValidateNotNullOrEmpty()][IntentField]$Intent  # Only Intent.Primary is mandatory
    [ValidateNotNullOrEmpty()][AuthorOrReferenceField]$AuthorField
    [ValidateNotNullOrEmpty()][string]$QueryVersion

    # Optional fields
    [list[SupportedPlatforms]]$SupportedPlatforms
    [list[SecurityProfiles]]$SecurityProfiles
    [list[AuthorOrReferenceField]]$References
    [string]$QueryDate
    [list[Levels]]$Verbosity
    [list[String]]$Requirements
    [list[TagField]]$Tags
    [YesNo]$RequiresAudit
    [RequiredSettings]$RequiredSettings
    [string]$Description

    # Constructor
    QueryMetadataSchema([string]$QueryName, [string]$PrimaryIntent, [string]$AuthorName, [string]$AuthorAlias, [string]$QueryVersion) {
        if ($null -eq $AuthorName -and $null -eq $AuthorAlias) { throw "[!] Missing at least one Author parameter." }
        $this.QueryName = $QueryName.Trim()
        $this.Intent = [IntentField]::new($PrimaryIntent)

        $Author = [AuthorOrReferenceField]::new()
        if ($AuthorName) {
            $Author.SetAuthorName($AuthorName)
        }
        if ($AuthorAlias) {
            $Author.SetAuthorAlias($AuthorAlias)
        }

        $this.AuthorField = $Author
        $this.QueryVersion = $QueryVersion
    }

    # Public Methods

    [string]GetSchemaVersion() {
        return [QueryMetadataSchema]::SCHEMA_META_VERSION
    }
    
    [void]AddPlatforms([string]$rawPlatformString) {
        if (-not $this.SupportedPlatforms) { $this.SupportedPlatforms = [list[SupportedPlatforms]]::new() }

        # AddPlatforms() accepts raw inputs from QUERY.XML files like 'WIN7, WIN8, WIN10, WIN2012, WIN2016, WIN2022'
        # Separate SupportedPlatforms by commas and add each one at a time.

        $rawPlatformString -split ',' | ForEach-Object {
            try {
                $this.SupportedPlatforms.Add( 
                    [SupportedPlatforms]$_.Trim() 
                )
            }
            catch {
                Write-Host "[!] Invalid Supported Platform: $_. Skipped." -ForegroundColor Yellow
            }
        }
    }
    [list[string]] GetStringPlatforms() {
        return ($this.SupportedPlatforms | ForEach-Object { $_.ToString() })
    }

    [void]AddSecurityProfile([string]$rawSecurityProfiles) {
        if (-not $this.SecurityProfiles) { $this.SecurityProfiles = [list[SecurityProfiles]]::new() }

        # AddSecurityProfile() accepts raw inputs from QUERY.XML files like 'Workstation, Member Server'
        # Separate Security Profiles by commas and add each one at a time.
        # Security profile allowed values are 'Workstation`, `Member Server`, and `Domain Controller`, and `Other`
        # Due to enum limitations, whitespaces in `Member Server` and `Domain Controller` need to be replaced with underscores (_)
        
        $rawSecurityProfiles -split ',' | ForEach-Object {
            $profile = ($_.Trim() -replace '\s', '_')
            try {
                $this.SecurityProfiles.Add([SecurityProfiles]$profile)
            }
            catch {
                Write-Host "[!] Invalid Security Profile: '$profile'. Skipped." -ForegroundColor Yellow
            }
        }
        
    }
    [list[string]] GetStringSecurityProfiles() {
        return $this.SecurityProfiles | ForEach-Object { $_.ToString() }
    }

    [void] AddAuthorName([string]$authorName) {
        $this.AuthorField.SetAuthorAlias($authorName.Trim())
    }
    [void] AddAuthorAlias([string]$authorAlias) {
        $this.AuthorField.SetAuthorAlias($authorAlias.Trim())
    }
    [void] AddAuthorResource([string]$resource) {
        $this.AuthorField.AddAuthorResource($resource)
    }
    [AuthorOrReferenceField] GetAuthor() {
        return $this.AuthorField
    }

    [void] AddReference([string]$referenceName, [string]$referenceAlias, [list[string]]$resources) {
        if (-not $this.References) { $this.References = [list[AuthorOrReferenceField]]::new() }
        if (-not $referenceName -and -not $referenceAlias -and -not $resources) { throw "Invalid reference. You must provide at least one reference parameter." }
        $NewReference = [AuthorOrReferenceField]::new()
        if ($referenceName) { $NewReference.SetAuthorName($referenceName) }
        if ($referenceAlias) { $NewReference.SetAuthorAlias($referenceAlias) }
        if ($resources) { 
            $resources | ForEach-Object { 
                $NewReference.AddAuthorResource( $_ ) 
            }
        }
        $this.References.Add($NewReference)
    }
    [list[AuthorOrReferenceField]] GetReferences() {
        return $this.References
    }

    [void] SetQueryDate($rawDate) {
        # Date format is YYYY-MM-DD from raw QUERY.XML file
        if (-not $rawDate -or ($rawDate.Trim() -notmatch "^\d{4}-\d{2}-\d{2}$")) {
            throw "Invalid date format. Expected date YYYY-MM-DD. Got '$rawDate'"
        }
        $this.QueryDate = $rawDate
    }
    [list[string]] GetRawQueryDate() {
        return $this.QueryDate
    }
    [list[string]] GetQueryDateParts() {
        return ($this.QueryDate -split '-', 3)
    }

    [void] SetVerbosity([string]$rawVerbosity) {
        # Raw verbosity structure is a string of Levels separated by commas.
        # e.g. Low, Medium, High    - Coverage query
        # e.g. Medium               - Complementary query or just one query

        if (-not $this.Verbosity) { $this.Verbosity = [list[Levels]]::new() }
        $rawVerbosity -split ',' | ForEach-Object {
            try {
                $this.Verbosity.Add( 
                    [Levels]$_.Trim() 
                )
            }
            catch {
                Write-Host "[!] Invalid Verbosity: $_. Skipped." -ForegroundColor Yellow
            }
        }
    }
    [list[string]] GetStringVerbosity() {
        return ($this.Verbosity | ForEach-Object { $_.ToString() })
    }

    [void] SetRequirements([string]$requirement) {
        # Raw requirements structure is a string of text values separated by commas.
        # E.g. Windows Sysmon, Other requirement    
        # Note: At the time, I cannot think of another requirement except from Sysmon.
        # For this reason, there is no enum enforcement.
        if (-not $this.Requirements) { $this.Requirements = [list[string]]::new() }
        $requirement -split ',' | ForEach-Object {
            $this.Requirements.Add($_.Trim())
        }
    }
    [list[string]] GetRequirements() {
        return $this.Requirements
    }

    [void] AddTag([string]$rawTag) {
        # A raw tag from a XML.QUERY file is a list of string in key/values pair format.
        # There can be several values in a key/values pair (key/value1, value2, valueN)
        # E.g. Technique/T1234, T5678
        # E.g. Category/Object Access
        # E.g. Action/Packet Drop, Network Filtering
        # The key of the key/values pair is enforced by the enum TagKeys
        if (-not $this.Tags) { $this.Tags = [list[TagField]]::new() }

        $newTag = [TagField]::new($rawTag)
        if ( $newTag.isTagValid ) { $this.Tags.Add($newTag) }
    }
    [list[object]] GetTags() {
        $queryTags = @()
        $this.Tags | ForEach-Object {
            $queryTags += $_.GetTag()
        }
        return $queryTags
    }
    [list[object]] GetTagObjects() {
        return ($this.Tags | ForEach-Object {
                [ordered]@{
                    Key    = $_.GetTagKey()
                    Values = $_.GetTagValue()
                }
            })
    }
    
    [void] SetRequiresAudit([string]$value) {
        try {
            $this.RequiresAudit = [YesNo]$value
        }
        catch {
            $this.RequiresAudit = [YesNo]'No'
            Write-Host "[!] Unknown value for RequiresAudit: $value. Field will default to 'No'."
        }
    }
    [string] GetRequiresAuditString() {
        return $this.RequiresAudit.ToString()
    }
    [bool] GetRequiresAuditBool() {
        if ($this.RequiresAudit.ToString() -eq 'Yes') {
            return $true
        }
        else {
            return $false
        }
    }

    [void] SetRequiredSettings([string]$rawRequiredSettings) {
        # [TODO] Future feature
        $this.RequiredSettings = [RequiredSettings]::new($rawRequiredSettings)
    }
    [list[string]] GetRequiredSettingsLines() {
        $lines = $this.RequiredSettings.GetSettingsLines()
        return $lines
    }

    [void] SetDescription([string]$rawDescription) {
        $this.Description = $rawDescription
    }
    [string] GetDescription() {
        return $this.Description
    }

    [string] ToString() {
        return "QueryName=$($this.QueryName) Intent=$($this.Intent.Primary) Platforms=[$($this.SupportedPlatforms -join ',')], TagsCount=$($this.Tags.Count)"
    }

}

#
# QUERY EVENT META SCHEMA
#
class QueryEventMetadataSchema {
    static [string] $SCHEMA_EVT_VERSION = 1.0

    # [TODO]
}


#
# Tests
#

function Test-QueryMetadataSchema {
    Write-Host "=== Building new QueryMetadataSchema ===" -ForegroundColor Cyan
    $QMS = [QueryMetadataSchema]::new(
        'Test Query',
        'Application And Services',
        'John Doe',
        'Johnny',
        '1.0'
    )

    #
    # Supported Platforms
    #
    Write-Host "`n--- Supported Platforms ---" -ForegroundColor Yellow
    $platforms = 'WIN10, WIN2012, LINUX, Windows2019'
    $QMS.AddPlatforms($platforms)
    Write-Host "Platforms:" -ForegroundColor Green
    $QMS.GetStringPlatforms() | Format-Table

    #
    # Security Profiles
    #
    Write-Host "`n--- Security Profiles ---" -ForegroundColor Yellow
    $profiles = 'Workstation, Member Server, Invalid Value, Computers'
    $QMS.AddSecurityProfile($profiles)
    Write-Host "Profiles:" -ForegroundColor Green
    $QMS.GetStringSecurityProfiles() | Format-Table

    #
    # References
    #
    Write-Host "`n--- References ---" -ForegroundColor Yellow
    $refData = @{
        Name      = 'Michel de CREVOISIER'
        Alias     = 'mdecrevoisier'
        Resources = @('Github/Windows-auditing-baseline', 'URL/https://github.com/mdecrevoisier/Windows-auditing-baseline')
    }
    $QMS.AddReference($refData.Name, $refData.Alias, $refData.Resources)

    Write-Host "References Detail:" -ForegroundColor Green
    $QMS.GetReferences() | ForEach-Object {
        $_.GetAuthorOrReferenceDetails() | Format-List
        Write-Host "`n  --- References.Resources ---" -ForegroundColor Yellow
        Write-Host "    Resources Detail:" -ForegroundColor Green
        $_.GetAuthorOrReferenceDetails().Resources | ForEach-Object {
            $_.GetResourceObject() | Format-List
        }
    }

    #
    # Query Date
    #
    Write-Host "`n--- Query Date ---" -ForegroundColor Yellow
    $QMS.SetQueryDate('2025-06-27')
    Write-Host "Query Date:" -ForegroundColor Green $QMS.GetRawQueryDate()

    #
    # Verbosity
    #
    Write-Host "`n--- Verbosity Levels ---" -ForegroundColor Yellow
    $verbosities = 'Medium, Medium, High, Invalid, Critical, Verbosity'
    $QMS.SetVerbosity($verbosities)
    Write-Host "Verbosity:" -ForegroundColor Green
    $QMS.GetStringVerbosity() | Format-Table

    #
    # Requirements
    #
    Write-Host "`n--- Requirements ---" -ForegroundColor Yellow
    $QMS.SetRequirements('Windows Sysmon, Other Tool')
    Write-Host "Requirements:" -ForegroundColor Green
    $QMS.GetRequirements() | Format-Table

    #
    # Tags
    #
    Write-Host "`n--- Tags ---" -ForegroundColor Yellow
    $tags = @(
        'Action/Packet Drop, Network Filtering',
        'Subcategory/Filtering Platform Packet Drop',
        'InvalidKey/Object Access'
    )
    $tags | ForEach-Object { $QMS.AddTag($_) }
    Write-Host "Tags:" -ForegroundColor Green
    $QMS.GetTags() | Format-Table

    #
    # Requires Audit
    #
    Write-Host "`n--- Requires Audit ---" -ForegroundColor Yellow
    $QMS.SetRequiresAudit('Yes')
    Write-Host "RequiresAudit" -ForegroundColor Green
    $QMS.GetRequiresAuditString()

    #
    # Required Settings
    #
    Write-Host "`n--- Required Settings ---" -ForegroundColor Yellow
    $requiredSettingsBlock = @"
    - AuditPolicy: Object Access/Filtering Platform Connection
    - AuditPolicy: Object Access/Filtering Platform Packet Drop
"@
    $QMS.SetRequiredSettings($requiredSettingsBlock)
    Write-Host "Required Settings:" -ForegroundColor Green
    $QMS.GetRequiredSettingsLines()
    #
    # Description
    #
    Write-Host "`n--- Description ---" -ForegroundColor Yellow
    $desc = 'Monitors allowed and blocked network traffic on Windows systems for outbound connections, binds, and packet filtering actions.'
    $QMS.SetDescription($desc)
    Write-Host "Description:" -ForegroundColor Green
    $QMS.GetDescription()

    #
    # Summary dump
    #
    Write-Host "`n--- Final Object Summary ---" -ForegroundColor Cyan
    $QMS | Format-List
}