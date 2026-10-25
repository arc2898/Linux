# Universal Package Manager styling

EVERLUMEN integrates the real UPM project at https://github.com/arc2898/Universal-Package-Manager. The shell button opens the UPM CLI in a terminal. The wrapper paints a neon title and streams UPM output through a color filter for status, warning, errors and manager tags, while preserving UPM's exit status. It does not reimplement package selection or package operations.

Check with everlumen-doctor. To build UPM locally, install Go then run ./install.sh --bootstrap-upm. The bootstrap clones upstream, downloads Go modules, runs tests and go vet, builds a user-local binary and reports its version.

On Arch, the dependency installer bypasses UPM's current Pacman adapter, which uses a standalone pacman -S command. The theme's fallback uses pacman -Syu --needed instead, avoiding the partial-upgrade path.
