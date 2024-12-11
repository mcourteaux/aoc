#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file(#run replace(#file, ".jai", ".input"));
  while input[input.count - 1] == #char "\n" input.count -= 1;

  map := split(input, "\n");
  for line : map {
    for * line {
      <<it = <<it - #char "0";
    }
  }
  for line : map {
    for line {
      print("%", it);
    }
    print("\n");
  }

  count_trails :: (map: []string, r: int, c: int, len: int) -> int, int {
    score := 0;
    count := 0;
    if (map[r][c] & 0xf) == 9 - len {
      if len == 0 {
        if map[r][c] == 9 {
          map[r][c] |= 0x80; // Change the map to not count twice!
          score += 1;
        }
        count += 1;
      } else {
        if r + 1 < map.count     score, count += count_trails(map, r + 1, c, len - 1);
        if r - 1 >= 0            score, count += count_trails(map, r - 1, c, len - 1);
        if c + 1 < map[0].count  score, count += count_trails(map, r, c + 1, len - 1);
        if c - 1 >= 0            score, count += count_trails(map, r, c - 1, len - 1);
      }
    }
    return score, count;
  }

  height := map.count;
  width := map[0].count;
  score := 0;
  count := 0;
  for row : 0..height-1 {
    for col : 0..width-1 {
      if map[row][col] == 0 {
        trailhead, trailcount := count_trails(map, row, col, 9);
        score += trailhead;
        count += trailcount;
        if trailhead > 0 {
          print("Trailhead from % % with score % and count %\n", row, col, trailhead, trailcount);

          // Reset 9's
          for map {
            for * it {
              if <<it == 0x89 then <<it = 9;
            }
          }
        }

      }
    }
  }
  print("Score: %\n", score);
  print("Count: %\n", count);
}
