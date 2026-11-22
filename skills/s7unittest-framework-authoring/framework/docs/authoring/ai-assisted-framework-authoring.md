# AI-Assisted Framework Authoring

The `s7unittest-framework-authoring` skill helps understand existing S7 blocks, select useful behavioral tests, and implement agreed scenarios with the S7 UnitTest framework. It complements the regular authoring guides rather than defining production requirements or replacing engineering review.

## Navigation

- [Choose The Entry Point](#choose-the-entry-point)
- [Understand The Block Before Selecting Tests](#understand-the-block-before-selecting-tests)
- [Prioritize A Proportional Plan And Explain Omissions](#prioritize-a-proportional-plan-and-explain-omissions)
- [Establish The Conditions For A Meaningful Observation](#establish-the-conditions-for-a-meaningful-observation)
- [Implement And Review Agreed Intent](#implement-and-review-agreed-intent)
- [Installation And Compatibility](#installation-and-compatibility)

## Choose The Entry Point

- **Derive tests:** provide the DUT, relevant requirements, and available caller/dependency context. Ask for an explanation of the behavior and a proportionate test plan before implementation.
- **Implement defined intent:** provide agreed scenarios, expected behavior, and integration constraints. Proceed to framework composition without repeating settled test discovery.

An analysis-only request ends with analysis or a plan. Missing consequential requirements remain owner decisions. Ordinary implementation details do not require three fixed approval gates or a machine-readable intermediate plan.

Supported artifacts remain Run Control, Test Suites, Test Cases, Preparations, and Assertion integration. Serial, parallel, and configured parallel-slot execution are available where ordering and ownership permit them. Test Cases can use static checks, single or multiple test states, and optional Preparation. Prefer framework Sequencers and Orchestrators over duplicating lifecycle and event behavior.

## Understand The Block Before Selecting Tests

Identify the subject, inspected revision/source set, supported interface, and requested boundary. Read declarations and relevant bodies together; inspect callers, configuration, nested instances, shared storage, and dependencies where they explain the behavior being tested. An FC may access shared state; an FB need not have relevant history. Block kinds alone do not establish purity or statefulness.

Keep these evidence kinds separate:

| Kind | Meaning |
| --- | --- |
| Specified | Expected behavior supported by accepted requirements or contracts. |
| Observed | Behavior found in implementation, callers, or an existing test. |
| Proposed characterization | Observed behavior proposed for intentional preservation, pending owner acceptance. |
| Unresolved | Missing/conflicting intent or integration facts, including labeled hypotheses. |

Source can reveal useful candidates without proving their expected results. Comments, another implementation, and passing old tests do not automatically settle correctness. Resolve material conflicts with the owner; do not select whichever interpretation makes a test pass. Continue work independent of the open decision.

Explain observable behavior, retained state, call order, time sources, effects, dependencies, and limits using proportional prose or a table, not a mandatory report schema. Missing bodies or writers limit corresponding conclusions; a successful search does not prove complete dependency coverage.

## Prioritize A Proportional Plan And Explain Omissions

Start with the small set of essential observable questions: what must the block
do, which defined boundaries change its treatment, and which credible failures
or state/history paths could invalidate a real use? Consider both the consequence
of a defect and how likely the implementation or its dependencies are to introduce
it. Methods, branches, Assertion types and test counts do not define that set.

Select representatives for distinct treatments, meaningful boundaries and relevant
histories. Before adding another group, ask: which relevant wrong behavior could
it distinguish that the selected groups do not already address? A distinct
boundary, failure/recovery path or credible independent implementation/regression
risk can justify it. Another ordinary value with the same treatment usually
cannot. This is a reasoned selection, not a requirement to execute a mutation
for every test.

Consolidate candidates before presenting the recommended plan. Also compare
implementation variants rather than automatically repeat a full matrix for every
type. Compare the required behavior, execution/history and relevant failure
mechanisms. Where a shared pattern is supported, use a deeper representative
matrix and targeted checks for actual differences. Similar source or a renamed
type alone does not establish equivalence: precision, representable neighbors,
range, storage, conversions and separately maintained implementations can expose
different defects. Keep the relevant distinguishing checks and state the limits
of the representative coverage. Do not demand exhaustive equivalence proof merely
to avoid arbitrary repetition.

Data variation and scenario identity are different decisions. Several values
that answer one behavioral question can share table-driven checks if the failing
row, stimulus and expectation remain identifiable. Keep independently meaningful
starting conditions, state/history, ownership, recovery or expected behavior
separate. Ordered steps belong together when their interaction is the subject.
Reducing the number of Test Case FBs by hiding unrelated behaviors behind modes
does not improve the test plan.

Present the recommended core first. For each selected group, explain the basis,
starting condition, stimulus/call sequence, independent expected observation,
completion condition and additional distinction proportionally. A small plan
can stay compact:

| Scenario | Basis and setup | Stimulus and observation | Completion and omission |
| --- | --- | --- | --- |
| Lower clamp | Any DINT accepted; no mutable fixture | -101/-100/-99 produce -100/-100/-99 | Finish after all three checks; upper boundary remains a separate group |
| Fault rejects a request | Defined permission table | Otherwise valid request with Fault TRUE produces FALSE | Finish after evaluation; no resource cleanup |
| Missing feedback | Defined cyclic deadline; subject baseline restored | Request, observe Command, keep Feedback FALSE, inspect the bounded final outcome | Finish at the observation endpoint even if Error never appears; exact deadline needs separate timing evidence |

Stop adding cases when the essential behavioral questions and selected material
risks are addressed and further reasonable candidates add no material distinction.
Do not use a fixed quota, percentage, all-combinations mandate or the mere
existence of another method as a reason to continue. A known relevant regression
can still justify a specific check even when the ordinary outcome class is
already represented.

Explain grouped redundancy and meaningful omissions briefly, rather than require
a worksheet for every Assertion or data row. Mark material gaps as unresolved,
blocked, outside the supported model or deferred with their consequence; they
do not become covered because the plan is small. Add further tests only with
their own contribution, not as an automatic optional-test catalogue.

This consolidation applies when selecting or reviewing test scope. For an
implementation-only request, preserve the already agreed scenarios. Propose a
material scope reduction for owner agreement rather than silently remove tests
or expected observations.

Tests need clear failure context, isolation and repeatability. Those quality
concerns also appear in
[Microsoft's unit-testing guidance](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices).
Apply them to cyclic PLC execution as described here rather than impose a fixed
wall-clock test budget or exactly one Act call on every scenario.

Apply the additional-contribution question within data groups too. Covering relevant input classes and parameter positions does not by itself require their full Cartesian product. Use justified representatives across those dimensions and targeted combinations for interactions, independent implementation risks or other material distinctions. A full matrix remains appropriate when those distinctions justify it; neither its presence nor its absence alone establishes quality. Grouping rows into one Case does not replace this selection decision.

Review coverage and redundancy together. Before expanding an already represented path, check the whole plan for missing essential valid behavior, relevant boundaries and observable outcome classes, as well as error paths. Many variations of one behavior do not compensate for an unrepresented material behavior elsewhere. Do not turn this review into a mandatory checklist of every imaginable partition; select by the subject's requirements and material risks.

Apply input partitions, boundaries, feasible decisions, state/history, timing and recovery only where they distinguish relevant behavior. A pure FC needs no cyclic fixture merely because the framework supports one. Before handoff, reconcile implemented groups and data variations with the selected behavioral questions, not only Case count or group names.

Each expectation needs an accepted requirement, owner decision, or explicitly accepted characterization. Use independent examples, relationships, or another suitable oracle; reimplementing the DUT algorithm in Expected calculations can reproduce its defect. Independence alone is not enough: an invariant or relationship that also permits a relevant wrong result needs another distinguishing observation. Explain that distinction analytically; executing a fault for every test is not required.

### Keep Checked Information Clear

Reduce redundant scenarios, not the visibility of their expectations. Assertion count is not an optimization target. Prefer a direct actual/expected comparison when checking a value, rather than precomputing that comparison solely to assert TRUE.

A composite Boolean condition can be appropriate for a coherent domain property. Prefer expressing it as a named signal before the Assertion; its name should clearly state the information conveyed. Apply the same clean-code judgment as in production code: a name does not rescue an expression that compresses too many independent statements. Decompose such conditions into meaningful signals and, where needed, separate Assertions so readers can understand the expected properties and diagnose which one failed with useful actual values.

Do not turn this into one Assertion per variable, a prohibition on AND/OR, or a mechanical expression-length limit. Review the clarity of the signal's meaning, its content and the resulting diagnostics together. Before selecting the Assertion and its instance arrangement, consider a plausible failure as presented through the PC client's available name, resource/state context and the family's supported message: can the reader locate the check, understand the expectation and see the relevant actual deviation? Prefer typed direct checks over precomputed Boolean verdicts when those would discard useful values. Preserve exact/tolerant and other accepted semantics, meaningful stable identities and bounded rendering limits; the message identifies an observed deviation, not necessarily its technical cause. Use the complete [failure-information selection guidance](assertions.md#review-the-resulting-failure-information), not a new logging protocol or mandatory per-Assertion fault exercise.

Choose stateful Assertion instances together with the scenario's [execution structure](test-case.md#choosing-test-states), not from data-row counts alone. The [Assertion Authoring guide](assertions.md#instance-ownership-and-data-variations) distinguishes continuous observation, meaningful multi-state reuse and independent check sites within one state. Prefer separate instances for those independent sites; justify exceptional same-state sample reuse by its concrete benefit and sufficient diagnostic semantics. Keep Assertion identities stable, use logged State for actual framework-step context, and account for result/finding latching. Neither automatic one-instance-per-row duplication nor minimizing instances at the expense of required results is the goal.

## Establish The Conditions For A Meaningful Observation

Make starting condition, owned stimulus, DUT execution, observation, completion, and cleanup explicit. These are reasoning questions, not six mandatory tests. Apply only the relevant ones; a stateless value comparison needs no clock, settling phase or resource lifecycle merely because other patterns use them.

Distinguish conditions given by requirements or inspected integration facts, conditions the test will establish through its supported arrangement, and assumptions still unresolved. Keep these distinctions in the ordinary plan, not a mandatory extra worksheet. For each consequential prerequisite or numeric bound, identify its basis and how it will be satisfied. A proposed fixture choice does not create a DUT or consumer requirement. An unknown capacity, service latency or duration is not justified by inventing a conservative threshold or safety margin. Name the missing evidence and affected conclusion; ask when the arrangement or acceptance depends on that fact. A source-only draft may leave that part explicitly unqualified without turning it into a new mandatory precondition.

- **Call/sample order:** distinguish a Test Case command from its processing by an externally called DUT. Preserve cycle order and use `ObserveFirstCycle` only when the selected Assertion supports it and the scenario requires it.
- **Observation/evaluation:** collecting samples and explicitly evaluating them differ. Match `Enable`, `Evaluate`, and reset to the selected Assertion; do not complete before intended checks have evaluated. A held Passed result does not prove a new sample or completed collection. Keep the intended final sample and explicit evaluation in the correct phase.
- **Time/failure endpoints:** identify the actual timer/clock or supplied cycle time, units, resolution, and bounds. Repeated calls do not necessarily advance time. A chosen sample point does not justify an additional acceptance-window limit. A missed required sample needs explicit diagnosis; a later correct value cannot prove the missed observation. A missing required response must become a diagnosable failure at the agreed endpoint, not wait for success until framework timeout. Do not invent tolerances or relax deadlines to obtain a pass.
- **Supervision:** distinguish subject response requirements from Preparation, Test Case, Reset/Abort, Suite, and Run Control supervision. Derive parent budgets from relevant child paths, execution pattern, and justified overhead; clarify missing material bounds. Keep estimates distinguishable from established bounds. Use the framework's existing capacity/reservation behavior rather than add unsupported project-side capacity gates; a missing consumer-service bound limits the completion claim, not permission to invent a drain guarantee or free-space requirement.
- **Baseline/reuse:** reset owned DUT, fixture, Assertion, and scenario history to the actual baseline. Readiness reflects required nested reset completion, not merely the enclosing Reset state. Release shared state through its owner protocol, not a non-owner overwrite.

Do not add arbitrary waits or Preparation when the start condition is already controlled. Preparation establishes a prerequisite, not an untested successful execution of the behavior that the test is meant to prove; Ready is startability, not proof that the Completed target was reached. Removing unnecessary constraints must preserve meaningful sample bounds and history. An absent required response cannot simply be dismissed as invalid setup. Conversely, an unbound resource or unusable sample does not establish a DUT defect. Diagnose the distinction through documented framework outcomes; never silently pass an unevaluated claim, skip the intended check or invent a Skip/Inconclusive result.

## Choose Dependencies And Reuse

Use the real DUT and normally real dependencies. A double is a narrow exception for unavailable dependency control/observation, not a replacement for the implementation whose correctness is claimed. Explain the substitution, limits, and independent safeguards against drift. Distinguish unit claims from dependency-integration or actual hardware/environment checks.

When a double is needed, identify the behavior and consumed dependency version it models. Where feasible within the agreed scope, compare relevant boundary behavior against the real dependency using independently justified expectations and retain focused real-binding checks. Repeat applicable comparisons when that behavior or its contract changes; interface compatibility does not prove behavioral compatibility. A deliberately injected fault need not reproduce ordinary real-device behavior. Do not mirror the whole dependency merely to claim equivalence. If comparison is unavailable, state the limit instead of claiming compatibility.

Search existing Test Cases, Preparations, and helpers before adding types. Choose the narrowest useful generally reusable, resource-family, or dedicated scope according to stable behavior and actual bindings; do not prefer abstraction for a hypothetical second use. Separate variable stimulus, expectations, limits, and durations from invariant facts. Do not add production fields/seams or unrelated mode switches merely for genericity.

Reuse types without sharing mutable lifecycle state between independent Test Case instances. Concurrent uses need separate scenario progress, Assertions, Preparations, ControlData, and identity. Within one Case, continuous observation or other compatible Assertion-instance reuse follows the [ownership criteria](assertions.md#instance-ownership-and-data-variations); an array of distinct instances does not share that state. Serial scheduling alone does not reset shared resources. Preparation establishes a start condition; it must not hide tested behavior or own a second DUT call.

Where reuse is claimed, review a second suitable binding for unchanged scenario meaning, compatible interface, distinct state and command/reset ownership. Say whether this is source reasoning, native compilation or executed behavior. A hypothetical binding is a design argument, not executed reuse evidence; a source-only task does not authorize new runtime work.

## Implement And Review Agreed Intent

Choose the simplest understandable framework arrangement preserving the agreed observations, isolation and failure attribution, not the fewest Cases, states, instances or source lines. Decide execution structure separately from call/data representation using the [Test Case criteria](test-case.md#choosing-test-states); explicit calls and arrays of distinct instances are alternatives without a universal preference. Resolve interfaces from matching framework resources and declarations; surface discrepancies instead of inventing blocks or parameters. Templates are scaffolds, not authority for behavior or timeout values.

Preserve the consuming project's existing structure and integrate owners in their appropriate locations. For first-time setup or an unclear/missing structure, propose a concrete owner hierarchy, folder placement and any Software Unit arrangement and agree it with the user before creation. Do not create a separate hierarchy or require/exclude Software Units by default; already applicable project rules or an agreed structure do not need another approval. Apply the included general guidance to actual target symbol visibility, Mastercopy destination context and constant scope; these are not alternative test-selection policies.

Review the actual scenario against its stated or already agreed purpose before judging its individual operations:

- Identify whether it checks normal operation, deliberately stimulates invalid input/a fault, or protects an invariant. Read its starting condition, intervention, call/sample sequence, expected observation and expectation basis together. Do not infer the purpose from an isolated assignment or repeated-looking read, and do not require new per-scenario fields or another worksheet.
- Evaluate against that purpose. A deliberate negative test need not preserve the normal operating conditions it intentionally violates when the expected response has an accepted basis. For example, a normally fixed setting can be deliberately invalidated to check specified rejection/error handling. Intention alone does not justify arbitrary out-of-contract Expected values, unsupported bindings, or waiving framework, fixture-ownership or access constraints. Keep genuinely missing expected behavior unresolved.
- A deliberately protected invariant remains a legitimate observation even when source or execution-model reasoning already explains it. Reading plain outputs twice can intentionally protect the absence of read-triggered processing; source-obvious behavior alone is not a redundancy finding. Apply the proportional-selection questions to the actual purpose and observations, not a requirement that every test expose a currently suspected implementation defect or require complex execution.
- Before reporting a confirmed defect, identify the concrete contradiction, supporting requirement/source and consequence. Distinguish requirement conflicts, DUT defects, fixture mistakes and missing evidence from optional consolidation, cost or readability tradeoffs. Similar-looking steps, an alternative grouping or a low-cost invariant do not by themselves establish a defect. Propose an optimization only on its concrete merits; do not silently remove an agreed check or reclassify a legitimate scenario to enforce a personal preference.

Review independent expectations, stimulus/call/sample ownership, failure endpoints, lifecycle metadata, result aggregation, finalization, reset and reuse under that interpretation. Reconcile meaningful coverage and actual duplication together; these review protections do not authorize unjustified matrices or automatic preservation of every added test. Ask the user only about genuinely missing or conflicting intent/integration facts that change the outcome or arrangement. Do not request renewed justification when purpose and expected behavior are already clear or agreed.

The skill does not select an IDE/MCP access route or grant permission to import, save, compile, download, or control a runtime. Those operations follow the consuming project's engineering workflow. Source review, native compilation, runtime observations, and demonstrated fault detection provide different evidence; catalog or wording checks do not replace them.

When evaluating the skill, preserve the initial proposal and distinguish supplied scenarios, independently derived scenarios, and feedback-driven changes. A collaboratively refined passing application does not prove independent first-pass test selection.

## Installation And Compatibility

Obtain `s7unittest-framework-authoring-<skill-version>.zip` from an available release or Package Registry. It includes the required general SCL coding and review resources for implementation as well as test derivation; no other installed skill or external checkout is required. Repository sources do not imply a published release exists.

The skill has an independent package version and declared framework compatibility. Check `package-manifest.json` and `references/framework-model.yaml` against the consumed framework version. Verify the manifest's `payload` hashes and `resourceSources` identities for the included general guidance; equal version strings alone do not establish matching content. Do not mix catalogs, templates or resources from different package sets. Development does not itself increment versions or authorize publication.

Install the complete `s7unittest-framework-authoring` directory using the assistant host's skill mechanism. For Codex, place it below `$CODEX_HOME/skills/` and verify discovery in a new session; other hosts use their own installation paths and discovery procedure. Package identity and resource-integrity requirements remain the same.

When updating an existing installation, compare the complete file inventory and hashes with the validated packages, including unexpected old files. Extracting with overwrite alone does not remove obsolete guidance. Remove only identified obsolete package files from the selected Authoring skill directory, preserve unrelated skills and host configuration, and repeat the comparison. Recheck discovery and a representative authoring request after installation.

The repository-local Self-Test skill adds namespace, internal DUT, existing owner-integration, and Mirror constraints for this library's own tests. It is not part of the general package and must not duplicate general catalogs or templates.

## Related Guides

- [Framework model](framework-model.md)
- [Run Control authoring](run-control.md)
- [Test Suite authoring](test-suite.md)
- [Test Case authoring](test-case.md)
- [Preparation authoring](preparation.md)
- [Assertion authoring](assertions.md)
