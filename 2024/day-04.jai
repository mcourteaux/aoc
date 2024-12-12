#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#load "AOC.jai";

main :: () {
  input := fetch_puzzle_input();

  lines := split(input, "\n");
  if lines[lines.count - 1].count == 0 then lines.count -= 1;

  num_hits_part_1 := 0;
  num_hits_part_2 := 0;

  height := lines.count;
  width := lines[0].count;

  Dir :: struct {
    x : int;
    y : int;
  }

  TARGET :: "XMAS";
  #run print("Target: % with length: %\n", TARGET, TARGET.count);

  for line, row : lines {
    for char, col : line {
      // Part 1
      if char == TARGET[0] {
        for dir : Dir.[.{0, 1}, .{1, 1}, .{1, 0}, .{1, -1}, .{0, -1}, .{-1, -1}, .{-1, 0}, .{-1, 1}] {
          end_x := col + dir.x * (TARGET.count - 1);
          end_y := row + dir.y * (TARGET.count - 1);
          if end_x < 0 || end_y < 0 || end_x >= width || end_y >= height {
            continue;
          }

          // We can safely iterate!
          found := true;
          for i : 1..TARGET.count - 1 {
            if lines[row + dir.y * i][col + dir.x * i] != TARGET[i] {
              found = false;
              break;
            }
          }

          if found then num_hits_part_1 += 1;
        }
      }

      // Part 2
      if row > 0 && row < width  - 1
      && col > 0 && col < height - 1 {
        if char == #char "A" {
          lu := lines[row - 1][col - 1];
          ru := lines[row - 1][col + 1];
          ld := lines[row + 1][col - 1];
          rd := lines[row + 1][col + 1];
          if ((lu == #char "M" && rd == #char "S")
           || (lu == #char "S" && rd == #char "M"))
          && ((ru == #char "M" && ld == #char "S")
           || (ru == #char "S" && ld == #char "M")) {
             num_hits_part_2 += 1;
           }
        }
      }
    }
  }

  print("Found % times % in a % x % letter grid.\n", num_hits_part_1, TARGET, height, width);
  print("Found % X-shaped MAS's.\n", num_hits_part_2);
}
