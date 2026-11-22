# Framework Model

The PLC-side unit test framework is organized as a hierarchy of reusable framework blocks and project-specific test blocks. Library projects use this structure to bind their own Test Suites, Test Cases, Preparations, and Assertions into the common execution flow.

## Framework Authoring Model

A library project provides one entry path into the unit test framework, binds concrete Test Suites in its Run Control implementation, and implements project-specific Test Suites and Test Cases below that Run Control.

The generic framework blocks provide the common execution, lifecycle, event, and aggregation behavior. Project-specific blocks provide the concrete test intent, resource binding, and checks.

As an author, start with the framework-provided Sequencers and Orchestrators. They are the recommended implementation path for normal Run Control, Test Suite, and Test Case lifecycle handling. Add project-specific code only where a concrete project binding or test intent is needed.

## Framework Structure

The framework is organized in execution levels. Each level owns the execution of the level below it and publishes its own status view.

| Level | Function within the framework |
| --- | --- |
| Run Control | Owns one complete unit test run and connects the external run command interface to Suite-level execution. |
| Test Suite | Groups related Test Cases and controls their execution as one Suite-level result. |
| Test Case | Executes one concrete test scenario and produces the result that is aggregated by the owning Test Suite. |
| Preparation | Brings a resource into the required start condition for a Test Case before active test execution. |
| Assertion | Evaluates one concrete condition and contributes its result to the owning Test Case. |

Each level owns the execution of the level below it. This ownership includes starting, aborting, resetting, timeout monitoring where applicable, and aggregating the subordinate result.

In practice, this means:

| You usually author | The framework usually provides |
| --- | --- |
| concrete Run Control Suite binding | Run Control lifecycle Sequencer and Suite Orchestrators |
| concrete Test Suite Test Case binding | Test Case Orchestrators and Suite status/result helpers |
| concrete Test Case behavior | Test Case Sequencers, Preparation integration, Assertion interfaces |
| resource-specific Preparation logic | Preparation status interpretation by the Test Case |
| Assertion selection and wiring | reusable Assertion blocks and result semantics |

### Run Control

Run Control is the top-level owner of one complete unit test run. It receives the external run commands, binds the concrete Test Suites of the library project, monitors the overall run, and publishes the run-level status.

Application projects should use the framework-provided Run Control Sequencer for the generic lifecycle and one Suite Orchestrator for the Suite execution model.

The framework provides the Run Control lifecycle helper, run-level timeout handling, Suite orchestration helpers, result aggregation, and the public run status view. A library project configures the run, binds concrete Suites, and exposes the intended entry point.

Run Control is also the boundary where an external runner observes whether the PLC-side unit test run is ready, running, completed, aborted, or failed. The lower framework levels provide the detailed diagnostic information that explains how that run-level result was produced.

### Test Suite

A Test Suite groups related Test Cases. It translates Suite-level execution into Test Case-level execution.

Test Suites should use a generic Test Case Orchestrator when the desired Test Case execution model matches an available orchestrator.

The framework provides Suite status handling, Test Case command helpers, and reusable Test Case orchestration patterns. The project-specific part is the grouping of Test Cases that belong together from a test intent perspective.

A Test Suite owns the execution of its Test Cases. It starts them, observes their completion, handles abort and reset propagation, and aggregates their results into one Suite-level result.

Test Suites are not intended to be reused in the same way as Test Cases. They are usually specific to one library project or one test grouping inside that project.

### Test Case

A Test Case owns the actual test behavior. It prepares resources when needed, applies stimuli, evaluates Assertions, and publishes the Test Case result.

Test Cases should use a Sequencer when the generic Test Case lifecycle can be handled by the framework.

The framework provides Test Case status handling, Sequencers for common lifecycle patterns, Preparation integration concepts, Assertion interfaces, and result aggregation rules. The project-specific part is the actual test scenario.

A Test Case owns the resources it actively manipulates while it is in an active state. For behavior tests, this includes setting stimuli and evaluating the resulting feedback. The Test Case configuration must ensure that no other Test Case controls the same resource at the same time.

Test Cases are intended to be more reusable than Test Suites. A reusable Test Case represents one stable, behavior-oriented scenario and receives its resource, scenario, configuration, and identity bindings from the owning Suite or call context. Depending on its dependencies, it can be generally reusable, resource-family specific, or intentionally dedicated.

The tested FB or FC may be instantiated and called inside the Test Case or externally in the PLC program. An external call allows one Test Case to validate different blocks through a common stimulus and feedback interface. Detailed selection, interface, and composition guidance is provided in [Test Case authoring](test-case.md).

### Preparation

