#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#import "Bit_Operations";
#load "AOC.jai";

PROFILE :: true;

FixedSize_BitArray :: struct ($N: s64) {
  NUM_SLOTS :: (N + 63) / 64;
  slots : [NUM_SLOTS]u64;
};

set_bit :: inline (ba: *FixedSize_BitArray($N), bit: u64, val: bool) {
  slot := bit >> 6;
  #if !PROFILE assert(slot < ba.NUM_SLOTS);
  shift : u64 = xx(bit & 63);
  U1 : u64 : 1;
  mask := U1 << shift;
  ba.slots[slot] = (ba.slots[slot] & ~mask) | ((cast(u64)(-cast(s64)val)) & mask);
}

get_bit :: inline (ba: *FixedSize_BitArray($N), bit: u64) -> bool {
  slot := bit >> 6;
  #if !PROFILE assert(slot < ba.NUM_SLOTS);
  shift : u64 = xx(bit & 63);
  U1 : u64 : 1;
  mask := U1 << shift;
  return (ba.slots[slot] & mask) != 0;
}

count_bits :: inline (ba: *FixedSize_BitArray($N)) -> u64 {
  count : u64 = 0;
  for ba.slots {
     count += xx popcount(it);
  }
  return count;
}

main :: () {
  SAMPLE :: false;
  #if SAMPLE {
    input := fetch_demo_puzzle_input(true, 0);
  } else {
    input := fetch_puzzle_input(true);
  }
  lines := split(input, "\n");

  NUM_NAMES :: 26 * 26;
  VertexSet :: FixedSize_BitArray(NUM_NAMES);
  full_vertex_set : VertexSet;
  connections : [NUM_NAMES][NUM_NAMES]u8;

  name_to_idx :: inline (name: string) -> u64 {
    return cast(u64)(name[0] - #char "a") * 26 + cast(u64)(name[1] - #char "a");
  }
  idx_to_name :: inline (idx: u64) -> [2]u8 {
    return u8.[xx ((idx / 26) + #char "a"), xx ((idx % 26) + #char "a")];
  }

  num_connections := 0;
  for line : lines  {
    name1 := slice(line, 0, 2);
    name2 := slice(line, 3, 2);

    i1 := name_to_idx(name1);
    i2 := name_to_idx(name2);
    connections[i1][i2] = 1;
    connections[i2][i1] = 1;
    print("% -- % == % -- %\n", name1, name2, i1, i2);

    set_bit(*full_vertex_set, i1, true);
    set_bit(*full_vertex_set, i2, true);

    num_connections += 1;
  }
  print("Made: % connections\n", num_connections);

  num_cliques_with_t_found := 0;
  for i : 0..NUM_NAMES-1 {
    for j : i+1..NUM_NAMES-1 {
      if !connections[i][j] continue;
      for k : j+1..NUM_NAMES-1 {
        if !connections[i][k] continue;
        if !connections[j][k] continue;

        ni := idx_to_name(xx i);
        nj := idx_to_name(xx j);
        nk := idx_to_name(xx k);

        if ni[0] == #char "t" || nj[0] == #char "t" || nk[0] == #char "t" {
          print("Found a clique of 3, with computer starting with t: %,%,%\n", string.{2, ni.data}, string.{2, nj.data}, string.{2, nk.data});
          num_cliques_with_t_found += 1;
        }
      }
    }
  }

  print("Number of cliques found with computer name starting with t: %\n", num_cliques_with_t_found);

  // Part 2: Maximum Clique Problem -- Bron-Kerbosch Algorithm.
  bron_kerbosch :: (r: VertexSet, p: VertexSet, x: VertexSet, connections : *[NUM_NAMES][NUM_NAMES]u8) -> bool, VertexSet {
    biggest_clique_size : u64 = 0;
    biggest_clique : VertexSet;

    if count_bits(*p) == 0 && count_bits(*x) == 0 {
      return true, r;
    }

    for v_idx : 0..NUM_NAMES - 1 {
      if get_bit(*p, xx v_idx) {
        r2 : VertexSet = r;
        set_bit(*r2, xx v_idx, true);
        p2 : VertexSet = p;
        x2 : VertexSet = x;
        set_bit(*p2, xx v_idx, false);
        set_bit(*x2, xx v_idx, false);
        for n_idx : 0..NUM_NAMES - 1 {
          if !(<<connections)[v_idx][n_idx] {
            set_bit(*p2, xx n_idx, false);
            set_bit(*x2, xx n_idx, false);
          }
        }
        found, answer := bron_kerbosch(r2, p2, x2, connections);
        if found {
          cand_size := count_bits(*answer);
          if cand_size > biggest_clique_size {
            biggest_clique_size = cand_size;
            biggest_clique = answer;
          }
        }

        set_bit(*p, xx v_idx, false);
        set_bit(*x, xx v_idx, true);
      }
    }
    return biggest_clique_size > 0, biggest_clique;
  }

  #if PROFILE t0 := current_time_monotonic();
  found, result := bron_kerbosch(.{}, full_vertex_set, .{}, *connections);
  print("Found: %\n", found);
  print("Result: %\n", result);
  #if PROFILE t1 := current_time_monotonic();
  #if PROFILE print("Runtime: %ms\n", to_float64_seconds(t1 - t0) * 1000.0);

  sb: String_Builder;
  for 0..NUM_NAMES-1 {
    if get_bit(*result, xx it) {
      name := idx_to_name(xx it);
      print(*sb, "%,", string.{2, name.data});
    }
  }
  password := builder_to_string(*sb);
  password.count -= 1;
  print("Password: %\n", password);
}
