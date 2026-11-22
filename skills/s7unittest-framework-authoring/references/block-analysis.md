# Understand The S7 Block And Its Dependencies

Use this reference for source-based test derivation or white-box review. It supports the evidence kinds in [the skill entrypoint](../SKILL.md#understand-the-subject-and-evidence), not a mandatory analyzer or extra report format.

## Establish The Evidence Boundary

Identify the subject, its revision or reproducible source snapshot, public interface, available requirements, and requested boundary. Separate snippets from complete blocks and actual configured program membership from loose sources. Keep reference-test answers out of an independent derivation exercise.

Read declarations and relevant bodies together. For S7, account for Software Unit/namespace resolution, block-local and global constants, UDT/DB layouts, multi-instance and separate instance DB state, and actual callers/bindings. An identifier, UUID, block version attribute, or successful compilation alone does not identify all behavioral inputs.

Saved VCI sources and a live engineering object can differ; identify which state supports the analysis and report disagreement rather than combining versions. Matching framework/library declarations establish available interfaces, not proof that an unknown installed implementation behaves like unrelated source.

## Follow Execution And Effects

Trace relevant guards, priority, assignments, branches, calls, outputs, and previous-cycle memorization in execution order. Distinguish a command request from its later processing. FC/FB classification alone does not establish purity, retained history, or isolation.

For cyclic behavior, inspect initial values, ordinary execution, disabling/skipped calls, interruption, error, reset, and reuse where relevant. Do not assume Reset, re-enable, PLC Stop/Start, and a newly initialized instance are equivalent; consider relevant retention/configuration without changing attributes.

Identify the actual time source, units, call order, and known bounds. A supplied OB cycle-time value, an accumulated runtime, and an IEC timer are not interchangeable merely because all are expressed in milliseconds. Keep missing task or timer context explicit.

Inspect relevant numeric conversions, overflow/precision limits, string/array bounds, `VAR_IN_OUT`/open-array bindings, and indirect or Variant access where they affect observable behavior. Distinguish normal operating conditions from a scenario's deliberate invalid/fault stimulation before calling an input or sequence out of scope. A specified error response can justify intentionally violating a normal condition; it is not automatically an invalid test. Do not invent unsupported malformed bindings, arbitrary out-of-domain expectations or extra cases solely to increase tests. Apply the entrypoint's intent-first review without weakening fixture ownership or framework execution constraints.

Record externally visible reads/writes and effects: global DBs, I/O, communication, event publication, and delegated operations. Determine what the test can control and observe without changing the production interface. An inaccessible observation is a fixture limitation or open decision, not permission to expose internal state.

## Resolve Only Relevant Dependencies

For each consequential dependency, retain the call/storage location, resolved identity or binding, why it matters, and one disposition:

| Disposition | Evidence |
| --- | --- |
| Reviewed | The necessary body, binding, type, or value was inspected; state what it establishes. |
| Unresolved | Required source, target, version, configuration, writer, or other context is missing or ambiguous. |
| Outside the chosen boundary | Explain why it is excluded and what conclusions that limits. |

Resolve called FC/FB declarations and bodies, nested instance state, shared writers, caller arguments, UDT/DB fields, and symbolic bounds only to the depth needed for the behavior or risk. Separate multiple possible indirect targets when the evidence does not determine one.

For constants, parameters and configured bounds, resolve the applicable value and override in the inspected configuration. A symbolic declaration, default or library API entry does not establish the value used by an unknown consuming project. Do not replace an unresolved expression or parameter with a fixed literal. For external services/libraries, separate declaration evidence, specified behavior, matching implementation evidence and actual execution; none implies the others.

Inventories and catalogs help navigation but are not a complete semantic call graph. Search hits can occur in comments, literals, or unrelated scopes; read surrounding declarations and executable code and respect truncated results. No custom parser is required simply to restate available source facts.

Graphical bodies, unavailable library implementations, ambiguous bindings, or incomplete snippets support bounded conclusions. Name the affected uncertainty and continue independent analysis rather than pretending the missing body is empty or the dependency resolved.

## Return A Proportional Understanding

Explain the subject and inspected source boundary, observable behavior, retained state/time/effects, relevant dependencies, critical risks, and unresolved questions. Cite supporting artifacts and locations, distinguishing serialized-file coordinates from executable-body coordinates when relevant. A shared source identity is sufficient; do not repeat a hash for every statement.

Keep Specified, Observed, Proposed characterization, and Unresolved claims separate. A candidate expectation needs accepted intent before implementation; a source-visible branch only suggests where to examine a useful distinction. Explain the consequence of an open question and what source or owner decision could settle it.

End with useful test implications and explicit coverage limits. A small pure function may need only a short explanation; a cyclic feedback sequencer needs history, call-order, and timeout context. Neither implies a test per branch. Source reasoning, compilation, and runtime observations remain distinct evidence.
