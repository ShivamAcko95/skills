# Communication Worker Debugging

Use this when an incident mentions communication-service, Camunda/Zeebe communication workers, `SendCommunication`, `ContextDataMapper`, quote sharing, `lead_360_share_quote`, `input_data`, or parsing errors while creating communication context.

## Required Evidence

1. Workflow id/process id, worker/task name, incident/job id, timestamp, and retry state.
2. Worker payload or workflow variables, especially `entity_details`, `proposal_id`, `reference_id`, and `lead_360_details`.
3. Proposal snapshot, including proposer/user parameters and `header.parameters.input_data_id.value`.
4. Fetched input-data capture payload when `input_data_id` is present.
5. Exact mapper line or parse site from repo evidence.

## Flow: `lead_360_share_quote`

Known path:
- `SendCommunication.handleJob` converts the Zeebe job map to `CommunicationRequest`.
- `CommunicationService.sendCommunication` calls `ContextDataMapper.getSuperContext`.
- `ContextDataMapper.getSuperContext` calls proposal and lead-360 context helpers based on `entityDetails`.
- Workflow-executer `process/config.json` maps selected fields from `input_data` plus `proposal_id` into the workflow variables for `share_quote`.
- `lead_360_share_quote.bpmn` maps those variables into `entity_details.lead_360_details`.

For this flow, validate whether `input_data` actually has the flat fields the config reads. In one confirmed case, the fetched `input_data` had nested quote data but missing/null flat fields:

```text
communication_channels = null
alternate_phone_number = absent
alternate_email = absent
document_list = null
selected_payment_frequency = null
monthly_pricing = absent
yearly_pricing = absent
porting_policy_start_date = null
```

Do not assume nested fields such as `quotes_for_lead` or `primary_recommended_plan.recommended_frequency` are mapped unless the workflow config explicitly maps them.

## DOB Parse Failures

For errors like:

```text
Failed to create super context, Exception: Text '' could not be parsed at index 0
```

check every `LocalDate.parse` site in the communication context helpers before blaming workflow wiring.

Known root cause pattern:
- `ContextHelper` parses proposer DOB from `proposal.users[role=proposer].parameters.dob.value`.
- If that value is `""`, `LocalDate.parse` fails with `Text '' could not be parsed at index 0`.
- The failure is not fixed merely by checking the insured member relation `Self`; this mapper reads the proposer user DOB. In affected data, `input_data.proposer_details.dob` and `input_data.insured_details[0].dob` may both be empty.

Repo search anchors:

```bash
rg -n "class SendCommunication|sendCommunication|getSuperContext|lead_360_details|porting_policy_start_date|LocalDate.parse|DOB" repos/communication-service
rg -n "lead_360_share_quote|share_quote|input_data|before_transformer" repos/workflow-executer-service repos/acko-camunda-config
```

## Reporting

State separately:
- whether the worker used `input_data`
- which `input_data` fields were absent/null versus present but nested under a different shape
- the exact proposal/user field that caused parsing failure
- whether the observed error is a data-quality issue, a workflow mapping issue, or mapper validation gap
