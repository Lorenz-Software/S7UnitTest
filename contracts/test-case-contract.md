# Test Case Contract

## Purpose

This contract defines the PLC-side producer contract for Test Case control/configuration and the related Preparation and Assertion interface rules.

## Scope

This contract defines:

- `UDT_UnitTestCaseControl`,
- `UDT_UnitTestCaseConfig`,
- `UDT_UnitTestCaseExecutionStatus`,
- `UDT_UnitTestPreparationStatus`,
- Test Case lifecycle metadata used for capacity-aware orchestration,
- assertion interface expectations relevant to the producer contract.

This contract references:

- `general-framework-contract.md` for shared execution/result semantics and shared type rules,
- `event-stream-model-contract.md` for event-entry structure, event classifications, and event-stream rules.

## Version

- Contract version: `1.0.0`

## Requirements

- `TCC-001` `UDT_UnitTestCaseControl` MUST use the top-level structure `Name`, `Cmd`, and `Status`.
- `TCC-002` `Name` MUST be a stable instance property and MUST NOT be modeled inside `Status`.
- `TCC-003` Test Case top-level field references MUST follow Table A.
- `TCC-004` Shared framework command fields MUST follow Table B.
- `TCC-005` Case-status fields MUST follow Table C.
- `TCC-006` Test Case configuration fields MUST follow Table D.
- `TCC-007` Test Case execution-status fields MUST follow Table E.
- `TCC-008` `Name` MUST be configured in `UDT_UnitTestCaseConfig` by the owning Test Suite and published by the Test Case into `UDT_UnitTestCaseControl`.
- `TCC-009` Preparation status fields MUST follow Table F and MUST NOT contain `Result` or `Inactive`.
- `TCC-010` Preparation MUST be controlled through its block interface by level-based `Enable` semantics and MUST report its execution state through `UDT_UnitTestPreparationStatus`.
- `TCC-011` Preparation timeout monitoring MUST remain the responsibility of the owning Test Case.
- `TCC-012` Test Case preparation MUST be modeled under `UnitTest.ExecutionStatus.Running`.
- `TCC-013` Assertions SHOULD expose their inputs and results through their block interface.
- `TCC-014` Assertions MUST support `Reset` and `Enable`. Assertions that can validly observe and evaluate without a previous enabled observation SHOULD support `ObserveFirstCycle`, and `ObserveFirstCycle` MUST default to `TRUE` when present.
- `TCC-015` The decisive assertion output toward the owning Test Case MUST be `Result`.
- `TCC-016` Assertion logging context passed into the assertion MUST include `Name`, `ResourceName`, and `State`.
- `TCC-017` Command triggers MUST be interpreted by positive edge.
- `TCC-018` Command triggers SHOULD normally be reset again at the end of the same internal cycle.
- `TCC-019` Timeout deactivation MUST NOT be allowed. Zero and negative timeout values MUST be treated as invalid.
- `TCC-020` Assertion-generated `Failed` and `Error` event entries MUST be emitted by the assertion itself as one-shot entries using the event structures and classifications defined in `event-stream-model-contract.md`.
- `TCC-021` Aggregation and higher-level test-case result events MUST remain the responsibility of the owning Test Case and MUST use the event structures and classifications defined in `event-stream-model-contract.md`.
- `TCC-022` A Test Case preparation failure or preparation timeout MUST prevent test-state execution and MUST complete the Test Case with `UnitTest.Result.Error`.
- `TCC-023` Assertion `Reset` MUST deterministically clear assertion-local state and MUST suppress evaluation and assertion-generated events while active.
- `TCC-024` Assertion `Enable = FALSE` MUST disable observation and direct evaluation from observation, and MUST NOT implicitly clear latched assertion state. A separate explicit `Evaluate` request remains governed by `TCC-055`.
- `TCC-025` Assertion `Enable = FALSE` MUST NOT overwrite a valid previously produced assertion `Result`.
- `TCC-026` Assertion `Reset` MUST have priority over `Enable`.
- `TCC-027` Assertion-generated event entries MUST use `UnitTest.OwnerScope.Assertion`.
- `TCC-028` Assertion-generated event entries MUST write the owning Test Case state provided through the assertion interface as `State`.
- `TCC-029` Text values rendered into assertion-generated event messages MUST be bounded by `UnitTest.TextLength.AssertionValue`.
- `TCC-030` Preparation MUST NOT use a separate external control UDT.
- `TCC-031` `PreparationStatus.Ready = TRUE` MUST mean that the Preparation can accept execution and is not actively driving the tested resource toward the target condition.
- `TCC-032` `PreparationStatus.Completed = TRUE` MUST mean that the Preparation target condition has been reached.
- `TCC-033` The owning Test Case or Test Case sequencer MUST NOT treat `PreparationStatus.Ready = TRUE` without `Completed = TRUE` as a direct error while the Test Case is in `Preparing`; deterministic termination MUST be handled by the preparation timeout.
- `TCC-034` Preparation status flags MUST follow the execution-status mapping defined in Table G.
- `TCC-035` Preparation error and preparation timeout diagnostic events emitted by a Test Case or Test Case sequencer MUST include the reported Preparation `State` in the event message.
- `TCC-036` Test Case `Ready = TRUE` MUST require both `State = UnitTest.State.Idle` and a positive implementation-specific ready release.
- `TCC-037` Before entering `Preparing`, the owning Test Case or Test Case sequencer SHOULD evaluate `PreparationStatus.Completed` and skip the active Preparation phase if the preparation target condition is already reached.
- `TCC-038` Test Case finalization MUST use `UnitTest.State.Completing` for final Test Case result and Assertion aggregation publication before the Test Case enters `UnitTest.State.Completed`.
- `TCC-039` Test Case MUST emit exactly one final Test Case Result event for each controllable Test Case lifecycle from `Idle` to `Completed`.
- `TCC-040` Test Case MUST emit exactly one final Test Case Aggregation event for each controllable Test Case lifecycle from `Idle` to `Completed`.
- `TCC-041` Test Case MUST emit its final Result and Aggregation events while in `UnitTest.State.Completing` and before the final state-transition event into `UnitTest.State.Completed`.
- `TCC-042` Test Case `Name` MUST be the full hierarchical Test Case name `<runControlName>.<suiteName>.<testCaseName>` defined by `event-stream-model-contract.md`.
- `TCC-043` The owning Test Suite MUST configure each Test Case with a valid full hierarchical Test Case name.
- `TCC-044` Assertion event names passed by a Test Case MUST start with the full Test Case name followed by `.` and a non-empty assertion-local name.
- `TCC-045` Test Case lifecycle-capacity metadata MUST follow Table C and the lifecycle-capacity metadata rules in this contract.
- `TCC-046` `PreparationStateCount` MUST describe the maximum number of Preparation-state entries along one executable Test Case lifecycle path from `Idle` to `Completed`.
- `TCC-047` `TestStateCount` MUST describe the maximum number of Test-state entries along one executable Test Case lifecycle path from `Idle` to `Completed`.
- `TCC-048` `PreparationStateCount = 0` MUST represent a Test Case without a Preparation state, and `TestStateCount` MUST be greater than `0`.
- `TCC-049` `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal` MUST be valid when the Test Case reports `State = UnitTest.State.Idle` and `Ready = TRUE`.
- `TCC-050` `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal` MUST remain stable throughout the following Test Case execution through `UnitTest.State.Completed`.
- `TCC-051` A Test Case with branching lifecycle paths MUST publish the longest executable path, and a Test Case with an unbounded number of Preparation-state or Test-state entries MUST be treated as invalid for capacity-aware orchestration.
- `TCC-052` When `ObserveFirstCycle = TRUE`, an Assertion MUST include the first enabled call after Reset or re-enable in its observation. When `ObserveFirstCycle = FALSE`, that call MUST NOT observe checked values or evaluate them unless a separate explicit `Evaluate` request applies.
- `TCC-053` After the first enabled call, an Assertion with `ObserveFirstCycle` MUST observe every continuously enabled call, subject to Reset priority and any assertion-specific explicit observation condition.
- `TCC-054` A disabled call MUST make the next enabled call a new first enabled call without clearing other latched assertion state.
- `TCC-055` An explicit `Evaluate` request MUST NOT be delayed or suppressed by `Enable` or `ObserveFirstCycle`, and Reset priority MUST suppress it.
- `TCC-056` Assertions that require a previous enabled value or signal sample MUST establish that baseline on the first enabled call and MUST NOT expose `ObserveFirstCycle` when observation without that baseline is invalid.
- `TCC-057` Sequence Assertions with explicit `Evaluate` MUST include the current input in sequence observation before evaluating completion.
- `TCC-058` Edge-count Assertions with explicit `Evaluate` MUST evaluate the already accumulated edge count and MUST NOT include the current input as an additional edge observation solely because `Evaluate = TRUE`.
- `TCC-059` Ordinary scalar REAL/LREAL Assertions MUST reject non-finite checked values, expected values and bounds with `UnitTest.Result.Error` during active observation, including the first enabled baseline observation of `AssertNoValueChange_*`; the affected families are listed under Floating-point Assertion domains.
- `TCC-060` REAL/LREAL Assertion tolerances MUST be finite and nonnegative; an invalid tolerance MUST produce `UnitTest.Result.Error` when observation or initial snapshot capture is active.
- `TCC-061` `AssertEqualArray_Real` and `AssertEqualArray_LReal` MUST reject any non-finite expected element with `UnitTest.Result.Error`; a non-finite actual element MUST be a mismatch against valid expected data.
- `TCC-062` REAL/LREAL `AssertArrayContainsValue_*`, `AssertArrayContainsArray_*` and `AssertArrayAllEqual_*` MUST reject expected NaN with `UnitTest.Result.Error`, permit expected signed infinity, never match actual NaN, and match infinities only when their signs agree. A nonmatching actual element MUST NOT invalidate a successful search elsewhere in the selected range.
- `TCC-063` REAL/LREAL `AssertArrayNoValueChange_*` MUST reject NaN in the initial snapshot with `UnitTest.Result.Error` before accepting that snapshot, permit signed infinity in the snapshot, and treat later actual NaN as a mismatch; unchanged same-sign infinity MUST match.
- `TCC-064` Floating-point domain validation MUST respect Reset and observation eligibility, MUST precede functional evaluation and search short-circuiting, and MUST remain effective after a held Failed result so that invalid data can escalate the result to Error. Existing Error priority and independent one-shot findings MUST remain unchanged.
- `TCC-065` Finite REAL/LREAL tolerance comparisons MUST avoid an overflowing typed difference and retain inclusive tolerance boundaries. A mathematical difference greater than the largest finite value of the checked type MUST be outside every valid tolerance, even when ordinary rounded subtraction would conceal that excess.
- `TCC-066` Numeric Assertion diagnostics MUST use six significant decimal digits by default with round-to-nearest, ties-to-even, and MUST NOT alter the values or rounding used by functional comparisons.
- `TCC-067` Numeric Assertion diagnostics MUST render NaN, positive infinity, negative infinity, positive zero and negative zero explicitly as `NaN`, `+Inf`, `-Inf`, `0` and `-0`, respectively, within the existing Assertion-value text limit.
- `TCC-068` `AssertArrayNoValueChange_*` MUST capture the first eligible snapshot after initialization or Reset and track its validity independently of `Result`. A snapshot MUST become valid only after successful validation and copying, and MUST remain the reference until Reset.
- `TCC-069` `AssertArrayNoValueChange_*` MUST preserve snapshot contents and validity while disabled and MUST NOT recapture on re-enable. Comparison MUST require two consecutive enabled non-Reset calls, including after re-enable.
- `TCC-070` `AssertArrayNoValueChange_*` Reset MUST invalidate the snapshot and clear result, previous-enable state and finding history without requiring a physical wipe of `Memory`. Reset MUST suppress snapshot capture as well as comparison and findings.
- `TCC-071` A held `UnitTest.Result.Error` in `AssertArrayNoValueChange_*` MUST prevent snapshot capture until Reset.
- `TCC-072` `AssertRisingEdgeCntInRange`, `AssertRisingEdgeCntNotInRange`, `AssertFallingEdgeCntInRange` and `AssertFallingEdgeCntNotInRange` MUST report `UnitTest.Result.Error` when `Minimum > Maximum` on an explicit `Evaluate` request not suppressed by Reset. `Minimum = Maximum` MUST remain valid. Invalid bounds MUST NOT alone enable observation or trigger evaluation without `Evaluate`.
- `TCC-073` `AssertContains_String`, `AssertContains_WString`, `AssertStartsWith_String`, `AssertStartsWith_WString`, `AssertEndsWith_String` and `AssertEndsWith_WString` MUST report `UnitTest.Result.Error` for an empty `Fragment`, `Prefix` or `Suffix`, respectively, during eligible observation, including after a held Failed result. Empty operands in exact text equality MUST remain valid. See Scalar search patterns and array-token counts.
- `TCC-074` The BYTE/WORD `AssertArrayTokenCnt*` and `AssertNoArrayToken_*` Assertions MUST count complete, non-overlapping token matches within the selected input range using full-width typed equality. After a match, the next candidate MUST start after the complete matched token; after a mismatch, the next candidate MUST advance by one element. See Scalar search patterns and array-token counts.

