# Naming Conventions

This document defines naming standards for all code, infrastructure, and documentation in this repository.

## Severity Guidelines

- **[BLOCKER]**: Names that break Azure/PowerShell functionality or violate platform constraints
- **[MAJOR]**: Names that violate team standards and harm consistency
- **[MINOR]**: Names that are inconsistent but don't break functionality
- **[NIT]**: Style preferences and minor inconsistencies

---

## 1. Azure Resource Names

**Standard format**: `{type}-{environment}-{purpose}`

### Validation Rules

**Resource Type Prefixes** — use the [Microsoft CAF standard abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations). Commonly used abbreviations:

```
# Management
rg       - Resource Group
mg       - Management Group

# Compute and Web
vm       - Virtual Machine
vmss     - Virtual Machine Scale Set
app      - Web App / App Service
func     - Function App
asp      - App Service Plan
ase      - App Service Environment

# Containers
aks      - AKS Cluster
cr       - Container Registry
ca       - Container App
cae      - Container App Environment

# Networking
vnet     - Virtual Network
snet     - Subnet
nsg      - Network Security Group
pip      - Public IP Address
lbi      - Load Balancer (internal)
lbe      - Load Balancer (external)
agw      - Application Gateway
afw      - Azure Firewall
afwp     - Azure Firewall Policy
bas      - Azure Bastion
ng       - NAT Gateway
erc      - ExpressRoute Circuit
vgw      - Virtual Network Gateway
vpng     - VPN Gateway
rt       - Route Table
afd      - Front Door (Standard/Premium)

# Storage
st       - Storage Account (no dashes, 3-24 chars, lowercase only)
bvault   - Backup Vault

# Databases
sql      - Azure SQL Server
sqldb    - Azure SQL Database
sqlmi    - SQL Managed Instance
cosmos   - Cosmos DB
psql     - PostgreSQL
mysql    - MySQL

# Security and Identity
kv       - Key Vault
id       - Managed Identity

# Monitoring and Management
log      - Log Analytics Workspace
appi     - Application Insights
aa       - Automation Account

# Integration
apim     - API Management
sbns     - Service Bus Namespace
sbq      - Service Bus Queue
sbt      - Service Bus Topic
evhns    - Event Hubs Namespace
evh      - Event Hub

# AI and ML
oai      - Azure OpenAI Service
mlw      - Azure Machine Learning Workspace
srch     - AI Search
```

**Environment abbreviations** (from `.canary.env` / `.env`):
- `can` — canary environment
- `liv` — live/production environment

These are the ONLY valid environment tokens in resource names. Common mistakes:
- ❌ `canary` (too long — use `can`)
- ❌ `live` (wrong — use `liv`)
- ❌ `canaray`, `canayr` (typos)
- ❌ `lve`, `ive`, `lv` (typos)

Mixing `can`/`canary` or `liv`/`live` within the same solution is a **[BLOCKER]**.

**Examples**:
- ✅ `rg-can-vending` (correct — canary)
- ✅ `rg-liv-platform` (correct — live)
- ✅ `stcanvending` (storage account, correct — no dashes allowed)
- ❌ `rg-canary-vending` (wrong abbreviation — use `can`) → [MAJOR]
- ❌ `rg-live-vending` (wrong abbreviation — use `liv`) → [MAJOR]
- ❌ `my-resource-group` (missing type prefix) → [MAJOR]
- ❌ `rg_can_vending` (underscores instead of dashes) → [MAJOR]
- ❌ `resourcegroup-can-vending` (wrong prefix) → [MAJOR]
- ❌ `rg-can-vending` (non-CAF abbreviation — use `rg`) → [MAJOR]

### Storage Account Special Rules

Storage accounts have Azure platform constraints:
- 3-24 characters
- Lowercase letters and numbers only (no dashes, no uppercase)
- Must be globally unique

**Format**: `st{environment}{purpose}` (no separators)

Examples:
- ✅ `stcanvending` (correct — canary)
- ✅ `stlivplatform` (correct — live)
- ❌ `st-can-vending` (contains dashes) → [BLOCKER]
- ❌ `stCanVending` (contains uppercase) → [BLOCKER]
- ❌ `stcanaryvending` (wrong abbreviation — use `can`) → [MAJOR]

---

## 2. PowerShell Files

### Script Files

**Format**: `Verb-Noun.ps1` (PascalCase with approved verbs)

**Approved verbs**: Get, Set, New, Remove, Add, Update, Test, Invoke, Start, Stop, Deploy, Register, Unregister

