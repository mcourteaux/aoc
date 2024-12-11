#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

main :: () {
  input := read_entire_file("day-05.input");

  lines := split(input, "\n");
  if lines[lines.count - 1].count == 0 then lines.count -= 1;

  Rule :: struct {
    a, b : u8;
  };

  rules : [1200]Rule;
  num_rules : int = 0;

  for line : lines {
    if line.count == 0 break;

    parts := split(line, "|");
    rules[it_index].a = xx string_to_int(parts[0]);
    rules[it_index].b = xx string_to_int(parts[1]);
    num_rules += 1;
  }
  print("Parsed % rules.\n", num_rules);

  updates : []string;
  updates.data = *lines[num_rules + 1];
  updates.count = lines.count - num_rules - 1;

  sum_of_middle_pages_good := 0;
  sum_of_middle_pages_bad := 0;

  for update : updates {
    auto_release_temp();

    pages_str := split(update, ",");
    pages_data : [64]int;
    pages : []int;
    pages.data = pages_data.data;
    pages.count = pages_str.count;

    for ps : pages_str {
      pages[it_index] = string_to_int(ps);
    }


    bad := false;
    for p1, p1i : pages {
      for rule : rules {
        if rule.a == p1 {
          for p2, p2i : pages {
            if rule.b == p2 {
              if p1i > p2i {
                print("%\e[31m violates rule %|%\e[0m\n", pages, rule.a, rule.b);
                bad = true;
                break p1;
              }
            }
          }
        }
      }
    }

    if !bad {
      print("% \e[32mis good\e[0m\n", pages);
      sum_of_middle_pages_good += pages[pages.count / 2];
    } else {
      // Reorder everything.
      bad := true;
      swaps := 0;
      while bad {
        bad = false;
        for p1, p1i : pages {
          for rule : rules {
            if rule.a == p1 {
              for p2, p2i : pages {
                if rule.b == p2 {
                  if p1i > p2i {
                    //print("Swap p[%]:% p[%]:%\n", p1i, pages[p1i], p2i, pages[p2i]);
                    Swap(*pages[p1i], *pages[p2i]);
                    bad = true;
                    swaps += 1;
                    break p1;
                  }
                }
              }
            }
          }
        }
      }
      print(">  corrected to: % with % swaps\n", pages, swaps);
      sum_of_middle_pages_bad += pages[pages.count / 2];
    }
  }
  print("sum of middle pages good: %\n", sum_of_middle_pages_good);
  print("sum of middle pages bad: %\n", sum_of_middle_pages_bad);
}
