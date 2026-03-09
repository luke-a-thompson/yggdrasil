# yggrasil

Typst package for mathematical rooted trees with validation by tree kind.

## API

- `node(...)`
- `edge(to: ..., kind: ...)`
- `cycle(nodes: ..., style: ...)`
- `cut(edges: ..., kind: "admissible" | "arbitrary")`
- `tree(root: ..., kind: ..., cuts: (...), cycles: (...))`
- `validate(tree)`
- `draw(tree)`

## Tree kinds

- `rooted`
- `planar`
- `nonplanar`
- `aromatic`
- `exotic-aromatic`
- `typed`

Kinds are subtypes via validation rules on one shared core model.

## Example

```typst
#import "src/lib.typ": node, cut, cycle, tree, draw

#let t = tree(
  kind: "aromatic",
  root: node($r$, id: "r", children: (
    node($a$, id: "a", ann: $gamma$),
    node($b$, id: "b"),
  )),
  cuts: (cut(edges: ("e0",), kind: "admissible"),),
  cycles: (cycle(nodes: ("a", "b")),),
)

The rooted tree can be shown inline as math: $1 + #draw(t) + 2$, or in display mode:

#align(center, draw(t))
```
