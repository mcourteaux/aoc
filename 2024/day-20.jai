#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Array";
#load "AOC.jai";

main :: () {
  cli_args := get_command_line_arguments();

  ANIMATE :: true;
  SAMPLE :: false;
  COOL_QUESTION := false; // COOL = one-entrance-one-exit

  for cli_args {
    if equal(it, "cool") {
      COOL_QUESTION = true;
    }
  }

  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  Node :: struct {
    cost: s64 = S32_MAX;
    r, c: s32;
    l: s8;
    coming_from: *Node;
    is_wall: bool;
    best_cheat: s32;
  };

  h := lines.count;
  w := lines[0].count;

  to_process : [..]*Node;

  goal_r, goal_c := 0, 0;
  start_r, start_c := 0, 0;

  PART :: 2;
  #if PART == 1 {
    MAX_CHEAT_TIME :: 2;
    MIN_CHEAT_IMPACT :: #ifx SAMPLE then 2 else 100;
  } else {
    MAX_CHEAT_TIME :: 20;
    MIN_CHEAT_IMPACT :: #ifx SAMPLE then 50 else 100;
  }
  grid : []Node = NewArray(w * h * (MAX_CHEAT_TIME + 1), Node);
  defer array_free(grid);

  gi :: inline (r: int, c: int, l: int) -> s64 #expand {
    assert(l <= MAX_CHEAT_TIME);
    return (r * w + c) * (MAX_CHEAT_TIME + 1) + l;
  }

  for line, row: lines {
    for char, col : line {
      for layer : 0..MAX_CHEAT_TIME {
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
            if 0 == layer {
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
  print("start: %\n", grid[gi(start_r, start_c, 0)]);
  print("goal: %\n", grid[gi(goal_r, goal_c, 0)]);


  check_neighbor :: (this: *Node, dr: int, dc: int, nbl: int) #expand {
    nbr := this.r + dr;
    nbc := this.c + dc;
    if min(nbr, nbc) < 0 || nbr >= h || nbc >= w return;
    nb := *grid[gi(nbr, nbc, nbl)];

    // No cheating at time=0 or time=MAX.
    if (nbl == 0 || nbl == MAX_CHEAT_TIME) && nb.is_wall return;


    new_cost := this.cost + 1;
    if new_cost < nb.cost {
      nb.cost = new_cost;
      nb.coming_from = this;

      if COOL_QUESTION {
        if nbl >= 1 && !nb.is_wall return; // Cheat ends
      }
      if nbl == MAX_CHEAT_TIME return; // Cheat also ends...

      array_add(*to_process, nb);
    }
  }

  // Start with a regular no-cheat solve!
  array_add(*to_process, *grid[gi(start_r, start_c, 0)]);
  while to_process.count > 0 {
    node := to_process[0];
    array_unordered_remove_by_index(*to_process, 0);

    check_neighbor(node,  0, +1, 0);
    check_neighbor(node,  0, -1, 0);
    check_neighbor(node, -1,  0, 0);
    check_neighbor(node, +1,  0, 0);
  }
  node := *grid[gi(goal_r, goal_c, 0)];
  print("Fastest no-cheat track: % picoseconds\n", node.cost);

  // Unwind fastest track.
  no_cheat_cells: [..]*Node;
  defer array_free(no_cheat_cells);

  array_add(*to_process, node);
  while to_process.count {
    node = to_process[0];
    array_unordered_remove_by_index(*to_process, 0);

    array_insert_at(*no_cheat_cells, node, 0);

    if node.coming_from {
      array_add(*to_process, node.coming_from);
    }
  }

  num_good_cheats := 0;
  best_cheat := 0;

  cheat_histogram : [..]s64;
  defer array_free(cheat_histogram);

  #if ANIMATE {
    viz: String_Builder;
  }

  for ns, nsi : no_cheat_cells {
    // For every start, find all cheats starting here.
    // 1) Clear the time >= 1 part.
    for r : 0..h-1 {
      for c : 0..w-1 {
        grid[gi(r, c, 0)].best_cheat = 0;
        for t : 1..MAX_CHEAT_TIME {
          using grid[gi(r, c, t)];
          cost = S32_MAX;
          coming_from = null;
        }
      }
    }
    // 2) Solve
    csr := ns.r;
    csc := ns.c;
    cheat_start_node := *grid[gi(csr, csc, 0)];
    #if SAMPLE && !ANIMATE print("Solving cheats from: %,%\n", csr, csc);
    array_add(*to_process, cheat_start_node);
    while to_process.count {
      node := to_process[0];
      array_unordered_remove_by_index(*to_process, 0);

      check_neighbor(node,  0, +1, node.l + 1);
      check_neighbor(node,  0, -1, node.l + 1);
      check_neighbor(node, -1,  0, node.l + 1);
      check_neighbor(node, +1,  0, node.l + 1);
    }

    for ne, nei : no_cheat_cells {
      if nei <= nsi + MIN_CHEAT_IMPACT continue;

      // Find the fastest time the cheat finds this end point.
      earliest_exit : *Node = null;
      for l : 1..MAX_CHEAT_TIME {
        node := *grid[gi(ne.r, ne.c, l)];
        if node.cost < S32_MAX {
          earliest_exit = node;
          break;
        }
      }

      if earliest_exit != null {
        savings := ne.cost - earliest_exit.cost;
        cheat_time := earliest_exit.cost - ns.cost;
        if savings >= MIN_CHEAT_IMPACT {
          ns.best_cheat = xx savings;
          num_good_cheats += 1;
          #if SAMPLE && !ANIMATE {
            print(
              "Cheat from %,% to %,% saves % picoseconds (taking % picos).\n",
              ns.r, ns.c, ne.r, ne.c, savings, cheat_time
            );
          }

          array_resize(*cheat_histogram,
                       max(cheat_histogram.count, savings + 1));
          cheat_histogram[savings] += 1;
          best_cheat = max(best_cheat, savings);
        }
      }
    }

    #if ANIMATE {
      skip_to_col :: (skip: s64) -> int, int, int {
        skip = min(skip - MIN_CHEAT_IMPACT, 200);
        return 200 - skip, skip, 100;
      }
      defer reset(*viz);
      for r : 0..h-1 {
        for c : 0..w-1 {
          using grid[gi(r, c, 0)];

          cheat : *Node = null;
          for l : 1..MAX_CHEAT_TIME {
            n := *grid[gi(r, c, l)];
            if n.cost < S32_MAX {
              cheat = n;
              break;
            }
          }

          if r == ns.r && c == ns.c {
            print(*viz, "\e[31;41m@@\e[0m");
          } else if is_wall {
            if cheat {
              dr := cheat.coming_from.r - r;
              dc := cheat.coming_from.c - c;
              dir : string;
              if dc ==  0 && dr ==  1 dir = "^^";
              if dc ==  0 && dr == -1 dir = "vv";
              if dc ==  1 && dr ==  0 dir = "<<";
              if dc == -1 && dr ==  0 dir = ">>";
              print(*viz, "\e[38:5:242;48:5:237m%\e[0m", dir);
            } else {
              print(*viz, "\e[38:5:237;48:5:237m##\e[0m");
            }
          } else {
            if cheat {
              savings := cost - cheat.cost;
              if savings >= MIN_CHEAT_IMPACT {
                r, g, b := skip_to_col(savings);
                //print(*viz, "\e[32;42m<>\e[0m");
                print(*viz, "\e[48;2;%;%;%m  \e[0m", r, g, b);
              } else {
                //print(*viz, "\e[2;35;45m<>\e[0m");
                print(*viz, "\e[48;2;%;%;%m  \e[0m", 50, 30, 10);
              }
            } else {
              print(*viz, "  ");
            }
          }
        }
        print(*viz, "\n");
      }
      viz_str := builder_to_string(*viz);
      defer free(viz_str.data);
      print("\e[2J\e[1;1H%", viz_str);
      sleep_milliseconds(40);
    }
  }
  #if SAMPLE && !ANIMATE {
    print("\n");
    for array_view(cheat_histogram, 0, best_cheat + 1) {
      if it > 0 {
        print("% Cheats saving % picoseconds\n", it, it_index);
      }
    }
  }
  print("Num good cheats: %\n", num_good_cheats);

}
