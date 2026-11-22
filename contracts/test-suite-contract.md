# Test Suite Contract

## Purpose

This contract defines the PLC-side producer contract for Test Suite control and configuration.

## Scope

This contract defines:

- `UDT_UnitTestSuiteControl`,
- `UDT_UnitTestSuiteConfig`,
- suite-local naming rules.

This contract references:

- `general-framework-contract.md` for shared execution/result semantics and shared type rules,
- `event-stream-model-contract.md` for event-entry structure, event classifications, and event-stream rules.

## Version

- Contract version: `1.0.0`

## Requirements

- `TSC-001` `UDT_UnitTestSuiteControl` MUST use the top-level structure `Name`, `Cmd`, and `Status`.
- `TSC-002` `Name` MUST be a stable instance property and MUST NOT be modeled inside `Status`.
- `TSC-003` Test Suite top-level field references MUST follow Table A.
- `TSC-004` Shared framework command fields MUST follow Table B.
- `TSC-005` Suite-status fields MUST follow Table C.
- `TSC-006` Test Suite configuration fields MUST follow Table D.
- `TSC-007` `Name` MUST be configured in `UDT_UnitTestSuiteConfig` by the owning Run Control implementation and published by the Test Suite into `UDT_UnitTestSuiteControl`.
- `TSC-008` Command triggers MUST be interpreted by positive edge.
- `TSC-009` Command triggers SHOULD normally be reset again at the end of the same internal cycle.
- `TSC-010` Timeout deactivation MUST NOT be allowed. Zero and negative timeout values MUST be treated as invalid.
- `TSC-011` Test Suite finalization MUST use `UnitTest.State.Completing` for final Suite result and Test Case aggregation publication before the Suite enters `UnitTest.State.Completed`.
- `TSC-012` Test Suite MUST emit exactly one final Suite Result event for each controllable Suite lifecycle from `Idle` to `Completed`.
- `TSC-013` Test Suite MUST emit exactly one final Suite Aggregation event for each controllable Suite lifecycle from `Idle` to `Completed`.
- `TSC-014` Test Suite MUST emit its final Result and Aggregation events while in `UnitTest.State.Completing` and before the final state-transition event into `UnitTest.State.Completed`.
- `TSC-015` Test Suite `Name` MUST be the full hierarchical Suite name `<runControlName>.<suiteName>` defined by `event-stream-model-contract.md`.
- `TSC-016` The owning Run Control implementation MUST configure each Suite with a valid full hierarchical Suite name.
- `TSC-017` A Test Suite MUST configure contained Test Cases with full hierarchical names below its own Suite name.
- `TSC-018` A Test Suite implementation MAY use the generic Suite Sequencer and Test Case Orchestrators or MAY implement the required lifecycle and child-execution behavior directly.
- `TSC-019` Regardless of the selected implementation pattern, the Test Suite implementation MUST provide the same command handling, lifecycle signals, status, result, aggregation, timeout handling, and owner-level event semantics defined by this contract.
- `TSC-020` If subordinate Test Case abort handling does not finish within `AbortTimeout`, the Test Suite MUST emit a framework diagnostic event and complete its lifecycle with `UnitTest.Result.Error`.
- `TSC-021` If subordinate Test Case reset handling does not finish within `ResetTimeout`, the Test Suite MUST emit a framework diagnostic event and complete its lifecycle with `UnitTest.Result.Error`.
- `TSC-022` Test Case Orchestrator events MUST NOT be emitted or interpreted as Test Suite lifecycle, Result, or Aggregation evidence.
- `TSC-023` Test Suite reset handling MUST bound subordinate Test Case reset dispatch against the available event-buffer capacity so that the expected reset events fit while the required producer headroom remains available.
- `TSC-024` Framework-provided Test Case Orchestrators MUST use capacity-bounded reset batches and MUST wait for sufficient event-buffer capacity before starting additional required Test Case resets.
- `TSC-025` A subordinate Test Case in `UnitTest.State.Idle` with `Status.Execution.Ready = TRUE` MAY be treated as reset-complete without receiving another reset command.
- `TSC-026` Test Suite `ResetTimeout` monitoring MUST cover the complete reset operation, including time spent waiting for event-buffer capacity and subordinate Test Case completion.
- `TSC-027` A project-specific Test Suite implementation that does not use a framework Test Case Orchestrator MUST provide equivalent capacity-bounded reset dispatch and completion behavior.
- `TSC-028` Framework-provided Test Case Orchestrators MUST gate normal Test Case Start dispatch according to the normal-execution capacity model defined in this contract.
- `TSC-029` One Test Case Orchestrator instance MUST start at most one subordinate Test Case in one PLC cycle.
- `TSC-030` Serial, parallel, and slot-based Test Case Orchestrators MUST preserve the candidate-selection semantics defined under Normal execution capacity responsibility.
- `TSC-031` Temporarily insufficient event-buffer capacity MUST delay Test Case dispatch without producing a cyclic event or a configuration error.
- `TSC-032` Capacity-waiting time after an accepted Suite Start MUST remain part of the active Test Suite and Test Case Orchestrator runtime.
- `TSC-033` Invalid Test Case lifecycle-capacity metadata, arithmetic overflow during budget calculation, or an individual Test Case budget that cannot fit with the configured execution headroom MUST be treated as a Test Case orchestration configuration error.
- `TSC-034` Framework-provided Test Case Orchestrators MUST reserve each accepted Test Case event budget in the producer-owned global event-buffer reservation count before issuing the corresponding Test Case Start command.
- `TSC-035` Global Test Case event-buffer reservations MUST prevent concurrently active Test Case Orchestrators from allocating the same event-buffer capacity.
- `TSC-036` A project-specific Test Suite implementation that does not use a framework Test Case Orchestrator MUST provide equivalent normal-execution reservation and capacity-gating behavior when it claims the capacity guarantee defined by this contract.
- `TSC-037` A Test Case Orchestrator MUST retain its local reservation contribution and MUST reconcile it with the producer-owned global reservation count.
- `TSC-038` A Test Case Start reservation MUST remain pending until the subordinate Test Case has left `UnitTest.State.Idle` or has reached `UnitTest.State.Completed` when the Orchestrator is called again.
- `TSC-039` If a subordinate Test Case remains in `UnitTest.State.Idle` on that following Orchestrator call, the Orchestrator MUST release the pending reservation, emit a Framework diagnostic event, and enter its error handling path.
- `TSC-040` An accepted Test Case execution reservation MUST be retained through active execution, Abort, and finalization until the subordinate Test Case reaches `UnitTest.State.Completed`.
- `TSC-041` Parent Reset MUST replace execution reservations with the reservations required for subordinate Reset processing; each Reset reservation MUST be released when the corresponding subordinate Test Case reaches `UnitTest.State.Idle` with `Status.Execution.Ready = TRUE`.
- `TSC-042` A successfully completed Run Control Reset MUST leave no Test Case execution or Reset reservation in the producer-owned global event-buffer reservation count.
- `TSC-043` `UnitTest.EventBuffer.ExecutionHeadroom` MUST remain outside Test Case reservations as shared producer capacity for Run Control, Test Suite, Orchestrator, and exceptional Framework events.
- `TSC-044` The shared execution headroom MUST NOT be interpreted as a per-owner reservation or as a guarantee for an unbounded number of simultaneously produced non-TestCase events.
- `TSC-045` Regular Test Suite transition from `Running` to `Completing` MUST require completed subordinate execution and a completed Test Case Orchestrator when one is used. When the generic Sequencer and Orchestrator are composed, the Sequencer MUST consume `OrchestratorState` and `OrchestratorResult` retained from the same preceding Orchestrator call; `OrchestratorState` MUST equal `UnitTest.State.Completed` for regular completion. Raw subordinate lifecycle signals supplied to the Orchestrator MUST remain independent of its own completion.
- `TSC-046` A Test Case Orchestrator's final result MUST describe technical execution. Functional `Failed` results of subordinate Test Cases MUST be aggregated by the Test Suite, not converted into a technical Orchestrator `Failed` result. Genuine technical errors MUST retain controlled error handling.
- `TSC-047` The Test Suite MUST settle its final result before emitting final Result and Aggregation events and MUST retain that result throughout `Completing` and `Completed` until Reset. Subsequent helper/status observations MUST NOT rewrite the published result.
- `TSC-048` Reset, explicit Abort, controlled error termination and timeout exits MUST retain their respective completion conditions; the regular child-and-Orchestrator completion gate MUST NOT be imposed on these paths. Untouched Idle/Ready Test Cases MUST NOT have to execute merely to complete controlled error termination.

