#import "kinds.typ": kind-spec
#import "model.typ": edge-index, node-index
#import "style.typ": default-style, merge-style

#let _nodes(node) = {
  let children = node.children.fold((), (acc, e) => acc + _nodes(e.to))
  (node,) + children
}

#let _edges(node) = {
  node.children.fold((), (acc, e) => acc + (e,) + _edges(e.to))
}

#let _paths(node, prefix: ()) = {
  if node.children.len() == 0 {
    (prefix,)
  } else {
    node.children.fold((), (acc, e) => acc + _paths(e.to, prefix: prefix + (e.id,)))
  }
}

#let _count-members(xs, ys) = {
  xs.fold(0, (n, x) => n + (if ys.contains(x) { 1 } else { 0 }))
}

#let _cut-edges(c) = {
  let e = c.edges
  if type(e) == str { (e,) } else { e }
}

#let _validate-cuts(t, edges-by-id) = {
  let paths = _paths(t.root)

  for c in t.cuts {
    let ck = c.at("cut-kind", default: "admissible")
    if ck != "admissible" and ck != "arbitrary" {
      panic("Unknown cut kind: " + repr(ck))
    }

    let cut-edges = _cut-edges(c)
    for id in cut-edges {
      if not edges-by-id.keys().contains(id) {
        panic("Cut references unknown edge id: " + repr(id))
      }
    }

    if ck == "admissible" {
      for p in paths {
        if _count-members(cut-edges, p) > 1 {
          panic("Admissible cuts may cut at most one edge per root-to-leaf path")
        }
      }
    }
  }
}

#let _visit(node, spec, stack: (), seen: ()) = {
  if not spec.at("allow-cycles") {
    if seen.contains(node.id) {
      panic("Cycle or repeated node id found in a non-cyclic tree kind")
    }
  }

  for e in node.children {
    _visit(e.to, spec, stack: stack + (node.id,), seen: seen + (node.id,))
  }
}

#let _validate-typed(nodes, spec) = {
  if spec.at("require-typed-decoration") {
    for n in nodes {
      if type(n.meta) != dictionary or not n.meta.keys().contains("dec") {
        panic("typed trees require node meta key `dec`")
      }
    }
  }
}

#let _validate-edge-kinds(edges, spec, style) = {
  let allowed-shapes = spec.at("allowed-edge-kinds")
  let edge-presets = style.at("edge-presets", default: (:))

  for e in edges {
    let k = e.at("edge-kind", default: "branch")
    if not edge-presets.keys().contains(k) {
      panic("Unknown edge kind `" + repr(k) + "`. Available: " + repr(edge-presets.keys()))
    }
    let shape = edge-presets.at(k).at("shape", default: k)
    if not allowed-shapes.contains(shape) {
      panic(
        "edge kind `" + repr(k) + "` resolves to shape `" + repr(shape)
          + "`, which is not allowed for this tree kind",
      )
    }
  }
}

#let _cycle-node-ids(c) = {
  let n = c.nodes
  if type(n) == str { (n,) } else { n }
}

#let _validate-cycles(t, nodes-by-id, spec, strict, style) = {
  if t.cycles.len() > 0 and not spec.at("allow-tree-cycles", default: false) {
    panic("cycles: (...) is only supported for aromatic and exotic-aromatic trees")
  }

  for c in t.cycles {
    let ids = _cycle-node-ids(c)
    if ids.len() == 0 {
      panic("cycle(nodes: ...) must include at least one node id")
    }

    for i in range(ids.len()) {
      let id = ids.at(i)
      if ids.slice(0, i).contains(id) {
        panic("cycle contains duplicate node id: " + repr(id))
      }
      if not nodes-by-id.keys().contains(id) {
        panic("cycle references unknown node id: " + repr(id))
      }
    }

    let depths = ids.map(id => nodes-by-id.at(id).depth)

    if strict and depths.len() > 1 {
      let d0 = depths.first()
      for d in depths {
        if d != d0 {
          panic("cycle nodes must be on the same depth level in strict mode")
        }
      }
    }
  }
}

#let validate(t, strict: true) = {
  if strict {
    let spec = kind-spec(t.kind)
    let used-style = merge-style(default-style, t.style)
    let nodes = _nodes(t.root)
    let nodes-by-id = node-index(t)
    let edges = _edges(t.root)

    _validate-edge-kinds(edges, spec, used-style)
    _validate-typed(nodes, spec)
    _visit(t.root, spec)
    _validate-cycles(t, nodes-by-id, spec, strict, used-style)

    _validate-cuts(t, edge-index(t))
  }

  t
}
