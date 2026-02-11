# File Export Patterns

## CSV Export (Client-Side)

**Pattern:** Data URI with client-side download

**Location:** `packages/domain/src/utils/formatDataForCsvExport.ts`

```typescript
const formatDataForCsvExport = (csvContent: string): string => {
  return `data:text/csv;charset=utf-8,${encodeURIComponent(csvContent)}`
}
```

**Usage:**
```typescript
const rawCsv = buildRawCsv(data)
const dataUri = formatDataForCsvExport(rawCsv)

const link = document.createElement('a')
link.href = dataUri
link.download = 'filename.csv'
document.body.appendChild(link)
link.click()
document.body.removeChild(link)
```

**Key Point:** No server round-trip - CSV built and downloaded entirely in browser.

## PDF Export (Server-Side)

**Pattern:** Server generates PDF as base64, client converts to blob URL

### GraphQL Flow

**1. Backend returns base64:**
```typescript
// Resolver returns pdfBase64
const documents = await pdfService().generateDocuments()
return documents.map(doc => ({
  id: doc.id,
  name: doc.name,
  content: doc.pdfBase64,  // Base64 string
}))
```

**2. GraphQL query:**
```graphql
query DynamicDocumentsQuery($applicationId: ID!) {
  cao: CAO {
    dynamicDocuments(applicationId: $applicationId) {
      id
      name
      content  # Base64 encoded PDF
    }
  }
}
```

**3. Client converts to blob URL:**
```typescript
// packages/domain/src/utils/objectUrl.ts
const getObjectUrl = (base64Encoded: string) => {
  const blob = new Blob(
    [Uint8Array.from(atob(base64Encoded), c => c.charCodeAt(0))],
    { type: 'application/pdf' }
  )
  return URL.createObjectURL(blob)  // blob:// URL
}

// Usage
const pdfUrl = getObjectUrl(document.content)
window.open(pdfUrl)
```

### REST API Flow

**Pattern:** Binary response as arraybuffer

**Backend:**
```typescript
// console-api
const pdfBuffer = Buffer.from(pdfBase64, 'base64')
res.type('pdf')
res.status(200).send(pdfBuffer).end()
```

**Frontend proxy:**
```typescript
// console-web/src/api/extensions/routes/api.ts
if (url.includes('/pdf')) {
  request.responseType = 'arraybuffer'
}
```

## When to Use Each Pattern

**Base64 (via GraphQL):**
- PDF generation from application data
- Dynamic documents
- Small to medium PDFs
- When you need PDF content in GraphQL response

**Data URI (client-side):**
- CSV exports
- Small text files
- No server processing needed

**Binary/Arraybuffer (REST):**
- Large PDFs
- Pre-generated files
- File streaming
- Better memory efficiency

## CSV Generation Server-Side

**Location:** `src/console-api/src/dbm/services/DBMProductService.ts`

**Pattern:**
```typescript
const exportRatesCsv = (): string => {
  const csvRows: string[][] = []
  csvRows.push(['product_id', 'variant_id', 'tier_number', 'apy_percent', ...])

  // Build rows from data
  products.forEach(product => {
    // ... row building logic
  })

  return csvRows.map(row => row.join(',')).join('\n')
}
```

**Exposed via GraphQL:**
```typescript
exportRatesCsv: {
  type: GraphQLString,
  resolve: async (source, _args, _context, { rootValue: { CAO } }) => {
    const dbmProductService = DBMProductService(fullConfig)
    return dbmProductService.exportRatesCsv()  // Returns CSV string
  }
}
```

## Key Files

| Pattern | File |
|---------|------|
| CSV Data URI | `packages/domain/src/utils/formatDataForCsvExport.ts` |
| PDF to Blob | `packages/domain/src/utils/objectUrl.ts` |
| PDF Service | `src/console-api/src/cao/services/PdfService.ts` |
| CSV Generation | `src/console-api/src/dbm/services/DBMProductService.ts` |
| PDF Controller | `src/pdf-service/src/controllers/pdf.controller.ts` |
| REST Proxy | `src/console-web/src/api/extensions/routes/api.ts` |
