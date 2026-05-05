# API Checks

Use these as read-only templates. Replace placeholders, preserve response ids, and redact secrets. Ask before POST/PUT/PATCH/DELETE calls that mutate state; evaluation-style POSTs are allowed only when they do not persist state.

## Proposal Search

Goal: find the proposal entity and the identifiers needed for downstream checks.

Capture:
- `proposal_id`, proposal status, journey/source, product, environment
- `user_id`, `entity_id`, `ekey`, proposer/member identifiers
- order/payment references, policy references, latest updated timestamp

Template:

```bash
curl -sS "$PROPOSAL_BASE_URL/<proposal-search-path>?proposal_id=<PROPOSAL_ID>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>"
```

If path is unknown, search local repos:

```bash
rg -n "proposal.*search|search.*proposal|proposal_id|proposalId" /Users/shivam.yadav/shivam/demo
```

## Entity Service

Use when `user_id` is absent, inaccessible, stale, or not accepted by downstream services.

Capture:
- central entity id
- ekey
- mapped user id
- active/merged/deleted state if present

Template:

```bash
curl -sS "$ENTITY_BASE_URL/<entity-path>?ekey=<EKEY_OR_ENTITY_KEY>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>"
```

Repo hints:

```bash
rg -n "CentralEntityClient|getCentralUserByEkey|entity service|ekey" /Users/shivam.yadav/shivam/demo
```

## Eligibility Engine

Capture rule name, request payload, response status, decision fields, reasons, rule traces, and timestamp.

Template:

```bash
curl -sS "$ELIGIBILITY_BASE_URL/<evaluate-path>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  --data '<ELIGIBILITY_REQUEST_JSON>'
```

Repo hints:

```bash
rg -n "eligibility|evaluate|RuleEngine|EligibilityProcessor|map\\(proposal|map\\(.*Proposal" /Users/shivam.yadav/shivam/demo
```

## Order and Payment

Capture:
- order id from proposal
- order status and source
- instalments with due date, amount, status, payment order ids
- payment records/transactions for each relevant order/payment id
- failed event or sync status if present

Templates:

```bash
curl -sS "$ORDER_BASE_URL/<order-fetch-path>/<ORDER_ID>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>"

curl -sS "$ORDER_SERVICE_BASE_URL/<payment-record-path>?order_id=<ORDER_ID>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>"
```

Repo hints:

```bash
rg -n "LifeOrderClient|order-service|order-management|instalments|paymentRecords|paymentOrderIds|order_id|orderId" /Users/shivam.yadav/shivam/demo
```
