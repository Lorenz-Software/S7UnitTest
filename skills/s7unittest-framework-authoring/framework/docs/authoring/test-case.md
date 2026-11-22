# Test Case Authoring

A Test Case implements one concrete test scenario and produces one Test Case result. It is the framework level that owns the actual test behavior.

The Test Case should use a framework Sequencer when the generic Test Case lifecycle fits the scenario. The project-specific code should focus on resource ownership, stimulus, Preparation, Assertions, and result handling.

## Navigation

- [Choosing Test States](#choosing-test-states)
- [Resource Ownership And Stimulus](#resource-ownership-and-stimulus)
- [Test Case Composition](#test-case-composition)
- [Sequencer Usage](#sequencer-usage)
- [Assertions](#assertions)

## Test Case Responsibility

The Test Case owns the behavior that is being tested. It prepares the required start condition, applies stimuli, observes feedback, evaluates Assertions, aggregates Assertion results, and publishes the final Test Case result.

The Test Case is responsible for translating a concrete scenario into a deterministic PLC execution sequence. It should not rely on hidden state from previous runs, uncontrolled external writes, or log-only failure detection.

The Test Case is not responsible for Suite-level orchestration. The owning Test Suite starts, aborts, resets, monitors, and aggregates Test Cases.

## Choosing Test States

Prefer `UnitTestCaseSequencer_MultiTestState` when a scenario has successive stimulus/observation phases spanning invocations. The framework should own phase progression, state context and supervision rather than a second phase controller hidden inside one test state. For example, filling a buffer, rejecting an extra record and draining the queue are useful distinct test states within one Case, not three independent Cases.

Use `UnitTestCaseSequencer` for a coherent check without a separate multi-invocation phase sequence. A private phase controller is a justified exception, not the default representation of a fixed trace. Explain the concrete reason for that exception instead of treating a shorter framework declaration as sufficient justification.

Choose states by behavioral meaning, not mechanically by PLC cycle, operation or data row. Decide execution structure separately from the representation of calls, instances and binding data. An array of independent Assertion instances, grouped by bounded loop calls, can express checks in one invocation or within meaningful framework states without adding any cross-cycle iteration. Individually written calls and instance arrays are alternative representations, not different lifecycle models. Select both dimensions from observable behavior, actual call/sample boundaries, isolation, diagnostic granularity, readability and evidenced cyclic/storage constraints:

- Keep a coherent set of immediate checks in one state when no separate invocation boundaries are needed; use explicit calls or distinct-instance arrays according to the clarity and homogeneity of their bindings. No wait between different array elements is required. Preserve outputs if a later DUT call would overwrite shared storage; do not copy independently stored outputs unnecessarily.
- Use framework states for meaningful successive steps or needed invocation boundaries and logged state context, not just to save Assertion instances. State context does not create an independent Assertion result or reset failed/history state.
- Use separate Cases when independent baselines, results, ownership or incompatible histories are required; several Assertions of one coherent behavior need not become several Cases.
- Use bounded within-invocation data iteration only when homogeneous immediate samples remain readable, attributable and within established cyclic constraints. Stateful DUT/Assertion call-ownership rules still apply.
- Distribute homogeneous samples across invocations only for a concrete workload, call-order or resource reason. Account for extra progress state, Reset/Abort, finite completion and the required failure attribution rather than choosing one row per cycle by habit.

A bounded index may iterate records or input vectors within one state; it must not also take over the behavioral phase sequence. Its admissibility does not make it the preferred representation. A data table does not automatically provide independent framework executions or results like a parameterized host-language test runner. Apply the [Assertion ownership criteria](assertions.md#instance-ownership-and-data-variations), including the preference for separate independent check sites within one state and the limits of first-failure reporting. Explain consequential choices briefly; do not require a general test-data infrastructure or a fixed decision worksheet.

Capture and evaluate each state's required observations before advancing, keep completion independent of Passed, and retain earlier results through finalization. A counter or CASE statement alone does not make an implementation inappropriate; neither shorter source nor fewer instances alone makes it preferable.

## Reuse Model

A reusable Test Case represents one stable, behavior-oriented scenario. Prefer describing observable behavior instead of coupling the scenario to one concrete tested block. The same Test Case can then be used for different resources or different externally called blocks that expose the required stimulus and feedback.

Choose the most reusable form that keeps the scenario and its interface clear:

- A generally reusable Test Case has no dependency on a concrete project resource or resource family.
- A resource-family Test Case uses one stable typed resource interface and can be instantiated for different resources or tested blocks of that family.
- A dedicated Test Case is intentionally bound to one project structure, resource instance, or block when further abstraction would not provide meaningful reuse.

Reuse changes data bindings, not the scenario itself. Test-state sequence, stimulus behavior, checked property, Assertion activation, and result interpretation remain stable. Avoid mode, test-type, Assertion-selection, or flow-selection parameters that combine unrelated scenarios in one Test Case.

Put values on the Test Case interface when they vary by resource instance or tested-block configuration. Typical examples are stimulus values, expected values, tolerances, limits, and observation times. Keep invariant scenario facts as local constants. `TestTime` is therefore an input only when it varies by instance; a fixed observation time can remain a scenario constant.

The owning Suite should establish Test Case configuration and scenario bindings before reset or start and keep them stable during the Test Case lifecycle.

## Tested Block And Resource Interfaces

The tested FB or FC can be called inside or outside the Test Case.

With an internal call, the Test Case instantiates the tested FB or calls the FC itself. This intentionally couples the Test Case to that block type while still allowing reuse for different instances and parameter sets of the same type.

With an external call, the tested block is instantiated and called elsewhere in the PLC program. The Test Case works only through explicit stimulus, feedback, Control, and resource interfaces. This is the preferred way to reuse one behavior-oriented Test Case for different block types. The project call order and any resulting cycle delay remain visible parts of the test integration.

Prefer resource interfaces in this order:

1. Direct typed parameters for a small and readable interface.
2. Existing production Control or resource UDTs that already represent the required data.
3. An existing resource-ID plus getter/setter access pattern.
4. A dedicated UnitTest-specific interface UDT only when a coherent signal group would otherwise make the interface impractical.

Use inputs for observations, expected values, limits, and other read-only scenario data. Use in-out parameters for stimulus and resource data written by the Test Case. Stimulus outputs are an exception and require the Test Case to own the value completely.

Do not modify production DUT, Control, or resource UDTs for UnitTest needs. A UnitTest-specific interface UDT should remain reusable at the selected scope and must not become an arbitrary container for unrelated scenario configuration.

Generally reusable and resource-family Test Cases must not bind a concrete global resource instance directly. A resource-ID based getter/setter abstraction remains reusable because the concrete instance is selected through the interface. A dedicated Test Case may use direct project-global binding when that choice is deliberate and visible.

Each stateful use requires its own Test Case FB instance, Control data, Sequencer state, Assertion state, and hierarchical identity. Shared resource data is safe only when Test Suite orchestration prevents concurrent write ownership.

## Refactoring Existing Test Cases

An existing dedicated Test Case can be made reusable when its scenario remains meaningful for more than one resource or tested-block instance. Refactor the bindings, not the test intent:

1. Record the existing test-state sequence, stimulus behavior, Preparation, Assertions, result meaning, events, and cycle behavior as the semantic baseline.
2. Identify concrete resource bindings, instance-specific values, and tested-block dependencies.
3. Select the target reuse class. Keep the Test Case dedicated when extracting dependencies would obscure the scenario or require mode-selected behavior.
4. Move only variable bindings and scenario parameters to explicit interfaces. Keep invariant scenario facts and the scenario flow inside the Test Case.
5. Preserve whether the tested FB or FC is called internally or externally unless that call ownership is changed deliberately. Changing call ownership can change PLC call order and cycle behavior.
6. Reuse existing Preparations and framework Assertions where their behavior still fits. Do not replace established lifecycle or finding semantics with local alternatives.
7. Validate the refactored block with at least two independent instances. Each use must have separate Test Case, Sequencer, Preparation, Assertion, Control data, and identity state.

The refactoring is complete only when the original scenario still produces equivalent lifecycle, result, aggregation, and event behavior for its original binding. Generalization must not introduce new acceptance criteria or silently alter existing ones.

## Naming

The Test Case receives its full hierarchical name from the owning Test Suite:

```text
<runControlName>.<suiteName>.<testCaseName>
```

Use this full Test Case name in status publication, Sequencer calls, lifecycle events, result events, and aggregation events.

When calling Assertions, generate the Assertion event name from the Test Case name plus one assertion-local name:

```scl
Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'Feedback')
```

The Assertion name then becomes:

```text
<runControlName>.<suiteName>.<testCaseName>.Feedback
```

Do not pass only a local Assertion name. The PC-side event log uses the full name to place Assertion findings below the owning Test Case.

## Resource Ownership And Stimulus

The owning orchestration ensures that only one Test Case controls a shared external resource at any one time. Test Cases do not coordinate with one another or implement locks or ownership registries for that scheduling responsibility. Configure the owning hierarchy so resource-conflicting cases are not executed concurrently.

Functional stimulus ownership has two parts:

- Preparation establishes the start condition during its enabled active execution.
- The Test Case drives the behavior being checked during its active test state or states.

Both may use the same resource in their respective phases. Preparation stimulus belongs in Preparation; test-state stimulus belongs in the Test Case. Neither an inactive Preparation nor an inactive/completed Test Case may keep influencing the resource and thereby disturb a later test.

Public Reset used for reset or abort cleanup is separate from functional stimulus. Request it through the DUT interface and then monitor the defined idle condition. Repeat requests according to the public interface's edge or level semantics; they still target the same idle condition, and the DUT protects its own critical Reset sections. The reset target may be Idle with DUT Ready FALSE. This does not replace the Framework Full Owner Idle/Ready start gate or allow a stable inactive test to keep another test's resource under Reset.

Feedback should represent the observed reaction of the tested logic or simulated process. A Test Case should not overwrite feedback locally just to make its own Assertions pass.

Preparation is responsible for stimulus during `Preparing`:

```scl
REGION Preparation
    #Preparation(
        Enable := #State = "UnitTest.State.Preparing",
        Status => #PreparationStatus
    );
END_REGION
```

Test-state stimulus is handled by the Test Case after Preparation has completed:

```scl
REGION Stimulus
    IF #State = "UnitTest.State.Running" THEN
        #Stimulus := TRUE; // Trigger the behavior evaluated by Assertions.
    END_IF;
END_REGION
```

For multi-run-state Test Cases, stimulus handling should explicitly reflect which running state owns which part of the scenario.

## Test Case Composition

A Test Case should be structured around clearly separated regions:

```scl
REGION Default values
    // Initialize temporary values used by the Test Case.
END_REGION

REGION Configuration checks
    // Evaluate configuration errors before lifecycle execution.
END_REGION

REGION Prepare sequencer inputs
    // Derive inputs for the Sequencer.
END_REGION

REGION Sequencer
    // Call the selected Test Case Sequencer.
END_REGION

REGION Preparation
    // Call optional Preparation logic.
END_REGION

REGION Stimulus
    // Drive scenario stimulus only while the Test Case owns the resource.
END_REGION

REGION Assertions
    // Call Assertions and collect assertion-local results.
END_REGION

REGION Result handling
    // Derive the Test Case result from lifecycle and Assertion results.
END_REGION

REGION Status
    // Publish the Test Case status view.
END_REGION
```

The concrete structure depends on the scenario, but the separation should remain stable. The Sequencer owns the generic lifecycle flow. The Test Case owns scenario-specific behavior and final result handling.

## Sequencer Usage

The framework provides Sequencers for common Test Case lifecycle patterns.

`UnitTestCaseSequencer` handles a Test Case with one active running state.

`UnitTestCaseSequencer_MultiTestState` handles a Test Case with multiple sequential test states. The test states are sequential and do not branch internally except through external reset or abort commands.

Use a Sequencer when the generic lifecycle fits the scenario. This is the recommended implementation path for behavior Test Cases and for most Test Cases that need Preparation or multi-cycle execution.

The Sequencer abstracts the generic Test Case execution mechanics: lifecycle state progression, command priority, reset and abort handling, runtime tracking, Preparation runtime tracking, lifecycle events, Preparation timeout/error diagnostics, configuration-error reaction, and controlled transition into finalization.

The Test Case supplies scenario conditions to the Sequencer and reacts to the state values returned by the Sequencer. The Test Case still owns the scenario itself: Preparation call, stimulus, feedback observation, Assertion calls, Assertion aggregation, final Test Case result, and final Test Case aggregation.

Do not duplicate Sequencer lifecycle logic in the Test Case around the Sequencer. If project code sets the lifecycle state directly, handles command priority itself, or emits duplicate lifecycle events, it is a custom Test Case state machine and must own those responsibilities completely.

Example:

```scl
REGION Sequencer
    #Sequencer(
        CycleTime := #CycleTime,
        Name := #ConfigData.Name,
        ResourceName := #ResourceName,
        CmdData := #ControlData.Cmd,
        ConfigData := #ConfigData,
        LifecycleSignals := #LifecycleSignals,
        State => #State,
        PreviousState => #PreviousState,
        Result => #SequencerResult,
        ConfigError => #GenericConfigError,
        Runtime => #Runtime,
        PreparationRuntime => #PreparationRuntime,
        TestStateRuntime => #TestStateRuntime
    );
END_REGION
```

Signals passed to the Sequencer should be prepared before the call. Sequencer outputs and in-out data should be evaluated after the call.

The Sequencer should receive one compact lifecycle-signal structure. Build that structure close to the Sequencer call from Preparation status and Test Case-local conditions. Avoid spreading Sequencer start/finish decisions across stimulus, assertion, or result code.

## Lifecycle States

The Test Case lifecycle is represented by framework state constants. When a Sequencer is used, the Sequencer owns this lifecycle. The Test Case reacts to the published state and should not implement a competing Test Case state machine.

The relevant Test Case lifecycle states are:

- `UnitTest.State.Reset`: reset Test Case state and reset Assertions.
- `UnitTest.State.Idle`: inactive base state; the Test Case can accept Start only when Ready and without a held Error.
- `UnitTest.State.Preparing`: Preparation may actively establish the required start condition.
- `UnitTest.State.Running`: active test evaluation state.
- `UnitTest.State.Completing`: finish normal execution and prepare final aggregation/result handling.
- `UnitTest.State.Aborting`: abort execution after an external abort command.
- `UnitTest.State.AbortingFromError`: abort execution after a detected error condition.
- `UnitTest.State.Completed`: stable final state for the Test Case execution.

`UnitTestCaseSequencer_MultiTestState` can publish multiple sequential test states starting at `UnitTest.State.Running`. The Test Case should use these states to decide which stimuli and Assertions are active in each phase.

Unhandled Test Case lifecycle state values are framework errors. They are not an uninitialized state and should be completed through the controlled error finalization path.

With a provided Sequencer, project-specific Test Case code should not set Test Case states directly. Only a custom Test Case lifecycle implementation should own Test Case states directly.

The Sequencers publish Reset for at least one invocation before reacting to invalid Reset configuration, so local state and Assertions can be reset. A configuration error in Reset finalizes with Error through Completing and Completed. In Idle, a configuration error instead remains Idle/Error, blocks Ready and Start, and is held until an explicit Reset, even if configuration has been corrected. Neither pre-execution path enters AbortingFromError; do not use that phase for configuration initialization work.

Idle/Error is not a completed test execution and does not publish final Result/Aggregation events solely for that error. It has no active work to abort and can satisfy the parent's abort-completion check without becoming Completed. Preparation and test-execution error handling remain unchanged.

## Preparation

Preparation is a Test Case helper concept. It brings the tested resource into the required start condition before active test evaluation starts.

Preparation is called by the Test Case and reports `UDT_UnitTestPreparationStatus` back to the Test Case or Sequencer. The Preparation does not own the Test Case result.

The Test Case enables Preparation while the Test Case is in the Preparation phase. The Preparation may complete immediately if the target condition is already reached.

Detailed guidance for reuse, interface design, target-state coverage, and status behavior is provided in [Preparation authoring](preparation.md).

Before creating a new Preparation, check whether an existing Preparation already establishes the required target condition. Prefer reusing its FB type with different resource and target bindings. Generalize an existing Preparation only while its single target-condition behavior and interface remain clear. Each stateful Test Case instance still owns a separate Preparation instance.

Example:

```scl
REGION Preparation
    #Preparation(
        Enable := #State = "UnitTest.State.Preparing",
        Status => #PreparationStatus
    );
END_REGION
```

Preparation timeout and Preparation error handling belong to the Test Case lifecycle. When a Sequencer is used, the Sequencer monitors Preparation runtime and emits the corresponding diagnostic events.

Preparation shall not perform functional Assertions and shall not emit PC-facing Test Case result or aggregation events.

## Assertions

Assertions evaluate concrete conditions during active test states. The Test Case owns when Assertions are reset, enabled, and aggregated.

Assertion reset should be tied to `UnitTest.State.Reset`. `Enable` should be true only in states where the Assertion is intended to evaluate the scenario.

A typical Assertion call has a stable shape: reset in `Reset`, enable in the relevant active state, pass the Test Case state for diagnostics, and collect the Assertion result for later aggregation.

Example using an `AssertEqual_Bool` multi-instance named `Assertion_Feedback`, called every Test Case invocation:

```scl
REGION Assertions
    #Assertion_Feedback(Reset := #State = "UnitTest.State.Reset",
        Enable := #State = "UnitTest.State.Running",
        Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'Feedback'),
        ResourceName := #ResourceName,
        State := #State,
        Expected := TRUE,
        IN := #Feedback,
        Result => #AssertionResult_Feedback);
END_REGION
```

Assertions should not emit Test Case lifecycle or Test Case result events. Assertion results are aggregated by the Test Case into Assertion counters and the final Test Case result.

For multi-run-state Test Cases, each Assertion should be enabled only in the state or states where its condition is meaningful.

Choose the narrowest Assertion that describes the intended check. For assertion selection and family-specific guidance, see [Assertion authoring](assertions.md).

Use framework Assertions first. If no existing Assertion expresses the required condition clearly, a project- or TestCase-specific Assertion is preferable to complex evaluation logic embedded directly in the Test Case. This is a justified case-by-case exception. The specific Assertion must still implement one coherent check and follow the framework Assertion interface, reset, stable-result, event-context, and finding-event semantics.

## Result Handling

The Test Case owns the final Test Case result. The Sequencer can report generic lifecycle errors, explicit abort handling, configuration errors, Preparation errors, or Preparation timeouts, but functional pass/fail evaluation belongs to the Test Case.

Result handling should be centralized in the `Result handling` region. Do not mix final result generation into Sequencer input preparation, stimulus logic, or Assertion calls.

Typical result sources are:

- Sequencer result for generic lifecycle conditions,
- Preparation-derived result for Preparation error or Preparation timeout,
- Assertion results for passed, failed, or assertion error,
- local configuration errors detected before lifecycle execution.

The Test Case must interpret the Sequencer result in the context of its own lifecycle. A Sequencer-reported `Error` escalates to the Test Case result. A Sequencer-reported `Abort` is only valid as confirmation of a Test Case abort path that was already selected from an explicit abort command; otherwise it is a framework error.

Assertion result aggregation should be explicit and stable for one Test Case execution. A failed or error Assertion should keep contributing to the Test Case result until the Test Case is reset.

For normal Sequencer-based Test Cases, the practical pattern is:

- combine Sequencer and scenario-specific lifecycle results,
- combine Assertion results into the Test Case result,
- emit final Test Case result and aggregation only during finalization,
- keep the final transition to `Completed` as the last lifecycle event.

## Status Publication

The Test Case publishes its status view after the Sequencer, Preparation, stimulus handling, Assertions, and result handling have run for the current cycle.

The status view includes lifecycle state, execution status, result, runtime, configuration status, Preparation activity, lifecycle-capacity metadata, and Assertion counters.

`UpdateTestCaseStatusView` is the framework utility that maps Test Case state, result, runtime, configuration status, readiness, lifecycle-capacity metadata, Preparation activity, and Assertion counters into the published Test Case status view.

`PreparationStateCount` and `TestStateCount` count entries along the longest finite executable path from `Idle` to `Completed`, not merely distinct numeric states. Use `PreparationStateCount := 0` when the Test Case has no Preparation state; `TestStateCount` must be greater than zero. Together with `AssertionCountTotal`, these values must be valid at `Idle AND Ready` and remain stable through `Completed` so the owning Test Case Orchestrator can reserve the required event capacity before Start.

Example:

```scl
REGION Status
    "UpdateTestCaseStatusView"(
        State := #State,
        Result := #Result,
        Runtime := #Runtime,
        ConfigError := #ConfigError,
        Ready := #Ready,
        PreparationStateCount := #PreparationStateCount,
        TestStateCount := #TestStateCount,
        AssertionCountTotal := #AssertionCountTotal,
        AssertionCountPassed := #AssertionCountPassed,
        AssertionCountFailed := #AssertionCountFailed,
        AssertionCountError := #AssertionCountError,
        ControlData := #ControlData
    );
END_REGION
```

The owning Test Suite consumes this status for monitoring and aggregation.

## Events

Test Case events are emitted by the component that owns the corresponding lifecycle, result, aggregation, or diagnostic situation.

When a Sequencer owns the Test Case lifecycle, it owns recurring lifecycle events and Preparation timeout/error diagnostic events. The Test Case should not emit duplicate lifecycle events for the same transitions.

The Test Case owns final result and aggregation events because it owns the final Test Case result and Assertion aggregation.

### State Transition Events

State transition events are emitted by the Sequencer when the Test Case lifecycle state changes.

The Test Case should not emit a second state transition event around the Sequencer. If the Test Case implements a custom state machine, state transition events become part of that custom lifecycle responsibility.

### Preparation Diagnostic Events

Preparation timeout and Preparation error diagnostic events are emitted by the Sequencer when it owns Preparation monitoring.

These events should include the Preparation state so the PC-side log and PLC diagnostics can explain why the Test Case could not enter active evaluation.

### Result Events

Result events are emitted when the final Test Case result is known.

Result and aggregation events are finalization events. They are emitted before the final state-transition event into `Completed`.

Example:

```scl
#RetVal_Event := "CreateUnitTestResultEvent"(
    OwnerScope := "UnitTest.OwnerScope.TestCase",
    Name := #ControlData.Name,
    ResourceName := #ResourceName,
    State := #ControlData.Status.Execution.State,
    Result := #ControlData.Status.Execution.Result,
    Message := 'Test Case completed.'
);
```

### Aggregation Events

Test Case aggregation events describe how Assertion results contributed to the Test Case result.

```scl
#RetVal_Event := "CreateUnitTestCaseAggregationEvent"(TestCaseControl := #ControlData);
```

This event directly affects the PC-side unit test log because it explains Assertion counts for the final Test Case result.

The Test Case result event and aggregation event must be emitted before the final state-transition event into `Completed`, not in the same PLC cycle.

## Example Implementations

The framework contains example Test Case implementations that show the main Test Case authoring patterns:

- `UnitTestCase_Example_StaticCheck`: shows a static check scenario with Assertion-based result handling.
- `UnitTestCase_Example_Behavior`: shows a behavior scenario without a generic Test Case Sequencer.
- `UnitTestCase_Example_SequencedBehavior`: shows behavior testing with `UnitTestCaseSequencer`.
- `UnitTestCase_Example_MultiTestState`: shows behavior testing with `UnitTestCaseSequencer_MultiTestState`.

These examples are intended as authoring references for project-specific Test Case implementations.

## Validation

Before using a Test Case in a project, check that:

- The selected reuse class matches the Test Case dependencies.
- The Test Case represents one stable behavior-oriented scenario without mode-selected alternatives.
- Variable resource and scenario data is supplied explicitly while invariant scenario facts remain local constants.
- Internal or external calling of the tested FB or FC is deliberate and visible.
- Production UDTs have not been modified for UnitTest needs.
- Each stateful Test Case use has separate instance and Control data.
- Configuration errors are detected before normal lifecycle execution starts.
- Stimulus is written only while the Test Case owns the resource.
- Feedback is observed from the tested logic or simulation and is not locally overwritten to satisfy Assertions.
- Preparation is enabled only during the Preparation phase.
- Preparation status is passed to the Sequencer when the Sequencer owns Preparation monitoring.
- Assertions are reset only in `UnitTest.State.Reset`.
- Assertions are enabled only in states where their checks are meaningful.
- Existing Preparations and Assertions have been considered before new specific blocks are introduced.
- Test Case result handling is centralized.
- Status publication happens after Sequencer, Preparation, Assertions, and result handling.
- Lifecycle events are not duplicated around a Sequencer.
