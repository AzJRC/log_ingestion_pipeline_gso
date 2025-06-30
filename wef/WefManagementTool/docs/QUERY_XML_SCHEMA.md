# Query Metadata Schema (QUERY.XML)

This document describes the standardized schema for `QUERY.XML` metadata files used in this project. These XML files encapsulate structured information about security detection queries, making them portable, versioned, and auditable.

## Objectives

- Establish a consistent format for documenting detection queries.
- Standardize fields to support programmatic parsing and future automation (e.g., audit policy recommendations).
- Facilitate sharing and maintenance of queries across platforms and environments.

## Metadata Structure

Each `QUERY.XML` must include a comment block following this structure:

```xml
<!--
    MetaSchemaVersion:  1.0
    QueryName:          File Sharing Activity
    Intent:
        - Primary:      Security and Auditing
        - Secondary:    Network
    Platform:           WIN7, WIN10, WIN2016, WIN2019, WIN2022
    SecurityProfile:    Member Server, Workstation
    Author:
        - Name:         Alejandro Rodriguez
        - Alias:        Username/AzJRC
        - Resource:     Github/WefManagementTool
        - Resource:     URL/https://github.com/AzJRC/Log-Ingestion
    Reference:
        - Name:         Michel de CREVOISIER
        - Alias:        mdecrevoisier
        - Resource:     Github/Windows-auditing-baseline
        - Resource:     URL/https://github.com/mdecrevoisier/Windows-auditing-baseline
    QueryVersion:       1.0
    QueryDate:          2025-06-27
    Tag:                Technique/T1021.002
    Tag:                Technique/T1222.001
    Tag:                Technique/T1187
    Tag:                Category/Object Access
    Tag:                Subcategory/File Share
    Tag:                Action/Resource Sharing
    Tag:                Misc/SMB
    Tag:                Misc/Admin Shares
    RequiresAudit:      Yes
    RequiredSettings:
        - AuditPolicy:  Object Access/File Share
    Description:        Monitors access and changes to network shares (creation, modification, deletion, and SMB auth failures).
-->
```

## Fields fields

The following table enlists the mandatory fields of a `QUERY.XML` file.

| Field 	| Description 	|
|---	|---	|
| `MetaSchemaVersion` 	| Version of this metadata schema. Ensures backward compatibility and programmability of scripting tools. 	|
| `QueryName` 	| Human-readable descriptive name of the query. 	|
| `Intent.Primary` 	| Intent of the query. Must be one of the following allowed values: `Security and Auditing`, `Application and Services`, `Identity and Access`, `System`, `Network`. 	|
| `Author` 	| Structured information including the name, alias, and related resources of the person that created a query. 	|
| `QueryVersion` 	| Version number in format `X.Y`. Minor changes involve modifying or fixing already declared Select or Suppress tags that do not change the intent of the query. Major changes involve adding new Select or Suppress queries or changes that affect the intent of the query. 	|

The following table enlists the non mandatory (but strictly recommended) fields of a QUERY.XML file.

