#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

PRINT_STONES :: false;

Memoization :: struct {
  STONE_SLOTS :: 2000;
  BLINK_SLOTS :: 800;
  memory: [BLINK_SLOTS][STONE_SLOTS]s64;
}

memoization : Memoization;

blink :: (stone: s64, times: int) -> s64 {
  if times == 0 {
    if PRINT_STONES print("% ", stone);
    return 1;
  }

  memoize := stone < Memoization.STONE_SLOTS && times < Memoization.BLINK_SLOTS;
  if memoize && memoization.memory[times][stone] != -1 {
    return memoization.memory[times][stone];
  }

  count := 0;
  if stone == 0 {
    count += blink(1, times - 1);
  } else {
    pot := 1;
    exp := 0;
    while pot <= stone {
      pot *= 10;
      exp += 1;
    }
    if exp % 2 == 0 && exp >= 1 {
      hpot := 1;
      for 1..(exp/2) {
        hpot *= 10;
      }
      left := stone / hpot;
      right := stone - left * hpot;
      assert(left * hpot + right == stone);
      count += blink(left, times - 1);
      count += blink(right, times - 1);
    } else {
      count += blink(stone * 2024, times - 1);
    }
  }

  if memoize {
    memoization.memory[times][stone] = count;
  }

  return count;
}

run_stones :: (input: string, blink_count: int) {
  t0 := current_time_monotonic();
  numbers := split(input, " ");
  stone_count := 0;
  for num_str : numbers {
    num := string_to_int(num_str);
    stone_count += blink(num, blink_count);
  }
  if PRINT_STONES print("\n");
  t1 := current_time_monotonic();
  print("Stones: %  (% ms)\n", stone_count, to_float64_seconds(t1 - t0) * 1000.0);
}

main :: () {
  for 0 .. 2 {
    // Init memoization
    print("\nClear memoization.\n");
    for memoization.memory {
      for * it {
        <<it = -1;
      }
    }

    run_stones("125 17", 6);
    run_stones("125 17", 25);
    run_stones("4022724 951333 0 21633 5857 97 702 6", 25);
    run_stones("4022724 951333 0 21633 5857 97 702 6", 75);
    run_stones("4022724 951333 0 21633 5857 97 702 6", 200);
    run_stones("4022724 951333 0 21633 5857 97 702 6", 400);
  }
}