Preparation is a Test Case helper concept. It brings a resource into the required start condition before the Test Case enters its active test phase.

Preparation publishes status to the owning Test Case. The Test Case owns the Preparation timeout monitoring and decides how preparation errors affect the Test Case result.

The framework defines how Preparation status is interpreted by the owning Test Case. Preparation itself implements the resource-specific logic needed to reach the required start condition.

A Preparation can already be completed when the resource is in the required condition. If work is needed, it reports running while it moves the resource toward that condition.

Preparation does not own the Test Case result. It reports readiness, running, completion, and errors; the Test Case decides how those signals affect the Test Case lifecycle and result.

### Assertion

Assertions evaluate individual conditions. They are called by Test Cases and publish assertion-local results to the Test Case.

Assertions do not own the Test Case lifecycle. The Test Case decides when Assertions are enabled, reset, and aggregated into the Test Case result.

The framework provides common Assertion blocks and the common result semantics for assertion evaluation. Project-specific Test Cases select and parameterize Assertions according to the checked behavior.

Assertions are intentionally narrower than Test Cases. They should evaluate one condition and report a stable local result until reset. They should not emit PC-facing lifecycle or result events for the Test Case.

The state context for assertion diagnostics comes from the owning Test Case. This keeps assertion diagnostics understandable even when the Assertion itself is stateful internally.

## Ownership Boundaries

Generic framework behavior should stay in framework-owned blocks. Project-specific behavior should stay in project-authored blocks.

Run Control owns the project-specific Suite binding. It should not reimplement generic Suite orchestration when an existing Suite Orchestrator matches the required execution model.

Test Suites own the project-specific Test Case grouping. Test Cases own the actual test behavior, Preparation usage, stimulus handling, and Assertion evaluation.

## Configuration And Control Data

Configuration data describes how an authored artifact should run. Control data contains commands and the public status view for the current execution.

Configuration is expected to be set explicitly by the owning level before subordinate execution starts. Control data belongs to the artifact that owns and publishes the corresponding status.

Shared arrays use framework constants for their configured size. The configured size must match the authored instances and calls in the corresponding project implementation.

## Sequencers And Orchestrators

Sequencers and Orchestrators are framework-owned implementation helpers for recurring lifecycle and execution patterns. They are not mandatory, but they are the default recommendation for new authoring work when the provided behavior matches the intended execution model.

Use them because they keep the difficult generic parts in one place:

- command priority and trigger propagation,
- lifecycle state progression,
- readiness and completion checks,
- timeout and error paths,
- runtime tracking where the helper owns it,
- recurring lifecycle and diagnostic events,
- generic result escalation for the execution model.

The project-specific block still owns the concrete binding around the helper. It binds and calls concrete Suites, Test Cases, Preparations, and Assertions; assigns configuration; maps lifecycle signals; applies stimulus; and creates scenario-specific results where required. Logical ownership does not require every child to occupy the parent's instance DB; separately instantiated Suites can retain the same explicit call and control-data binding.

Do not treat a Sequencer or Orchestrator as a replacement for the project-specific block. It abstracts the common execution mechanics, not the concrete test intent or static TIA instance binding.

Custom state-machine logic is allowed for special cases, but it should be a deliberate choice. If a provided Sequencer or Orchestrator models the required behavior, using it is the preferred authoring approach.

The existing Orchestrators also enforce EventBuffer capacity constraints internally. This does not add another author-selected execution model: choose serial, parallel, or slot-based parallel execution from ordering, concurrency, and resource ownership. Do not choose an Orchestrator from EventBuffer size and do not create an `Adaptive` variant. A direct owner implementation that omits the generic Orchestrator must provide the equivalent capacity behavior defined by the owner contract.

## Execution Models

The framework provides reusable execution helpers for common orchestration patterns.

Run Control can use serial, fully parallel, or slot-based parallel Suite orchestration. Test Suites can use comparable Test Case orchestration patterns. Test Cases can use Sequencers when the generic Test Case lifecycle should be handled by a reusable block.

The level-specific authoring guides describe which helper variants exist and how to wire them.

## Monitoring

Monitoring follows the ownership hierarchy. A level monitors the subordinate level that it starts and aggregates.

Monitoring includes timeout handling, readiness checks before subordinate execution is started, observation of subordinate completion, and deterministic reaction to subordinate errors. The subordinate level publishes status; the owning level decides how that status affects the owner's lifecycle and result.

Run Control monitors Test Suites through the selected Suite Orchestrator. Test Suites or Test Case Orchestrators monitor Test Cases. Test Cases monitor Preparation. Assertions are evaluated by the owning Test Case and do not own lifecycle monitoring.

