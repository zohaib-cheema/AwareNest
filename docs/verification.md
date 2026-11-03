# Companion journal verification

The tested flow is account creation, private journal entry, persistence after reload, mood filtering, deletion, sign out, and sign in.

The app passed browser checks at 1487 by 1057 and 390 by 844. The in app browser failed to attach, so verification used Playwright with an isolated Chrome session. Page identity, meaningful content, console health, and the absence of a framework error overlay were checked. The initial unauthenticated session check returns an expected HTTP 401.

The browser flow also exercised a delayed filter response followed by a different selection. The older response did not replace the newer result. Mobile content stayed within the viewport.

The generated concept and final browser screenshot were both inspected. Comparison points included the white background, evergreen accent, header navigation, heading hierarchy, chart and composer layout, mood controls, notes field, primary button, and recent entry rows. Chart sizing was corrected during the review. The implementation was verified against that visual direction. Sample values, dates, row count, and the mobile single column arrangement vary with data and viewport.

PostgreSQL integration tests cover authentication, account isolation, persistent entries, input validation, weekly averages, missing days, filtering, pagination, and cookie clearing. Python tests cover migration integrity, repeated imports, conflicting snapshots, source preservation, private settings, and exports.

The images use a synthetic local test account and sample notes. No personal journal data was used. The Flutter prototype, native mobile device behavior, reverse proxy deployment, and multiple server instance rate limiting were outside this verification.

The visual concept was generated with the built in image tool. The screenshot in this repository is the running application, not that concept image.
