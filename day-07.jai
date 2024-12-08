#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file("day-07.input");
  while input[input.count - 1] == #char "\n" input.count -= 1;
  lines := split(input, "\n");

  sum_good_results : s64 = 0;
  sum_good_results_with_concat : s64 = 0;

  for line : lines {
    found, result_str, seq_string := split_from_left(line, #char ":");
    assert(found);

    target := string_to_int(result_str, 10, s64);

    // Cut off the space after the colon.
    seq_string.data += 1;
    seq_string.count -= 1;

    numbers_str := split(seq_string, cast(u8) #char " ");
    numbers : []s64;
    numbers.data = talloc(numbers_str.count * size_of(s64));
    numbers.count = numbers_str.count;

    for numbers_str {
      numbers[it_index] = string_to_int(it, 10, s64);
    }
    numbers.count = numbers_str.count;

    num_of_operators := numbers.count - 1;
    num_combinations := 1 << num_of_operators;

    num_digits_multiplier :: (num: s64) -> s64 {
      thres := 10;
      while !(num < thres) thres *= 10;
      return thres;
    }

    search_for_combination :: (intermediate_result: s64, numbers: []s64,
                               index: int, target: s64, $support_concat := false) -> bool {
      if index == numbers.count {
        return intermediate_result == target;
      }
      new_result : s64;
      // Test +
      new_result = intermediate_result + numbers[index];
      if new_result <= target {
        if search_for_combination(new_result, numbers, index + 1, target, support_concat) {
          return true;
        }
      }
      // Test *
      new_result = intermediate_result * numbers[index];
      if new_result <= target {
        if search_for_combination(new_result, numbers, index + 1, target, support_concat) {
          return true;
        }
      }
      #if support_concat {
        // Test ||
        next_num := numbers[index];
        new_result = intermediate_result * num_digits_multiplier(next_num)  + next_num;
        if new_result <= target {
          if search_for_combination(new_result, numbers, index + 1, target, support_concat) {
            return true;
          }
        }
      }
      return false;
    }

    good_no_concat := search_for_combination(0, numbers, 0, target, false);
    if good_no_concat {
      print("% is good (no concat, and of course with as well)\n", line);
      sum_good_results += target;
      sum_good_results_with_concat += target;
    } else {
      good_with_concat := search_for_combination(0, numbers, 0, target, true);
      if good_with_concat {
        print("% is good (with concat)\n", line);
        sum_good_results_with_concat += target;
      }
    }
  }
  print("sum of good results: %\n", sum_good_results);
  print("sum of good results with concat: %\n", sum_good_results_with_concat);
}
