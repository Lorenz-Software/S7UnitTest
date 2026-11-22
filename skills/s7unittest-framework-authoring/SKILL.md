---
name: s7unittest-framework-authoring
description: Derive and review behavioral unit-test plans for existing S7 PLC blocks, then implement agreed scenarios with the S7 UnitTest framework. Use for test selection, reusable Test Cases and Preparations, or framework-conforming TIA Portal SCL. Does not define production requirements or operate the engineering environment or PLC runtime.
metadata:
  version: "1.1.1"
  framework_compatibility: "2.0.0"
---

# S7 UnitTest Framework Authoring

Support two entry points: understand an existing DUT and derive useful tests, or implement/revise already-defined test intent. Do not force rediscovery for an implementation-only request. Stop at a plan when only analysis was requested.

Select observable scenarios before framework Assertions. For implementation, prefer the framework's Sequencers, Orchestrators, status helpers, result helpers, event helpers, and Assertions over locally duplicating their behavior.

For SCL generation, changes or technical source review, apply the general source-authoring and technical-review resources resolved through [framework resources](references/framework-resources.md). They are included in the standalone package; no other installed skill or external checkout is required. Preserve their full type/range, source-context, attribute, cyclic-behavior and verification guidance together with this skill's test intent, independent expectations and framework composition. Pure scenario analysis does not require a native operation or loading unrelated implementation guidance.

## Authoring Boundary

- Treat accepted requirements, owner decisions, and already-agreed test intent as the basis for expectations. Do not silently redefine them from current output, comments, or passing existing tests.
- Inspect the DUT, callers, and relevant dependencies to explain behavior and derive candidates, not to declare observed behavior correct or modify production code.
- Ask a focused question when missing intent or integration facts change an expectation, resource effect, execution order, concurrency, or feasible observation. Do not ask the user to reconfirm an already clear or agreed purpose merely because another arrangement would also be possible. Continue independent work; do not turn ordinary parameter choices into three fixed approval gates or require a machine-readable plan.
- Do not invent framework blocks, interfaces, constants, states, results, or events. Resolve them from the catalogs.
- Do not use entries listed under `internalBlocks` as project-facing authoring building blocks.
- Authoring does not authorize engineering access, installation, deployment, online control, or resource writes. Those operations follow the project's own permissions and workflow, not procedures embedded in this skill.

## Understand The Subject And Evidence

For source-based analysis, read [block and dependency analysis](references/block-analysis.md). Identify the actual subject, inspected revision/source set, public boundary, requirements, callers, configuration, and dependencies relevant to the requested behavior. Missing bodies or integration facts limit the affected conclusions, not all independent analysis. Do not infer purity from FC or statefulness from FB alone.

Keep four evidence kinds distinct:

- **Specified:** expected behavior supported by accepted requirements or contracts.
- **Observed:** behavior found in source, callers, or existing tests.
- **Proposed characterization:** observed behavior proposed for intentional preservation, pending owner acceptance.
- **Unresolved:** missing/conflicting intent or integration facts, including explicitly labeled hypotheses.

A current return value is not an independent correctness criterion. Report conflicts between requirements and implementation. Trace expectations to specified behavior, an owner decision, or an accepted characterization; do not encode an unresolved hypothesis as an acceptance test. An independent relationship or invariant is not sufficient by itself if it still permits the relevant wrong result.

## Select A Proportional Test Plan

Start with essential observable questions and material risks, considering both defect consequences and credible likelihood in the implementation/dependencies. Consolidate candidates before presenting the recommended core; methods, branches, Assertion types and test counts do not define that core. Consider applicable partitions, boundaries, feasible decisions, state/history, call order, configuration, timing, initialization, and recovery. Do not impose every technique on every subject. For the complete selection procedure and examples, resolve the matching guide's `#prioritize-a-proportional-plan-and-explain-omissions` section through [framework resources](references/framework-resources.md).

For each meaningful scenario, establish its intent basis, starting condition, owned stimulus, call/sample sequence, independently justified expected observation, and finite completion/failure endpoint. Include isolation, reset, and reuse where relevant. A compact explanation or table is sufficient; no fixed schema or per-row worksheet is required.

