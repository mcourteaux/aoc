#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";

walk :: (lines_: []string, start_r: int, start_c: int, init_dir_x: int, init_dir_y: int) -> int, bool {
  lines := lines_;

  for line: lines {
    for * line {
      if <<it == #char "." then <<it = 0;
    }
  }

  MASK_U :: 0x81;
  MASK_D :: 0x82;
  MASK_L :: 0x84;
  MASK_R :: 0x88;

  dir_to_mask :: (dir_x: int, dir_y: int) -> u8 {
    mask : u8 = 0;
    if dir_x == -1 then mask |= MASK_L;
    if dir_x ==  1 then mask |= MASK_R;
    if dir_y == -1 then mask |= MASK_U;
    if dir_y ==  1 then mask |= MASK_D;
    return mask;
  }

  height := lines.count;
  width := lines[0].count;

  dir_x := init_dir_x;
  dir_y := init_dir_y;
  curr_r := start_r;
  curr_c := start_c;

  // Visit the first position!
  num_positions := 1;
  lines[curr_r][curr_c] = dir_to_mask(dir_x, dir_y);

  is_in :: inline (x: int, y: int, height: int, width: int) -> bool {
    return y >= 0 && x >= 0 && y < height && x < width;
  }

  loop := false;
  while is_in(curr_r + dir_y, curr_c + dir_x, height, width) {
    next_char := lines[curr_r + dir_y][curr_c + dir_x];
    if next_char == #char "#" {
      // Hit obstacle, rotate!
      dir_x, dir_y = -dir_y, dir_x;
    } else {
      // Move
      curr_r += dir_y;
      curr_c += dir_x;
      // Mark as visited and count it if we didn't yet.
      prev_mask := lines[curr_r][curr_c];
      if prev_mask == 0 {
        num_positions += 1;
      }
      curr_mask := dir_to_mask(dir_x, dir_y);
      if prev_mask & curr_mask & 0x0f {
        // Loop detected!
        loop = true;
        break;
      }
      lines[curr_r][curr_c] = prev_mask | curr_mask;
    }
  }
  return num_positions, loop;
}

main :: () {
  input := read_entire_file(#run replace(#file, ".jai", ".input"));
  while input[input.count - 1] == #char "\n" input.count -= 1;

  input_part_1 := copy_string(input);
  lines_part_1 := split(input_part_1, "\n");

  height := lines_part_1.count;
  width := lines_part_1[0].count;

  // Find starting point
  curr_r, curr_c := 0, 0;
  for line, r : lines_part_1 {
    for char, c : line {
      if char == #char "^" {
        curr_r, curr_c = r, c;
        break line;
      }
    }
  }

  {
    num_pos, loop := walk(lines_part_1, curr_r, curr_c, 0, -1);
    print("num positions hit: %\n", num_pos);
  }

  num_good_obstacles := 0;
  for row : 0..height-1 {
    for col : 0..width-1 {
      if (lines_part_1[row][col] & 0x80) && !(row == curr_r && col == curr_c)
      {
        // Guard moved here, let's put a crate, and see if it's any good.
        auto_release_temp();

        input_copy := copy_string(input);
        lines := split(input_copy, "\n");

        lines[row][col] = #char "#";

        num_pos, loop := walk(lines, curr_r, curr_c, 0, -1);
        if loop {
          num_good_obstacles += 1;
        }
      }
    }
  }
  print("Num good obstacle positions: %\n", num_good_obstacles);
}

