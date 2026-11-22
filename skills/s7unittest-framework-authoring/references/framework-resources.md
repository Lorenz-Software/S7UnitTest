# Resolve Matching S7 Framework Resources

Use this reference before framework implementation. Select one coherent resource set; do not mix an installed skill's catalogs with another checkout's templates or an unrelated library version.

## Packaged Use

An extracted package has `package-manifest.json` beside `SKILL.md`. It declares the source `skillVersion`, selected `packageVersion`, exact `frameworkVersion` and payload hashes. A release-candidate suffix belongs to the package version, not a silently changed source version. A dirty snapshot is development evidence, not a tagged release.

Resolve these resources relative to that package's skill directory:

| Need | Resource |
| --- | --- |
| Framework structure and patterns | `framework/docs/authoring/framework-model.md` |
| Derivation and proportional test selection | `framework/docs/authoring/ai-assisted-framework-authoring.md` |
| Run Control / Suite / Case / Preparation composition | Matching guide under `framework/docs/authoring/` |
| Assertion semantics and selection | `framework/docs/authoring/assertions.md` and relevant `references/assertion-catalog.yaml` entries |
| Framework block declarations and classification | Relevant `references/block-catalog.yaml` entries |
| S7 declaration/statement syntax and numeric representations | `framework/engineering-skill/skill/references/s7-styleguide.md#expression-contexts` and `framework/engineering-skill/skill/references/s7-styleguide.md#type-usage-and-conversions` |
| General and UnitTest attribute matrices and qualified import profiles | `framework/engineering-skill/skill/references/s7-styleguide.md#block-and-variable-attributes` and `framework/docs/s7_unittest_styleguide.md#unit-test-artifact-attributes` |
| Normative lifecycle, result, and event behavior | Matching documents under `framework/contracts/` |
| Architecture context | `framework/docs/framework-architecture.md` |

The catalogs are the existing maintained S7 API projection, validated against framework exports during packaging. Public helpers are listed under `blocks`; `integrationExamples` separately records optional project-adapted examples, not callable framework API. Development source-path metadata is omitted from the public catalogs. No PLC implementation, development scripts, reference projects, or local Self-Test overlay is distributed as part of the general skill.

## Repository Use

In the public repository, this same complete distribution is under `skills/s7unittest-framework-authoring/`. Its catalogs and templates resolve relative to that skill root. Authoritative framework guides, contracts and project styles are included under its `framework/docs/authoring/`, `framework/contracts/` and named `framework/docs/` paths above. The package includes unchanged snapshots of the general S7 styleguide and the general rule-resolution, source-authoring and review references. Their distributed paths and payload hashes are recorded in the Authoring manifest's `resourceSources`. Do not create another maintained copy of those documents inside the Authoring skill. No development checkout or additional skill is required.

Inspect only relevant resources. Use `references/framework-model.yaml` for declared compatibility and framework levels, then the relevant block/Assertion entries and owner integration reference. Templates are scaffolds, not the authority for interfaces or required behavior.

## Included SCL Guidance

For SCL implementation, changes or technical source review, read the relevant general references from the selected resource set:

| Need | Packaged resource |
| --- | --- |
| Rule authority, context and evidence | `framework/engineering-skill/skill/references/rule-sources.md` |
| Typed expressions, representations, attributes and cyclic implementation | `framework/engineering-skill/skill/references/source-authoring.md` |
| Independent source review, stored values/properties and diagnostics | `framework/engineering-skill/skill/references/review-and-verification.md` |

The paths above refer to bundled files, not another installed skill. No Engineering entry point, companion ZIP, external checkout or global skill lookup is required.

Verify the Authoring manifest's `payload` hashes and `resourceSources` mappings for all four general references, including the styleguide. The package validator compares the snapshots byte-for-byte with their canonical sources and rejects missing, changed or incorrectly mapped resources before materializing an isolated layout. This validation belongs to package preparation; using the standalone skill does not require a development checkout. Equal version strings alone are not content identity. Missing required guidance leaves the affected implementation/review claim unresolved; it is not permission to invent a replacement or demand another installed skill. Pure scenario analysis can continue where independent of that gap.

Use the included source-authoring and review references for typed expressions/ranges, supported source contexts, declaration attributes and native evidence, applying the general styleguide and actual project's refinement. Styleguides still own the policy and qualification limits. The UnitTest layer preserves accepted stimulus/Expected meanings, framework-derived state relationships, required scaffold properties and owner semantics; a valid framework relationship does not waive technical engineering requirements. These methods supply no competing attribute matrix or overrides the project's access authority.

## Compatibility And Limits

Keep the selected skill path and resource provenance explicit. Compare declared skill/framework versions across the entrypoint, model, and package manifest when present; compare the framework identity with the library actually consumed. Version equality alone cannot establish identical working-copy content. Missing or conflicting resources are an information gap, not permission to invent an API or fall back silently to another installation.

Source review, successful packaging, native compilation, and runtime observations support different claims. Resource selection does not define engineering access procedures or authorize installation, deployment, or PLC operations.
