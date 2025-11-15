# TODO – `analytics_gen`

## Active Work Items
- [x] Clean the export output directory before each generation so toggling formats never leaves stale artifacts.
- [x] Emit the generated tracking plan as runtime metadata (`Analytics.plan`) so apps can inspect events/domains without re-parsing YAML.
- [x] Debounce watch mode regenerations so a single file save only triggers one code run across repeated file-system events.
- [x] Back up each new guarantee with targeted tests and update the README so users know about the new behaviors.

## Notes
- Tests should cover the new export cleanup and analytics plan metadata, plus a focused unit test exercise for the new watch scheduler.
- README updates need to mention the runtime plan constant and the refined watch/export behaviors.