## Requirement Details

### Test Case orchestration array bounds

Test Case orchestration arrays MUST have matching declared bounds within the inclusive index range `1..32767`; a lower bound greater than `1` is permitted. Configuration and control arrays, and the execution-slot array when used, MUST have identical lower and upper bounds. The shared configuration validation MUST inspect the original `DInt` bounds before narrowing them or using them for dispatch. Index `0` remains reserved for "no candidate". This orchestration limit does not restrict Assertion input arrays.

### Table A: Test Suite top-level fields

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

### Table C: Suite-status fields

| Field | Type | Default |
| --- | --- | --- |
| `Execution` | `UDT_UnitTestExecutionStatus` | field defaults of nested UDT |
| `TestCaseCountTotal` | `UINT` | `0` |
| `TestCaseCountInactive` | `UINT` | `0` |
| `TestCaseCountIdle` | `UINT` | `0` |
| `TestCaseCountRunning` | `UINT` | `0` |
| `TestCaseCountCompleted` | `UINT` | `0` |
| `TestCaseCountPassed` | `UINT` | `0` |
| `TestCaseCountFailed` | `UINT` | `0` |
| `TestCaseCountError` | `UINT` | `0` |
| `Runtime` | `DINT` | `0` |

### Table D: Test Suite configuration fields

