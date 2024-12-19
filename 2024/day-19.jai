#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  available := split(lines[0], ", ");
  lines = array_view(lines, 2);
  print("Available patterns: %\n", available);

  combination_cache : [10000]s64;

  design_possible :: (design : string, available: []string, combination_cache: []s64) -> s64 {
    if design.count == 0 return 1;
    if combination_cache[design.count] != -1 {
      return combination_cache[design.count];
    }
    num := 0;
    for pattern : available {
      if pattern.count <= design.count {
        if starts_with(design, pattern) {
          left := design;
          left.data += pattern.count;
          left.count -= pattern.count;
          num += design_possible(left, available, combination_cache);
        }
      }
    }
    combination_cache[design.count] = num;
    return num;
  }

  num_possible := 0;
  total_possible := 0;
  for design : lines {
    for * combination_cache {
      <<it = -1;
    }
    possible := design_possible(design, available, combination_cache);
    print("% is ", design);
    if possible > 0 {
      num_possible += 1;
      total_possible += possible;
      print("possible in % ways!\n", possible);
    } else {
      print("impossible!\n");
    }
  }
  print("Num possible designs: %\n", num_possible);
  print("Num total possible design ways: %\n", total_possible);
}
