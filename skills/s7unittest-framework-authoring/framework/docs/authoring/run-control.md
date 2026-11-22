# Run Control Authoring

Run Control is the project-specific top-level execution block for one PLC-side unit test run. It owns the public run command/status data, binds the concrete Test Suites of the library project, and delegates reusable lifecycle and Suite orchestration behavior to framework blocks.

The preferred implementation pattern is:

- use `UnitTestRunControlSequencer` for the generic Run Control lifecycle,
- use one Suite Orchestrator for Suite execution,
- keep concrete Suite configuration and Suite calls explicit in the Run Control implementation,
- update the Run Control status view after subordinate Suite calls.

## Run Control Responsibility

Run Control translates external run commands into Suite-level execution. It is responsible for:

- configuring the registered Suites,
- calling the selected Suite Orchestrator,
- calling each concrete Test Suite once per cycle,
- aggregating Suite status into the run-level status view,
- emitting or delegating run-level lifecycle, result, aggregation, and diagnostic events according to the framework lifecycle contract.

Run Control is not responsible for Suite-internal Test Case behavior, Preparation behavior, or Assertion checks.

## Composition

A Run Control implementation should keep the generic flow and the project-specific binding visibly separated:

```scl
REGION Default values
	// Initialize temporary values used by Run Control.
END_REGION

REGION Configuration
	// Assign run and Suite configuration.
END_REGION

REGION Lifecycle signals
	// Derive current subordinate readiness/completion signals.
END_REGION

REGION Sequencer
	// Call UnitTestRunControlSequencer.
END_REGION

REGION Suite orchestrator
	// Call the selected Suite Orchestrator.
END_REGION

REGION Suite calls
	// Call each registered Test Suite exactly once per cycle.
END_REGION

REGION Result handling
	// Create the run result from lifecycle state, generic helper results, and Suite results.
END_REGION

REGION Status
	// Publish the Run Control status view after Suite calls.
END_REGION
```

The Sequencer owns the generic Run Control lifecycle. The Suite Orchestrator owns the generic execution model for the registered Suites. The Run Control implementation owns the concrete Suite binding around those blocks.

Pass the public command storage directly to the Run Control Sequencer through its `CmdData` in-out parameter. The Sequencer owns command consumption and acknowledgement. Do not clear `ControlData.Cmd.Start`, `Abort` or `Reset` again in the enclosing Run Control: doing so can erase a pending request before the Sequencer has accepted it. A startup Reset written once by the application must remain pending until the Sequencer consumes it.

Retain the Suite Orchestrator state and technical result in initialized persistent variables, starting with `UnitTest.State.Uninitialized` and `UnitTest.Result.NotEvaluated`. Pass them to the Sequencer's `OrchestratorState` and `OrchestratorResult` inputs. The Sequencer is called before the Suite Orchestrator and therefore consumes the paired outputs from the preceding Orchestrator call. The later Orchestrator call refreshes those same variables for the next PLC cycle. Do not declare this handover as `VAR_TEMP` and do not add parallel shadow values.

`AreTestSuitesCompleted(...)` supplies the raw child-completion snapshot. Regular completion additionally requires the retained `OrchestratorState = UnitTest.State.Completed`. Do not fold that extra gate into the shared `LifecycleSignals.Completed`: the Orchestrator must still receive the independent child snapshot. A Suite Orchestrator `Error`, technical `Failed`, or unexpected `Abort` is reported through the retained result and causes controlled error finalization without treating idle, not-started Suites as completed. Reset, explicit Abort, error termination and timeout exits keep their own completion conditions.

Successful Suite orchestration reports a technical `Passed` even when a child Suite has a functional `Failed` result. Run Control aggregates functional child results. On first entry to `Completing`, create the final result after subordinate calls and publish status before the final Result/Aggregation events. During subsequent `Completing` calls and in `Completed`, retain that published result until Reset rather than recomputing it from later helper observations. Keep the configured `CompletionDelay` and normal status/diagnostic processing.

Run Control lifecycle completion, final Result, and final Aggregation evidence remain Run Control events. Suite Orchestrators may emit their own technical state-transition diagnostics with `UnitTest.OwnerScope.TestSuiteOrchestrator`; these diagnostics help debug the Suite orchestration state machine and do not replace Run Control lifecycle evidence.

Keep the Run Control implementation focused on binding and wiring:

- configure the run and registered Suites,
- derive lifecycle signals for the generic blocks,
- call the Sequencer and selected Suite Orchestrator,
- call each concrete Suite,
- create the Run Control result and status view after subordinate calls.

## Recommended Generic Helpers

Use `UnitTestRunControlSequencer` unless the Run Control lifecycle itself must behave differently from the framework lifecycle. The Sequencer handles the generic Run Control state machine, command priority, lifecycle events, runtime handling, configuration-error reaction, and controlled finalization.

