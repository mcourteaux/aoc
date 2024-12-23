#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Array";
#load "AOC.jai";

Coord :: struct { r: s8; c: s8; };

operator - :: inline (a: Coord, b: Coord) -> Coord {
  return Coord.{a.r - b.r, a.c - b.c};
}
operator + :: inline (a: Coord, b: Coord) -> Coord {
  return Coord.{a.r + b.r, a.c + b.c};
}
operator == :: inline (a: Coord, b: Coord) -> bool {
  return a.r == b.r && a.c == b.c;
}
is_zero :: (using a: Coord) -> bool {
  return r == 0 && c == 0;
}
taxi :: (using a: Coord) -> int {
  return abs(r) + abs(c);
}


NUMERIC_COORDS : [11]Coord : .[
  .{3, 1}, // 0
  .{2, 0}, .{2, 1}, .{2, 2}, // 1,2,3
  .{1, 0}, .{1, 1}, .{1, 2}, // 4,5,6
  .{0, 0}, .{0, 1}, .{0, 2}, // 7,8,9
  .{3, 2} // A
];
NUMERIC_LAYOUT :: int.[
  7, 8, 9,
  4, 5, 6,
  1, 2, 3,
 -1, 0, 10
];

ARROW_COORDS : [5]Coord : .[
  .{0, 1}, // U
  .{1, 0}, .{1, 1}, .{1, 2}, // L, D, R
  .{0, 2} // A
];
ARROW_LAYOUT :: int.[
  -1, 0, 4,
   1, 2, 3
 ];
diff_to_arrow_coord :: (dr: s8, dc: s8) -> Coord {
  if dr == -1 && dc ==  0 return ARROW_COORDS[0];
  if dr ==  1 && dc ==  0 return ARROW_COORDS[2];
  if dr ==  0 && dc == -1 return ARROW_COORDS[1];
  if dr ==  0 && dc ==  1 return ARROW_COORDS[3];
  if dr ==  0 && dc ==  0 return ARROW_COORDS[4]; // A
  assert(false, "dr=%, dc=%", dr, dc);
  return Coord.{};
}


shortest_paths :: (layout: []int, layout_w: s8, layout_h: s8, from: Coord, to: Coord) -> [2][6]u8, int {
  assert(from.r >= 0 && from.r < layout_h);
  assert(from.c >= 0 && from.c < layout_w);
  assert(to.r >= 0 && to.r < layout_h);
  assert(to.c >= 0 && to.c < layout_w);
  c2i :: (c: Coord) -> u8 #expand {
    assert(c.r >= 0 && c.r < layout_h);
    assert(c.c >= 0 && c.c < layout_w);
    return xx(c.r * layout_w + c.c);
  }
  i2c :: (i: u8) -> Coord #expand {
    return .{xx i / layout_w, xx i % layout_w};
  }
  Node :: struct {
    cost: u8 = U8_MAX;
    steps: u8 = U8_MAX;
    cf: u8 = U8_MAX; // coming from
  };
  start_idx := c2i(from);

  graph: [12 * 2]Node;
  q: [32]u8;
  ql := 0;
  graph[start_idx].cost = 0;
  graph[start_idx].steps = 0;
  graph[start_idx + 12].cost = 0;
  graph[start_idx + 12].steps = 0;

  q[0] = start_idx;
  q[1] = start_idx + 12;
  ql = 2;

  check_nb :: (idx: u8, current_l: u8, dr: s8, dc: s8, nbl: u8) #expand {
    coord := i2c(idx);
    nbr := coord.r + dr;
    nbc := coord.c + dc;
    if nbr < 0 || nbc < 0 || nbr >= layout_h || nbc >= layout_w return;
    nb_idx := c2i(.{nbr, nbc});
    //print("check_nb(%, %, %) : nb_idx=%\n", idx, dr, dc, nb_idx);
    if layout[nb_idx] == -1 return; // No button on layout.

    n := *graph[idx + 12 * current_l];
    nb := *graph[nb_idx + 12 * nbl];
    fcost := n.cost + 1 + (ifx current_l != nbl 4 else 0);
    if fcost < nb.cost {
      nb.cost = xx(fcost);
      nb.steps = n.steps + 1;
      nb.cf = idx + 12 * current_l;

      assert(ql < 16);
      q.data[ql] = xx(nb_idx + 12 * nbl);
      ql += 1;
    }
  }
  while ql {
    n := q[0];
    if ql > 1 then { q[0] = q[ql - 1]; q[ql - 1] = 0; }
    ql -= 1;

    if n < 12 {
      // vertical layer
      check_nb(n, 0, -1,  0, 0);
      check_nb(n, 0,  1,  0, 0);

      // change direction
      check_nb(n, 0,  0, -1, 1);
      check_nb(n, 0,  0,  1, 1);
    } else {
      // horizontal layer
      check_nb(n - 12, 1,  0, -1, 1);
      check_nb(n - 12, 1,  0,  1, 1);

      // change direction
      check_nb(n - 12, 1, -1,  0, 0);
      check_nb(n - 12, 1,  1,  0, 0);
    }
  }
  //print("Graph: %\n", graph);
  result : [2][6]u8;

  // Unwind
  idx := c2i(to);
  if graph[idx].cost >= graph[idx + 12].cost {
    idx += 12;
  }
  count := graph[idx].steps + 1;
  while true {
    //print("% coming from %\n", idx, graph[idx].cf);
    result[0][graph[idx].steps] = idx % 12;
    if idx == start_idx || idx == start_idx + 12 break;
    idx = graph[idx].cf;
  }
  return result, count;
}

