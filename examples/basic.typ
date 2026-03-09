#import "../src/lib.typ": cut, cycle, draw, edge, node, tree

#set page(width: auto, height: auto, margin: 8pt)
#show link: underline

Consider an ODE $dif/(dif t) = f(y(t))$.

#let cherry = tree(
  kind: "rooted",
  root: node($r$, children: (
    node($a$),
    node($b$),
  )),
)

#let ladderThree = tree(
  kind: "rooted",
  root: node($r$, children: (
    node($a$, children: (
      node($b$),
    )),
  )),
)

The two terms of its third order #link("https://en.wikipedia.org/wiki/Taylor_series")[Taylor expansion] are $f''(f'f')$ and $f''(f'f)$. These can be represented as the inline rooted trees #draw(ladderThree) and #draw(cherry) or in display mode:

$ draw(ladderThree), space draw(cherry). $

#let planar_cherry = tree(
  kind: "planar",
  root: node($r$, children: (
    node($a$),
    node($b$),
  )),
)
If this ODE is posed on a manifold, we can use planar rooted rooted trees where $#draw(planar_cherry) != #draw(planar_cherry)$.

#v(20pt)

#let cut_cherry = tree(
  kind: "rooted",
  root: node($r$, children: (
    node($a$),
    node($b$),
  )),
  cuts: (cut(edges: ("e0",), kind: "admissible"),),
)

Trees can be cut $ #draw(cut_cherry) = $.


#v(20pt)

#let aromatic_cherry = tree(
  kind: "aromatic",
  root: node($r$, id: "r", children: (
    node($a$, id: "a"),
    node($b$, id: "b"),
  )),
  cycles: (cycle(nodes: ("a", "b")),),
)

Some trees smell particularly good, like this #emph("aromatic tree") $ #draw(aromatic_cherry) $.

For more exotic problems, we have the #emph("exotic aromatic") trees,

#let exotic_aromatic_cherry = tree(
  kind: "exotic-aromatic",
  root: node($r$, id: "r", children: (
    node($a$, id: "a"),
    node($b$, id: "b"),
  )),
  cycles: (cycle(nodes: ("a")),),
)

$ #draw(exotic_aromatic_cherry) $