Use one Suite Orchestrator for the registered Suite execution model. The Orchestrator decides when Suites receive start, abort, and reset commands, observes Suite readiness and completion, monitors Suite runtime, and reports generic orchestration errors back to Run Control.

The Run Control block remains responsible for:

- assigning Run Control and Suite configuration,
- deriving lifecycle signals for the Sequencer and Orchestrator,
- declaring and calling the concrete Suite instances,
- combining Sequencer, Orchestrator, and Suite results into the Run Control result,
- publishing the Run Control status view after the Suite calls.

Do not reimplement Suite start/abort/reset propagation, Suite timeout monitoring, or Suite orchestration events next to the Orchestrator. If that logic is needed in project code, the implementation is no longer using the standard execution model and should be treated as a custom Run Control.

## Suite Registration

Registered Suites must be consistent across:

- `ConfigData.SuiteCount`,
- Suite configuration data,
- Suite control data,
- concrete Suite instance bindings, whether separately instantiated or declared locally,
- concrete Suite calls.

The shared Suite arrays are sized by `UnitTest.SuiteArray.Length`. `ConfigData.SuiteCount` is the number of registered Suite instances that shall be processed in the current project implementation. Slots above `SuiteCount` are array capacity, not registered Suites.

For every registered Suite index, the implementation needs one configured Suite, one control-data entry, and one concrete Suite call:

```scl
#ControlData.Name := 'UnitTest';

"DB_UnitTestSuiteConfig".Data[1].Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'UnitTestSuite_Example');
"DB_UnitTestSuiteConfig".Data[1].Timeout := 1000;

#Suite_1(
	ConfigData := "DB_UnitTestSuiteConfig".Data[1],
	ControlData := "DB_UnitTestSuiteControl".Data[1]
);
```

Suite names are full hierarchical names. Generate them from the Run Control name and one local Suite segment. Do not use spaces or dots in the local Suite segment:

```scl
"DB_UnitTestSuiteConfig".Data[1].Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'Suite_Assertions');
```

This makes Suite events appear below the Run Control in the PC-side event log.

Do not hide project-specific Suite binding behind a generic loop unless the Suite instances and their configuration are actually generic.

## Suite Orchestrators

The framework provides three Suite Orchestrators for Run Control implementations.

### `UnitTestSuiteOrchestrator_Serial`

Starts one Suite at a time and waits until the active Suite has completed before the next Suite is started.

Use it when Suite execution must be deterministic and exclusive, or when Suites may share resources.

### `UnitTestSuiteOrchestrator_Parallel`

Starts all registered Suites together and completes when all registered Suites have completed or an abort/error path ends execution.

Use it only when all registered Suites and their Test Cases can safely run in parallel.

### `UnitTestSuiteOrchestrator_ParallelSlots`

Runs Suites in configured execution slots. Suites in the same slot can run in parallel; the next slot starts after the current slot has completed.

Use it when some Suites can run in parallel but others must be separated by execution order or resource ownership.

The slot assignment is Run-Control-local execution configuration:

```scl
#SuiteExecutionSlot[1] := 1;
#SuiteExecutionSlot[2] := 1;
#SuiteExecutionSlot[3] := 2;
```

All registered Suites must have a valid slot assignment.

### Reset Scheduling

All three Suite Orchestrators reset Suites sequentially, independent of their normal serial, parallel, or slot-based execution model. Before starting a required Suite reset, the Orchestrator checks the available event-buffer capacity through `GetEventBufferFreeEntries`.

The framework keeps the configured `UnitTest.EventBuffer.ResetHeadroom` of `20` entries free and reserves another `4` entries for the Suite reset being started. A Suite already in `UnitTest.State.Idle` with `Status.Execution.Ready = TRUE` is skipped because it is already in the required startable base state.

Capacity waiting remains part of Run Control reset handling and therefore counts toward `ResetTimeout`. If a custom Run Control does not use a Suite Orchestrator, it must provide equivalent bounded reset dispatch instead of resetting every Suite unconditionally in one cycle.

## Lifecycle

Run Control uses the shared full-owner lifecycle states.

`UnitTest.State.Uninitialized` is the passive initial state before an explicit reset has established a defined base state. It is not an error and does not emit lifecycle or framework events.

`UnitTest.State.Reset` clears the current run state and propagates reset to the registered Suites.

`UnitTest.State.Idle` is the startable base state. `Ready = TRUE` requires both the idle state and subordinate readiness.

`UnitTest.State.Running` represents active Suite orchestration.

`UnitTest.State.Completing` is the finalization state. Run-level result and aggregation events are emitted before Run Control enters `Completed`.

`UnitTest.State.Completed` is the only stable final state. Leaving it requires an explicit reset.

`UnitTest.State.Aborting` represents explicit external abort handling and leads to `UnitTest.Result.Abort`.

