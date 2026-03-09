#import "@preview/cetz:0.4.2": canvas, draw as cdraw
#import "layout.typ": layout
#import "style.typ": merge-style
#import "validate.typ": validate

#let _collect-edges(node) = {
  node.children.fold((), (acc, e) => {
    (
      acc
        + (
          (
            id: e.id,
            edge-kind: e.at("edge-kind", default: "branch"),
            from: (node.x, node.y),
            to: (e.to.x, e.to.y),
            style: e.style,
            meta: e.meta,
          ),
        )
        + _collect-edges(e.to)
    )
  })
}

#let _collect-nodes(node) = {
  (node,) + node.children.fold((), (acc, e) => acc + _collect-nodes(e.to))
}

#let _collect-node-map(node, idx: (:)) = {
  let with-current = idx + ((node.id): node)
  node.children.fold(with-current, (acc, e) => _collect-node-map(e.to, idx: acc))
}

#let _cut-ids(tree) = {
  tree.cuts.fold((), (acc, c) => {
    let e = c.edges
    acc + (if type(e) == str { (e,) } else { e })
  })
}

#let _edge-presets(style) = style.at("edge-presets", default: (:))
#let _as-dict(x) = if type(x) == dictionary { x } else { (:) }

#let _resolve-edge-style(e, style) = {
  let presets = _edge-presets(style)
  let k = e.at("edge-kind", default: "branch")
  if not presets.keys().contains(k) {
    panic("Unknown edge kind: " + repr(k) + ". Available: " + repr(presets.keys()))
  }

  let resolved = presets.at(k) + _as-dict(e.style)
  let stroke = resolved.at("stroke", default: style.at("edge-stroke"))
  resolved + (stroke: stroke)
}

#let _draw-edge(e, style) = {
  let p1 = e.from
  let p2 = e.to
  let resolved = _resolve-edge-style(e, style)
  let shape = resolved.at("shape", default: e.at("edge-kind", default: "branch"))
  let stroke = resolved.at("stroke")

  if shape == "branch" or shape == "liana" {
    cdraw.line(p1, p2, stroke: stroke)
  } else if shape == "stolon" {
    let gap = resolved.at("stolon-gap", default: 3pt)
    let half = gap / 2
    let dx = p2.at(0) - p1.at(0)
    let dy = p2.at(1) - p1.at(1)
    let len = calc.sqrt((dx / 1pt) * (dx / 1pt) + (dy / 1pt) * (dy / 1pt)) * 1pt

    if len == 0pt {
      cdraw.line(p1, p2, stroke: stroke)
      return
    }

    // Offset along the edge normal so stolon renders as two parallel lines.
    let nx = -dy / len
    let ny = dx / len

    let p1a = (p1.at(0) + nx * half, p1.at(1) + ny * half)
    let p2a = (p2.at(0) + nx * half, p2.at(1) + ny * half)
    let p1b = (p1.at(0) - nx * half, p1.at(1) - ny * half)
    let p2b = (p2.at(0) - nx * half, p2.at(1) - ny * half)

    cdraw.line(p1a, p2a, stroke: stroke)
    cdraw.line(p1b, p2b, stroke: stroke)
  } else {
    panic("Unknown edge shape: " + repr(shape) + ". Supported shapes: (\"branch\", \"liana\", \"stolon\")")
  }
}

#let _draw-cut(e, style) = {
  let p1 = e.from
  let p2 = e.to
  let mx = (p1.at(0) + p2.at(0)) / 2
  let my = (p1.at(1) + p2.at(1)) / 2
  let h = style.at("cut-half-width", default: 1.8pt)
  cdraw.line((mx - h, my), (mx + h, my), stroke: style.at("cut-stroke"))
}

#let _cycle-node-ids(c) = {
  let n = c.nodes
  if type(n) == str { (n,) } else { n }
}