| Field | Type | Default |
| --- | --- | --- |
| `Name` | `STRING[UnitTest.TextLength.Name]` | `''` |
| `Timeout` | `DINT` | `10000` |
| `ResetTimeout` | `DINT` | `1000` |
| `AbortTimeout` | `DINT` | `1000` |

### Naming

The Test Suite `Name` is not a local display label. It is the full hierarchical Suite name used in status data and event entries:

```text
<runControlName>.<suiteName>
```

The owning Run Control configures this value. The Suite publishes the same value into its control data and uses it as the parent path for Test Case names. Test Case names configured by the Suite follow:

```text
<runControlName>.<suiteName>.<testCaseName>
```

Local Suite and Test Case name segments must follow the hierarchy and character rules from `event-stream-model-contract.md`. Invalid Suite names are Suite configuration errors. Invalid Test Case names are detected by the owning Test Case and propagate upward through Test Case readiness and result handling.

### Owner interactions

- Test Suite is orchestrated by the owning Run Control path or by a higher-level explicit suite invocation context.
- Test Suite is the semantic owner of its lifecycle, command handling, lifecycle signals, result, aggregation, and owner-level events.
- Test Suite owns execution control of contained Test Cases.
- Test Suite aggregates test-case-level execution and result information into its own status structure.
- Test Suite does not own assertion logic.
- Test Suite uses the event structures and classifications defined in `event-stream-model-contract.md` when emitting suite-level events.
- Test Suite emits suite-level lifecycle, Result, and Aggregation evidence with `UnitTest.OwnerScope.TestSuite` and its full hierarchical Suite name.
- The generic `UnitTestSuiteSequencer` can provide the Suite lifecycle state machine, command processing, runtime handling, lifecycle signals, timeout monitoring, and Suite owner state-transition events.
- The generic `UnitTestCaseOrchestrator_*` blocks can provide serial, parallel, or slot-based execution orchestration of contained Test Cases.
- Use of the generic Sequencer and Orchestrators is optional. A project-specific implementation that does not use them is responsible for implementing the same contract behavior directly.
- Test Case Orchestrators are technical helpers below Test Suite, not independent reportable UnitTest owner levels and not owners of the Suite lifecycle.
- Test Case Orchestrators may emit technical orchestration state-transition diagnostics with `UnitTest.OwnerScope.TestCaseOrchestrator`. These diagnostics describe the Test Case Orchestrator state machine and must not be interpreted as Test Suite lifecycle completion, Test Suite Result, or Test Suite Aggregation evidence.

