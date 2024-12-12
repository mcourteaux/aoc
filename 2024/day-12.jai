#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#load "AOC.jai";

main :: () {
  input := fetch_puzzle_input();
  while input[input.count - 1] == #char "\n" input.count -= 1;

  lines := split(input, " ");

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

  for label_count: labels {
    label := #char "A" + it_index;
    if num_labels == 0 continue;


  }

}