- `TCC-075` A Test Case sequencer MUST expose `UnitTest.State.Reset` for at least one invocation before reacting to invalid Reset configuration; invalid configuration in Reset MUST finalize through `UnitTest.State.Completing` with `UnitTest.Result.Error`.
- `TCC-076` Invalid configuration in `UnitTest.State.Idle` MUST retain Idle with `UnitTest.Result.Error`, suppress Start and Ready, and remain latched until Reset; it MUST NOT emit final Result or Aggregation solely for that Idle error. See Pre-execution configuration errors.
- `TCC-077` An Idle/Error Test Case requires no abort work and MAY satisfy the parent's abort-completion check without being Completed. See Pre-execution configuration errors.
- `TCC-078` The orchestration above the affected Test Cases MUST ensure that at most one Test Case controls a shared external resource at a time; Test Cases MUST NOT coordinate with peers to provide this orchestration guarantee. See External resource ownership and Reset.
- `TCC-079` A Test Case MUST confine functional manipulation of external resources to its active Preparation and test phases; its Preparation MUST stop influencing the resource outside its enabled active execution, and an inactive or completed Test Case MUST NOT interfere with a subsequent user of the resource. See External resource ownership and Reset.
- `TCC-080` Public DUT Reset requests used for reset or abort cleanup are an exception to the active-phase stimulus restriction. After requesting Reset, the Test Case MUST monitor the defined idle condition rather than continue functional stimulus; reaching that DUT idle condition MUST NOT by itself require DUT Ready to be TRUE. See External resource ownership and Reset.
- `TCC-081` Repeated public Reset requests MUST target the same defined DUT idle condition; protection of critical sections during DUT Reset execution MUST remain the DUT's responsibility, not Test Case peer arbitration. See External resource ownership and Reset.

