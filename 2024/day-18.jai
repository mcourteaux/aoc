#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
    GS :: 7;
    NUM_WALLS :: 12;
  } else {
    input := fetch_puzzle_input(true);
    GS :: 71;
    NUM_WALLS :: 1024;
  }
  lines := split(input, "\n");

  Node :: struct {
    wall: bool;
    x, y: s8;
    cost: s64 = S32_MAX;
  }

  for num_walls : NUM_WALLS..lines.count {
    auto_release_temp();

    grid: [GS][GS]Node;

    for line : lines {
      if it_index == num_walls break;
      parts := split(line, ",");
      x := string_to_int(parts[0]);
      y := string_to_int(parts[1]);
      grid[y][x].wall = true;
    }
    for y : 0..GS-1 {
      for x : 0..GS-1 {
        grid[y][x].x = xx x;
        grid[y][x].y = xx y;
        if num_walls == NUM_WALLS print("%", ifx grid[y][x].wall then "#" else " ");
      }
      if num_walls == NUM_WALLS print("\n");
    }


    to_process : [..]*Node;
    defer array_free(to_process);

    array_add(*to_process, *(grid[0][0]));
    grid[0][0].cost = 0;


    check_neighbor :: (this: *Node, dx: s8, dy: s8) #expand {
      nbx := this.x + dx;
      nby := this.y + dy;
      if nbx < 0 || nby < 0 || nbx >= GS || nby >= GS return;
      nb := *(grid[nby][nbx]);
      if nb.wall return;
      new_cost := this.cost + 1;
      if nb.cost > new_cost {
        nb.cost = new_cost;
        array_add(*to_process, nb);
      }
    }

    while to_process.count > 0 {
      node := to_process[0];
      array_ordered_remove_by_index(*to_process, 0);
      //print("process: %\n", <<node);

      check_neighbor(node, -1,  0);
      check_neighbor(node, +1,  0);
      check_neighbor(node,  0, -1);
      check_neighbor(node,  0, +1);
    }

    exit := grid[GS-1][GS-1];
    print("Cost to get to exit after % bytes: %\n", num_walls, exit.cost);
    if exit.cost == S32_MAX {
      print("Coordinate of byte %: %\n", num_walls, lines[num_walls-1]);
      break;
    }
  }
}

