#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Operations";
#import "Hash_Table";
#load "AOC.jai";


main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  Wire :: struct {
    val: bool;
    rank: int;
    generated_by: int;
  };

  wires : Table(string, Wire);
  init(*wires);
  defer deinit(*wires);

  sb_dot : String_Builder;
  node_id := 0;
  defer reset(*sb_dot);
  print(*sb_dot, "digraph G {\n");

  line_idx := 0;
  while lines[line_idx].count {
    defer line_idx += 1;
    auto_release_temp();

    parts := split(lines[line_idx], ": ");
    wire := parts[0];
    signal := string_to_int(parts[1]);
    table_add(*wires, wire, Wire.{signal == 1, 0, node_id});

    print(*sb_dot, "n%[label=%];\n", node_id, wire);
    node_id += 1;
  }

  to_process : [..]s32;
  defer array_free(to_process);

  line_idx += 1;
  while line_idx < lines.count {
    defer line_idx += 1;
    array_add(*to_process, xx line_idx);
  }


  while to_process.count {
    auto_release_temp();

    line_idx := to_process[0];
    array_ordered_remove_by_index(*to_process, 0);

    parts := split(lines[line_idx], " ");
    assert(parts.count == 5);
    wire1 := parts[0];
    wire2 := parts[2];
    op := parts[1];
    output := parts[4];

    wire1_val, wire1_set := table_find(*wires, wire1);
    wire2_val, wire2_set := table_find(*wires, wire2);
    out_val : bool;
    if wire1_set && wire2_set {
      if op[0] == {
        case #char "A"; out_val = wire1_val.val && wire2_val.val;
        case #char "O"; out_val = wire1_val.val || wire2_val.val;
        case #char "X"; out_val = wire1_val.val ^  wire2_val.val;
      }
      print("%[%,%] % %[%,%] = %[%]\n",
        wire1, cast(int) wire1_val.val, wire1_val.rank, op,
        wire2, cast(int) wire2_val.val, wire1_val.rank,
        output, cast(int) out_val
      );
      gen := Wire.{
        out_val,
        max(wire1_val.rank, wire2_val.rank) + 1,
        node_id,
      };
      table_set(*wires, output, gen);

      shape: string;
      if op[0] == {
        case #char "A"; shape = "ellipse";
        case #char "O"; shape = "box";
        case #char "X"; shape = "diamond";
      }
      print(*sb_dot, "n% [label=\"%\\n%\" shape=%];\n", node_id, op, output, shape);
      print(*sb_dot, "n% -> n%;\n", wire1_val.generated_by, node_id);
      print(*sb_dot, "n% -> n%;\n", wire2_val.generated_by, node_id);
      node_id += 1;
    } else {
      // Reprocess later
      array_add(*to_process, line_idx);
    }
  }

  print(*sb_dot, "}\n");
  {
    file := file_open("graph.dot", true);
    defer file_close(*file);
    data := builder_to_string(*sb_dot);
    defer free(data.data);
    file_write(*file, data);
  }

  x := 0;
  y := 0;
  z := 0;
  for wire, key: wires {
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
  print("x: % = % = %\n",
    formatInt(x, base=2, minimum_digits=64),
    formatInt(x, base=16, minimum_digits=8),
    x);
  print("y: % = % = %\n",
    formatInt(y, base=2, minimum_digits=64),
    formatInt(y, base=16, minimum_digits=8),
    y);
  print("z: % = % = %\n",
    formatInt(z, base=2, minimum_digits=64),
    formatInt(z, base=16, minimum_digits=8),
    z);
  z_expected := x + y;
  print("Z: % = % = %\n",
    formatInt(z_expected, base=2, minimum_digits=64),
    formatInt(z_expected, base=16, minimum_digits=8),
    z_expected);
}
