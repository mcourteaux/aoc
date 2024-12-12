#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";

#load "AOC.jai";

FREE : u32 : cast,no_check(u32) -1;

print_filesystem :: (expanded: []u32) {
  ABC :: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for expanded {
    if it == FREE {
      print(".");
    } else {
      print("%", slice(ABC, it % ABC.count, 1));
    }
  }
  print("\n");
}

checksum :: (expanded: []u32) -> s64 {
  checksum : s64 = 0;
  for expanded {
    if it != FREE {
      checksum += it * it_index;
    }
  }
  return checksum;
}

copy_and_shadow :: (array: *[]$T) #expand {
  backup := <<array;
  <<array = array_copy(backup);
  `defer {
    array_free(<<array);
    <<array = backup;
  };
}

main :: () {
  input := fetch_puzzle_input();
  while input[input.count - 1] == #char "\n" input.count -= 1;

  PRINT := input.count < 40;

  fs_size : s64 = 0;
  for input {
    assert(it >= #char "0" && it <= #char "9");
    size := it - #char "0";
    fs_size += size;
  }
  print("File system size: %\n", fs_size);
  print("Blocks: %\n", input.count);

  File :: struct {
    id: u32;
    start: u32;
    size: u32;
  };

  // Expand
  expanded : []u32 = NewArray(fs_size, u32);
  defer array_free(expanded);

  index := 0;
  file_id_counter : u32 = 0;
  in_file := true;
  files: []File = NewArray((input.count + 1) / 2, File);
  defer array_free(files);

  for input {
    block_size : s16 = xx (it - #char "0");
    if in_file {
      if block_size == 0 {
        print("File of length zero detected: %\n", file_id_counter);
      }
      for 0..block_size-1 {
        expanded[index + it] = file_id_counter;
      }
      assert(file_id_counter < files.count);
      files[file_id_counter] = .{file_id_counter, xx index, xx block_size};
      file_id_counter += 1;
    } else {
      for 0..block_size-1 {
        expanded[index + it] = FREE;
      }
    }
    index += block_size;
    in_file = !in_file;
  }
  if PRINT print_filesystem(expanded);

  // Compact (part 1)
  {
    copy_and_shadow(*expanded);
    print("Compacting (part 1)...\n");
    index = 0;
    for #v2 < 0..fs_size-1 {
      if expanded[it] == FREE {
        continue;
      }
      // Find space to put this block
      while expanded[index] != FREE {
        index += 1;
        if index >= expanded.count break;
      }
      if index >= it break;
      expanded[index] = expanded[it];
      expanded[it] = FREE;
      if PRINT print_filesystem(expanded);
      index += 1;
    }

    // Checksum
    print("Checksum after compaction: %\n", checksum(expanded));
  }

  // Compact (part 2)
  {
    copy_and_shadow(*expanded);
    print("Compacting (part 2)...\n");
    index = 0;
    first_gap : [10]s32;
    for #v2 < file: files {
      file_id := file.id;
      size := file.size;
      start := file.start;
      while find_good_gap := true {
        // Find where a gap starts.
        while first_gap[size] < expanded.count && expanded[first_gap[size]] != FREE {
          first_gap[size] += xx files[expanded[first_gap[size]]].size;
        }
        // Check if it's big enough.
        gap_size := 0;
        gap_start := first_gap[size];
        if gap_start >= expanded.count continue file;
        while gap_start + gap_size < expanded.count && expanded[gap_start + gap_size] == FREE {
          gap_size += 1;
        }
        if gap_size >= size {
          break find_good_gap;
        } else {
          first_gap[size] = xx (gap_start + gap_size);
        }
      }

      // Move the file
      dst := first_gap[size];
      src := start;
      if dst >= xx src continue file;
      first_gap[size] += xx size;

      for 0..size - 1 {
        expanded[dst + xx it] = file_id;
        expanded[src + xx it] = FREE;
      }

      if PRINT print_filesystem(expanded);
      index += 1;
    }

    // Checksum
    print("Checksum after compaction: %\n", checksum(expanded));
  }
}

