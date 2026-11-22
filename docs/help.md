# Library API Help

Extract the supplied `s7-unittest-api-<framework-version>.zip` and open `index.html`. The HTML package and native library are supplied release assets; using them does not require the generator or its development inputs.

The API reference covers callable framework blocks, relevant UDTs, global data areas and constants. It describes purpose, interfaces, parameters, return values and necessary usage conditions, including lifecycle/result semantics where needed to use an API correctly. It is not a complete framework, authoring or implementation manual.

The standalone HTML package contains an `index.html` entry, local navigation, search, styles, images and license. It works after extraction without a web server, network dependency, running PLC, TIA session or installed assistant skill. The seven existing Authoring Guides are included as a complementary section with chapter navigation, shared search and guide/API associations. They explain typical application tasks, composition, examples and key pitfalls, not every specification detail. Exact interfaces and relevant parameter/error conditions belong in the API reference; contracts remain the normative development/review basis, not required guide reading or an appendix. Required navigation stays offline.

Examples and editable integration scaffolds do not receive API pages. They may be referenced as examples where useful. Internal implementations are not documented merely because they are delivered. Internal declaration dependencies are described only to the extent needed to understand and use the selected public interfaces; API coverage is not one page per library inventory entry.

## Reference Pages

| Page kind | Content and order |
| --- | --- |
| FB | Name/kind, concise purpose, public interface signature and parameter table in source declaration order, necessary usage/domain/observation/result/error information, relevant local type/constant/API links. No body, private state listing or generated owner/scenario scaffold. |
| FC | The same applicable content plus a separate return section when non-Void. Boolean returns are distinguished from Error/status returns and described by their actual meaning. |
| UDT | Name/purpose and a hierarchical field reference with types, declared defaults, descriptions and relevant ownership notes. Repeated named UDTs are linked rather than copied into every caller page. |
| Global DB | Consumer role and public data paths, declared field types/default references, explicit shipped initialization by path, and necessary ownership/access conditions. Public projections/internal fields are identified; not all storage is writable, visible or completely described. |
| Constant table | Named groups where the existing symbols support them; name, type, declared value and description for each selected constant, with adjustable/fixed meaning from existing rules. Symbolic cross-links retain the existing constants; no enum or API setter is implied. |

## TIA Library Lookup

In the supplied global library, select a documented mastercopy and press Shift+F1. The delivered library contains the matching user-documentation pages and local resources. This library-side lookup does not automatically install help into a consuming project.

The qualified calls worked with the existing TIA language configuration using
the `en-US` help files, without another language directory or a central help
installation. TIA can require a security confirmation before opening local HTML.
Do not suppress that confirmation or change browser security settings. If a call
cannot resolve a file, enable the user-documentation call log in TIA settings
and inspect the actual searched names/directories before changing the mapping.

## Boundaries

The API reference describes selected public interfaces, not every delivered implementation or example. Authoring Guides explain typical tasks; the [contracts](../contracts/README.md) remain available for exact interface semantics. No central documentation installer or automatic consumer-project help transfer is provided.

See [Library Usage](library-usage.md) for mastercopies and [Project Use And Validation](project-use.md) for the archived project.