- `TCC-082` Edge-count Assertions MUST retain `65535` as a valid observed count. If another eligible edge would exceed the `UInt` count range, the Assertion MUST keep `EdgeCount` at `65535`, latch `UnitTest.Result.Error`, and emit one Assertion Error finding. Further calls MUST NOT increment the counter or perform functional count evaluation until Reset clears the error and count. A prior Passed or Failed result MUST NOT suppress this overflow detection.

## Requirement Details

### Table A: Test Case top-level fields

| Field | Type | Default |
| --- | --- | --- |
| `Name` | `STRING[UnitTest.TextLength.Name]` | `''` |
| `Cmd` | `STRUCT` | fields defaulted explicitly in code |
| `Status` | `STRUCT` | fields defaulted explicitly in code |

### Table B: Shared framework command fields

| Field | Type | Default |
| --- | --- | --- |
| `Start` | `BOOL` | `FALSE` |
| `Abort` | `BOOL` | `FALSE` |
| `Reset` | `BOOL` | `FALSE` |

### Table C: Case-status fields

| Field | Type | Default |
| --- | --- | --- |
| `Execution` | `UDT_UnitTestCaseExecutionStatus` | field defaults of nested UDT |
| `PreparationStateCount` | `UINT` | `0` |
| `TestStateCount` | `UINT` | `0` |
| `AssertionCountTotal` | `UINT` | `0` |
| `AssertionCountPassed` | `UINT` | `0` |
| `AssertionCountFailed` | `UINT` | `0` |
| `AssertionCountError` | `UINT` | `0` |
| `Runtime` | `DINT` | `0` |

