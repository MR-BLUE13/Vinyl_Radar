# Radar Feed Aggregator (V1)

## Scope
- First batch sources:
  - Blood Records
  - bad world
  - Banquet Records
- Rough Trade US is reserved for phase 2.

## API contract
`GET /v1/radar/releases`

Response:
```json
{
  "generatedAt": "2026-03-22T13:00:00Z",
  "releases": [
    {
      "id": "blood_records_12345",
      "artist": "Artist",
      "title": "Release Title",
      "coverImageURL": "https://...",
      "sourceItemURL": "https://...",
      "sourceItemKey": "blood_records_product_12345",
      "storeID": "store_blood_records",
      "publishedAt": "2026-03-22T12:40:00Z",
      "flags": ["NEW", "LIMITED", "COLORED"]
    }
  ]
}
```

## Store IDs
- `store_blood_records`
- `store_bad_world`
- `store_banquet_records`
- `store_rough_trade_us` (reserved)

## Normalization rules
- Keep source records separate even for same artist/title across stores.
- De-duplicate only within a single store using `sourceItemKey`.
- `NEW`: first-seen timestamp within 72h.
- `LIMITED`: keywords include `limited`, `copies`, `numbered`.
- `COLORED`: keywords include `colored`, `coloured`, `splatter`, `clear`, `marble`.
- `EXCLUSIVE`: keywords include `exclusive`, `store exclusive`.

## Fetch cadence
- Run every 10 minutes.
- Execution order:
  1. blood
  2. bad world
  3. banquet
- Single source failure must not block the whole snapshot.

## Adapter stubs (phase 1)
- `BloodRecordsAdapter`: `/collections/drops`
- `BadWorldAdapter`: site product/drop listing entrypoint
- `BanquetRecordsAdapter`: `/pre-orders`

## Adapter stub (phase 2)
- `RoughTradeUSAdapter`
