#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file("day-03.input");

  sum_muls := 0;
  sum_muls_predicated := 0;

  enabled := true;

  for start : 0..input.count - 6 {

    if input[start + 0] == #char "d"
    && input[start + 1] == #char "o"
    && input[start + 2] == #char "("
    && input[start + 3] == #char ")" {
      enabled = true;
    }

    if input[start + 0] == #char "d"
    && input[start + 1] == #char "o"
    && input[start + 2] == #char "n"
    && input[start + 3] == #char "'"
    && input[start + 4] == #char "t"
    && input[start + 5] == #char "("
    && input[start + 6] == #char ")" {
      enabled = false;
    }

    if input[start + 0] == #char "m"
    && input[start + 1] == #char "u"
    && input[start + 2] == #char "l"
    && input[start + 3] == #char "(" {
      comma_idx := find_index_from_left(input, ",", start + 4);
      if comma_idx == -1 break;
      close_idx := find_index_from_left(input, ")", comma_idx + 1);
      if close_idx == -1 break;

      print("Evaluating % ...\n", slice(input, start, close_idx - start + 1));

      num_left_str := slice(input, start + 4, comma_idx - start - 4);
      num_right_str := slice(input, comma_idx + 1, close_idx - comma_idx - 1);

      parse_num :: (str: string) -> int, bool {
        good := str.count > 0;
        num := 0;
        for str {
          if #char "0" <= it && #char "9" {
            num = num * 10 + (it - #char "0");
          } else {
            good = false;
            break;
          }
        }
        return num, good;
      }

      num_left, left_good := parse_num(num_left_str);
      num_right, right_good := parse_num(num_right_str);

      if left_good && right_good {
        sum_muls += num_left * num_right;
        if enabled {
          sum_muls_predicated += num_left * num_right;
        }
      }
    }
  }

  print("Sum muls: %\n", sum_muls);
  print("Sum predicated muls: %\n", sum_muls_predicated);
}