### Lifecycle-capacity metadata

`PreparationStateCount` and `TestStateCount` describe the maximum number of entries into the corresponding state categories during one controllable Test Case lifecycle. They count state entries along an executable path, not merely distinct numeric state values.

For a branching Test Case, the published values describe the longest executable path. Finite repeated state sequences are included according to their maximum number of entries. An unbounded loop cannot provide stable capacity metadata and is therefore invalid for capacity-aware orchestration.

`AssertionCountTotal` describes the number of Assertions owned by the Test Case for the same execution. These three values are structural execution metadata. They are published cyclically in the Test Case status view, become valid with the executable `Idle AND Ready` state, and remain stable until the execution reaches `Completed`.

### Table D: Test Case configuration fields

| Field | Type | Default |
| --- | --- | --- |
| `Name` | `STRING[UnitTest.TextLength.Name]` | `''` |
| `Timeout` | `DINT` | `5000` |
| `PreparationTimeout` | `DINT` | `2000` |

### Naming

The Test Case `Name` is the full hierarchical Test Case name used in status data and event entries:

```text
<runControlName>.<suiteName>.<testCaseName>
```

The owning Test Suite configures this value. The Test Case publishes the same value into its control data and uses it as the parent path for Assertion event names.

Assertion event names passed to Assertion blocks follow:

