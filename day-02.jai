#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file("day-02.input");
  lines := split(input, "\n");

  num_safe := 0;
  num_safe_with_dampener := 0;

  for line: lines {
    if line.count == 0 then continue;
    str_nums := split(line, " ");
    for skip_index : -1..str_nums.count-1 {
      last_num := 0;
      goes_up := false;
      good := true;
      num_idx_with_skip := 0;
      for num_str : str_nums {
        if it_index == skip_index {
          continue;
        }
        num := string_to_int(num_str);
        if num_idx_with_skip == 0 {
          last_num = num;
        } else {
          diff := num - last_num;
          if num_idx_with_skip == 1 {
            goes_up = diff > 0;
          } else {
            good &= ((diff > 0) ^ (!goes_up));
          }
          good &= diff != 0;
          good &= abs(diff) <= 3;
          last_num = num;
        }
        num_idx_with_skip += 1;
      }
      if good {
        print("line: %  -> safe = %\n", line, good);
        if skip_index == -1 then num_safe += 1;
        else {
          num_safe_with_dampener += 1;
          break;
        }
      }
    }
  }
  print("total num safe: %\n", num_safe);
  print("total num safe with dampener: %\n", num_safe_with_dampener);
}
