# Payment and Order Debugging

Use this when Jira mentions payment summary, pending instalments, instalment amount/status, payment record, order id, order-service, order-management, payment collection, or renewal/payment reminder state.

## Required Evidence

1. Proposal snapshot and order/payment references.
2. Resolved user identifier or ekey.
3. Order fetch from order-management or order-service.
4. Instalment list and payment order ids.
5. Payment records or transactions for relevant order/payment ids.
6. Repo/log evidence for the service that maps order state into the user-visible payment summary.

## Trace Order ID

Start from proposal fields and payment/order references. If Jira has no order id, search proposal payload for:
- `order_id`, `orderId`
- `payment_order_id`, `paymentOrderId`, `paymentOrderIds`
- policy/order references
- latest payment summary block

Then fetch the order and compare it to proposal state. Do not infer order state from proposal alone.

## Verify Instalments

For each instalment capture:
- instalment id/key
- due date
- amount
- status
- payment order ids
- paid/failed/pending timestamps
- retry or collection state if present

If a summary selects a "current" instalment, inspect code for ordering rules and matching by ekey/payment order id:

```bash
rg -n "instalment|paymentOrderIds|oldestMatching|pendingInstalments|payment summary|PaymentReminder|ContextDataMapper|CommsOrderProcessor" /Users/shivam.yadav/shivam/demo
```

## Verify Payment Records

Fetch payment records for the order id and any payment order ids referenced by instalments. Compare:
- record status vs instalment status
- transaction timestamp vs order update timestamp
- amount and currency
- duplicate/missing records
- failure reason or gateway status

If order-service and order-management disagree, identify which system is the source for the user-visible flow in the affected repo.

## Mandate Schedule and Rs.2 Refund

Use this branch when renewal/mandate flows mention `refundMandateOrderDetails`, `updateMandateOrderDetails`, `copyMandateAndCreatePaymentPlan`, `_mandate_schedule`, `Refund not initiated`, or mandate instalments with unexpected ids.

Key distinction:

| Field | Owner | Meaning |
| --- | --- | --- |
| order `Instalment.instalmentId = 0` | order-service | mandate marker/sentinel |
| payment create request `instalment_sequence = 0` | order-service -> payment-service | business sequence identifying mandate instalment |
| payment response/event `instalment_id` | payment-service | persisted/generated payment-service instalment id |

Do not assume mandate `instalment_id` is `0`. For mandate schedules, real data may be:

```json
{"instalment_id": 1, "instalment_sequence": 0}
```

Required checks:
- Fetch payment plan/schedule and locate the schedule whose `schedule_reference_id` ends with `_mandate_schedule`.
- Capture each mandate instalment's `instalment_id`, `instalment_sequence`, amount, status, and payment order ids.
- Inspect the payment event consumed by the worker; it should contain both `instalment_id` and `instalment_sequence`.
- Inspect refund request payload. Refund APIs expect `installment_id`/`instalment_id` from payment-service, not order-service's sequence marker.

Known root cause pattern:
- `RefundMandateOrderDetails` builds Rs.2 refund request.
- Old buggy behavior hardcoded `installment_id = Constants.MANDATE_INSTALLMENT_ID` (`0`).
- If payment-service generated mandate row as `instalment_id = 1` with `instalment_sequence = 0`, refund API could not match the row, returned no successful refund instalments, and worker threw `RuntimeException("Refund not initiated")`.
- Correct behavior: find the payment event instalment where `instalment_sequence == "0"` and use that event's actual `instalment_id` in the refund request.

Repo anchors in `order_service`:

```bash
rg -n "MANDATE_INSTALLMENT_ID|RefundMandateOrderDetails|createRefundRequestOfRs2|_mandate_schedule|generateMandateScheduleDetails|createNewScheduleAndCopyMandate" repos/order_service/health-order/src/main/java
```

Specific code points to inspect:
- `Constants.MANDATE_INSTALLMENT_ID = 0`
- `MandateOrderService` creates mandate order instalment with `instalmentId(0)`.
- `ScheduleGenerator.orderInstalmentsToPaymentPlanInstalmentsMapper` maps order `instalmentId` to payment request `instalmentSequence`.
- `InstalmentRequestDto` has `instalmentSequence`, not `instalmentId`.
- `InstalmentResponse` has both `instalmentId` and `instalmentSequence`.
- `PaymentEvent.Instalment` has both `instalmentId` and `instalmentSequence`.
- `RefundApiRequestDto.RefundInstallmentsDto.installmentId` is the actual payment-service id expected by refund.

## Root Cause Patterns

Check for:
- proposal points to old/missing order id
- instalment is paid but payment record did not sync
- payment record exists but instalment status is stale
- wrong instalment selected because matching uses first payment order id or ekey
- order-service event failed and left local state unsynced
- mandate refund uses sequence marker `0` as payment-service `instalment_id`
- frontend/payment summary reads proposal snapshot while backend reads order state
- environment mismatch between proposal and order services

Report the exact mismatch and the system of record, for example: "proposal references order O, order instalment I is PAID, but payment summary uses stale proposal block P, so UI shows pending."