```text
<runControlName>.<suiteName>.<testCaseName>.<assertionName>
```

For Assertion events, everything after the third dot belongs to the assertion-local name. Assertion blocks do not validate this hierarchy themselves; the Test Case is responsible for passing the correct name context. The event-stream consumer can use the first three path segments to derive the owning Test Case.

Run Control, Suite, and Test Case name segments must follow the hierarchy and character rules from `event-stream-model-contract.md`. Invalid Test Case names are configuration errors for the owning implementation path.

### Table E: Test Case execution-status fields

| Field | Type | Default |
| --- | --- | --- |
| `State` | `INT` | `UnitTest.State.Uninitialized` |
| `ExecutionStatus` | `INT` | `UnitTest.ExecutionStatus.Unknown` |
| `Result` | `INT` | `UnitTest.Result.NotEvaluated` |
| `Uninitialized` | `BOOL` | `FALSE` |
| `ConfigError` | `BOOL` | `FALSE` |
| `Ready` | `BOOL` | `FALSE` |
| `Running` | `BOOL` | `FALSE` |
| `Completed` | `BOOL` | `FALSE` |
| `Aborted` | `BOOL` | `FALSE` |
| `Inactive` | `BOOL` | `FALSE` |
| `Error` | `BOOL` | `FALSE` |
| `PreparationActive` | `BOOL` | `FALSE` |
| `TestActive` | `BOOL` | `FALSE` |

### Table F: Preparation status fields

| Field | Type | Default |
| --- | --- | --- |
| `State` | `INT` | `0` |
| `ExecutionStatus` | `INT` | `UnitTest.ExecutionStatus.Unknown` |
| `Ready` | `BOOL` | `FALSE` |
| `Running` | `BOOL` | `FALSE` |
| `Completed` | `BOOL` | `FALSE` |
| `Error` | `BOOL` | `FALSE` |

### Table G: Preparation execution-status mapping

