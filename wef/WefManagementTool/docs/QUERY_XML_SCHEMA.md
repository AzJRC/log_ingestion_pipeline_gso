# Query Metadata Schema (QUERY.XML)

This document describes the standardized schema for `QUERY.XML` metadata files used in this project. These XML files encapsulate structured information about security detection queries, making them portable, versioned, and auditable.

---

## Objectives

- Establish a consistent format for documenting detection queries.
- Standardize fields to support programmatic parsing and future automation (e.g., audit policy recommendations).
- Facilitate sharing and maintenance of queries across platforms and environments.

---

## Metadata Structure

Each `QUERY.XML` must include a comment block following this structure:

```xml
<!--
    MetaSchemaVersion:  1.0
    QueryName:          File Sharing Activity
    Intent:
        - Primary:      Security & Auditing
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

| Field               | Description                                                                                                                       |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `MetaSchemaVersion` | Version of this metadata schema. Ensures backward compatibility.                                                                  |
| `QueryName`         | Human-readable descriptive name of the query.                                                                                     |
| `Intent.Primary`    | Must be one of: `Security & Auditing` (sa), `Application & Services` (as), `Identity & Access` (ia), `System` (s), `Network` (n). |
| `Author`            | Structured information including Name, Alias, and Resource.                                                                       |
| `QueryVersion`      | Version number of the query logic or scope.                                                                                       |

The following table enlists the non mandatory (but strictly recommended) fields of a QUERY.XML file.

| Field              | Description                                                                  |
| ------------------ | ---------------------------------------------------------------------------- |
| `Intent.Secondary` | More granular category, open to interpretation (e.g., `Network File Share`). |
| `Platform`         | List of operating systems this query applies to.                             |
| `SecurityProfile`  | Roles or asset types relevant for the query (e.g., `Domain Controller`).     |
| `Reference`        | External documentation or advisories.                                        |
| `QueryDate`        | Date of creation or last revision.                                           |
| `Tag`              | Multi-key taxonomy for advanced categorization (explained below).            |
| `RequiresAudit`    | Indicates if this query needs additional auditing enabled.                   |
| `RequiredSettings` | Lists audit policy or configuration settings needed for full effectiveness.  |
| `Description`      | Free text summary of the query purpose and scope.                            |

## Tag Structure

Tags use `Key/Value` pair values to provide semantic categorization. Recommended keys:

| Key           | Purpose                                                                                                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| `Technique`   | Maps to MITRE ATT\&CK techniques (e.g., `Technique/T1071.002`).                                                   |
| `Category`    | Aligns with Microsoft's high-level audit policy categories (e.g., `Category/Object Access`).                      |
| `Subcategory` | Represents more detailed audit subcategories (e.g., `Subcategory/File Share`).                                    |
| `Action`      | Describes the monitored behavior or operation (e.g., `Action/Resource Sharing`).                                  |
| `Misc`        | Used for miscellaneous context such as protocols, special cases, or infrastructure references (e.g., `Misc/SMB`). |

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