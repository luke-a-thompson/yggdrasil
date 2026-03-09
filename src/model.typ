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

#let node(
  label: none,
  id: auto,
  fill: none,
  stroke: auto,
  ann: none,
  children: (),
  ..meta,
) = (
  _kind: "node",
  id: id,
  label: label,
  fill: fill,
  stroke: stroke,
  ann: ann,
  children: children,
  meta: _meta(meta),
)

#let edge(
  to: none,
  kind: "branch",
  id: auto,
  style: (),
  ..meta,
) = {
  if to == none { panic("edge(...) requires `to:`") }
  if kind == "loop" {
    panic("edge(kind: \"loop\", ...) was removed; use cycle(...)+tree(cycles: (...))")
  }
  (
    _kind: "edge",
    id: id,
    to: to,
    edge-kind: kind,
    style: style,
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
      panic("node children must be node(...) or edge(...) values")
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
          edge-kind: "branch",
          style: (),
          meta: (),
        ),),
        s3,
      )
    } else if child-kind == "edge" {
      if type(child.to) != dictionary or child.to.at("_kind", default: none) != "node" {
        panic("edge(to: ...) must reference a node(...) value")
      }

      let edge-id-out = _resolve-id(child.id, s, "edge", "e")
      let edge-id = edge-id-out.at(0)
      let s2 = edge-id-out.at(1)

      let to-out = _normalize-node(child.to, s2)
      let to-node = to-out.at(0)
      let s3 = to-out.at(1)

      (
        edges + ((
          _kind: "edge",
          id: edge-id,
          to: to-node,
          edge-kind: child.at("edge-kind", default: "branch"),
          style: child.style,
          meta: child.meta,
        ),),
        s3,
      )
    } else {
      panic("node children must be node(...) or edge(...) values")
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
      ),
    )

    let with-subtree = _edge-index(first.to.children, first.to.id, idx: next)
    _edge-index(rest, parent-id, idx: with-subtree)
  }
}

#let edge-index(t) = _edge-index(t.root.children, t.root.id)

#let _node-index(node, idx: (:), depth: 0) = {
  let with-current = idx + ((node.id): (node: node, depth: depth))
  node.children.fold(with-current, (acc, e) => _node-index(e.to, idx: acc, depth: depth + 1))
}

#let node-index(t) = _node-index(t.root, idx: (:), depth: 0)
