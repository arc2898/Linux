# Universal Package Manager styling

EVERLUMEN integrates the actual UPM project at https://github.com/arc2898/Universal-Package-Manager. The shell button opens the UPM CLI in a terminal. The wrapper adds a neon banner but forwards commands directly to the real upm executable; it does not replace UPM's package resolution logic.

Check with everlumen-doctor. To build locally, install Go then run ./install.sh --bootstrap-upm. The bootstrap clones upstream, downloads Go modules, runs tests and go vet, builds a user-local binary and reports its version.

On Arch the dependency installer bypasses UPM's current Pacman adapter, which uses a standalone pacman -S command. The theme's fallback uses pacman -Syu --needed instead, avoiding the partial-upgrade path.