When an Orchestrator or Sequencer is used, the corresponding monitoring logic should stay inside that generic block. Project-specific code should not duplicate the same monitoring behavior unless it intentionally implements a custom execution model.

## Commands And Trigger Propagation

Commands flow from the owning level to the subordinate level. Each owner decides how incoming commands affect its own lifecycle and which subordinate triggers must be generated.

The common commands are start, abort, and reset.

Start begins subordinate execution. The owner should only start a subordinate artifact when that artifact is ready for execution and when the owner's lifecycle allows a start.

Abort requests controlled termination of active subordinate execution. If a level owns multiple subordinate artifacts, abort propagation must consider all subordinate artifacts that may still be active or not yet settled.

Reset returns the owner and its subordinate artifacts to a defined base state. Reset has priority over starting new execution.

If start and abort are present in the same cycle, abort must prevent new subordinate starts. This avoids starting work that is already known to be cancelled.

The owner is responsible for observing whether subordinate abort and reset paths reach stable states. If subordinate execution does not settle within the configured monitoring window, the owner must react deterministically.

When an Orchestrator or Sequencer is used, command priority and subordinate trigger propagation should stay inside that generic block. Project-specific code should not duplicate start, abort, or reset propagation around it.

## Capacity-Aware Reset Propagation

Reset can generate several events for every owner in the hierarchy. Resetting all subordinate owners at once can therefore fill the event buffer before the consumer can release entries.

The generic Orchestrators prevent this by staging subordinate reset commands according to the currently available event-buffer capacity. Suite resets below Run Control are dispatched sequentially. Test Case resets below a Suite are dispatched in capacity-bounded batches. A subordinate owner that is already in `Idle` and reports `Ready = TRUE` does not need another reset command.

Waiting for event-buffer capacity is part of the reset lifecycle. The configured reset timeout continues to run while the Orchestrator waits. A project-specific implementation that does not use a generic Orchestrator must provide equivalent capacity-aware reset propagation itself.

## Capacity-Aware Test Case Execution

Each Test Case publishes `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal` in its status view. These values describe the longest finite executable lifecycle path, are valid when the Test Case is `Idle AND Ready`, and remain stable through `Completed`.

The three framework Test Case Orchestrators use this metadata to reserve a conservative event budget in the producer-owned global EventBuffer accounting before they issue `Cmd.Start`. Reservations from concurrently active Test Suites therefore cannot allocate the same physical capacity. The Orchestrators retain and release their reservations according to the Test Suite contract; project-specific Suite code must not duplicate that accounting around them.

A direct Test Suite implementation without a framework Test Case Orchestrator must provide equivalent global reservation and capacity-gating behavior for normal execution in addition to capacity-aware Reset propagation.

## Status View

Each level publishes a status view for its own execution. Important status concepts include readiness, running state, completion, result, runtime, and subordinate aggregation.

Readiness is not only a state-machine state. A level can only be considered ready when its own state and required subordinate readiness allow a safe start.

Lifecycle states and execution status are separate concepts.

Lifecycle states describe the internal sequence of a framework level. They express where the level currently is in its state machine, for example reset, idle, preparing, running, completing, aborting, aborting from error, or completed.

Execution status is the published status view derived from the lifecycle state and additional conditions. It provides externally useful categories such as ready, running, completed, aborted, or error. Owning levels and diagnostics should consume this status view instead of relying on all internal lifecycle states of the subordinate level.

`Uninitialized` is a defined lifecycle state before an explicit reset has established a valid base state. It is not an error and does not produce lifecycle or framework events. An unhandled state value is different: it is a framework error and must be finalized as an error through the controlled lifecycle path.

The framework level that owns a state machine is responsible for keeping lifecycle state, execution status, result, runtime, monitoring, aggregation, and events consistent.

## Diagnostics

Diagnostic data and local debug views are useful for engineering and troubleshooting.

Diagnostics should help users understand the PLC-side execution flow during online observation or debugging. They should be derived from framework status and local implementation context instead of duplicating execution decisions.

Diagnostic data must not be confused with the PLC/PC communication contract unless explicitly documented as part of that contract.

## Result Aggregation

Result aggregation follows the ownership hierarchy. A level aggregates the results of the subordinate level that it executes.

Run Control aggregates the Suite-level outcome into the complete run result. A Test Suite aggregates Test Case results. A Test Case aggregates Assertion results.

Preparation is not aggregated like a test result. Preparation is a lifecycle prerequisite of the owning Test Case. Preparation completion allows the Test Case to continue; Preparation errors or timeouts are handled by the Test Case lifecycle and can lead to an error result for the Test Case.

