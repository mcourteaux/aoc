#import "Basic"()(MEMORY_DEBUGGER=false);
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Operations";
#import "Random";
#import "Hash_Table";
#load "AOC.jai";

Wire :: struct {
  val: bool;
  rank: int;
  generated_by: int;
  highest_bit_influence: int;
};

WireSwap :: struct {
  output_1: string;
  output_2: string;
};

find_swap :: (output: string, swaps: []WireSwap) -> *WireSwap, int #expand {
  for * swaps {
    if equal(it.output_1, output) { return it, 0; }
    if equal(it.output_2, output) { return it, 1; }
  }
  return null, 0;
}


run_graph :: (gate_descs: []string, swaps: []WireSwap, wires: *Table, sb_dot: *String_Builder, node_id: *s64, verbose := true) -> s64, s64, s64 {
  auto_release_temp();

  to_process : [..]s32;
  defer array_free(to_process);
  for gate_descs {
    array_add(*to_process, xx it_index);
  }

  idle_counter := 0;
  while to_process.count {
    idx := to_process[0];
    array_ordered_remove_by_index(*to_process, 0);

    parts := split(gate_descs[idx], " ");
    defer array_free(parts);
    assert(parts.count == 5);
    wire1_name := parts[0];
    wire2_name := parts[2];
    op := parts[1];
    output_name := parts[4];

    swap, swap_outidx := find_swap(output_name, swaps);
    if swap {
      output_name = ifx swap_outidx == 0
        then swap.output_2
        else swap.output_1;
    }

    wire1, wire1_set := table_find(wires, wire1_name);
    wire2, wire2_set := table_find(wires, wire2_name);
    out_val : bool;
    if wire1_set && wire2_set {
      if op[0] == {
        case #char "A"; out_val = wire1.val && wire2.val;
        case #char "O"; out_val = wire1.val || wire2.val;
        case #char "X"; out_val = wire1.val ^  wire2.val;
      }
      if verbose print("%[%,r=%,b=%] % %[%,r=%,b=%] = %[%]\n",
        wire1_name, cast(int) wire1.val, wire1.rank, wire1.highest_bit_influence, op,
        wire2_name, cast(int) wire2.val, wire2.rank, wire2.highest_bit_influence,
        output_name, cast(int) out_val
      );
      gen := Wire.{
        out_val,
        max(wire1.rank, wire2.rank) + 1,
        <<node_id,
        max(wire1.highest_bit_influence, wire2.highest_bit_influence),
      };
      table_set(wires, output_name, gen);

      if sb_dot {
        shape: string;
        if op[0] == {
          case #char "A"; shape = "ellipse";
          case #char "O"; shape = "box";
          case #char "X"; shape = "diamond";
        }
        print(sb_dot, "n% [label=\"%\\n%\\nr=% b=%\" shape=%];\n",
              <<node_id, op, output_name, gen.rank, gen.highest_bit_influence, shape);
        print(sb_dot, "n% -> n%;\n", wire1.generated_by, <<node_id);
        print(sb_dot, "n% -> n%;\n", wire2.generated_by, <<node_id);
      }

      idle_counter = 0;
      <<node_id += 1;
    } else {
      // Reprocess later
      array_add(*to_process, idx);
      idle_counter += 1;
      if idle_counter == to_process.count {
        break;
      }
    }
  }

  if to_process.count > 0 {
    // Not finished!
    if verbose print("Not finished.\n");
    return -1, -1, -1;
  }

  x := 0;
  y := 0;
  z := 0;
  for wire, key: <<wires {
    value := wire.val;
    if key[0] == #char "x" && value {
      bit := string_to_int(slice(key, 1, 10));
      x |= 1 << bit;
    } else if key[0] == #char "y" && value {
      bit := string_to_int(slice(key, 1, 10));
      y |= 1 << bit;
    } else if key[0] == #char "z" && value {
      bit := string_to_int(slice(key, 1, 10));
      z |= 1 << bit;
    }
  }

  return x, y, z;
}

run_graph :: (gate_desc: []string, swaps: []WireSwap, input_x: s64, input_y: s64, sb_dot: *String_Builder, node_id: *s64, verbose := true) -> s64, s64, s64 {
  wires : Table(string, Wire);
  init(*wires);
  defer deinit(*wires);

  for bit: 0..44 {
    table_add(*wires, tprint("x%", formatInt(bit, minimum_digits=2)),
              Wire.{(input_x >> bit) & 1 == 1, 0, <<node_id, bit});
    <<node_id += 1;

    table_add(*wires, tprint("y%", formatInt(bit, minimum_digits=2)),
              Wire.{(input_y >> bit) & 1 == 1, 0, <<node_id, bit});
    <<node_id += 1;
  }

  x, y, z := run_graph(gate_desc, swaps, *wires, sb_dot, node_id, verbose);
  if x != -1 && y != -1 {
    assert(x == input_x);
    assert(y == input_y);
  }
  return x, y, z;
}

