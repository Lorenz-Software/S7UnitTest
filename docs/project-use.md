# Project Use And Validation

The publication contains the archived framework project as `Project/S7_UnitTest.zap21`. Use TIA Portal V21 to retrieve it into a separate working directory. The publication does not contain a VCI source tree or the development repository's automation environment.

## Supported Execution Scope

The framework supports unit testing standard (non-fail-safe) PLC logic in PLCSIM Advanced. Testing fail-safe (F) blocks is outside the supported scope. The current PC-side execution workflow does not provide an F-software download path; successful execution and CI integration for F-block tests are therefore not guaranteed. The framework does not provide functional-safety validation or certification.

An F-capable CPU or a successful engineering compilation alone does not establish support for testing its F program. Adding F-block support would require a separately designed and validated engineering, download, execution and automation workflow; it is not enabled by including an F station in the reference project.

## Repository Implementation

The logical architecture is independent from concrete TIA software-unit names. In the provided TIA project, the framework and Self-Test roles are:

- `03_Handling`: reusable UnitTest framework and handling implementation.
- `90_UnitTest`: dedicated PLC-side UnitTest usage and framework self-test area.

The `90_UnitTest` area is intentionally separate from reusable framework implementation. It represents the project-local UnitTest execution area rather than an application production implementation area.

## Library And Project Roles

The archived project provides the framework implementation and its Self-Tests. The separately supplied native library provides reusable mastercopies, not the concrete Self-Test application. See [Library Usage](library-usage.md) and the [architecture](framework-architecture.md#library-dependency-boundary).

## Compile The Project

Compile the provided PLC software in TIA Portal. For a complete validation, use a complete software rebuild and inspect the diagnostic list; do not substitute an unchanged incremental result for a full-build result.

Use scoped or incremental compilation during normal editing. A successful incremental result with no newly compiled blocks does not establish that the complete software is warning-free. Report the compilation scope and whether blocks were actually compiled; do not replace earlier warning evidence with a later empty incremental result.

Inspect the complete diagnostic list, including warnings from intermediate imports and builds. Classify warnings as introduced, pre-existing or unresolved, and retain their artifact, location and message until corrected or explicitly accepted by the owner. A clean-build claim requires an actual complete rebuild and reviewed diagnostics, not merely a successful tool response.

## Execute And Observe

The supported execution environment is PLCSIM Advanced. Use the external runner's supported load/start workflow for the compiled application. The framework repository supplies the PLC-side application and its contracts, not the PC runner implementation or a ready-made CI environment.

The PLC-side UnitTest application owns startup initialization. After PLC startup, download, or restart, Run Control must reach a reset-defined base state through PLC-side reset handling before normal start processing is expected.

An external runner may still request reset explicitly, but a CI-triggered run must not depend on the external runner issuing the first reset only to make the PLC startup state valid.

Run Control must be ready before a normal Start request. Use the existing [Run Control integration](authoring/run-control.md#startup-initialization) and [communication contract](../contracts/plcsim-advanced-communication-contract.md) rather than inventing another command interface.

For deliberately PLC-only diagnostics, follow the [optional consumer guidance](authoring/run-control.md#optional-plc-only-diagnostic-consumption). It is not a replacement for complete PC-side result evidence and must not run alongside the PC consumer.

## Interpret Validation Results

Compilation, selective library-consumer compilation, framework Self-Test execution and complete event-stream evaluation establish different facts. See [Self-Test Coverage](selftest-coverage.md) for the maintained coverage model and limits, and [event-stream semantics](../contracts/event-stream-model-contract.md) for result evidence.

## Available Tooling

The supplied [SCL import indentation helper](../tools/scl/README.md) prepares structurally tab-indented source for TIA V21 import. It includes an offline test and does not operate TIA or the PLC.

Use TIA Portal for the archived project. The supplied [Authoring distribution](authoring/ai-assisted-framework-authoring.md#installation-and-compatibility) supports test derivation and implementation. The native library and HTML help are already prepared artifacts. No public build or generator command is supplied that requires the excluded VCI tree or an internal MCP setup.