sign :: (x : s8) -> s8 {
  if x < 0 return -1;
  if x > 0 return 1;
  return 0;
}

arrow_coord_to_string :: (arrow: Coord) -> string {
  i := 0;
  while i < ARROW_COORDS.count {
    if ARROW_COORDS[i].r == arrow.r && ARROW_COORDS[i].c == arrow.c {
      break;
    }
    i += 1;
  }
  assert(i < ARROW_COORDS.count);
  return slice("^<v>A", i, 1);
}

State :: struct {
  robot_coords: [3]Coord;
  last_diffs: [3]Coord;
  button_presses := 0;
};

init_state :: (using state: *State) {
  robot_coords[0] = NUMERIC_COORDS[10];
  robot_coords[1] = ARROW_COORDS[4];
  robot_coords[2] = ARROW_COORDS[4];

  last_diffs[0] = Coord.{};
  last_diffs[1] = Coord.{};
  last_diffs[2] = Coord.{};

  button_presses = 0;
}

enter_arrow :: (using state: *State, robot_idx: int, key_coord: Coord) -> int {
  if robot_idx == 3 {
    // We are human! Let's just push it.
    //print("Press %, with state: %\n", arrow_coord_to_string(key_coord), <<state);
    print(arrow_coord_to_string(key_coord));
    return 1;
  }
  buttons := 0;

  paths, num_paths := shortest_paths(ARROW_LAYOUT, 3, 2, robot_coords[robot_idx], key_coord);

  for paths[0] {
    if it_index == 0 continue;
    if it_index == num_paths break;
    idx := ARROW_LAYOUT[it];
    target := ARROW_COORDS[idx];
    next_diff := target - robot_coords[robot_idx];

    arrow_coord_for_direction := diff_to_arrow_coord(next_diff.r, next_diff.c);
    buttons += enter_arrow(state, robot_idx + 1, arrow_coord_for_direction);
    robot_coords[robot_idx] += next_diff;
    last_diffs[robot_idx] = next_diff;

    if key_coord == target break;
  }

  // Enter the A on the next remote!
  buttons += enter_arrow(state, robot_idx + 1, ARROW_COORDS[4]);

  return buttons;
}

enter_numeric :: (using state: *State, key_coord: Coord) -> int {
  buttons := 0;

  paths, num_paths := shortest_paths(NUMERIC_LAYOUT, 3, 4, robot_coords[0], key_coord);
  //print("Enter_numeric: paths=%\n", paths);

  for paths[0] {
    if it_index == 0 continue;
    if it_index == num_paths break;
    idx := NUMERIC_LAYOUT[it];
    target := NUMERIC_COORDS[idx];
    next_diff := target - robot_coords[0];

    arrow_coord_for_direction := diff_to_arrow_coord(next_diff.r, next_diff.c);
    buttons += enter_arrow(state, 1, arrow_coord_for_direction);
    robot_coords[0] += next_diff;
    last_diffs[0] = next_diff;

    if key_coord == target break;
  }

  // Enter the A on the next remote!
  buttons += enter_arrow(state, 1, ARROW_COORDS[4]);

  return buttons;
}


main :: () {
  SAMPLE :: true;

  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  VERBOSE :: true;

  for code : lines {
    state: State;
    init_state(*state);

    buttons := 0;
    print("Code: %  \n", code);
    for digit : code {
      nr_target: Coord;
      if digit == #char "A" nr_target = NUMERIC_COORDS[10];
      else nr_target = NUMERIC_COORDS[digit - #char "0"];

      //print("(%:%,%->%,%)", string.{1, *digit}, nr.r, nr.c, nr_target.r, nr_target.c);

      buttons += enter_numeric(*state, nr_target);

    }
    print(":  % buttons\n", buttons);
  }

}
