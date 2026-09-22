
# FluidSynth with Emscripten-specific patch

This repository is based on [FluidSynth](https://github.com/FluidSynth/fluidsynth) repository, and contains some changes to build with Emscripten.

The original README is here: [README.original.md](./README.original.md)

## Build (enikey87)

In order to build WebAssembly version of fluidsynth by yourself:
```shell
# Builds libsndfile into ../libsndfile-emscripten; build.sh requires it for the sf3 variants
./build_libsndfile.sh
# All variants of libfluidsynth-X.X.X.js + libfluidsynth-X.X.X.wasm files will be stored to ./dist
./build.sh
```

`build.sh` installs the Emscripten SDK into `../emsdk` if `emcmake` is not on `PATH`.

## Build with Docker (enikey87)

A single command builds every variant into `./dist`:

```shell
docker compose run --rm --build --user "$(id -u):$(id -g)" builder
```

`--user` keeps the artifacts owned by you rather than by root. The image carries a
prebuilt libsndfile (needed for sf3), so a rebuild only recompiles fluidsynth.

## Build (from jet2jet)

> Tested with Emscripten version 3.1.10.

1. (Optional) Update `emscripten/exports.txt`, containing export functions for JS program
    * The script `emscripten/make-exports.js` will update this automatically, gathering functions from `include` directory.
2. Make sure that Emscripten is usable on the current environment
3. Make `build` directory
4. Enter `build` directory and execute `emcmake cmake -Denable-oss=off -DCMAKE_BUILD_TYPE=Release ..`
    * If no other options are specified, and `cmake` is running with `emcmake` (or `emconfigure`), the build configurations are initialized for Emscripten-build mode.
5. In `build` directory, execute `emmake make`

After successful build, `libfluidsynth-<version>.js` will be created at `build/src` directory.

* If `enable-debug` specified on the `cmake` execution (e.g. `emcmake cmake -Denable-debug=on ..`), a map file `libfluidsynth-<version>.wasm.map` is also generated.
    * Currently it seems that it cannot be used.
* If `enable-separate-wasm` specified on the `cmake` execution (e.g. `emcmake cmake -Denable-separate-wasm=on ..`), `libfluidsynth-<version>.wasm` and `libfluidsynth-<version>.wast` are also generated.
    * For AudioWorklet, you cannot use `*.wasm` file directly.
* In Emscripten-build mode, standalone application named `fluidsynth` is not emitted.

## Build static library for Emscripten

Please specify `-D BUILD_SHARED_LIBS=off` on calling emcmake. (e.g. `emcmake cmake -D BUILD_SHARED_LIBS=off ..`)

In this mode, you can also build sources under `doc` directory (e.g. `cd build/doc && make fluidsynth_simple -j16`), although all exportable functions will be exported.

## Usage

Place `libfluidsynth-<version>.js` file to your space and load `libfluidsynth-<version>.js`. After load, almost all FluidSynth API functions are accessible via `Module` object (note that all function names have the prefix `_`).

To use `libfluidsynth-<version>.js` in AudioWorklet, load it into AudioWorklet before your worklet JS file. In your worklet JS file, you can access `Module` object via `AudioWorkletGlobalScope.wasmModule`.

## Miscellaneous

### Per-track audio groups (opt-in)

Set `synth.per-track-audio` to `1` before creating the synth, and set
`synth.audio-channels`, `synth.audio-groups`, and `synth.effects-groups` to the SMF
track count. The setting defaults to `0`: existing stereo playback is unchanged.
Check that setting the option succeeds before using this mode with a WASM build.

This mode assumes the channel layout this fork's SMF loader produces: each track
uses melodic channels 0–8 and drum channel 9, and is remapped onto ten private
MIDI channels, so at most 25 tracks fit into the default 256 MIDI channels. Each
track keeps its own drum channel across reset and seek. Channel controllers,
program changes, and pitch bends remain within that track. Audio and
reverb/chorus are routed to the same track group.
Render all groups with `fluid_synth_process`; fewer output groups intentionally
wrap/mix according to the normal FluidSynth group semantics. As before, callers
must zero output buffers before rendering. General SMF channel layouts and
device-specific SysEx channel reassignment are not supported by this mode.

* Currently only several APIs are tested. Some APIs such as for drivers may not work.

## License

This program and all source codes, including the original FluidSynth program, its source codes, modifications of FluidSynth source codes for building library with Emscripten, and sources codes used only for building `libfluidsynth-<version>.js`, are licensed under [GNU Lesser General Public License (v2.1)](./LICENSE) (LGPL v2.1).
