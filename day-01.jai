#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file("day-01.input");
  lines := split(input, "\n");

  list_A : [..]int;
  list_B : [..]int;

  for lines {
    space_idx := find_index_from_left(it, #char " ");
    if space_idx == -1 then break;
    A := string_to_int(slice(it, 0, space_idx));
    B := string_to_int(slice(it, space_idx + 1, it.count - space_idx - 1));

    array_add(*list_A, A);
    array_add(*list_B, B);
  }

  print("Sorting...\n");
  quick_sort(list_A, x => x);
  quick_sort(list_B, x => x);

  diff := 0;
  for i : 0..list_A.count - 1 {
    diff += abs(list_A[i] - list_B[i]);
  }
  print("diff = %\n", diff);

  sim_score := 0;
  for a : list_A {
    for b : list_B {
      if a == b {
        sim_score += a;
      }
    }
  }
  print("sim_score = %\n", sim_score);
}