backtrack_swap :: (gate_descs: []string, swaps: *[4]WireSwap, error: int, default_wires: Table(string, Wire)) -> bool {
  if error == 4 {
    return true;
  }

  ERROR_RANGES ::  s64.[17,19,  22,30,  25,29,  39,45];
  elb := ERROR_RANGES[error * 2];
  eub := ERROR_RANGES[error * 2 + 1];

  nodes_in_range: [..]string;
  defer array_free(nodes_in_range);
  for wire, wire_name : default_wires {
    if wire.highest_bit_influence >= elb && wire.highest_bit_influence <= eub {
      if wire.rank > 0 {
        array_add(*nodes_in_range, wire_name);
      }
    }
  }
  print("Error %: range (%,%) gathered % wires.\n", error, elb, eub, nodes_in_range.count);
  //checking_mask := ((1<<eub)-1) & ~((1<<elb) - 1);
  checking_mask := ((1<<eub)-1);
  if error == 3 {
    checking_mask = -1;
  } else {
    checking_mask = 0;
  }
  print("Checking mask : %\n", formatInt(checking_mask, base=2, minimum_digits=64, digits_per_comma=8, comma_string="_"));


  for n1 : nodes_in_range {
    for n2 : array_view(nodes_in_range, it_index + 1) {
      if equal(n1, n2) continue;
      auto_release_temp();

      //print("Attempting swap % <-> % ... ", n1, n2);
      swap := WireSwap.{n1, n2};
      (<<swaps)[error] = swap;

      good := true;
      num_tests := ifx error == 3 then 100 else 1;

      for test : 0..num_tests-1 {
        // x_input := (x_ << (elb - 1)) & ((1 << 44) - 1) & ~((1 << elb) - 1);
        // y_input := (y_ << (elb - 1)) & ((1 << 44) - 1) & ~((1 << elb) - 1);
        //x_input : s64 = xx(random_get() & xx((1 << eub) - 1));
        //y_input : s64 = xx(random_get() & xx((1 << eub) - 1));
        x_input : s64 = xx(random_get() & xx((1 << 44) - 1));
        y_input : s64 = xx(random_get() & xx((1 << 44) - 1));

        node_id := 10000;
        x, y, z := run_graph(gate_descs, <<swaps, x_input, y_input, null, *node_id, verbose=false);

        //print("   % + % -> %  (expected: %)  ", x, y, z, x + y);

        if x == -1 || y == -1 {
          good = false;
          break test;
        }

        if (x + y) & checking_mask == (z & checking_mask) {
          //print("MATCHES!\n");
        } else {
          good = false;
          break test;
        }
      }

      if good {
        print("OK.\n");
        print("Swap that passed all tests: % <-> %\n", n1, n2);
        if backtrack_swap(gate_descs, swaps, error + 1, default_wires) return true;
      } else {
        //print("Fail.\n");
      }
    }
  }
  print("Failed, backtrack to error=%.\n", error - 1);
  return false;
}


main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");
  defer array_free(lines);

  node_id := 0;
  default_wires : Table(string, Wire);
  init(*default_wires);
  defer deinit(*default_wires);

  sb_dot : String_Builder;
  defer reset(*sb_dot);
  print(*sb_dot, "digraph G {\n");

  line_idx := 0;
  while lines[line_idx].count {
    defer line_idx += 1;
    auto_release_temp();

    parts := split(lines[line_idx], ": ");
    defer array_free(parts);
    wire := parts[0];
    signal := string_to_int(parts[1]);
    bit := string_to_int(advance(wire));
    table_add(*default_wires, wire, Wire.{signal == 1, 0, node_id, bit});

    print(*sb_dot, "n%[label=%];\n", node_id, wire);
    node_id += 1;
  }

  gate_descs := array_view(lines, line_idx + 1);

  swaps : [4]WireSwap;

  x, y, z := run_graph(gate_descs, swaps, *default_wires, *sb_dot, *node_id);

  print(*sb_dot, "}\n");
  {
    file := file_open("graph.dot", true);
    defer file_close(*file);
    data := builder_to_string(*sb_dot);
    defer free(data.data);
    file_write(*file, data);
  }

  print("x: % = % = %\n",
    formatInt(x, base=2, minimum_digits=64, digits_per_comma=8, comma_string="_"),
    formatInt(x, base=16, minimum_digits=8),
    x);
  print("y: % = % = %\n",
    formatInt(y, base=2, minimum_digits=64, digits_per_comma=8, comma_string="_"),
    formatInt(y, base=16, minimum_digits=8),
    y);
  print("z: % = % = %\n",
    formatInt(z, base=2, minimum_digits=64, digits_per_comma=8, comma_string="_"),
    formatInt(z, base=16, minimum_digits=8),
    z);
  z_expected := x + y;
  print("Z: % = % = %\n",
    formatInt(z_expected, base=2, minimum_digits=64, digits_per_comma=8, comma_string="_"),
    formatInt(z_expected, base=16, minimum_digits=8),
    z_expected);

  // Part 2: Let's find which pairs to swap.
  swaps[0] = .{"z18", "hmt"}; // Correct!
  swaps[1] = .{"z27", "bfq"}; // Correct, I think (manually inspected)!
  swaps[2] = .{"z31", "hkh"}; // Correct, I think (manually inspected)!
  found_solution := backtrack_swap(gate_descs, *swaps, 3, default_wires);
  print("Found solution: %  %\n", found_solution, swaps);

  // Stress test solution!
  print("Stress testing...\n");
  for run: 0..1000 {
    x_input : s64 = xx(random_get() & ((1 << 44) - 1));
    y_input : s64 = xx(random_get() & ((1 << 44) - 1));
    x, y, z := run_graph(gate_descs, swaps, x_input, y_input, null, *node_id, verbose=false);
    if x + y != z {
      print("Broke for: % + % = %. real output was: %\n", x, y, x + y, z);
      break;
    }
  }

  print("Found these swaps: %\n", swaps);
  involved_wires: [8]string;
  for swaps {
    involved_wires[it_index * 2 + 0] = it.output_1;
    involved_wires[it_index * 2 + 1] = it.output_2;
  }
  quick_sort(involved_wires, compare_strings);
  print("Sorted: %\n", join(..involved_wires, separator=","));
}
