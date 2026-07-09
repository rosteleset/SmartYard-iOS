# Codex Project Rules

- Do not run `xcodebuild` unless explicitly requested.
- If a build check is needed, first ask the user to run the command locally.
- Verify changes using only static analysis: `git diff`, project search, and reading files.
- If a build is required, provide a short command and wait for the user's error log.
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
- For programmatic layout, prefer the local AutoLayoutDSL helpers from `UIStackView+Ext` and `UIView+Ext`.
- Prefer stack-based programmatic layout with `UIStackView.vertical`, `UIStackView.horizontal`, `HSpacer`, `VSpacer`, and `pinSubview`; add arranged subviews with the `UIStackView.vertical(...).add { ... }` / `UIStackView.horizontal(...).add { ... }` builder style when possible; use explicit constraints mainly for fixed sizes, overlays, and cases that stack layout cannot express cleanly.
- When pinning a subview to all edges of its superview, use `pinSubview` instead of `snp.makeConstraints { make in make.edges.equalToSuperview() }`.
- Before creating custom buttons, controls, or repeated UI pieces, check for existing project components such as `SmartYardActionModeButton` and reuse them when they fit.
- In reusable cells, keep `prepareForReuse` focused on lifecycle cleanup such as resetting dispose bags and cancelling async work; do not duplicate UI state that is always set by `configure`.
- For xibless views and cells, separate visual setup from layout setup with clearly marked `setupUI` and `setupConstraints` sections/functions.
- Prefer existing utilities from SwifterSwift and local extensions before adding custom helper code.