`UnitTest.State.AbortingFromError` represents controlled termination after an internal, subordinate, timeout, readiness, configuration, or framework error and leads to `UnitTest.Result.Error`.

Unhandled state values are framework errors. They are not `Uninitialized`; they must be completed through the controlled error finalization path.

## Startup Initialization

The PLC-side UnitTest application owns startup initialization. After PLC startup, download, or restart, Run Control must reach a reset-defined base state through PLC-side reset handling before normal start processing is expected.

An external runner may still request reset explicitly, but a CI-triggered run must not depend on the external runner issuing the first reset only to make the PLC startup state valid.

The Run Control implementation may use first-scan reset handling or an equivalent PLC-side initialization path. It must not implicitly start a UnitTest run during startup initialization.

The application must also provide the concrete configuration and cyclic call of its Run Control instance. `ConfigureUnitTests` and `ExecuteUnitTests` are optional project-adapted integration examples, not mandatory framework helpers or prescribed block names. The delivered `ExecuteUnitTests` has its concrete Run Control call commented out; bind that call explicitly if reusing it. Configuration, startup initialization and execution may instead be placed directly in the application entry or another project-owned adapter. Establish the actual cycle-time and startup signals from the consuming project's context rather than assuming an example supplies a complete application.

Run Control also owns event-buffer request processing. Call `ProcessUnitTestEventBufferRequests` early in the Run Control cycle, before the current run logic produces new events. The utility processes consumer requests to release acknowledged entries or reset the complete event buffer.

Use the framework's existing `InitializeUnitTestEventBuffer` startup utility and `ProcessUnitTestEventBufferRequests` integration point; do not call low-level FIFO push/pop helpers from normal Run Control authoring. The EventBuffer uses a framework-owned, typed FIFO in `03_Handling` and does not require the generic FIFO from `02_CommonUnit`. That generic FIFO can remain in the project for unrelated uses. Physical EventBuffer length and usable capacity differ by one entry; let the semantic framework utilities handle capacity accounting.

Use the parameterless `IsEventBufferValid()` Logging function for the Run Control's EventBuffer validity guard. `NOT IsEventBufferValid()` is equivalent to `FifoControl.ConfigError OR FifoControl.IndexError`; it preserves the error condition without making Run Control address the EventBuffer DB directly. The function checks these validity flags, not available capacity.

`BufferCmd.Reset` is not the Run Control lifecycle command `Cmd.Reset`. It discards the current event-buffer epoch, including buffered and not-yet-released events, and resets the event-buffer handover status. A consumer observes completion when the PLC has cleared `BufferCmd.Reset` back to `FALSE`. Use this destructive request only when the current buffered event log is intentionally discarded, for example before beginning a fresh monitoring session after stale buffer contents were detected.

## Optional PLC-Only Diagnostic Consumption

`UnitTestEventBufferDiagConsumer` is an optional FB for allowing PLC-only tests to progress when no PC application drains the EventBuffer. Its implementation is present in the PLC sources. The following guidance describes its explicit opt-in integration.

### Explicit Integration

Declare a dedicated instance only in a project that deliberately wants diagnostic consumption. Call it after Run Control on the same cyclic task. Keep both calls cyclic during startup Reset, normal execution, and post-completion draining; gating the consumer call on a running test would leave startup or finalization events undrained. Run Control continues processing buffer requests even when no test is running.

Do not add a default instance, instance DB, or call to the framework, normal Run Control examples, or the default application entry point. Merely installing the library performs no consumption. A permanently installed instance with `Enable := FALSE` is not a substitute for this structural opt-in.

Use this consumer instead of, not alongside, a PC consumer. It neither detects PC absence nor arbitrates ownership or takes over automatically.

### Consumption And Diagnostics

The agreed inputs are `Enable` (default `FALSE`), `CycleTime`, `MaxEventsPerCall` (default `32`), `ConsumeInterval` (default `10` ms), and `ResetDiagnostics`. Both timing inputs use the framework's `DInt` millisecond convention.

The first enabled call processes a batch immediately. Later batches follow the configured interval; interval `0` permits a batch on every enabled call. Each batch is bounded by `MaxEventsPerCall` and the available readable entries. There are no catch-up bursts to compensate for missed intervals. Choose batch size and interval to provide adequate drain throughput for the test configuration without excessive cyclic work; the defaults are not a throughput guarantee for every project.

The consumer reads events in FIFO order and sets `BufferCmd.DeleteSequenceId` to the last consumed entry. Run Control processes that watermark on its next call through `ProcessUnitTestEventBufferRequests`. Do not move or duplicate that service call into the consumer. The consumer does not clear records or modify FIFO indexes, status, reservations, or test results.

For pending watermarks and EventBuffer resets: do not lower a pending watermark, acknowledge unread entries, or reuse assumptions from a previous buffer epoch. Reading entries and requesting release is not a second deletion-confirmation state machine.

