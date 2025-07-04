using namespace system.collections.generic

# Reference:
# https://learn.microsoft.com/en-us/windows/win32/wes/queryschema-elements

enum QuerySchemaTagNames {
    Query
    Select
    Suppress
}

class QueryTypeElement {
    static [string] $QUERY_TYPE_SUPPRESS = 'Suppress'
    static [string] $QUERY_TYPE_SELECT = 'Select'

    [ValidateNotNullOrEmpty()][string]$Type             # select | suppress
    [ValidateNotNullOrEmpty()][string]$Channel          # Event channel, like Security or Microsoft-Windows-SMBServer/Security
    [ValidateNotNullOrEmpty()][string]$XPath            # XPath expression, like *[System[(EventID=4624)]]
    [list[int]]$Events

    QueryTypeElement($Type, $Channel, $XPath) {
        $this.Type = $Type 
        $this.Channel = $Channel
        $this.XPath = $XPath
        $this.Events = $this.ParseXPathEvents($XPath)
    }

    [list[int]] ParseXPathEvents($XPath) {
        $EventList = [list[int]]::new()

        if (-not ($XPath -match 'EventID')) {
            return $EventList
        }
        
        $SingleEventRegex = 'EventID\s?=\s?(\d+)'
        $RangeEventRegex = 'EventID\s?&gt;=\s(\d+)\sand\sEventID\s?&lt;=\s?(\d+)'

        $SingleEventMatches = [regex]::Matches($XPath, $SingleEventRegex)
        foreach ($MatchGroup in $SingleEventMatches) {
            $EventList.Add([int]$MatchGroup.Groups[1].Value)
        }

        $RangeEventMatches = [regex]::Matches($XPath, $RangeEventRegex)
        foreach ($MatchGroup in $RangeEventMatches) {
            $EventRangeLowerBound = [int]$MatchGroup.Groups[1].Value
            $EventRangeHigherBound = [int]$MatchGroup.Groups[2].Value
            foreach ($i in $EventRangeLowerBound..$EventRangeHigherBound) {
                $EventList.Add($i)
            }
        }
        return $EventList
    }
}

class QueryElement {
    [int]$QueryId
    $SelectQueryElements = [list[QueryTypeElement]]::new()
    $SuppressQueryElements = [list[QueryTypeElement]]::new()

    QueryElement([int]$QueryId) {
        $this.QueryId = $QueryId
    }

    [void] AddQueryTypeElement([QueryTypeElement]$QueryTypeElement) {
        if ($QueryTypeElement.Type -eq [QueryTypeElement]::QUERY_TYPE_SELECT) {
            $this.SelectQueryElements.Add($QueryTypeElement)
        }
        elseif ($QueryTypeElement.Type -eq [QueryTypeElement]::QUERY_TYPE_SUPPRESS) {
            $this.SuppressQueryElements.Add($QueryTypeElement)
        }
        else {
            throw "Invalid Type: $($QueryTypeElement.Type)"
        }
    }

    [list[QueryTypeElement]] GetQueryTypeElements() {
        return ($this.SelectQueryElements + $this.SuppressQueryElements)
    }

    [list[QueryTypeElement]] GetSelectQueryTypeElements() {
        return ($this.SelectQueryElements)
    }

    [list[QueryTypeElement]] GetSupressQueryTypeElements() {
        return ($this.SuppressQueryElements)
    }
}

class QueryListElement {
    $QueryElements = [list[QueryElement]]::new()

    [void] AddQueryElement($QueryElement) {
        $this.QueryElements.Add($QueryElement)
    }

    [list[QueryElement]] GetQueryElements() {
        return $this.QueryElements
    }

    [QueryElement] GetLastQueryElement() {
        return $this.QueryElements[-1]
    }

    [void] WriteQueryListElement($OutputPath) {
        Write-QueryListXmlFile -QueryList $this.QueryElements -OutputPath $OutputPath
    }

    [int] GetQueryTypeElementCount() {
        $count = 0
        Foreach ($QueryElement in $this.QueryElements) {    
            $count += $QueryElement.GetQueryTypeElementCount().Count
        }
        return $count
    }
}
