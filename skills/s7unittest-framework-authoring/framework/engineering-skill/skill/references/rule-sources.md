# Resolve Engineering Rules And Evidence

Resolve sources before deriving implementation choices. A skill version, familiar filename or installed folder alone does not establish the current project's applicable rules.

## Included Rules And Package Identity

The [general S7 styleguide](s7-styleguide.md) is part of this skill and is the canonical general coding source. Resolve it relative to this reference in both a source checkout and an extracted package. No external repository or separately installed styleguide is required. The consuming project's instructions identify its refinements, behavior/interface contracts and engineering workflow; those are project inputs, not another general-styleguide dependency.

For an explicitly selected package, read `package-manifest.json` at that package's skill root. Its `payload` records the distributed files and SHA-256 hashes. The Engineering package identifies its guide through `generalStyleguide`; a standalone Authoring package includes these references as resources and records their canonical-source mapping through `resourceSources`. Use the selected package's own entry point and manifest, not an assumed sibling skill. Verify required files and their declared identities/hashes, including the entry point's skill name/version. An entry point alone is not a verified complete package. If required guidance is unavailable, report the affected gap before claiming compliant implementation; do not search an external checkout, invent missing rules or silently switch to an older global installation.

Apply the actual consuming project's rules, not the framework repository's family, publication settings, namespace or data roles by default. Ordinary SCL engineering needs general guidance and its own project context, not UnitTest catalogs/contracts. Where multiple selected skills supply derived snapshots of the same guidance, establish that their identities agree; a newer timestamp or convenient wording is not conflict resolution.

## Authority By Responsibility

| Source | What it supplies |
| --- | --- |
| Accepted requirements and owner decisions | Intended behavior, input/configuration domains, external effects, priorities and allowed changes. |
| Applicable contracts and actual interfaces | Stable fields/types, API and lifecycle/ownership obligations. An implementation inconsistent with a contract is a finding, not a replacement specification. |
| General styleguide and project refinement | Coding requirements, declaration/attribute choices and supported representations with their stated limits. |
| Actual source, callers, dependencies and target configuration | Current behavior, technical bindings and relevant risks; observed output alone does not establish intended correctness. |
| Applicable Siemens documentation and bounded native qualification | Instruction semantics and technical capabilities for the actual CPU, TIA version, access mode, datatype and format. |
| Project workflow and agent instructions | Access authority, tool/target selection, before-state handling, native operations, export/archive responsibilities and protected paths. |
| Domain authoring skill or overlay | Task-specific design/application method, such as UnitTest composition and local Self-Test isolation. |

Read the relevant content, not just a heading or search hit. If output was truncated, retrieve the needed section in a bounded form before relying on it. Separate specified behavior, observed behavior, documented capability, native evidence and unresolved information in consequential decisions. No fixed worksheet is required.

## Use Applicable Technical Evidence

Check whether a representation is documented, natively qualified within a matching context, or still open. Preserve distinctions between accepted syntax, stored source, effective properties and runtime behavior. A successful import on another CPU/context or a serializer omitting a property proves neither universal support nor rejection.

Consult available authoritative instruction documentation for consequential technical uncertainty. Do not substitute guesswork or a request for blind user confirmation. Where documentation/evidence cannot establish a required fact, state exactly what remains unknown and agree an authorized qualification path under the project workflow. A source-only draft may explicitly retain that limit; it must not be presented as a verified native result.

For unfamiliar syntax, instruction bindings or import representations, follow [qualification before replication](source-authoring.md#qualify-uncertain-constructs-before-replication). A matching checked example must match the actual object/declaration context and relevant target/toolchain conditions, not merely use a similar keyword. Do not infer SCL acceptance from another IEC dialect, a host language or a different import route.

## Select Only Relevant Guidance

For generation, resolve the general guide's interfaces, declaration/expression contexts, metadata, attributes, type/conversion, cyclic execution and readability sections as applicable. Then apply the consuming project's refinement and relevant contracts. For changes, also read the exact existing artifact and affected dependencies/consumers before deriving replacements. For domain code, preserve the selected framework's actual call/order/result contract; a general cyclic-code preference is not a reason to replace it.

Stop for owner alignment when authoritative sources conflict, the intended external behavior is missing, or the proposed resolution changes a policy/interface beyond scope. Do not turn an available technical fact, ordinary implementation choice or unsupported evidence claim into a new user-owned product decision.
