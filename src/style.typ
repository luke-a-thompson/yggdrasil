#let default-style = (
  node-radius: 1.8pt,
  node-fill: black,
  node-stroke: none,
  edge-stroke: black + 0.5pt,
  cut-stroke: red + 0.8pt,
  cut-half-width: 3.5pt,
  edge-presets: (
    branch: (
      shape: "branch",
      stroke: black + 0.5pt,
    ),
    liana: (
      shape: "liana",
      stroke: black + 0.5pt,
      liana-lift: 3pt,
    ),
    stolon: (
      shape: "stolon",
      stroke: black + 0.5pt,
      stolon-gap: 0.8pt,
    ),
  ),
  cycle-style: (
    stroke: black + .5pt,
    side-radius: 2.4pt,
  ),
  label-size: 6pt,
  label-dx: 3.2pt,
  label-dy: 0pt,
  x-gap: 10pt,
  y-gap: 8pt,
  inline-baseline: 25%,
)

#let merge-style(base, override) = {
  if type(override) != dictionary {
    return base
  }

  let merged = base + override

  let with-edge-presets = if base.keys().contains("edge-presets") and override.keys().contains("edge-presets") {
    merged + (
      "edge-presets": base.at("edge-presets") + override.at("edge-presets"),
    )
  } else {
    merged
  }

  if base.keys().contains("cycle-style") and override.keys().contains("cycle-style") {
    with-edge-presets + (
      "cycle-style": base.at("cycle-style") + override.at("cycle-style"),
    )
  } else {
    with-edge-presets
  }
}
