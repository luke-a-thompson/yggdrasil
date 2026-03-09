#let _meta(meta) = if meta == none { () } else { meta }

#let _next-id(state, key, prefix) = {
  let value = state.at(key, default: 0)
  (prefix + str(value), state + ((key): value + 1))
}

#let _resolve-id(id, state, key, prefix) = {
  if id == auto {
    _next-id(state, key, prefix)
  } else {
    (id, state)
  }
}

#let _validate-level-shift(level-shift) = {
  if level-shift == auto {
    auto
  } else if type(level-shift) == int and level-shift >= 0 {
    level-shift
  } else {
    panic("node(level-shift: ...) must be auto or a non-negative integer, got " + repr(level-shift))
  }
}

#let _resolved-level-shift(level-shift) = {
  let shift = _validate-level-shift(level-shift)
  if shift == auto { 1 } else { shift }
}

#let node(
  label: none,
  id: auto,
  fill: none,
  stroke: auto,
  ann: none,
  children: (),
  edge-kind: "branch",
  edge-style: (),
  level-shift: auto,
  ..meta,
) = {
  let validated-level-shift = _validate-level-shift(level-shift)
  (
    _kind: "node",
    id: id,
    label: label,
    fill: fill,
    stroke: stroke,
    ann: ann,
    children: children,
    edge-kind: edge-kind,
    edge-style: edge-style,
    "level-shift": validated-level-shift,
    meta: _meta(meta),
  )
}

#let cut(
  edges: none,
  kind: "admissible",
  style: (),
  id: auto,
  ..meta,
) = {
  if edges == none { panic("cut(...) requires `edges:`") }
  (
    _kind: "cut",
    id: id,
    edges: edges,
    cut-kind: kind,
    style: style,
    meta: _meta(meta),
  )
}

#let cycle(
  nodes: none,
  style: (),
  id: auto,
  ..meta,
) = {
  if nodes == none { panic("cycle(...) requires `nodes:`") }
  (
    _kind: "cycle",
    id: id,
    nodes: nodes,
    style: style,
    meta: _meta(meta),
  )
}

#let _normalize-node(n, state) = {
  let node-id-out = _resolve-id(n.id, state, "node", "n")
  let node-id = node-id-out.at(0)
  let s1 = node-id-out.at(1)

  let folded = n.children.fold(((), s1), (acc, child) => {
    let edges = acc.at(0)
    let s = acc.at(1)

    if type(child) != dictionary {
      panic("node children must be node(...) values")
    }

    let child-kind = child.at("_kind", default: none)
    if child-kind == "node" {
      let child-out = _normalize-node(child, s)
      let child-node = child-out.at(0)
      let s2 = child-out.at(1)

      let edge-id-out = _resolve-id(auto, s2, "edge", "e")
      let edge-id = edge-id-out.at(0)
      let s3 = edge-id-out.at(1)

      (
        edges + ((
          _kind: "edge",
          id: edge-id,
          to: child-node,
          edge-kind: child.at("edge-kind", default: "branch"),
          "level-shift": _validate-level-shift(child.at("level-shift", default: auto)),
          style: child.at("edge-style", default: ()),
          meta: (),
        ),),
        s3,
      )
    } else {
      panic("node children must be node(...) values")
    }
  })

  ((
    _kind: "node",
    id: node-id,
    label: n.label,
    fill: n.fill,
    stroke: n.stroke,
    ann: n.ann,
    children: folded.at(0),
    edge-kind: n.at("edge-kind", default: "branch"),
    edge-style: n.at("edge-style", default: ()),
    "level-shift": _validate-level-shift(n.at("level-shift", default: auto)),
    meta: n.meta,
  ), folded.at(1))
}

#let _normalize-cut(c, state) = {
  let cut-id-out = _resolve-id(c.id, state, "cut", "c")
  let cut-id = cut-id-out.at(0)
  let s1 = cut-id-out.at(1)

  ((
    _kind: "cut",
    id: cut-id,
    edges: c.edges,
    cut-kind: c.at("cut-kind", default: "admissible"),
    style: c.style,
    meta: c.meta,
  ), s1)
}

#let _normalize-cuts(cuts, state) = {
  cuts.fold(((), state), (acc, c) => {
    let out = _normalize-cut(c, acc.at(1))
    (acc.at(0) + (out.at(0),), out.at(1))
  })
}

#let _normalize-cycle(c, state) = {
  let cycle-id-out = _resolve-id(c.id, state, "cycle", "y")
  let cycle-id = cycle-id-out.at(0)
  let s1 = cycle-id-out.at(1)

  ((
    _kind: "cycle",
    id: cycle-id,
    nodes: c.nodes,
    style: c.style,
    meta: c.meta,
  ), s1)
}

#let _normalize-cycles(cycles, state) = {
  cycles.fold(((), state), (acc, c) => {
    let out = _normalize-cycle(c, acc.at(1))
    (acc.at(0) + (out.at(0),), out.at(1))
  })
}

#let tree(
  root: none,
  kind: "rooted",
  id: auto,
  style: (),
  cuts: (),
  cycles: (),
  ..meta,
) = {
  if root == none {
    panic("tree(...) requires `root:` with a node(...) value")
  }
  if type(root) != dictionary or root.at("_kind", default: none) != "node" {
    panic("tree(root: ...) must receive node(...)")
  }

  let root-out = _normalize-node(root, ("node": 0, "edge": 0, "cut": 0, "cycle": 0))
  let cuts-out = _normalize-cuts(cuts, root-out.at(1))
  let cycles-out = _normalize-cycles(cycles, cuts-out.at(1))

  (
    _kind: "tree",
    id: if id == auto { "t0" } else { id },
    kind: kind,
    root: root-out.at(0),
    cuts: cuts-out.at(0),
    cycles: cycles-out.at(0),
    style: style,
    meta: _meta(meta),
  )
}

#let _edge-index(edges, parent-id, idx: (:)) = {
  if edges.len() == 0 {
    idx
  } else {
    let first = edges.first()
    let rest = edges.slice(1)

    let next = idx + (
      (first.id): (
        from: parent-id,
        to: first.to.id,
        edge-kind: first.at("edge-kind", default: "branch"),
        "level-shift": first.at("level-shift", default: auto),
      ),
    )

    let with-subtree = _edge-index(first.to.children, first.to.id, idx: next)
    _edge-index(rest, parent-id, idx: with-subtree)
  }
}

#let edge-index(t) = _edge-index(t.root.children, t.root.id)

#let _node-index(node, idx: (:), depth: 0) = {
  let with-current = idx + ((node.id): (node: node, depth: depth))
  node.children.fold(with-current, (acc, e) => {
    _node-index(e.to, idx: acc, depth: depth + _resolved-level-shift(e.at("level-shift", default: auto)))
  })
}

#let node-index(t) = _node-index(t.root, idx: (:), depth: 0)
