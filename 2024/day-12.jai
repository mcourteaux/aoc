#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#load "AOC.jai";

main :: () {
  input := fetch_puzzle_input();
  //input := copy_string("AAAA\nBBCD\nBBCC\nEEEC");

  while input[input.count - 1] == #char "\n" input.count -= 1;
  lines := split(input, "\n");

  labels : [27]u8;
  num_labels := 0;
  for line : lines {
    for line {
      idx := it - #char "A";
      if labels[idx] == 0 {
        num_labels += 1;
      }
      labels[idx] += 1;
    }
  }
  print("labels: %\n", labels);

  Fence :: struct {
    row: u16;
    col: u16;
    row_out_dir: s8;
    col_out_dir: s8;
  };

  Side :: struct {
    min_row : s16;
    max_row : s16;
    min_col : s16;
    max_col : s16;
    row_out_dir : s8;
    col_out_dir : s8;
  };

  fence_stack: [..]Side;
  array_reserve(*fence_stack, 1024);

  find_garden :: (lines: []string, tgt: u8, row: int, col: int, fence_stack: *[..]Side) -> int, int {
    perim := 0;
    area := 1;

    height := lines.count;
    width := lines[0].count;

    // Mark the cell as in-process, so we don't recurse
    lines[row][col] = ~tgt;

    check_neighbour :: (drow: int, dcol: int) #expand {
      nrow := row + drow;
      ncol := col + dcol;
      if nrow >= 0 && nrow < height
      && ncol >= 0 && ncol < width {
        if lines[nrow][ncol] == tgt {
          `perim, `area += find_garden(lines, tgt, nrow, ncol, fence_stack);
        } else if lines[nrow][ncol] != ~tgt {
          //print("Garden % fence perimeter between: % % and % % (nb val: %)\n", string.{1, *tgt}, row, col, nrow, ncol, lines[nrow][ncol]);
          `perim += 1;
          array_add(fence_stack, Side.{xx row, xx row, xx col, xx col, drow, dcol});
        }
      } else {
        //print("Garden % map-fence perimeter at: % %\n", string.{1, *tgt}, row, col);
        `perim += 1;
        array_add(fence_stack, Side.{xx row, xx row, xx col, xx col, drow, dcol});
      }
    }

    check_neighbour( 1, 0);
    check_neighbour(-1, 0);
    check_neighbour(0,  1);
    check_neighbour(0, -1);

    return perim, area;
  }

  merge_sides :: (sides: *[..]Side) {
    is_hor :: inline (side : Side) -> bool { return side.col_out_dir == 0; }
    is_ver :: inline (side : Side) -> bool { return side.row_out_dir == 0; }
    same_ori :: inline (a: Side, b: Side) -> bool { return a.col_out_dir == b.col_out_dir && a.row_out_dir == b.row_out_dir; }
    in_line :: inline (a: Side, b: Side) -> bool {
      if (same_ori(a, b)) {
        if (is_hor(a)) return a.min_row == b.min_row;
        if (is_ver(a)) return a.min_col == b.min_col;
        assert(false);
      }
      return false;
    }
    inline_and_connect :: inline (a: Side, b: Side) -> bool {
      if (same_ori(a, b)) {
        if (is_hor(a)) return a.min_row == b.min_row && min(a.max_col, b.max_col) + 1 == max(a.min_col, b.min_col);
        if (is_ver(a)) return a.min_col == b.min_col && min(a.max_row, b.max_row) + 1 == max(a.min_row, b.min_row);
        assert(false);
      }
      return false;
    }
    merge :: inline (a: Side, b: Side) -> Side {
      return .{min(a.min_row, b.min_row), max(a.max_row, b.max_row), min(a.min_col, b.min_col), max(a.max_col, b.max_col), a.row_out_dir, b.col_out_dir};
    }

    did_merge := true;
    while did_merge {
      did_merge = false;

      for a_idx : 0..sides.count-1 {
        a : Side = (<<sides)[a_idx];
        for b_idx : a_idx+1..sides.count-1 {
          b : Side = (<<sides)[b_idx];
          if inline_and_connect(a, b) {
            //print("Connect % and %\n", a, b);
            merged := merge(a, b);

            (<<sides)[a_idx] = merged;
            array_unordered_remove_by_index(sides, b_idx);
            did_merge = true;
            break a_idx;
          }
        }
      }
    }
  }

  cost := 0;
  bulk_cost := 0;
  for label_count: labels {
    label := #char "A" + it_index;
    if num_labels == 0 continue;


    for line, row : lines {
      for char, col : line {
        if char == label {

          fence_stack.count = 0; // Reset count

          perimeter, area := find_garden(lines, xx label, row, col, *fence_stack);
          merge_sides(*fence_stack);
          print("Garden % has perimeter % (% distinct sides) and area %\n", string.{1, xx*label}, perimeter, fence_stack.count, area);
          cost += perimeter * area;
          bulk_cost += fence_stack.count * area;
        }
      }
    }
  }
  print("Total \"modern business\" cost: %\n", cost);
  print("Total \"modern business\" bulk cost: %\n", bulk_cost);

}
