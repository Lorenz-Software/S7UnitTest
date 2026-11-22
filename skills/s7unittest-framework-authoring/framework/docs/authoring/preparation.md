# Preparation Authoring

A Preparation brings a tested resource into the start condition required by a Test Case. It encapsulates target-state establishment so the Test Case can focus on the behavior that is actually being evaluated.

The Test Case owns the Preparation call, timeout monitoring, and interpretation of the returned status. A Preparation does not own the Test Case lifecycle, the DUT call, Assertions, or the final Test Case result.

## Responsibility

A Preparation implements one clear target-condition behavior. While enabled, it may apply the stimulus required to reach that condition and reports its progress through `UDT_UnitTestPreparationStatus`.

A Preparation should be able to bring the resource from every state expected during normal operation into the required Test Case start condition. It must not depend on a previous test run having left the resource in one particular state.

States that cannot be handled should be exceptional and explicitly recognizable. If the Preparation cannot reach the target condition from such a state, it reports `Error`. Do not use `Error` as an alternative branch for normal resource states that the Preparation could handle deterministically.

If the resource is already in the target condition, the enabled Preparation completes without applying unnecessary stimulus.

## Reuse Models

Choose the narrowest reuse scope that keeps the Preparation interface understandable.

### Generally Reusable

A generally reusable Preparation has no dependency on a concrete resource family. Its target-condition behavior can be applied through general or shared data types.

### Resource-Family Specific

A resource-family Preparation uses one stable, typed resource interface. It can be instantiated for multiple resources and used by multiple Test Cases. This is the normal choice when target-state behavior depends on a project or library resource model.

### Dedicated

A dedicated Preparation is intentionally bound to one resource instance, Test Case, or scenario. Use this form when a reusable interface would only expose implementation details without providing meaningful reuse.

A dedicated Preparation still follows the same Enable, status, and resource-ownership rules as reusable Preparations.

## Interface Design

Every Preparation uses the framework interface:

- `Enable : Bool` grants temporary stimulus ownership while the Test Case is preparing.
- `Status : UDT_UnitTestPreparationStatus` reports Preparation readiness and active execution status.

Add only the resource and target-condition data required by the behavior:

- Pass variable targets, limits, timing values, and read-only resource values as inputs.
- Pass writable stimulus or resource data as in-out parameters.
- Prefer in-out parameters over output-based stimulus so resource writes and ownership remain visible at the call.
- Use output-based stimulus only when the Test Case must perform the final signal wiring for a justified integration reason.

Do not modify DUT or resource UDTs to add UnitTest-specific fields. Production interfaces remain unchanged by UnitTest code.

If many coherent signals would otherwise make the interface difficult to use, a separate Preparation interface UDT may group signals to or from the Preparation. Design this UDT for the same reuse scope as the Preparation. Do not use it as an arbitrary collection of TestCase-specific parameters.

Variable targets and resource-specific values belong on the interface. Internal constants are appropriate only for invariant details of the implemented target-condition behavior.

## Resource Dependencies

Generally reusable and resource-family Preparations should not access concrete global resource instances directly. Pass their dependencies through the block interface.

A dedicated Preparation may use an intentional global binding when that dependency is visible in the implementation and does not hide resource ownership. Prefer an interface dependency whenever it remains clear and practical.

The Preparation does not own the DUT call. For a DUT called inside the Test Case, the Preparation modifies the passed stimulus data before the Test Case applies it. For an externally called DUT, the Preparation acts on the passed resource interface while enabled.

## Refactoring Existing Preparations

An existing dedicated Preparation can be made reusable when the same target-condition behavior applies to more than one resource instance. Refactor concrete bindings, not the target condition:

