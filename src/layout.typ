#import "style.typ": default-style, merge-style

#let _resolved-level-shift(level-shift) = {
  if level-shift == auto {
    1
  } else if type(level-shift) == int and level-shift >= 0 {
    level-shift
  } else {
    panic("node(level-shift: ...) must be auto or a non-negative integer")
  }
}

#let _leaf-count(node) = {
  if node.children.len() == 0 {
    1
  } else {
    node.children.fold(0, (n, e) => n + _leaf-count(e.to))
  }
}

#let _max-y(node) = {
  node.children.fold(node.y, (m, e) => calc.max(m, _max-y(e.to)))
}

#let _place-node(node, depth: 0, x-center: 0pt, style: ()) = {
  let y = depth * style.at("y-gap")
  let leaves = _leaf-count(node)
  let start = x-center - (leaves * style.at("x-gap")) / 2

  let folded = node.children.fold(((), start), (acc, e) => {
    let placed = acc.at(0)
    let cursor = acc.at(1)

    let subtree-leaves = _leaf-count(e.to)
    let subtree-width = subtree-leaves * style.at("x-gap")
    let child-center = cursor + subtree-width / 2

    let shift = _resolved-level-shift(e.at("level-shift", default: auto))
    let placed-child = _place-node(e.to, depth: depth + shift, x-center: child-center, style: style)
    (
      placed + ((
        id: e.id,
        edge-kind: e.at("edge-kind", default: "branch"),
        "level-shift": e.at("level-shift", default: auto),
        style: e.style,
        meta: e.meta,
        to: placed-child,
      ),),
      cursor + subtree-width,
    )
  })

  (
    id: node.id,
    label: node.label,
    fill: node.fill,
    stroke: node.stroke,
    meta: node.meta,
    x: x-center,
    y: y,
    children: folded.at(0),
  )
}

#let layout(tree, mode: "auto", style: ()) = {
  let merged = merge-style(default-style, tree.style)
  let used-style = merge-style(merged, style)

  let root-leaves = _leaf-count(tree.root)
  let root-x = (root-leaves * used-style.at("x-gap")) / 2
  let placed-root = _place-node(tree.root, depth: 0, x-center: root-x, style: used-style)

  (
    tree: tree,
    root: placed-root,
    style: used-style,
    mode: mode,
    width: root-leaves * used-style.at("x-gap"),
    height: _max-y(placed-root) + used-style.at("y-gap"),
  )
}