| Preparation condition | `ExecutionStatus` | Required flags |
| --- | --- | --- |
| No active preparation work and target condition not reached | `UnitTest.ExecutionStatus.Idle` | `Running = FALSE`, `Completed = FALSE`, `Error = FALSE`; `Ready` reflects whether the Preparation is currently callable |
| Actively driving the resource toward the target condition | `UnitTest.ExecutionStatus.Running` | `Ready = FALSE`, `Running = TRUE`, `Completed = FALSE`, `Error = FALSE` |
| Target condition reached | `UnitTest.ExecutionStatus.Completed` | `Running = FALSE`, `Completed = TRUE`, `Error = FALSE` |
| Preparation cannot continue meaningfully | `UnitTest.ExecutionStatus.Error` | `Running = FALSE`, `Error = TRUE` |

### Preparation execution semantics

`UDT_UnitTestCaseExecutionStatus` is intentionally aligned with `UDT_UnitTestExecutionStatus` and extends it through an explicit field copy with test-case-specific execution flags.

For non-state-machine-based preparations:

- while `Enable = TRUE`, the preparation MAY establish the target state over one or more cycles,
- if `Enable = FALSE` before the target state is reached, the preparation returns to performing no action on the resource and reports `Ready = TRUE`.

For state-machine-based preparations:

- the internal preparation state machine runs only while enabled,
- if `Enable = FALSE` before the target state is reached, the preparation returns to performing no action on the resource and its internal state machine returns to its executable base state.

The standard Preparation block interface is:

- `Enable : BOOL` as level-based execution and resource-ownership signal from the owning Test Case,
- `Status : UDT_UnitTestPreparationStatus` as structured status returned to the owning Test Case.

`Ready` is a preparation-readiness signal, not a target-condition signal. `Ready = TRUE` indicates that the Preparation is callable and not actively changing the tested resource. `Ready` may therefore be `TRUE` even when the target condition has not been reached.

`ExecutionStatus = Idle` means that the Preparation is not actively working. It does not by itself imply `Ready = TRUE`. A Preparation may report `ExecutionStatus = Idle` with `Ready = FALSE` when it is not actively manipulating the resource but cannot currently accept preparation execution.

`Running = TRUE` indicates that the Preparation is actively trying to establish the target condition. `Completed = TRUE` indicates that the target condition has been reached. Once `Completed = TRUE`, the Preparation must not perform further preparation work in the current preparation phase unless keeping the reached condition stable is explicitly part of the preparation behavior.

`Ready = TRUE` and `Completed = TRUE` may be set at the same time when the target condition has been reached and no further active preparation work is required. `Running = TRUE` is exclusive to `Ready = TRUE` and `Completed = TRUE`.

If `Enable = FALSE` while the Preparation is running and the target condition has not been reached, the Preparation should stop active resource manipulation and return to `Ready = TRUE` without setting `Completed`. If the target condition has already been reached, the Preparation reports `Completed = TRUE`.

While the owning Test Case is in `Preparing`, `PreparationStatus.Completed = TRUE` is the normal transition condition into the test states. `PreparationStatus.Error = TRUE` is a preparation error condition. Other non-final states, including `Ready = TRUE` with `Completed = FALSE`, keep the Test Case in `Preparing` until the preparation completes, errors, or the Test Case-owned preparation timeout expires.

When a Test Case starts and the Preparation already reports `Completed = TRUE`, the owning Test Case or Test Case sequencer skips the active `Preparing` phase and enters the test states directly. This prevents enabling active Preparation behavior when the resource is already in the required target condition.

### External resource ownership and Reset

TCC-078 through TCC-081 distinguish normal functional stimulus from Reset requests. The owning orchestration schedules exclusive resource use across the affected Test Cases. Test Cases do not negotiate ownership with one another, acquire peer locks or maintain a peer ownership registry for that scheduling responsibility. Sequential reuse must not be disturbed by commands left active by an inactive Test Case.

Preparation establishes the start condition within the active Preparation phase. It does not continue driving the external resource after its delegated active execution ends. Stimulus needed by the following test phase belongs to the active Test Case, not to a still-influential inactive Preparation.