**Examples**:
- ✅ `Deploy-Infrastructure.ps1` (correct)
- ✅ `Get-ResourceGroup.ps1` (correct)
- ❌ `deploy-infrastructure.ps1` (lowercase) → [MAJOR]
- ❌ `deploy_infrastructure.ps1` (underscore) → [MAJOR]
- ❌ `DeployInfrastructure.ps1` (missing verb-noun separator) → [MAJOR]
- ❌ `Create-Resource.ps1` (unapproved verb, use New-) → [MINOR]

### Module Files

**Format**: `ModuleName.psm1` (PascalCase)

Examples:
- ✅ `VendingHelpers.psm1` (correct)
- ❌ `vending-helpers.psm1` (kebab-case) → [MAJOR]

### Variables

**Local variables**: `$camelCase`
```powershell
$resourceGroup = "rg-can-app"
$storageAccount = "stcanapp"
```

**Script-scope variables**: `$PascalCase`
```powershell
$script:ConfigPath = "./config.json"
$script:DefaultRegion = "norwayeast"
```

**Environment variables**: `$env:SCREAMING_SNAKE_CASE`
```powershell
$apiKey = $env:API_KEY
$dbPassword = $env:DB_PASSWORD
```

**Examples**:
- ✅ `$resourceGroupName` (local, camelCase) → correct
- ✅ `$script:DefaultLocation` (script-scope, PascalCase) → correct
- ❌ `$ResourceGroupName` (local with PascalCase) → [MINOR]
- ❌ `$resource_group_name` (snake_case) → [MAJOR]

---

## 3. Bicep Files

### File Names

**Format**: `kebab-case.bicep`

**Examples**:
- ✅ `resource-group.bicep` (correct)
- ✅ `storage-account.bicep` (correct)
- ❌ `ResourceGroup.bicep` (PascalCase) → [MAJOR]
- ❌ `resource_group.bicep` (snake_case) → [MAJOR]
- ❌ `resourcegroup.bicep` (no separator) → [MINOR]

### Parameters and Variables

**Format**: `camelCase`

```bicep
param resourceGroupName string
param environment string = 'can'

var storageAccountName = 'st${environment}app'
var location = 'norwayeast'
```

**Examples**:
- ✅ `param storageAccountName string` (camelCase) → correct
- ❌ `param StorageAccountName string` (PascalCase) → [MINOR]
- ❌ `param storage_account_name string` (snake_case) → [MAJOR]

### Resource Symbolic Names

**Format**: `camelCase` (Bicep convention)

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  // ...
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  // ...
}
```

---

## 4. Documentation Files

### Markdown Files

**Format**: `kebab-case.md`

**Examples**:
- ✅ `coding-guidelines.md` (correct)
- ✅ `pipeline-design.md` (correct)
- ✅ `README.md` (exception - uppercase by convention) → correct
- ❌ `CODING_GUIDELINES.md` (SCREAMING_SNAKE_CASE) → [MAJOR]
- ❌ `CodingGuidelines.md` (PascalCase) → [MAJOR]
- ❌ `coding_guidelines.md` (snake_case) → [MINOR]

---

## 5. GitHub Workflow Files

### Workflow Files

**Format**: `kebab-case.yml` or `kebab-case.yaml`

**Naming pattern**: `{action}-{target}-{environment}.yml`

**Examples**:
- ✅ `deploy-infrastructure-canary.yml` (correct)
- ✅ `validate-bicep-pr.yml` (correct)
- ❌ `DeployInfrastructureCanary.yml` (PascalCase) → [MAJOR]
- ❌ `deploy_infrastructure_canary.yml` (snake_case) → [MAJOR]

### Workflow Job Names

**Format**: `kebab-case` (lowercase)

```yaml
jobs:
  validate-bicep:
    # ...

  deploy-infrastructure:
    # ...
