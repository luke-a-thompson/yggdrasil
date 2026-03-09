#import "style.typ": default-style, merge-style

#let _leaf-count(node) = {
  if node.children.len() == 0 {
    1
  } else {
    node.children.fold(0, (n, e) => n + _leaf-count(e.to))
  }
}

#let _max-depth(node) = {
  if node.children.len() == 0 {
    0
  } else {
    1 + node.children.fold(0, (m, e) => calc.max(m, _max-depth(e.to)))
  }
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

    let placed-child = _place-node(e.to, depth: depth + 1, x-center: child-center, style: style)
    (
      placed + ((
        id: e.id,
        edge-kind: e.at("edge-kind", default: "branch"),
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
    ann: node.ann,
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
    height: (1 + _max-depth(placed-root)) * used-style.at("y-gap"),
  )
}
