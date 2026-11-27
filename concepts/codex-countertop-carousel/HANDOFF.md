# Carousel handoff

Updated 2026-11-27. Owner/executor: Codex in the originating 3D Print chat. Repository: `mlwhite0907/DIY-Supplement-Dispenser`; branch: `codex/carousel-concept`; folder: `concepts/codex-countertop-carousel/`. Claude's current implementation is separate. Do not modify or merge into it as routine synchronization.

## Current requirements, in priority order

1. Appearance should be very close to the Instagram reel, not a generic cylindrical hopper carousel. Use the satin/champagne fronts, continuous circular silhouette, individual black scalloped caps, black rims, rectangular windows, horizontal ridged thumbwheels and top handle.
2. **12 total, six wide wedge cartridges per level**, two detachable independently rotating tiers. Owner removed the original fixed ten-count requirement and explicitly rejected 24. Thirteen would be tolerated if it improved proportions, but symmetric six-plus-six is the current decision.
3. Individually removable, positively retained cartridges, an individual dial, and a closed condition for handling. Increase useful powder capacity relative to spice jars. Exact grams must be verified by weighing, not assumed from click count.
4. Countertop first; a single tier may eventually mount under a cabinet after the mounting structure is engineered and tested.
5. Show actual 3D model renders for visual feedback. Keep the repository updated so another agent can continue from the files.

## Current implementation and proof

`prototype-v01/cad/appearance.scad` is the current visual source. Its README and build script define the component envelopes and renders. `validation/mesh-report.json`, when present, proves the individual exports were checked, not that the device works. The older `carousel-layout.scad`, SVG and development plan are archived five-per-tier studies. They are superseded by this handoff.

**Latest proof:** six renders generated; nine single-component closed meshes passed orientation/positive-volume checks and 256 mm component-envelope checks. The exported GLB has 84 named objects and passed a reload/count/bounds check, with Y up for glTF. `prototype-v01/validation/build-evidence.json` preserves the exact geometry commit, job and output hashes. README previews and downloadable outputs are now present. No dispenser operation, assembled interference check, load rating or physical acceptance is implied.

`prototype-v01/cad/mechanism-study.scad` is a draft horizontal rotor with housing, crude latch, hub and column geometry. It was started before the horizontal thumbwheel appearance was recognized; its shaft axis differs from the visual model. It is retained only as explicit unvalidated research. Do not export, print, or combine it with the approved exterior as if mechanically resolved.

## Next concrete work

1. Review the rendered exterior with Michael. Change proportions/window/dial/cap styling in the visual CAD rather than presenting unrelated generated pictures.
2. Fit a vertical-axis rotary pocket cassette with separated fill/discharge ports, closed transit position, anti-leak sealing and captive, cleanable parts inside one cartridge. Resolve flow taper, usable capacity, torque and actual scale-based increments with powder tests.
3. Design and test one cradle/latch coupon, real independent tier bearings, a keyed detachable structural connector, and a stable base. Explicitly model and check bolt paths, clearances and removal sweeps. The top handle is not load rated.
4. Only then multiply proven components into twelve copies and assess the full/uneven load case. Under-cabinet suspension needs independent engineering and actual substrate/load verification.

No purchase, print start, native routine, email, worker wake or notification was authorized or performed for this checkpoint. No physical fit, powder, leakage, cleaning, food-contact or load test is complete. Continue in the same branch and folder; do not replace the main project's design authority.