Request public DUT Reset according to that interface's edge or level semantics, then monitor the defined idle condition. Repeating the same Reset request does not select a different expected terminal condition. Protecting critical sections within the Reset implementation is the DUT's task. This does not authorize direct writes to DUT status or private instance data.

DUT Idle and DUT Ready are different observations: the agreed Reset target can be Idle while DUT Ready remains FALSE. This does not relax the existing startability and Idle/Ready requirements for Framework Full Owners or the conditions required to execute the next test. Reset handling is not permission to keep a resource under Reset from a stable inactive Test Case after another test has taken control.

### Owner interactions

- Test Case is orchestrated by a containing Test Suite or equivalent higher-level invocation context.
- Test Case owns the interpretation of Preparation status and the supervision of Preparation timeout.
- Test Case `Ready` may include implementation-specific startability conditions such as `PreparationStatus.Ready`.
- Test Case owns aggregation of Assertion results.
- Assertion-generated one-shot failed/error events remain assertion-owned, while higher-level scenario and aggregation events remain Test Case-owned.
- Test Case uses the event structures and classifications defined in `event-stream-model-contract.md` when emitting test-case-level events.
- Generic Test Case sequencers may own lifecycle events, state-transition events, preparation runtime accumulation, and preparation-timeout detection for sequencer-based Test Cases.
- Generic Test Case sequencers do not own concrete Preparation calls, concrete Assertion calls, final aggregation events, or final test-case result events.
- Test Case emits test-case-level events with `UnitTest.OwnerScope.TestCase`, even when a generic Test Case Sequencer technically emits lifecycle events on behalf of the Test Case lifecycle.

### Assertion interface semantics

`State` means the owning Test Case state. Assertions do not expose their own lifecycle state through this parameter.

`Name` means the full hierarchical Assertion event name assigned by the owning Test Case. Assertion blocks use the value for diagnostics and assertion-owned finding events; they do not derive or validate the parent Test Case hierarchy.

Assertion results are stable until explicit reset. `Enable = FALSE` pauses observation and direct evaluation from observation without de-escalating or clearing the current `Result`. It does not suppress a separate explicit `Evaluate` request against accumulated observation state.

While `Reset = TRUE`, the assertion clears resettable internal assertion state, suppresses evaluation, suppresses observation, and suppresses assertion-generated events. If a non-resettable internal assertion error must be reported, that behavior must be explicitly documented by the concrete assertion implementation.

The first enabled call is the first call with `Enable = TRUE` after Reset or after at least one call with `Enable = FALSE`. `ObserveFirstCycle = TRUE` includes that call in observation. `ObserveFirstCycle = FALSE` excludes it; continuously enabled calls after it are observed normally. Reset while enabled clears the previous-enable state, so the next non-Reset enabled call is again a first enabled call.

`ObserveFirstCycle` controls observation eligibility; it does not schedule evaluation. Direct Assertions evaluate from their active observation. An explicit `Evaluate` request remains independent from `Enable` and `ObserveFirstCycle`; Reset priority, configuration validity, and the concrete Assertion family's documented accumulated-state semantics still apply.

Assertions that need a previous enabled sample use the first enabled call to establish their baseline and do not expose `ObserveFirstCycle`. Sequence Assertions include the current input when explicitly evaluated. Edge-count Assertions explicitly evaluate only edges accumulated before the evaluation request. These are intentional family-specific semantics.

Text values rendered into assertion messages are diagnostics only. The preview limit applies to the rendered value in the message, not to the actual checked value.

### Array no-value-change snapshot lifetime

TCC-068 through TCC-071 distinguish the retained array reference from previous-enable history. `AssertArrayNoValueChange_*` uses external `Memory` for the first successfully captured monitored range. Capture leaves `Result = UnitTest.Result.NotEvaluated`; that result alone does not indicate whether a valid snapshot already exists.

A disabled call pauses comparison and restarts the consecutive-enabled-call gate without invalidating the reference. For example, capturing `10`, disabling before the first comparison, changing the input to `20`, and re-enabling preserves the reference `10`. The re-enable call does not compare; the following enabled call reports the change against `10`. Scalar `AssertNoValueChange_*` consecutive-sample behavior is unaffected.

