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

  MIN_CHANGE :: -9;
  MAX_CHANGE :: 9;
  NUM_CHANGES :: 19;
  buckets: [NUM_CHANGES * NUM_CHANGES * NUM_CHANGES * NUM_CHANGES]s64;

  changes_to_idx :: inline (changes: []s64) -> s64 {
    idx := changes[0] - MIN_CHANGE;
    idx = (idx * NUM_CHANGES) + (changes[1] - MIN_CHANGE);
    idx = (idx * NUM_CHANGES) + (changes[2] - MIN_CHANGE);
    idx = (idx * NUM_CHANGES) + (changes[3] - MIN_CHANGE);
    return idx;
  }

  sum := 0;

  PROFILE :: true;
  #if PROFILE t0 := current_time_monotonic();

  for line : lines {
    init_secret := string_to_int(line);

    s := init_secret;
    changes: [8]s64;
    last_digit := s % 10;

    MARKER :: (1 << 63);
    defer for * buckets {
      <<it &= (~MARKER);
    }

    for i : 0..1999 {

      PRUNE :: 16777216;
      s = (s ^ (s * 64)) % PRUNE;
      s = (s ^ (s / 32)) % PRUNE;
      s = (s ^ (s * 2048)) % PRUNE;

      digit := s % 10;
      defer last_digit = digit;

      ci := i % 8;
      change := digit - last_digit;
      changes[(ci + 0) % 8] = change;
      changes[(ci + 4) % 8] = change;
      if i >= 4 {
        last_changes := array_view(changes, (ci + 1) % 4, 4);
        #if !PROFILE assert(
          last_changes.count == 4,
          "i=%, ci=%, last_changes=%, changes=%",
          i, ci, last_changes, changes
        );
        idx := changes_to_idx(last_changes);
        if !(buckets[idx] & MARKER) {
          buckets[idx] += digit;
          buckets[idx] |= MARKER;
        }
      }
      //       0 1 2 3 4 5 6 7
      //       A B C D A B C D
      // ci=0    ^ ^ ^ ^
      // ci=1      ^ ^ ^ ^
      // ci=2        ^ ^ ^ ^
      // ci=3  ^ ^ ^ ^
      // ci=4    ^ ^ ^ ^
      // ci=5      ^ ^ ^ ^
      // ci=6        ^ ^ ^ ^
      // ci=7  ^ ^ ^ ^
    }
    #if !PROFILE print("%: %\n", init_secret, s);
    sum += s;
  }
  #if PROFILE t1 := current_time_monotonic();
  #if PROFILE print("Runtime: %ms\n", to_float64_seconds(t1 - t0) * 1000.0);

  print("Sum: %\n", sum);

  max_bananas := 0;
  for buckets {
    if it > 10 {
      changes : [4]s64;
      d := it_index;
      for #v2 < i : 0..3 {
        changes[i] = (d % NUM_CHANGES) + MIN_CHANGE;
        d /= NUM_CHANGES;
      }
      // print("Bananas in bucket %: %  changes: %\n", it_index, it, changes);
      max_bananas = max(max_bananas, it);
    }
  }
  print("Max bananas: %\n", max_bananas);
}

