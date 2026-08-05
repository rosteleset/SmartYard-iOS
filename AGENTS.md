# Codex Project Rules

- Do not run `xcodebuild` unless explicitly requested.
- If a build check is needed, first ask the user to run the command locally.
- Verify changes using only static analysis: `git diff`, project search, and reading files.
- If a build is required, provide a short command and wait for the user's error log.
- Push the `Sesame` branch only to the `gitap` remote.
- Push the `Teledom(OEM-version)` branch only to the `PUBLIC` GitHub remote.
- Use this commit message format:

  ```text
  <type>: <short description>

  <description of the problem or short feature description>

  - <optional commit body item>
  - <optional commit body item>
  ```

- Use only these commit types:
  - `build`: build system changes
  - `ci`: CI configuration changes
  - `docs`: documentation-only changes
  - `feat`: new functionality
  - `fix`: bug fix
  - `chore`: performance improvement
  - `refactor`: code refactoring
  - `style`: formatting and indentation
  - `test`: adding tests

- In RxSwift subscriptions, prefer `subscribe(with: self) { owner, ... in ... }` over `subscribe(onNext: { [weak self] ... })` when the subscription captures `self`.
- Prefer ternary operators over `if`/`else` when the expression stays readable and the conditional is simple.
- Follow the Google Swift Style Guide by default, unless existing project conventions or SwiftLint rules require otherwise.
- Follow the project programmatic-layout rules below.

## Programmatic layout rules

- Build ordinary rows and columns with `UIStackView.vertical(...)` and `UIStackView.horizontal(...)`. Use their `spacing`, `alignment`, `paddings`, and `arrangedSubviews` parameters instead of recreating equivalent constraints.
- Add static arranged subviews with the local builder: `stackView.add { ... }`. For a dynamic array, use `stackView.add(views)`. Use `insert(at:block:)` only when insertion at a specific arranged-subview index is required.
- `UIStackView.add { ... }`, `add(_:)`, and `insert(at:block:)` return `UIView`, not `UIStackView`. When stack-specific access is needed after population, create the stack first and call `stackView.add { ... }` as a separate statement.
- Express non-uniform gaps inside stacks with `VSpacer(value)` and `HSpacer(value)`. Use `VSpacer()` or `HSpacer()` for flexible space. Do not use `setCustomSpacing` or `addArrangedSubview(_:customSpacing:)` in feature layout.
- Use `UIStackView`'s `paddings` parameter for stack layout margins. Use `addBackground(color:cornerRadius:cornerMask:)` when a stack itself needs a background.
- Pin a child to all four parent edges with `pinSubview`. Use `.init(inset: value)` when all four insets are equal; spell out `UIEdgeInsets(top:left:bottom:right:)` only when they actually differ.
- Use `view.insets(...)` or `view.add(insets:)` when a view needs to be wrapped in an inset container before it is placed in a stack.
- Add a subview with SnapKit constraints through `addSubview(view) { make in ... }`. Use direct `snp.makeConstraints` only when the view is already in the hierarchy.
- Use SnapKit mainly for fixed control/icon sizes, aspect ratios, overlays, centering, and relationships that stack layout cannot express cleanly. Do not introduce `NSLayoutConstraint.activate`, anchors, or `translatesAutoresizingMaskIntoConstraints` in new feature layout when the local DSL or SnapKit can express the layout.
- Do not hardcode the overall width or height of content views, modal content, cells, or screens. Derive container size from safe/readable guides and intrinsic content. Fixed dimensions remain acceptable for genuinely fixed controls, icons, and bounded media.
- For xibless views and cells, keep visual configuration in `setupUI` and hierarchy/layout construction in `setupConstraints`.
- Before creating custom buttons, controls, or repeated UI pieces, check for existing project components such as `SmartYardActionModeButton` and reuse them when they fit.
- In reusable cells, keep `prepareForReuse` focused on lifecycle cleanup such as resetting dispose bags and cancelling async work; do not duplicate UI state that is always set by `configure`.
- Prefer existing utilities from SwifterSwift and local extensions before adding custom helper code.

## Version-up and What's New workflow

- Treat every `v-up` as a release-preparation trigger for `What's New`.
- Work from the target operator branch. Find the latest previous `v-up` reachable from that branch, then review the exclusive commit range up to the version being prepared.
- Convert the range into user-facing pages for that specific operator. Include notable features, interface improvements, and meaningful fixes; do not impose an arbitrary small page limit.
- Give every page a localized title, message, and SF Symbol. When a feature depends on an operator-provided service, append `*` to its title and provide a localized `footnote` explaining that availability depends on the operator's support and connected services.
- Generate `What's New` content and translations for every app locale supported by the target build. Operator branches may require different pages and wording; do not copy another operator's release notes without checking its commit range and available services.
- Keep release-specific `What's New` pages, release versions, and translations as local build-preparation artifacts. Never stage, commit, or push them. Only reusable `What's New` infrastructure belongs in the repository.
- Before the release build, verify that the generated release version matches `MARKETING_VERSION` and that every generated page has all required translations. After the build, restore or remove the generated release-specific changes.
