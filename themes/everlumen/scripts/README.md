# Operational scripts

- doctor.sh: read-only OS-family, binary and session check.
- install-dependencies.sh: prompt-gated UPM-first/native fallback, optional GUI utilities and safe Arch transaction path.
- fallback-quickshell.sh: Nix user profile, then user-local source-build attempt.
- bootstrap-upm.sh: clones the actual UPM Go source, runs tests and vet, and builds to the user-local bin.
- everlumen-upm.sh: neon title wrapper that delegates all commands to real UPM.
- build-wallpaper.sh: renders the SVG artwork to PNG using available local tools.
- smoke-test.sh: offline script syntax, palette JS, JSON/SVG and disposable-HOME installer checks.

These checks cannot replace a live test on the target compositor, Qt build and desktop session.
