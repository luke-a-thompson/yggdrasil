#import "../src/lib.typ": cut, cycle, draw, node, tree

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

#let aromatic_tree1 = tree(
  kind: "exotic-aromatic",
  root: node($r$, id: "r", children: (
    node($r_2$, id: "r2", level-shift: 0),
    node($a$, id: "a"),
    node($b$, id: "b"),
  )),
  cycles: (cycle(nodes: ("r", "r2")),),
)

#let aromatic_tree2 = tree(
  kind: "exotic-aromatic",
  root: node($r$, id: "r", children: (
    node($r_2$, id: "r2"),
    node($a$, id: "a"),
    node($b$, id: "b", children: (
      node($c$, id: "c"),
    )),
  )),
)

Some trees smell particularly good, like the #emph("aromatic trees") $ #draw(aromatic_tree1), space #draw(aromatic_tree2) $.

For more exotic problems, we have the #emph("exotic aromatic") trees,

#let exotic_aromatic_cherry = tree(
  kind: "exotic-aromatic",
  root: node($r$, id: "r", children: (
    node($a$, id: "a"),
    node($b$, id: "b"),
  )),
  cycles: (cycle(nodes: "r"),),
)

$ #draw(exotic_aromatic_cherry) $
