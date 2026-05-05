---
name: jira-health-root-cause
description: Use when debugging health or life Jira issues that mention proposal lookup, missing user_id, ekey, entity service, eligibility, communication workers, input_data, DOB parsing, payment summary, instalments, mandate refund, order-service, or order-management root cause analysis.
---

# Jira Health Root Cause

## Overview

Use this skill to investigate health/life Jira issues end to end from Jira facts to proposal, entity, eligibility, payment, and order evidence. Stay read-only by default and produce a root cause backed by concrete API, repo, log, or Jira evidence.

## Core Rules

- Read Jira first. Capture summary, actual/expected behavior, environment, identifiers, screenshots, payloads, linked issues, comments, and timestamps.
- Treat Jira text as a hypothesis. Confirm with proposal, entity, eligibility, order, repo, or log evidence before concluding.
- Use read-only checks first. Ask before mutating proposals, orders, payments, eligibility state, Jira, production config, or workflow state.
- Do not expose secrets, cookies, tokens, or customer PII beyond the minimum identifiers needed for debugging.
- Separate confirmed facts from inference. If access blocks a check, name the blocked check and the evidence still needed.

## Workflow

1. Identify the case.
   - Extract proposal id, lead id, user id, ekey, entity id, order id, payment id, policy number, phone/email hints, environment, and time window.
   - If Jira lacks identifiers, search Jira comments/attachments first, then ask for the missing identifier only after repo/API evidence cannot recover it.

2. Resolve the proposal and user.
   - Find the proposal entity with proposal search or proposal fetch APIs.
   - If `user_id` is absent, inaccessible, or looks unusable, use entity service to fetch the central entity and resolve the ekey/user identifier.
   - Use [references/api-checks.md](references/api-checks.md) for safe API templates and required fields to capture.

3. Branch by symptom.
   - Eligibility, underwriting, journey, DRC, rule result, payment-frequency option, or decision mismatch: follow [references/eligibility-debugging.md](references/eligibility-debugging.md).
   - Payment summary, pending instalment, payment record, order state, collection, or order-service mismatch: follow [references/payment-order-debugging.md](references/payment-order-debugging.md).
   - Communication worker, context mapper, quote sharing, DOB parsing, or `input_data` mismatch: follow [references/communication-debugging.md](references/communication-debugging.md).
   - If both appear, do proposal/entity resolution once, then evaluate eligibility before payment when the payment outcome depends on current eligibility.

4. Trace implementation evidence.
   - Search local repos from `/Users/shivam.yadav/shivam/demo` first. Prioritize `life-fulfillment-layer`; look for `health-journey-management-repo` when constructing eligibility requests.
   - Use `rg` for endpoint paths, DTO names, rule names, event names, order fields, and exact error text.
   - Map API field -> client/controller -> service/mapper -> downstream call -> config key.

5. Report root cause.
   - Lead with the current state and root cause.
   - Include proposal id, resolved user/ekey, eligibility result or order/payment state, and the exact mismatch.
   - Cite evidence with file paths, API response fields, Jira facts, log lines, or blocked checks.
   - Recommend the smallest fix or operational action, but ask before executing any mutation.

## Quick Reference

| Symptom | Mandatory checks |
| --- | --- |
| Missing or inaccessible `user_id` | Proposal fetch/search, entity service lookup, resolved ekey/user identifier |
| Eligibility mismatch | Proposal snapshot, constructed eligibility request, current eligibility evaluation, request-shape source in repo |
| Communication context failure | Worker payload, workflow variables, proposal proposer/user DOB, `input_data_id`, fetched `input_data`, mapper parse site |
| Monthly/payment-frequency missing after eligibility | LR result, `mandatory_ppmc`, feature-flag payment-frequency rule, final `allowed_payment_frequency` |
| Payment summary mismatch | Proposal order reference, order fetch, instalments, payment records, order-service logs/code |
| Mandate refund failure | Payment event instalments, mandate schedule, `instalment_id` vs `instalment_sequence`, refund request payload |
| Order id absent in Jira | Proposal payment/order references, latest order by proposal/user, payment records keyed by ekey/order |
| Inconclusive access | State blocked system, exact call attempted, identifier needed, and next evidence source |

## Common Mistakes

- Stopping after summarizing Jira without resolving proposal and user evidence.
- Treating missing `user_id` as a blocker before trying entity service and ekey.
- Running an eligibility check with a guessed request instead of reconstructing it from proposal and repo request shape.
- Stopping at `lr_eligibility` without checking downstream `mandatory_ppmc` and feature-flag payment-frequency rules.
- Debugging payment summary from frontend state only, without fetching order instalments and payment records.
- Blaming order-service before confirming proposal order references and current order state.