### Reset capacity responsibility

Test Suite owns capacity-safe dispatch of subordinate Test Case resets. Capacity waiting is part of the active Suite reset operation; it does not suspend or restart reset timeout monitoring.

The framework Test Case Orchestrators satisfy this responsibility by starting only the number of concurrent Test Case resets for which event-buffer capacity is currently available. Direct implementations may use another scheduling algorithm, but they must preserve the same capacity and completion guarantees.

### Normal execution capacity responsibility

The framework Test Case Orchestrators estimate one complete Test Case event budget as:

```text
TestCaseEventBudget =
    PreparationStateCount
  + TestStateCount
  + AssertionCountTotal
  + 9
```

The fixed value consists of six normal fixed owner events outside the counted Preparation/Test state entries, one Abort trigger allowance, one additional transition into the abort path, and one exceptional Framework event. The six normal fixed events are the Start trigger, the three fixed lifecycle transitions outside the counted Preparation/Test entries, the final Result event, and the final Aggregation event. One finding event is budgeted per Assertion. A possible later escalation from a Failed finding to an Error finding is not budgeted for every Assertion.

Before starting one candidate, an Orchestrator atomically increases its contribution to the producer-owned global reservation count by the complete candidate budget. The increase is accepted only when:

```text
PhysicalFreeEntries >=
    GlobalReservedEntryCount
  + candidate TestCase event budget
  + UnitTest.EventBuffer.ExecutionHeadroom
```

`UnitTest.EventBuffer.ExecutionHeadroom` is a global project constant with the framework default `10`. It is independent of consumer polling, draining, and batch settings. It remains unreserved shared producer capacity for Run Control, Test Suite, Orchestrator, and exceptional Framework events. It is not a separate reservation for every active owner and does not guarantee capacity for an unbounded number of simultaneous non-TestCase events.

The producer maintains one global reservation count across all Test Case Orchestrators. Each Orchestrator owns one local aggregate contribution and may start at most one Test Case per PLC cycle. It reserves the complete candidate budget before issuing `Cmd.Start`. On the following Orchestrator call, the subordinate Test Case must have left `Idle` or already reached `Completed`; otherwise the reservation is rolled back and the failed Start reaction is handled as a Framework error. The complete original budget remains reserved until the Test Case reaches `Completed`. This is intentionally conservative because already emitted events do not reduce an active Test Case reservation.

Candidate selection preserves the established Orchestrator meanings:

- `Serial` considers the next Test Case in ascending array order and does not move a later Test Case ahead when the next candidate is waiting for capacity.
- `Parallel` scans not-yet-started Test Cases in ascending array order and starts the first candidate whose budget currently fits.
- `ParallelSlots` applies the same first-fitting behavior within the current slot and advances only after all Test Cases in that slot are `Completed`.

A valid Suite Start is accepted once even when no Test Case currently fits. The Orchestrator leaves `Idle`, measures active runtime, and waits without requiring another Start command. Abort prevents further dispatch and retains reservations for already accepted Test Cases through their completion.

Parent Reset replaces execution reservations with the capacity required by the subordinate Reset operation. Reset reservations are released as children reach `Idle AND Ready`. A successfully completed hierarchical Run Control Reset therefore leaves the global reservation count at `0`. A failed Reset does not silently discard reservations for children that did not return to the executable initial state.

The global reservation count combines the contributions of Test Case Orchestrators from concurrently active Test Suites. Sequential PLC invocation therefore cannot cause multiple Orchestrators to allocate the same physical event-buffer capacity.

## Compatibility

This contract defines the producer-side Test Suite data structures and lifecycle/orchestration responsibilities.

## Non-Requirements

This contract does not define:

- concrete reset-capacity reservation formulas,
- project-specific grouping policy,
- communication transport details,
- event structure or communication classifications.