```

**Examples**:
- ✅ `validate-bicep:` (correct)
- ✅ `deploy-infrastructure:` (correct)
- ❌ `Validate-Bicep:` (PascalCase) → [MINOR]
- ❌ `validate_bicep:` (snake_case) → [MINOR]

---

## 6. Detection Patterns

Use these patterns to detect naming violations:

### PowerShell Scripts Not Following Verb-Noun
```regex
# Files matching these patterns are violations:
^[a-z].*\.ps1$           # Lowercase start (should be PascalCase)
.*_.*\.ps1$              # Contains underscore (should be dash)
^[A-Z][a-z]+[A-Z].*\.ps1$ but no dash  # PascalCase without dash separator
```

### Bicep Files Not Using Kebab-Case
```regex
# Files matching these patterns are violations:
^[A-Z].*\.bicep$         # Starts with uppercase (should be lowercase)
.*_.*\.bicep$            # Contains underscore (should be dash)
.*[A-Z].*\.bicep$        # Contains any uppercase
```

### Documentation Not Using Kebab-Case
```regex
# Files matching these patterns are violations (except README.md):
^[A-Z_].*\.md$           # SCREAMING_SNAKE_CASE or starts with uppercase
.*_.*\.md$               # Contains underscore (should be dash)
.*[A-Z]{2,}.*\.md$       # Contains multiple consecutive uppercase (except README)
```

### Azure Resource Names
```regex
# Contains underscore instead of dash:
.*_.*

# Storage account violations:
^st.*-.*$                # Contains dash (not allowed for storage)
^st.*[A-Z].*$            # Contains uppercase (not allowed for storage)

# Non-CAF abbreviation (common mistakes):
^rsg-                    # Use rg- instead
^acr-                    # Use cr- instead
^plan-                   # Use asp- instead
^la-                     # Use log- instead
```

---

## 7. Language-Specific Casing Summary

| Language/Type | File Names | Variables/Params | Resources |
|---------------|------------|------------------|-----------|
| PowerShell    | PascalCase (Verb-Noun.ps1) | $camelCase (local) | - |
| Bicep         | kebab-case.bicep | camelCase | camelCase |
| Markdown      | kebab-case.md | - | - |
| YAML/Workflows| kebab-case.yml | kebab-case (jobs) | - |
| Azure Resources| kebab-case | - | {type}-{env}-{purpose} |

---

## 8. Consistency and Typo Detection

### Environment name consistency
All references to environments must use the correct abbreviation consistently:
- **Canary**: `can` (in resource names, file names, variables)
- **Live**: `liv` (in resource names, file names, variables)
- **Prep/PRD suffixes**: `prep` and `prd` for sub-environments (e.g., `sql-can-prep-db-services`)

Flag as **[BLOCKER]** if:
- Different environment tokens are mixed within the same solution (e.g., `can` in one resource and `canary` in another)
- A typo in an environment name could cause deployment to the wrong environment

Flag as **[MAJOR]** if:
- Wrong abbreviation used (`canary` instead of `can`, `live` instead of `liv`)
- Typo in environment name that doesn't match any known value

### Common spelling mistakes to watch for
Reviewers should flag these near-miss patterns:
- `canaray`, `canayr`, `canry` → should be `can`
- `live`, `lve`, `ive`, `lv` → should be `liv`
- `Resouces`, `Resorces` → `Resources` (common typo in script/file names)
- `Subcription` → `Subscription`
- `Enviroment` → `Environment`
- `Deploymnet` → `Deployment`

### Cross-reference validation
When reviewing, check that:
- Resource names in code match the pattern from `.canary.env` / `.env` (e.g., `rg-can-` prefix for canary resources)
- Variable names referencing environments use the correct token (`can` / `liv`, not `canary` / `live`)
- File references in workflows match actual file names exactly (case-sensitive)

---

## 9. Review Process

When reviewing naming conventions:

1. **Check file names first** (easiest to spot, highest impact on consistency)
2. **Validate Azure resource names** (functional impact + consistency)
3. **Check variable naming** (code readability)
4. **Review symbolic names** (Bicep resources, workflow jobs)

For each violation, provide:
- **Where**: Exact file name or line number
- **Why**: Which convention is violated
- **Fix**: Exact rename command or code change

### Example Findings

```markdown
- [MAJOR] PowerShell script violates Verb-Noun naming convention
  - **Where:** scripts/deploy-infrastructure.ps1
  - **Why:** Should use PascalCase: Deploy-Infrastructure.ps1
  - **Fix:** Rename: `mv scripts/deploy-infrastructure.ps1 scripts/Deploy-Infrastructure.ps1`

- [MAJOR] Bicep file violates kebab-case convention
  - **Where:** infra/ResourceGroup.bicep
  - **Why:** Should use kebab-case: resource-group.bicep
  - **Fix:** Rename: `mv infra/ResourceGroup.bicep infra/resource-group.bicep`

- [BLOCKER] Storage account name contains invalid characters
  - **Where:** storage-account.bicep:15
  - **Why:** Storage account names cannot contain dashes or uppercase
  - **Fix:** Change `st-canary-vending` to `stcanaryvending`
```
