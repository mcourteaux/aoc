#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

main :: () {
  //input := fetch_demo_puzzle_input(true, 0);
  input := fetch_puzzle_input(true);
  lines := split(input, "\n");

  delta_to_idx :: (dr: int, dc: int) -> int {
    if dr == -1 && dc ==  0 return 0;
    if dr ==  1 && dc ==  0 return 1;
    if dr ==  0 && dc == -1 return 2;
    if dr ==  0 && dc ==  1 return 3;
    assert(false);
    return -1;
  }
  idx_to_delta :: (idx: int) -> s8, s8 {
    if idx == 0 return -1, 0;
    if idx == 1 return  1, 0;
    if idx == 2 return 0, -1;
    if idx == 3 return 0,  1;
    assert(false);
    return 0, 0;
  }

  Node :: struct {
    cost: s64 = S32_MAX;
    r, c: s32;
    l: s8;
    coming_from: [4]*Node;
    is_wall: bool;
    counted: bool;
  };

  h := lines.count;
  w := lines[0].count;

  to_process : [..]*Node;

  goal_r, goal_c := 0, 0;
  start_r, start_c, start_l := 0, 0, delta_to_idx(0, 1);

  grid : []Node = NewArray(w * h * 4, Node);
  defer array_free(grid);

  gi :: inline (r: int, c: int, l: int) -> s64 #expand {
    return (r * w + c) * 4 + l;
  }

  for line, row: lines {
    for char, col : line {
      for layer : 0..3 {
        grididx := gi(row, col, layer);
        using *grid[grididx];
        r = xx row;
        c = xx col;
        l = xx layer;
        if char == #char "#" { // Wall
          is_wall = true;
        } else {
          is_wall = false;
          if char == #char "S" {
            if delta_to_idx(0, 1) == layer {
              cost = 0;
            }
            start_r, start_c = row, col;
          } else if char == #char "E" {
            goal_r, goal_c = row, col;
          }
        }
      }
    }
  }
  print("start: %\n", grid[gi(start_r, start_c, start_l)]);

  array_add(*to_process, *grid[gi(start_r, start_c, start_l)]);

  check_neighbor :: (this: *Node, dr : int, dc : int, layer: int) #expand {
    nb := *grid[gi(this.r + dr, this.c + dc, layer)];
    if nb.is_wall return;
    cost := abs(dr) + abs(dc);
    if this.l != layer {
      cost += 1000;
    }
    new_cost := this.cost + cost;
    if new_cost < nb.cost {
      nb.cost = new_cost;
      nb.coming_from[0] = this;
      nb.coming_from[1] = null;
      nb.coming_from[2] = null;
      nb.coming_from[3] = null;
      array_add(*to_process, nb);
    } else if new_cost == nb.cost {
      for cfi : 0..3 {
        if nb.coming_from[cfi] == this {
          // Already done!
          return;
        } else if nb.coming_from[cfi] == null {
          nb.coming_from[cfi] = this;
          break;
        }
      }
      array_add(*to_process, nb);
    }
  }

  while to_process.count > 0 {
    node := to_process[0];
    array_unordered_remove_by_index(*to_process, 0);

    // Check neighbor on own layer, which is only going forward in the current direction
    dr, dc := idx_to_delta(node.l);
    check_neighbor(node,  dr, dc, node.l);

    for layer : 0..3 {
      if layer != node.l {
        check_neighbor(node, 0, 0, layer);
      }
    }
  }
  overall_best_cost := 1000000000;
  for layer : 0..3  {
    using grid[gi(goal_r, goal_c, layer)];
    print("Score to get to goal (%, %, %) = %\n", goal_r, goal_c, layer, cost);
    overall_best_cost = min(overall_best_cost, cost);
  }

  // Unwind from goal to start.
  count := 0;
  for 0..3 {
    node := *grid[gi(goal_r, goal_c, it)];
    if node.cost == overall_best_cost {
      array_add(*to_process, node);
    }
  }
  while to_process.count > 0 {
    node := to_process[0];
    using node;
    array_unordered_remove_by_index(*to_process, 0);
    //print("Unwind node: %\n", <<node);

    if !counted {
      count += 1;
      for 0..3 {
        grid[gi(r, c, it)].counted = true;
      }
    }

    if r == start_r && c == start_c && l == start_l {
      continue; // We don't want to recurse beyond the start node.
    }

    for 0..2 {
      if coming_from[it] {
        array_add(*to_process, coming_from[it]);
        coming_from[it] = null;
      }
    }
  }

  // Find maximum best-cost per cell.
  max_cost := 0;
  for y : 0..h-1 {
    for x : 0..w-1 {
      n := grid[gi(y, x, 0)];
      if !n.is_wall {
        bc := n.cost;
        for l : 1..3 {
          bc = min(bc, grid[gi(y, x, l)].cost);
        }
        max_cost = max(max_cost, bc);
      }
    }
  }


  frac_to_col :: (frac: float) -> int, int, int {
    if frac < 0.5 {
      frac = frac * 2;
      return xx (frac * 255), xx ((1.0 - frac) * 205), 0;
    } else {
      frac = (frac - 0.5) * 2;
      return xx ((1.0 - frac) * 255), 0, xx (frac * 255);
    }
  }

  print("\n\n");
  for y : 0..h-1 {
    print("   ");
    for x : 0..w-1 {
      n := grid[gi(y, x, 0)];
      if n.is_wall {
        //print("\e[41;31m##\e[0m");
        print("\e[38:5:237m\e[48:5:237m##\e[0m");
      } else {
        bc := n.cost;
        for l : 1..3 {
          bc = min(bc, grid[gi(y, x, l)].cost);
        }
        frac := cast(float32) bc / max_cost;
        r, g, b := frac_to_col(frac);
        print("\e[48;2;%;%;%m%\e[0m", r, g, b, ifx n.counted "##" else "  ");
      }
    }
    print("\n");
  }
  print("\n");

  print("Counted % positions along the best paths\n", count);
}