The diagnostic outputs are `ConsumedEventCount`, `LastBatchEventCount`, `PeakPendingEventCount`, and `HasError`. Event counts refer to entries actually consumed, not differences between sequence IDs or confirmed producer deletions. Disabling retains diagnostic values and stops consumption; Run Control may still process an already submitted watermark. Re-enabling starts with an immediate batch. `ResetDiagnostics` clears diagnostic observations only, not buffer data, commands, or scheduling. These observations are not a test verdict or a complete event archive.

### Returning To PC Evaluation

Diagnostic consumption deliberately destroys event evidence. An empty buffer afterwards does not make the preceding run complete or evaluable by the PC application.

1. Finish or abort the PLC-only run and allow its lifecycle to settle. Keep Run Control and the diagnostic consumer cyclic while draining remaining events.
2. Disable or remove the diagnostic consumer integration before enabling PC consumption. Do not overlap the two consumers, even briefly.
3. With no active UnitTest execution, establish a fresh PC monitoring context and reset the EventBuffer through the regular `BufferCmd.Reset` request. Keep Run Control cyclic and wait until it clears the request. This also discards any outstanding watermark and starts a new event-buffer epoch; do not reset FIFO data manually.
4. With PC observation active and diagnostic consumption inactive, perform the normal Run Control lifecycle Reset, wait for readiness, and execute a new complete run. Only this newly observed run can provide complete PC-side evidence.

The EventBuffer reset and Run Control lifecycle Reset are distinct operations. Neither reconnecting the PC nor merely disabling the diagnostic consumer reconstructs discarded events. No PC-facing DB names, layouts, or contract versions change for this optional utility.

## Commands And Trigger Propagation

Run Control receives `Start`, `Abort`, and `Reset` through its control data.

Reset has priority. It returns Run Control and the registered Suites to a defined base state.

Abort prevents new starts and requests controlled termination of active subordinate execution.

Start is only valid when Run Control is ready and the subordinate Suite execution model reports that required Suites are ready.

When a Suite Orchestrator is used, Suite-level start, abort, and reset propagation belongs to that Orchestrator. The Run Control implementation must not duplicate the same trigger logic around it.

## Status Publication

Run Control publishes its status view after the Suite calls have updated their own status. This status view is used for PLC-side orchestration, TIA/HMI diagnostics, and parent-level visibility in the framework.

The PC-side unit test log is driven by the event stream, not by reconstructing final results from status DB snapshots.

Use `UpdateUnitTestRunControlStatusView` instead of writing the run status field by field.

## Events

Lifecycle events are emitted by the component that owns the lifecycle state machine. With the recommended pattern, this is the Run Control Sequencer.

Finalization events are emitted before the final transition to `Completed`. The Run Control result event is emitted first, the Run Control aggregation event afterwards, and the transition event into `Completed` is the final lifecycle event of the run.

Run-level aggregation describes how Suite results contributed to the run result. It is a Run Control responsibility and must not be duplicated by Suite Orchestrators or project-specific Suite code.

Framework diagnostic events explain configuration errors, readiness violations, timeouts, subordinate errors, and unhandled states. They provide diagnostic context but do not replace result and aggregation events.

Generic Sequencer and Suite Orchestrator results are interpreted by Run Control. A helper-reported `Error` escalates to the run result. A helper-reported `Abort` is only valid as confirmation of a Run Control abort path that was already selected from an explicit abort command; otherwise it is a framework error.

Suite Orchestrator state-transition diagnostics use the Orchestrator scope. They should not be used by project code or a client as the completion anchor for a UnitTest run; the Run Control `StateTransition` into `UnitTest.State.Completed` remains that anchor.

## Example Implementations

The framework contains `UnitTestRunControl_Example_Serial` as an authoring reference. It shows a Run Control implementation that binds concrete Suites to the serial Suite Orchestrator.

Additional Suite Orchestrator variants can be used in the same structure when the project needs fully parallel or slot-based parallel Suite execution.

## Validation

Before using a Run Control implementation in a project, check that:

- `ConfigData.SuiteCount` matches the registered Suite instances and calls.
- Each registered Suite has explicit configuration.
- Each registered Suite index has exactly one concrete Suite call.
- The selected Suite Orchestrator matches the intended Suite execution model.
- Slot configuration is complete when slot-based parallel execution is used.
- Run Control does not duplicate Sequencer or Orchestrator lifecycle, monitoring, trigger, or event logic.
- The Suite Orchestrator result is persistent, initialized with `UnitTest.Result.NotEvaluated`, passed to the Sequencer before the Orchestrator call, and refreshed by that Orchestrator call for the next cycle.
- Run Control status is published after subordinate Suite calls.
- Diagnostic views are not treated as the PC-facing result contract.