Aggregation includes result escalation and counters for subordinate outcomes. The owning level decides how subordinate results affect its own result.

Aggregation events document this aggregation for the PC-side unit test log. They are the log representation of aggregation, not the aggregation logic itself.

## Implementation Timer Constants

Self-counted runtime counters use block-local, typed constants for inactive, initial elapsed-time and accumulation-ceiling values. Keep the existing `T_OFF`, `T_ON` and `MAX_TIMER` scheme in direct lifecycle implementations and template runtime declarations; do not require a consuming project's `CommonConstants` table. Sequencer-based owners capture framework runtime outputs without introducing a second timer implementation. A different timer implementation may use actual timer blocks; no additional framework timer abstraction is required.

Use lifecycle state or the applicable execution-status flags to interpret execution activity, not an exact internal inactive runtime marker. Runtime checks should cover meaningful elapsed-time observations, deadlines and retained completed measurements; an expected elapsed time of zero can be expressed directly as `0`.

## Logging Concept

The PLC-side framework emits log events so an external runner can reconstruct the unit test execution without depending on PLC status DBs as the primary result source.

Log events describe lifecycle progress, final results, aggregation, and relevant diagnostics. Status DBs remain useful for engineering diagnostics and online observation, but the PC-side unit test log is driven by the event stream.

External PC consumers must not reconstruct the normative unit test result from status DB snapshots. They consume the PLC-owned event stream and may read only explicitly defined contract information from the event-buffer exchange area before or during consumption.

Project-specific code should avoid creating duplicate framework lifecycle events when the selected Orchestrator or Sequencer already emits them. Custom events should describe project-specific diagnostics or test-specific result information that is not already covered by the generic lifecycle flow.

## Events

Events are produced by the level that owns the corresponding lifecycle, result, aggregation, or diagnostic situation. Generic Orchestrators and Sequencers encapsulate recurring event emission for the execution patterns they implement.

For authoring, the important rule is simple: do not duplicate events that a selected Sequencer or Orchestrator already emits. Project-specific code should only emit events for behavior it truly owns.

### Lifecycle Events

Lifecycle events describe state transitions and execution progress of a framework level. They mainly support traceability and diagnostics of the PLC-side execution flow.

When an Orchestrator or Sequencer owns the lifecycle state machine, it is also responsible for the corresponding lifecycle events.

### Result Events

Result events describe the final result of a framework level. These events directly affect the PC-side unit test log because they communicate whether the observed artifact passed, failed, was aborted, or ended with an error.

Result events should be emitted by the level that owns the result. Assertions do not emit PC-facing Test Case result events; the owning Test Case aggregates Assertion results into the Test Case result.

### Aggregation Events

Aggregation events describe how subordinate results are summarized by the owning level. These events directly affect the PC-side unit test log because they explain how Suite, Test Case, or Assertion counts contributed to the final result.

Aggregation belongs to the owner of the subordinate level. The subordinate level publishes its status and result; the owner aggregates it.

Final result and aggregation events are emitted during finalization before the owner enters `Completed`. The state-transition event into `Completed` is the final lifecycle event for that owner run.

Technical Orchestrator state-transition diagnostics can appear in the same event stream. They help debug the helper state machine but are not the final lifecycle events of Run Control, Test Suites, or Test Cases.

### Diagnostic Events

Diagnostic events describe exceptional or explanatory conditions such as configuration errors, readiness violations, timeouts, or subordinate errors.

Diagnostic events are primarily execution diagnostics. They can influence the PC-side unit test log when they explain an error result, but they are not a replacement for result and aggregation events.

## Naming And Identification

Names identify authored artifacts in status data and log events. They also define the parent/child hierarchy used by the PC-side event log evaluation.

Use full hierarchical names:

| Artifact | Name form |
| --- | --- |
| Run Control | `<runControlName>` |
| Test Suite | `<runControlName>.<suiteName>` |
| Test Case | `<runControlName>.<suiteName>.<testCaseName>` |
| Assertion | `<runControlName>.<suiteName>.<testCaseName>.<assertionName>` |

The owning level generates the full name for the level below it. Run Control assigns Suite names. Test Suites assign Test Case names. Test Cases assign Assertion names when calling Assertion blocks.

Local Run Control, Suite, and Test Case name segments should be short and stable. Use only letters, digits, `_`, and `-`. Do not use spaces or dots in local segments. The dot is reserved as the hierarchy separator.

Orchestrator diagnostic events use the reserved suffix `.Orchestrator` below the owner they support, for example `<suiteName>.Orchestrator`. These events help diagnose generic helper state machines and are not additional reportable test levels.