| Field 	| Description 	| Example value	|
|---	|---	|---	|
| `Intent.Secondary` 	| More granular category, open to interpretation. We suggest using `auditpol` keywords or Mitre Att&ck alike terms. You can declare more than one secondary intent using commas[^1].	| `Account Management, Kerberos Operation` 	|
| `Platform` 	| List of operating systems this query applies to. Allowed values include `WIN7`, `WIN8`, (`WIN8.1`), `WIN10`, `WIN11`, `WIN2008`, `WIN2012`, `WIN2016`, `WIN2019`, `WIN2022`, and `WIN2025`. 	| `WIN8`, `WIN10`, `WIN2012`, `WIN2016`, `WIN2019`, `WIN2022` 	|
| `SecurityProfile` 	| Roles or asset types relevant for the query. Allowed values include `Domain Controller`, `Member Server`, `Workstation` or `Other`. 	| `Workstation`, `Member Server` 	|
| `Reference` 	| External documentation or advisories. 	| - 	|
| `QueryDate` 	| Date of creation or last revision. Dates must use the format `YYYY/MM/DD` or `YYYY-MM-DD`. 	| 2025-07-23 	|
| `Tag` 	| Multi-key taxonomy for advanced categorization. Read the section [Tag Structure](#tag-structure) to use this field effectively. 	| `Technique/T1234`, `Category/Object Access` 	|
| `RequiresAudit` 	| Indicates if this query needs additional auditing enabled. [Upcoming feature] 	| - 	|
| `RequiredSettings` 	| Lists audit policy or configuration settings needed for full effectiveness. [Upcoming feature] 	| - 	|
| `Description` 	| Free text summary of the query purpose and scope. 	| - 	|

[^1]: We suggest keeping the `Intent.Secondary` field as short as possible.

## Tag Structure

Tags use Key/Value pairs to provide semantic categorization of each query. This enables precise filtering, automated alert prioritization, and consistent documentation.

You can declare multiple values for the same key (e.g. `Technique/T1558, T1110`) to indicate that the query applies to several related items. Keep in mind that the `Category` and `Criticality` fields should have only one value.

| Key 	| Purpose 	| Example value 	|
|---	|---	|---	|
| `Technique` 	| Maps to MITRE ATT&CK techniques or subtechniques, supporting standardized threat modeling. 	| `Technique/T1558, T1110` 	|
| `Category` 	| Aligns with Microsoft's high-level audit policy categories, indicating broad areas of system activity[^2]. 	| `Category/Resource Access` 	|
| `Subcategory` 	| Maps to Microsoft's detailed audit policy subcategories, providing granular context[^2]. 	| `Subcategory/File Share` 	|
| `Action` 	| Describes the specific monitored behavior or operation, often reflecting a verb-like activity (e.g. "File Sharing"), a well-known adversary tactic (e.g. "Kerberoasting"), or a generic security operation (e.g. "Authentication"). 	| `Action/File Sharing`, `Action/Kerberoasting` 	|
| `Criticality` 	| Indicates the expected impact level of the detection using the supported values `Low`, `Medium`, or `High`. 	| `Criticality/Medium` 	|
| `Misc` 	| Used for additional context such as protocols, infrastructure elements, or environment specifics. 	| `Misc/SMB, ADDS` 	|

[^2]: Run `auditpol /get /category:*` to see all categories and subcategories.

## Author and Reference structure

Defines the origin and credibility of the query.

| Subfield   | Description                                                                                           |
| ---------- | ----------------------------------------------------------------------------------------------------- |
| `Name`     | Full name of the author or referenced author.                                                         |
| `Alias`    | Short handle, username, or alias (e.g., GitHub handle).                                               |
| `Resource` | One or more repositories, documentation links, or URLs.                                               |

For the `Resource` field, you must specify the type of resource using the value format `Type/Value`. Currently allowed types are:

| Key           | Purpose                                                                                                           |
| ------------- | ------------------------------------------------------- |
| `Github`      | Name of the GitHub repository.                          |
| `URL`         | URL to the online resource.                             |
| `Misc`        | Other resources.                                        |

```diff
+ Please, never forget to acknowledge the work of other people!
```

## Intent recommendations

Microsoft Windows follows a standard audit policy of categories and subcategories (as found in `auditpol`). The following table showcases a clear one-to-one mapping between the field `Intent.Primary` categories and Microsoft’s audit categories and subcategories.

| Microsoft Category (Secondary) 	| Intent.Primary 	| Notes & examples 	|
|:---:	|:---:	|:---:	|
| Account Logon 	| Identity and Access 	| Kerberos, credential validation 	|
| Account Management 	| Identity and Access 	| user & group mgmt 	|
| Logon/Logoff 	| Identity and Access 	| session tracking, VPN, IPSec 	|
| DS Access 	| Identity and Access 	| Directory Services 	|
| Privilege Use 	| Identity and Access 	| privilege elevation 	|
| Policy Change 	| Security and Auditing 	| audit policies, authz policies 	|
| Object Access 	| Security and Auditing 	| file shares, registry, storage 	|
| Detailed Tracking 	| Security and Auditing 	| process creation, DPAPI, RPC 	|
| Global Object Access Auditing 	| Security and Auditing 	| sweeping resource access 	|
| System 	| System 	| IPsec driver, system integrity, state changes 	|
| - 	| Application and Services 	| Reserved for SQL server applications or any provider outside of the security-centric categories 	|
| - 	| Network 	| Reserved for IIS, DNS, DHCP, Firewall or external systems that generate network-related logs 	|

* Depending on the needs of your organization, you may want to tweek the suggested assignments.

## RequiresAudit and AuditSettings fields

```diff
- Future implementation
```

The `RequiresAudit` and `AuditSettings` field will allow the user to decide if they want to enable required settings automatically.