Reset permits a new reference on a later eligible enabled call. Existing physical `Memory` contents are not a valid reference after Reset, even if they have not been overwritten. Range and Memory-capacity validation remain prerequisites for copying; rejected capture does not establish a valid snapshot.

For REAL/LREAL, TCC-063 applies NaN rejection only to the actual initial capture. Once a valid snapshot exists, re-enable is not another initial capture: NaN encountered during an eligible later comparison is a mismatch. Invalid tolerance still follows TCC-060 and TCC-064, including after a held Failed result. Snapshot retention does not clear results or rearm one-shot findings.

### Floating-point Assertion domains

The ordinary scalar REAL/LREAL families covered by TCC-059 are `AssertEqual_*`, `AssertNotEqual_*`, `AssertEqualTolerance_*`, `AssertNotEqualTolerance_*`, `AssertGreaterThan_*`, `AssertGreaterEqual_*`, `AssertLessThan_*`, `AssertLessEqual_*`, `AssertInRange_*`, `AssertNotInRange_*` and `AssertNoValueChange_*`. Finite values include normal values, subnormal values and both zero signs. This domain policy does not define new classification Assertions.

TCC-061 through TCC-063 distinguish invalid expected data or initial snapshot data from a functional mismatch in actual data. These numeric-domain rules are independent of the retained snapshot lifetime defined by TCC-068 through TCC-071. TCC-064 applies to every expected pattern element before a search may accept an early match.

TCC-065 includes maximum-finite versus a small opposite-sign operand: for example, maximum-finite versus `-1` is outside tolerance even when tolerance equals maximum-finite. It does not require an overflowing intermediate to establish that outcome.

TCC-066 and TCC-067 concern rendered diagnostics only. Comparison values and Assertion interfaces remain unchanged.

### Scalar search patterns and array-token counts

TCC-073 distinguishes the searched text from the search pattern. An empty actual `IN` with a nonempty pattern is valid text and yields a non-match. Empty `IN` with an empty pattern is still an empty-pattern error during eligible observation. The ordinary observation gate, first-cycle option, Reset priority and general Assertion result/event rules apply; this validation does not introduce an explicit `Evaluate` input.

TCC-074 counts tokens within the selected region of the current input, not across PLC cycles. Searching `[1,1,1]` for `[1,1]` counts one complete match; searching `[1,1,1,1]` counts two adjacent matches. Input and token arrays have independent declared bounds. WORD matching includes all 16 bits. These array-token Assertions have no mask parameter; masked single-value token checks belong to a separate family.

Existing range/configuration and result/count lifetimes are unchanged. A token longer than the selected range remains an array-token configuration error. A nonempty expected text longer than the searched text range remains a valid text-search non-match. `LengthUntil` missing-token failure, including `NotEqual`, is unaffected.

### Assertion-specific text length constants

| Symbolic constant | Value | Description |
| --- | ---: | --- |
| `UnitTest.TextLength.AssertionValue` | `40` | Max visible chars of one assertion value in event messages. |

### Pre-execution configuration errors

The first published Reset invocation remains available for resetting Test Case-local state and Assertions. Configuration must be valid before the following Reset-state evaluation to reach the normal Idle path. Correcting configuration after a held Idle error does not by itself release the error or permit Start; an explicit Reset establishes the new lifecycle baseline.

An Idle/Error child has no active work to abort. Recognizing that fact for parent abort acknowledgement does not mark the child Completed and does not manufacture final child Result or Aggregation evidence. Active children and other Error states are not covered by this exception.

## Compatibility

The public Assertion input `EvaluateFirstCycle` is renamed to `ObserveFirstCycle` without a compatibility alias. Assertion interfaces and named call bindings must migrate together.

This contract defines the producer-side Test Case, Preparation, and Assertion interaction structures only.

## Non-Requirements

This contract does not define:

- project-specific resource model,
- concrete assertion prototypes,
- event transport details,
- event structure or communication classifications.