For each additional scenario group or data variation within it, ask: which relevant wrong behavior could it distinguish that the selected scenarios do not already address? A distinct boundary, history/failure path or credible independent implementation/regression risk can justify it; another equivalent value alone cannot. Compare behavior, execution/history and failure mechanisms across input and implementation variants. Where a shared pattern is supported, use representative coverage plus targeted checks for genuine precision/range, storage/conversion or separate implementation differences. Similar-looking source alone does not prove equivalence, but do not demand exhaustive equivalence proof merely to avoid arbitrary repetition. Covering input classes and parameter positions does not automatically require their Cartesian product; justify further combinations by interactions or other material fault distinctions. Explain representative choices and limits briefly, not through a mandatory per-row worksheet or an executed fault challenge for every test.

Group data variations in one coherent scenario when a failing observation remains identifiable. Retain independently meaningful history, ownership, and recovery scenarios. Before expanding an already represented path, review the whole plan for missing essential valid behavior, relevant boundaries and observable outcome classes, as well as error paths. More variations of a represented behavior do not compensate for a material gap elsewhere. Stop adding tests when essential behavior and selected material risks are addressed and further cases add no material distinction. A known relevant regression can still justify a specific check in an already represented outcome class. Mark material gaps and their consequences explicitly; a small plan does not make them covered. Do not use fixed quotas, one test per branch, all-combinations mandates, or mandatory optional-test lists. Do not silently reduce already-agreed implementation scope.

Derive expectations independently from requirements, accepted examples, or justified relationships, not by copying the tested algorithm into Expected calculations. Use the real DUT and normally real dependencies. A double is a narrowly justified dependency substitute, never a replacement for the subject whose behavior is claimed; record its limits and appropriate checks against drift.

Keep the information being checked explicit. Prefer direct actual/expected Assertions for direct value comparisons. For a meaningful composite condition, prefer a named Boolean signal whose name states its domain meaning, and decompose it when the expression still compresses independently meaningful information. A name alone does not make an overloaded predicate clear. Preserve readable expectations and useful failure attribution; reducing redundant scenarios is not a reason to minimize Assertions or hide observations. Select the Assertion and instance arrangement also by the resulting PC-side finding: supported name/resource/state context and family message should locate the check, explain the expectation and expose the relevant actual deviation. Do not discard typed values into a Boolean verdict when a matching direct Assertion preserves them, infer root cause from a verdict, or weaken acceptance to hide rendering limits. Do not impose one Assertion per variable or ban Boolean composition by syntax.

Before implementation, separate relevant given conditions supported by requirements or inspected integration facts, conditions the test will establish, and unresolved assumptions. An unknown bound or missing prerequisite remains unresolved; calling an invented capacity, delay or margin conservative does not justify making it mandatory. State the affected claim and obtain consequential missing facts rather than turn an unsupported assumption into a requirement. Use the matching guide's observation-condition guidance through [framework resources](references/framework-resources.md).

For cyclic behavior, distinguish stimulus, DUT execution, and sampling order. Identify the actual time source and units; repeated calls do not necessarily advance time. A command issued after an external DUT call cannot be observed as already processed on that call. Apply `ObserveFirstCycle` only as supported by the selected Assertion. Preserve the collection/explicit `Evaluate` distinction and do not finish before the intended check has evaluated. A held Passed value does not by itself prove that the intended new sample or collection was evaluated.