1. Record the target condition, supported normal starting states, exceptional error conditions, active stimulus, internal progress, and `Ready`, `Running`, `Completed`, and `Error` behavior as the semantic baseline.
2. Identify concrete global resource bindings, instance-specific targets, limits, timing values, and invariant implementation details.
3. Select the target reuse class. Keep the Preparation dedicated when extraction would expose implementation details without meaningful reuse or would require target-condition mode selection.
4. Move only variable resource and target-condition dependencies to direct parameters, existing production UDTs, or an existing resource-ID accessor. Do not modify production UDTs.
5. Preserve level-based `Enable`, current status projection while disabled, write behavior while enabled, and the rule that Preparation never owns the DUT call.
6. Preserve handling of all expected normal resource states and the meaning of exceptional `Error` conditions.
7. Validate the original resource binding and at least one additional binding. Each concurrent use requires a separate Preparation FB instance and separate internal progress state.

The refactoring is complete only when the original binding reaches the same target condition with equivalent status and resource-write behavior. Generalization must not introduce another target condition, hidden cleanup behavior, or new DUT responsibilities.

## Enable And Status

`Enable` is a level-based execution and resource-ownership signal.

When `Enable = FALSE`:

- the Preparation performs no resource writes,
- its internal progress returns to an executable base state without cleanup writes,
- `Running` is `FALSE`,
- `Ready` states whether the Preparation can accept execution,
- `Completed` states whether the target condition is currently reached,
- `Error` states whether the Preparation currently recognizes a condition from which it cannot continue meaningfully.

When `Enable = TRUE`, the Preparation publishes one meaningful active condition:

- `Running` while it is actively driving the resource toward the target,
- `Completed` when the target condition has been reached,
- `Error` when it cannot continue meaningfully.

Use the existing framework state and execution-status constants. Preparation states describe local diagnostic progress and do not create another Full Owner lifecycle.

`Completed` is not a latched completion result from an earlier invocation. It is a current projection of the target condition and is evaluated even while disabled. This allows the Test Case Sequencer to skip active preparation when the resource is already in the required start condition.

## Stimulus Ownership

The Test Case owns the affected resource during its active lifecycle and delegates stimulus ownership to the Preparation while `Enable = TRUE`.

Preparation stimulus establishes the Test Case start condition. After preparation completes, stimulus required to exercise or maintain the tested behavior belongs to the active Test Case states.

A target condition should not require continued Preparation writes after completion. If a value must remain driven during test execution, the Test Case must take over that stimulus explicitly.

The owning orchestration prevents concurrent Test Cases from controlling the same external resource. The Preparation does not arbitrate with other tests; it acts only within its active delegation and does not continue influencing the resource after that delegation ends.

## Test Case Integration

Call the Preparation from the Test Case and pass its status into the Test Case lifecycle handling:

```scl
REGION Preparation
	#Preparation(
		Enable := #State = "UnitTest.State.Preparing",
		Status => #PreparationStatus
	);
END_REGION
```

When a framework Sequencer is used, the Sequencer monitors Preparation runtime and reports Preparation timeout or error diagnostics. The Test Case remains responsible for the concrete Preparation call and final result composition.

## Implementation Structure

A Preparation implementation should keep the resource evaluation, active stimulus, and status publication visibly separated:

```scl
REGION Evaluate resource
	// Evaluate readiness, target condition, and exceptional states.
END_REGION

REGION Active preparation
	// Drive the resource only while Enable is TRUE and the target is not reached.
END_REGION

REGION Status
	// Publish the inactive, running, completed, or error status.
END_REGION
```

For a multi-cycle Preparation, keep internal progress observable through `Status.State` and reset that progress to an executable base state when disabled. Do not perform resource cleanup merely because `Enable` was removed.

## Validation

Before using a Preparation, check that:

- It represents one understandable target-condition behavior.
- It handles all resource states expected during normal operation.
- Exceptional unsupported states produce `Error` rather than an undefined wait.
- It does not depend on a particular previous Test Case or test run.
- It performs no resource writes while disabled.
- It completes without unnecessary writes when the target is already reached.
- Writable resources and variable targets are exposed through a clear interface.
- DUT and resource UDTs contain no UnitTest-specific additions.
- It does not own the DUT call, Assertions, timeout monitoring, or final Test Case results.
- Stimulus required after preparation is owned explicitly by the Test Case.

The framework blocks `Preparation_Mock` and `Preparation_MockTimed` are test stubs for exercising the owning Test Case level. They demonstrate status interaction but are not reference implementations of production resource preparation.
