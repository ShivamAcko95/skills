# Eligibility Debugging

Use this when Jira mentions eligibility, underwriting, journey management, DRC, rule decisions, medical/financial decisions, or current eligibility mismatch.

## Required Evidence

1. Proposal snapshot from proposal search/fetch.
2. Resolved user identifier or ekey.
3. The exact eligibility request shape from code, preferably `health-journey-management-repo` when available.
4. Current eligibility evaluation response.
5. Comparison between expected Jira behavior and actual rule result.

## Build the Request

Do not guess the request payload from memory. Reconstruct it from the proposal and code.

Search order:

```bash
find /Users/shivam.yadav/shivam -maxdepth 4 -type d -iname "*health*journey*" -o -iname "*journey*management*"
rg -n "eligibility|Eligibility|RuleEngine|evaluate|request|proposal" /Users/shivam.yadav/shivam/demo
```

In code, look for:
- mapper classes that convert proposal to eligibility request
- rule names and attributes
- default/fallback values
- member/proposer fields
- product/source/journey flags
- cached or persisted eligibility context

## Evaluate Current Eligibility

Before running evaluation, confirm the call is read-only. If the endpoint persists decisions, ask the user before running it and provide the exact request.

Capture:
- endpoint and environment
- rule name/version if present
- request payload with secrets redacted
- response decision/status
- rejection/manual-review reasons
- missing or null input fields
- timestamps and correlation ids

## LR and Payment-Frequency Reasoning

Use this path when Jira says monthly is missing, only yearly is shown, `lr_eligibility` is `Limited accept`, or proposal eligibility contains `allowed_payment_frequency`.

1. Build the `lr_eligibility` request from proposal/journey config.
   - In health journey config, map proposer fields such as `gmc_customer -> gmc_user`, `car_customer -> car_user`, `bike_customer -> bike_user`, `partnership_customer -> partnership_user`, `location_category -> location`, `region -> state_region`, plus `family_type`, `credit_score`, and `auto_blacklisted`.
   - Search local repos for `health_retail_lr_eligibility`, `lr-eligibility`, and `/rules/health_retail_lr_eligibility/evaluate`.

2. Evaluate LR and inspect the matched rule in config.
   - Search `acko-camunda-config` for the prod DMN, usually under `health/retail/dmn/prod/eligibility`.
   - Confirm the DMN `hitPolicy`; if it is `FIRST`, the first matching row explains the output.
   - Capture `status`, `sub_status`, and `mandatory_ppmc`; do not infer monthly eligibility from LR alone.

3. If monthly/payment frequency is involved, evaluate the feature-flag payment-frequency rule.
   - Search for `health_retail_feature_flag_payment_frequency`, `feature-flag`, `allowed_payment_frequency`, and the misspelling `allowed_payment_fequency`.
   - Confirm which attributes the rule consumes. The known payment-frequency DMN uses `credit_score`, `car_customer`, and `mandatory_ppmc`.
   - With `FIRST` hit policy, a top rule like `mandatory_ppmc = "Yes, at Home" -> ["YEARLY"]` can block later rules that otherwise allow `["YEARLY","MONTHLY"]`.
   - Trace the merge transformer back to the proposal field: `payment_frequencies -> input_data.eligibility_details.allowed_payment_frequency`.

Reasoning summary format:

```text
LR rule matched because <proposal attributes>.
LR returned <status/sub_status> and mandatory_ppmc=<value>.
Feature-flag payment-frequency rule then matched <condition>.
Final allowed_payment_frequency became <values>.
Therefore <missing option/decision> is caused by <rule/config path>, not by <unrelated system>.
```

## Root Cause Patterns

Check for:
- proposal data changed after original decision
- missing user id resolved by ekey but not used in the eligibility request
- member/proposer mismatch
- stale cached eligibility context
- wrong source/product/journey flag
- mapper defaulting null values differently than expected
- rule engine returning manual check/reject due to incomplete attributes
- `mandatory_ppmc` or another eligibility output driving payment-frequency restriction
- config typo between `allowed_payment_frequency` and `allowed_payment_fequency`

Report the smallest confirmed mismatch: for example, "current proposal has X, mapper sends Y, rule expects Z, so eligibility now evaluates to A instead of B."
