#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Array";
#load "AOC.jai";

main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  inputs := split(input, "\n\n");
  defer array_free(inputs);


  keys: [..]u64; // bottom-up
  locks: [..]u64; // top-down

  PINS :: 5;
  DEPTH :: 5;

  for input : inputs {
    parsed: u64 = 0;

    for depth : 0..DEPTH {
      for pin : 0..PINS-1 {
        v := input[depth * (PINS + 1) + pin];
        if v == #char "#" {
          parsed |= (cast(u64)1) << ((depth - 0) * PINS + pin);
        }
      }
    }
    print("Input:\n%\nParsed:\n%\n\n", input,
          formatInt(parsed, base=2, digits_per_comma=PINS, comma_string="\n"));

    if input[0] == #char "#" {
      array_add(*locks, parsed);
    } else {
      array_add(*keys, parsed);
    }
  }

  possible_combinations := 0;
  for key: keys {
    for lock: locks {
      if key & lock == 0 {
        possible_combinations += 1;
      }
    }
  }
  print("Possible key/lock combinations: %\n", possible_combinations);

}