#let _resolve-cycle-style(c, style) = {
  let base = style.at("cycle-style", default: (:))
  (
    (
      stroke: base.at("stroke", default: style.at("edge-stroke")),
      "side-radius": base.at("side-radius", default: 2.4pt),
    )
      + _as-dict(c.style)
  )
}

#let _cycle-rails-y(node-y, style) = {
  let half-height = style.at("node-radius")
  (top: node-y - half-height, bottom: node-y + half-height)
}

#let _draw-self-cycle(node, style, resolved) = {
  let rails = _cycle-rails-y(node.y, style)
  let top-y = rails.top
  let bottom-y = rails.bottom
  let rr = calc.abs(bottom-y - top-y)
  let cy = (top-y + bottom-y) / 2
  cdraw.arc(
    (node.x, cy),
    radius: (rr, rr),
    start: 0deg,
    delta: 360deg,
    stroke: resolved.at("stroke"),
  )
}

#let _sort-points-by-x(points) = {
  points.fold((), (sorted, p) => {
    let left = sorted.filter(q => q.x <= p.x)
    let right = sorted.filter(q => q.x > p.x)
    left + (p,) + right
  })
}

#let _draw-cycle(c, nodes-by-id, style) = {
  let ids = _cycle-node-ids(c)
  let resolved = _resolve-cycle-style(c, style)

  let points = _sort-points-by-x(ids.map(id => nodes-by-id.at(id)))
  if points.len() == 1 {
    _draw-self-cycle(points.first(), style, resolved)
    return
  }

  let rails = _cycle-rails-y(points.first().y, style)
  let top-y = rails.top
  let bottom-y = rails.bottom
  let rail-shift = -style.at("node-radius")
  let top-line-y = top-y + rail-shift
  let bottom-line-y = bottom-y + rail-shift
  let left = points.first()
  let right = points.last()

  cdraw.line((left.x, top-line-y), (right.x, top-line-y), stroke: resolved.at("stroke"))

  let mid-y = (top-y + bottom-y) / 2
  let rx = resolved.at("side-radius", default: 2.4pt)
  let ry = calc.abs(bottom-y - top-y) / 2

  cdraw.arc((left.x, mid-y), radius: (rx, ry), start: 90deg, delta: 180deg, stroke: resolved.at("stroke"))
  cdraw.arc((right.x, mid-y), radius: (rx, ry), start: 90deg, delta: -180deg, stroke: resolved.at("stroke"))
  cdraw.line((left.x, bottom-line-y), (right.x, bottom-line-y), stroke: resolved.at("stroke"))
}

#let _draw-node(n, style) = {
  let fill = if n.fill == none { style.at("node-fill") } else { n.fill }
  let stroke = if n.stroke == auto { style.at("node-stroke") } else { n.stroke }

  cdraw.circle((n.x, n.y), radius: style.at("node-radius"), fill: fill, stroke: stroke)

  if n.label != none {
    cdraw.content(
      (n.x + style.at("label-dx", default: 0pt), n.y + style.at("label-dy", default: 0pt)),
      text(size: style.at("label-size", default: 6pt), n.label),
    )
  }
}

#let draw(tree, mode: "auto", strict: true, style: ()) = {
  let valid = validate(tree, strict: strict)
  let placed = layout(valid, mode: mode, style: style)
  let used-style = merge-style(placed.style, style)

  let edges = _collect-edges(placed.root)
  let nodes = _collect-nodes(placed.root)
  let nodes-by-id = _collect-node-map(placed.root, idx: (:))
  let cut-ids = _cut-ids(valid)

  box(
    baseline: used-style.at("inline-baseline", default: 50%),
    canvas(length: 1pt, {
      for e in edges {
        _draw-edge(e, used-style)
      }
      for c in valid.cycles {
        _draw-cycle(c, nodes-by-id, used-style)
      }
      for e in edges {
        if cut-ids.contains(e.id) {
          _draw-cut(e, used-style)
        }
      }
      for n in nodes {
        _draw-node(n, used-style)
      }
    }),
  )
}
