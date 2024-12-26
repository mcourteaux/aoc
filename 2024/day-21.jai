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

cache : [30][36]s64;

press_button :: (from: Coord, to: Coord, level: int, max_level: int) -> s64 {
  if level == max_level {
    //print(arrow_coord_to_string(to));
    return 1;
  }

  cache_level := max_level - level - 1;
  cache_slot := cast(int)(from.r * 3 + from.c) * 6 + cast(int)(to.r * 3 + to.c);
  if level > 1 && cache[cache_level][cache_slot] {
    return cache[cache_level][cache_slot];
  }

  counts_per_branch : [2]s64;
  for branch : 0..1 {
    diff := to - from;
    count := 0;
    nl_from := ARROW_COORDS[4];
    ignore_illegal_locations :: () #expand {
      pos := to - diff;
      if level == 0 {
        if NUMERIC_LAYOUT[pos.r * 3 + pos.c] == -1 {
          counts_per_branch[branch] = S64_MAX;
          continue branch;
        }
      } else {
        if ARROW_LAYOUT[pos.r * 3 + pos.c] == -1 {
          counts_per_branch[branch] = S64_MAX;
          continue branch;
        }
      }
    }
    if branch == 0 {
      while diff.r {
        move := Coord.{sign(diff.r), 0};
        nl_to := diff_to_arrow_coord(move.r, move.c);
        count += press_button(nl_from, nl_to, level + 1, max_level);
        diff = diff - move;
        nl_from = nl_to;
        ignore_illegal_locations();
      }
    }
    {
      while diff.c {
        move := Coord.{0, sign(diff.c)};
        nl_to := diff_to_arrow_coord(move.r, move.c);
        count += press_button(nl_from, nl_to, level + 1, max_level);
        diff = diff - move;
        nl_from = nl_to;
        ignore_illegal_locations();
      }
    }
    if branch == 1 {
      while diff.r {
        move := Coord.{sign(diff.r), 0};
        nl_to := diff_to_arrow_coord(move.r, move.c);
        count += press_button(nl_from, nl_to, level + 1, max_level);
        diff = diff - move;
        nl_from = nl_to;
        ignore_illegal_locations();
      }
    }
    count += press_button(nl_from, ARROW_COORDS[4], level + 1, max_level);

    counts_per_branch[branch] = count;
  }

  r := min(counts_per_branch[0], counts_per_branch[1]);
  if level > 1 {
    cache[cache_level][cache_slot] = r;
  }
  return r;
}


main :: () {
  SAMPLE :: false;

  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  for part : 1..2 {
    answer := 0;

    for code : lines {
      buttons := 0;
      coord_simple := NUMERIC_COORDS[10];
      print("Code: %  ", code);
      for digit : code {
        nr_target: Coord;
        if digit == #char "A" nr_target = NUMERIC_COORDS[10];
        else nr_target = NUMERIC_COORDS[digit - #char "0"];

        max_level := ifx part == 1 then 3 else 26;
        buttons += press_button(coord_simple, nr_target, 0, max_level);
        coord_simple = nr_target;
      }
      print(":  % buttons\n", buttons);

      answer += buttons * string_to_int(code);
    }
    print("Answer (part %): %\n", part, answer);
  }

}
