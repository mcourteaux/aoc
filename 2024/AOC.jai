fetch_puzzle_input :: (year: int, day: int, strip_trailing_newlines: bool) -> string {
  print("Fetching puzzle input for %/day-%\n", year, day);
  target := sprint("day-%.input", formatInt(day, minimum_digits=2));
  in_file, ok := file_open(target);
  if ok {
    defer file_close(*in_file);
    len := file_length(in_file);
    buffer := cast(*u8) alloc(len);
    ok = file_read(in_file, buffer, len);
    if ok {
      print("Read cached input from filesystem: %.\n", target);
      result := string.{len, buffer};
      if strip_trailing_newlines {
        while result[result.count - 1] == #char "\n" result.count -= 1;
      }
      return result;
    }
  }

  url := sprint("https://adventofcode.com/%/day/%/input", year, day);
  download(url, target);
  return fetch_puzzle_input(year, day, strip_trailing_newlines);
}

fetch_puzzle_input :: (strip_trailing_newlines := false, loc := #caller_location) -> string #expand {
  year, day :: #run -> int, int {
    parts := parse_path(loc.fully_pathed_filename);
    year := string_to_int(parts.words[parts.words.count - 2]);
    fn := parts.words[parts.words.count - 1];
    day := string_to_int(slice(fn, 4, 2));
    print("year: %, day: %\n", year, day);
    return year, day;
  };
  return fetch_puzzle_input(year, day, strip_trailing_newlines);
}

#scope_file

#import "File_Utilities";
#import "Curl";

// Curl expects a C function, that's why we have to use #c_call, and since #c_call doesn't provide a context and JAI function need it, we push_context
write_callback :: (contents: *u8, count: u64, size: u64, file: *File) -> u64 #c_call {
  total_size := count * size;
  new_context: Context;
  push_context new_context {
    // Write data to the file
    file_write(file, contents, cast(s64) total_size);
  }
  return total_size;
}

load_cookie :: () -> string {
  cookie, ok := read_entire_file(".cookie");
  if ok return cookie;
  cookie, ok = read_entire_file("../.cookie");
  assert(ok);
  return cookie;
}

download :: (url: string, target: string) -> bool {
  // Init Curl and setup a deferred cleanup
  curl = curl_easy_init();
  if !curl {
    print("An error occured while initting up the Curl connection, but Curl doesn't tell us why.\n");
    return false;
  }
  defer curl_easy_cleanup(curl);


  // Set target URL
  // Curl expect a null terminated string, since it's a C library.
  // We convert url to a c string, using temp_c_string (which uses a temporary allocator)
  curl_easy_setopt(curl, .URL, temp_c_string(url));
  curl_easy_setopt(curl, .COOKIE, temp_c_string(load_cookie()));

  // Set output info
  out_file, ok := file_open(target, for_writing=true);
  if !ok {
    print("Failed to open the output file '%' for storing the download.\n", target);
    return false;
  }
  defer file_close(*out_file);
  curl_easy_setopt(curl, .WRITEFUNCTION, write_callback);
  curl_easy_setopt(curl, .WRITEDATA, *out_file);

  // Perform the "easy" action
  print("Downloading %...\n", target);
  error_code := curl_easy_perform(curl);
  if error_code != .OK {
    error_message := to_string(curl_easy_strerror(error_code));
    defer free(error_message);
    print("Curl Error: %\n", error_message);
    return false;
  }
  print("File % downloaded successfully!\n", target);
  return true;
}

// We use a global to pass Curl instance to the callback, since we need it for fetching stats.
// Another potential solution is to pass a custom struct pointer in WRITEDATA, that includes both the file info and curl instance.
// That approach is probably more flexible in bigger applications, since it allows you to pass more things, without expossing them.
// It also doesn't limit you to one instance, which might not be desirable, for complex and/or multithreaded scenarios .
// Other curl examples explore that approach.
curl: *CURL;