Choose execution structure from the behavior, call/observation order, isolation, diagnostic needs and evidenced costs, not from desired code or instance counts. Separately choose explicit calls or arrays of distinct instances with aligned data and bounded loop calls for readability; arrays neither imply shared Assertion state nor cross-cycle progression. Prefer framework multi-test-state sequencing for successive stimulus/observation phases spanning invocations, rather than hiding another phase controller inside a single test state. Single-state checks remain appropriate without a separate multi-invocation phase sequence; justify an internal phase controller or cross-cycle data iterator rather than defaulting to either. Choose meaningful phases, not one state per PLC cycle or data row; see [execution-pattern selection](references/s7unittest.md#choose-test-state-granularity).

An absent expected response must have a diagnosable unsuccessful endpoint, not wait indefinitely for success until framework timeout or be dismissed as a fixture-precondition failure. Conversely, an unusable observation does not prove a DUT defect. Use documented framework outcomes, not an invented Skip/Inconclusive result. Keep a subject response deadline distinct from the enclosing supervision timeout; a selected sample point does not justify another acceptance bound. Do not invent timing limits or tolerances to make a scenario pass.

Reuse types without sharing mutable lifecycle state between independent or concurrent Test Case instances. Within one Case, choose separate Assertion instances or compatible repeated observation through the documented ownership criteria; do not confuse type reuse with instance reuse. Use a generally reusable, resource-family, or dedicated arrangement as justified; do not add production seams, test-only UDT fields, unnecessary Preparation, or a fixture framework merely for genericity.

For the human-facing explanation and review questions, resolve the matching AI-assisted authoring guide through [framework resources](references/framework-resources.md). The following implementation workflow consumes settled intent; it does not replace subject analysis or authorize unresolved expectations.

## Load Only Relevant References

Use progressive disclosure. Do not load every catalog in full unless the task genuinely requires it.

1. Read `references/framework-model.yaml` for the requested framework level and the lifecycle concepts it uses.
2. Search `references/block-catalog.yaml` for the selected Sequencer, Orchestrator, helper blocks, UDTs, and constants. Read only the matching entries and their dependencies.
3. For Test Case authoring, search `references/assertion-catalog.yaml` by assertion family, checked condition, and value type. Load only plausible candidates before selecting an Assertion.
4. Read the rules from `references/validation-checklist.yaml` that apply to the selected owner level, catalog entries, and template.
5. Use `references/structural-validation-handoff.md` for source-evidence review of call order, ownership, reset, and timing. An analyzer is optional; inspect source or request the missing evidence. Do not substitute search hits or regex matches for semantic SCL review.
6. Select exactly one starting template from `assets/templates/` for each requested owner block.
7. Resolve block names and interfaces from the matching catalogs and authoritative framework declarations/contracts. Surface discrepancies instead of silently choosing a stale catalog. Treat templates as implementation scaffolds, not interface authority.

## Implement And Review

For framework composition, load [S7 framework integration](references/s7unittest.md). It preserves owner-pattern selection, timeout derivation, templates, lifecycle/Assertion handling, fixture reset, and reuse review. Paths mentioned there are relative to this skill root. Resolve framework guidance and compatibility using [framework resources](references/framework-resources.md); no custom analyzer or engineering-access route is required.

Fit owners into the consuming project's existing structure. For first-time setup or an unclear structure, propose the concrete owner/folder arrangement and any Software Unit placement and align it with the user before creation; do not require or exclude units. Resolve technical namespace, visibility, library-copy and constant-scope decisions through the included general guidance under the agreed structure, not a competing Authoring policy.

Before handoff or a plan review, read each scenario's stated or agreed purpose and expectation basis before judging its stimulus: normal operation, deliberate invalid/fault stimulation, or an intentionally protected invariant. Evaluate setup, intervention, call/sample sequence and expected response against that purpose. A deliberate negative test need not preserve the normal operating conditions it intentionally violates; an invariant is not pointless merely because source or execution-model inspection already explains it. Neither intention alone nor current behavior justifies unsupported Expected values, and test intent does not waive framework, fixture-ownership or access constraints. Use the matching guide's intent-first review procedure through the resolved framework resources.

Reconcile implemented scenarios and data variations with their selected behavioral questions, including additional fault distinction and material omissions, not just Case count or group names. A confirmed finding needs a concrete contradiction and consequence; distinguish it from an unresolved fact or optional consolidation/readability tradeoff. Do not classify source-obvious properties, repeated-looking steps or a different preferred arrangement as defects by themselves. For already-agreed scope, report proposed changes instead of silently dropping scenarios or reopening settled intent.

When reviewing assisted test quality, distinguish supplied scenarios, independently derived scenarios, and revisions after feedback. Preserve the initial proposal when generation is being evaluated. Source review, compilation, passing reference tests, and actual fault detection support different claims; do not report a predicted fault challenge or repeated-run path as executed evidence.
