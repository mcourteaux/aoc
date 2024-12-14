#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

main :: () {
  input := fetch_puzzle_input(true);

  Robot :: struct {
    x : s64;
    y : s64;
    vx : s64;
    vy : s64;
  };

  W :: 101;
  H :: 103;

  TIME :: 100;

  robots : [..]Robot;

  lines := split(input, "\n");
  for lines {
    parts := split(it, " ");
    parts[0] = slice(parts[0], 2, 1000);
    parts[1] = slice(parts[1], 2, 1000);
    parse_pair :: (p: string) -> s32, s32 {
      comma := find_index_from_left(p, ",");
      return xx string_to_int(slice(p, 0, comma)),
             xx string_to_int(slice(p, comma + 1, 1000));
    }
    px, py := parse_pair(parts[0]);
    vx, vy := parse_pair(parts[1]);
    array_add(*robots, .{px, py, vx, vy});
  }

  get_quadrant :: (x: int, y: int) -> s8 {
    left := x < W / 2;
    right := x > W / 2;
    top := y < H / 2;
    bot := y > H / 2;
    if left && top return 0;
    if right && top return 1;
    if left && bot return 2;
    if right && bot return 3;
    return -1;
  }

  quads : [4]s64;
  middle := 0;
  for robots {
    rx := (it.x + (it.vx + W) * TIME) % W;
    ry := (it.y + (it.vy + H) * TIME) % H;
    quad := get_quadrant(rx, ry);
    if quad >= 0 quads[quad] += 1;
    else middle += 1;
  }

  print("Quads: % % % %\n", quads[0], quads[1], quads[2], quads[3]);
  print("In middle: %\n", middle);
  print("Safety Factor: %\n", quads[0] * quads[1] * quads[2] * quads[3]);


  // Start animation
  time : s64 = 0;
  picture : [(2*W + 1) * H]u8;
  spaces: [W * H]u8;
  while true {
    for * picture { <<it = #char " "; }
    for * spaces { <<it = 0; }
    for robots {
      rx := (it.x + (it.vx + W) * time) % W;
      ry := (it.y + (it.vy + H) * time) % H;
      picture[ry * (2*W + 1) + 2*rx] = #char "X";
      picture[ry * (2*W + 1) + 2*rx+1] = #char "X";
      spaces[ry * W + rx] = 1;
    }
    for y : 0..H-1 {
      picture[y * (2*W + 1) + 2*W] = #char "\n";
    }
    get :: (x: int, y: int) -> u8 #expand {
      if x < 0 || y < 0 || x >= W || y >= H return 0;
      return `spaces[y * W + x];
    }

    area :: (spaces: []u8, x: int, y: int) -> s32 {
      spaces[y * W + x] = 0;
      a : s32 = 1;
      if get(x + 1, y) a += area(spaces, x + 1, y);
      if get(x, y + 1) a += area(spaces, x, y + 1);
      if get(x - 1, y) a += area(spaces, x + 1, y);
      if get(x, y - 1) a += area(spaces, x, y - 1);
      return a;
    }

    connectivity := 0;
    for y : 1..H-2 {
      for x : 1..W-2 {
        if get(x, y) {
          a := area(spaces, x, y);
          connectivity += a * a;
        }
      }
    }

    if connectivity > 1000 {
      print("\e[2J\n%\nTime : %   Connectivity : %\n\n", string.{picture.count, picture.data}, time, connectivity);
      if (connectivity > 50000) {
        break;
      }
      sleep_milliseconds(xx (connectivity / 10));
    } else {
      print("\e[2J\nTime : %   Connectivity : %\n\n", time, connectivity);
    }
    time += 1;
  }

  print("Quads: % % % %\n", quads[0], quads[1], quads[2], quads[3]);
  print("In middle: %\n", middle);
  print("Safety Factor: %\n", quads[0] * quads[1] * quads[2] * quads[3]);
}
