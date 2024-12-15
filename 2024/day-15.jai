#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

ANIMATE :: true;
ANIMATION_SLEEP :: 1;

Move :: struct { char: u8; dx: s8; dy: s8; };
MOVES : [4]Move : Move.[
  .{#char "v",  0,  1},
  .{#char ">",  1,  0},
  .{#char "<", -1,  0},
  .{#char "^",  0, -1},
];
parse_move :: (move: u8) -> int, int {
  #insert #run -> string {
    sb: String_Builder;
    init_string_builder(*sb);
    print(*sb, "if move == {\n");
    for m : MOVES {
      print(*sb, "case %; return %, %;\n", m.char, m.dx, m.dy);
    }
    print(*sb, "}\n");
    return builder_to_string(*sb);
  };
  assert(false);
}

find_robot :: (glines : []string) -> int, int {
  rx, ry : int;
  for gline, y : glines {
    for char, x : gline {
      if char == #char "@" {
        rx, ry = x, y;
        break gline;
      }
    }
  }
  print("Robot found at : % %\n", rx, ry);
  return rx, ry;
}

part_1 :: (grid: string, moves: string) -> s64
{
  glines := split(grid, "\n");
  // Find robot
  rx, ry := find_robot(glines);
  glines[ry][rx] = #char ".";

  print("%\n", grid);

  for move : moves {
    if move == #char "\n" continue;

    dx, dy := parse_move(move);

    // Fetch tile next to robot in desired direction
    num_boxes := 0;
    clear_behind := false;
    while true {
      nx, ny := rx + dx * (num_boxes + 1), ry + dy * (num_boxes + 1);
      if glines[ny][nx] == {
        case #char "O"; num_boxes += 1;
        case #char "."; clear_behind = true; break;
        case #char "#"; clear_behind = false; break;
      }
    }
    if clear_behind {
      rx, ry += dx, dy;
      if num_boxes > 0 {
        glines[ry][rx] = #char ".";
        glines[ry + dy * num_boxes][rx + dx * num_boxes] = #char "O";
      }
    }
    #if ANIMATE {
      glines[ry][rx] = #char "@";
      print("\e[2J\n%\n\n", grid);
      glines[ry][rx] = #char ".";
      sleep_milliseconds(ANIMATION_SLEEP);
    }
  }

  print("Final grid:\n%\n", grid);
  answer := 0;
  for gline, y : glines {
    for char, x : gline {
      if char == #char "O" {
        answer += y * 100 + x;
      }
    }
  }
  print("Answer (Part 1): %\n", answer);
  return answer;
}

part_2 :: (grid: string, moves: string) -> s64
{
  sb : String_Builder;
  init_string_builder(*sb);
  for char : grid {
    if char == {
      case #char "."; append(*sb, "..");
      case #char "#"; append(*sb, "##");
      case #char "@"; append(*sb, "@.");
      case #char "O"; append(*sb, "[]");
      case #char "\n"; append(*sb, "\n");
    }
  }
  wgrid := builder_to_string(*sb);
  glines := split(wgrid, "\n");

  // Find robot
  rx, ry := find_robot(glines);
  glines[ry][rx] = #char ".";

  print("%\n", wgrid);

  for move : moves {
    if move == #char "\n" continue;

    dx, dy := parse_move(move);

    // Horizontal is easy...
    if dy == 0 {
      num_boxes := 0;
      spaces_traversed := 0;
      clear_behind := false;
      while true {
        nb := glines[ry][rx + dx * (1 + spaces_traversed)];
        if nb == {
          case #char "."; clear_behind = true; break;
          case #char "["; num_boxes += 1; spaces_traversed += 1;
          case #char "]"; spaces_traversed += 1;
          case #char "#"; clear_behind = false; break;
        }
      }
      if clear_behind {
        if num_boxes > 0 {
          print("Push %: % boxes\n%\n", dx, num_boxes, glines[ry]);
          // Move 1 space, or half a box.
          for #v2 < i : 0..spaces_traversed {
            glines[ry][rx + dx * (i + 1)] = glines[ry][rx + dx * i];
          }
          print("%\n", glines[ry]);
        }
        rx += dx;
      }
    } else {
      // Vertical is gonna be a b*tch...

      can_push :: (glines: []string, x: int, y: int, dy: int) -> bool {
        if glines[y][x] == {
          case #char "["; return can_push(glines, x    , y + dy, dy)
                              && can_push(glines, x + 1, y + dy, dy);
          case #char "]"; return can_push(glines, x    , y + dy, dy)
                              && can_push(glines, x - 1, y + dy, dy);
          case #char "."; return true;
          case #char "#"; return false;
        }
        assert(false);
      }

      push :: (glines: []string, x: int, y: int, dy: int) {
        if glines[y][x] & 0x80 {
          // Already pushed through other branch of recursion.
          return;
        }

        orig := glines[y][x];
        if orig == {
          case #char "[";
            push(glines, x    , y + dy, dy);
            push(glines, x + 1, y + dy, dy);
          case #char "]";
            push(glines, x    , y + dy, dy);
            push(glines, x - 1, y + dy, dy);
          case #char ".";
            return;
          case #char "#"; assert(false);
        }

        assert(glines[y + dy][x] == #char ".",
          "Where we push to must be free: % % = %\n%", x, y,
          string.{1, *glines[y+dy][x]}, join(..glines, "\n")
        );

        if orig == {
          case #char "[";
            glines[y + dy][x] = ~glines[y][x];
            glines[y + dy][x + 1] = ~glines[y][x + 1];
            glines[y][x] = #char ".";
            glines[y][x + 1] = #char ".";
          case #char "]";
            glines[y + dy][x] = ~glines[y][x];
            glines[y + dy][x - 1] = ~glines[y][x - 1];
            glines[y][x] = #char ".";
            glines[y][x - 1] = #char ".";
        }
      }

      if can_push(glines, rx, ry + dy, dy) {
        //print("Push up/down: %\n", dy);
        //print("%\n", wgrid);
        push(glines, rx, ry + dy, dy);
        //print("%\n\n", wgrid);
        for *wgrid {
          if <<it & 0x80 {
            <<it = ~<<it;
          }
        }
        ry += dy;
      }
    }
    #if ANIMATE {
      glines[ry][rx] = #char "@";
      print("\e[2J\n%\n\n", wgrid);
      glines[ry][rx] = #char ".";
      sleep_milliseconds(ANIMATION_SLEEP);
    }
  }

  print("Final grid:\n%\n", wgrid);
  answer := 0;
  for gline, y : glines {
    for char, x : gline {
      if char == #char "[" {
        answer += y * 100 + x;
      }
    }
  }
  print("Answer (Part 2): %\n", answer);
  return answer;
}


main :: () {
  input := fetch_puzzle_input(true);

  parts := split(input, "\n\n");
  grid, moves := parts[0], parts[1];

  a1 := part_1(copy_string(grid), moves);
  a2 := part_2(copy_string(grid), moves);
  print("Answers: % %\n", a1, a2);
}
