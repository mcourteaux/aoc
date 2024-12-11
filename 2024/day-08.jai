#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

char_to_freq :: (char: u8) -> int {
  if char >= #char "a" return char - #char "a" + 36;
  if char >= #char "A" return char - #char "A" + 10;
                       return char - #char "0";
}

main :: () {
  input := read_entire_file("day-08.input");

  lines := split(input, "\n");
  if lines[lines.count - 1].count == 0 then lines.count -= 1;

  width := lines[0].count;
  height := lines.count;

  Pos :: struct { r : int; c : int; };
  antenna_positions : [62][..]Pos;

  for line, row : lines {
    for char, col : line {
      if char != #char "." {
        freq := char_to_freq(char);
        //print("freq: % from char: % (%)\n", freq, char, string.{1, *char});
        array_add(*antenna_positions[freq], .{row, col});
      }
    }
  }

  for antenna_positions {
    print("%\n", it);
  }

  assert(width <= 100 && height <= 100);
  for part : 0..1 {
    antinodes_map : [100][100]u8;
    count_antinodes := 0;
    for antenna_type : antenna_positions {
      for pos1, pos1i : antenna_type {
        for pos2, pos2i : antenna_type {
          if pos1i == pos2i continue;
          using antinode_pos : Pos = ---;
          lower := ifx part == 0 then 2 else 1;
          upper := ifx part == 0 then 2 else 100;
          for i : lower..upper {
            r = pos2.r * i - pos1.r * (i - 1);
            c = pos2.c * i - pos1.c * (i - 1);
            if r >= 0 && c >= 0 && r < height && c < width {
              if antinodes_map[r][c] == 0 {
                antinodes_map[r][c] = 1;
                count_antinodes += 1;
              }
            } else {
              break;
            }
          }
        }
      }
    }
    print("\n");
    for array_view(antinodes_map, 0, height) {
      for array_view(it, 0, width) {
        print("%", ifx it then "X" else ".");
      }
      print("\n");
    }
    print("Unique antinodes: %\n", count_antinodes);
  }
}

