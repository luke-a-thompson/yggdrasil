#let kind-specs = (
  rooted: (
    allow-cycles: false,
    planar: true,
    allowed-edge-kinds: ("branch",),
    require-typed-decoration: false,
  ),
  planar: (
    allow-cycles: false,
    planar: true,
    allowed-edge-kinds: ("branch",),
    require-typed-decoration: false,
  ),
  nonplanar: (
    allow-cycles: false,
    planar: false,
    allowed-edge-kinds: ("branch",),
    require-typed-decoration: false,
  ),
  aromatic: (
    allow-cycles: true,
    planar: true,
    allowed-edge-kinds: ("branch",),
    require-typed-decoration: false,
    allow-tree-cycles: true,
  ),
  "exotic-aromatic": (
    allow-cycles: true,
    planar: true,
    allowed-edge-kinds: ("branch", "liana", "stolon"),
    require-typed-decoration: false,
    allow-tree-cycles: true,
  ),
  typed: (
    allow-cycles: false,
    planar: true,
    allowed-edge-kinds: ("branch",),
    require-typed-decoration: true,
  ),
)

#let kind-spec(kind) = {
  if not kind-specs.keys().contains(kind) {
    panic("Unsupported tree kind: " + repr(kind))
  }
  kind-specs.at(kind)
}
