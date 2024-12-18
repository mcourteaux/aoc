#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#import "Thread";
#load "AOC.jai";

RegisterState :: struct {
  A, B, C : s64;
  output_len: u8;
};

Cpu :: struct {
  using regs : RegisterState;
  ip: s64;

  output: [128]u8;

  verbose := false;
};

reset :: (cpu : *Cpu) {
  cpu.A = 0;
  cpu.B = 0;
  cpu.C = 0;
  cpu.ip = 0;
  cpu.verbose = false;
  cpu.output_len = 0;
}

combo_operand :: inline (cpu: *Cpu, operand: u8) -> s64 {
  if operand <= 3 return operand;
  if operand == 4 return cpu.A;
  if operand == 5 return cpu.B;
  if operand == 6 return cpu.C;
  assert(false);
  return 0;
}

combo_operand_name :: inline (cpu: *Cpu, operand: u8) -> string {
  if operand <= 3 return "lit";
  if operand == 4 return "reg A";
  if operand == 5 return "reg B";
  if operand == 6 return "reg C";
  assert(false);
  return "error";
}

adv :: (cpu: *Cpu, operand: u8) {
  num := cpu.A;
  shift := combo_operand(cpu, operand);
  if cpu.verbose {
    print(" -> A = A >> % (%)", shift, combo_operand_name(cpu, operand));
  }
  cpu.A = num >> shift;
}

bxl :: (cpu: *Cpu, operand: u8) {
  if cpu.verbose {
    print(" -> B = B ^ % (lit)", operand);
  }
  cpu.B ^= operand;
}

bst :: (cpu: *Cpu, operand: u8) {
  if cpu.verbose {
    print(" -> B = % (%) & 0x7", combo_operand(cpu, operand), combo_operand_name(cpu, operand));
  }
  cpu.B = combo_operand(cpu, operand) & 0x7;
}

jnz :: (cpu: *Cpu, operand: u8) {
  if cpu.A != 0 {
    if cpu.verbose print(" -> jump: % (lit)", operand);
    cpu.ip = operand;
    cpu.ip -= 2;
  }
}

bxc :: (cpu: *Cpu, operand: u8) {
  if cpu.verbose print(" -> B = B ^ C");
  cpu.B = cpu.B ^ cpu.C;
}

out :: (cpu: *Cpu, operand: u8) {
  op := combo_operand(cpu, operand);
  output := op & 0x7;
  if cpu.verbose print(" -> output: % (%) & 0x7 = %", op, combo_operand_name(cpu, operand), output);
  cpu.output[cpu.output_len] = xx(output);
  cpu.output_len += 1;
}

bdv :: (cpu: *Cpu, operand: u8) {
  num := cpu.A;
  shift := combo_operand(cpu, operand);
  if cpu.verbose print(" -> B = A >> % (%)", shift, combo_operand_name(cpu, operand));
  cpu.B = num >> shift;
}

cdv :: (cpu: *Cpu, operand: u8) {
  num := cpu.A;
  shift := combo_operand(cpu, operand);
  if cpu.verbose print(" -> C = A >> % (%)", shift, combo_operand_name(cpu, operand));
  cpu.C = num >> shift;
}

OPS :: struct { name: string;
                fn: type_of(jnz);
              }.[
  .{"adv", adv},
  .{"bxl", bxl},
  .{"bst", bst},
  .{"jnz", jnz},
  .{"bxc", bxc},
  .{"out", out},
  .{"bdv", bdv},
  .{"cdv", cdv},
];

simulate :: (cpu: *Cpu, program: []u8) {
  auto_release_temp();
  while cpu.ip + 1 < program.count {
    opcode := program[cpu.ip];
    operand := program[cpu.ip + 1];

    op := OPS[opcode];
    if cpu.verbose {
      print("ip: % | A=% B=% C=% | op % (%), operand: %",
        formatInt(cpu.ip, 16, 3),
        formatInt(cpu.A, 16, 8, digits_per_comma=4, comma_string="_"),
        formatInt(cpu.B, 16, 8, digits_per_comma=4, comma_string="_"),
        formatInt(cpu.C, 16, 8, digits_per_comma=4, comma_string="_"),
        opcode, op.name, operand);
    }
    op.fn(cpu, operand);
    if cpu.verbose {
      print("\n");
    }

    cpu.ip += 2;
  }
  if cpu.verbose print("Final IP: %\n", cpu.ip);
}

revert_n_bits :: (x: s64, $n: int) -> s64 {
  r := 0;
  for i : 0..n-1 {
    r |= ((x >> i) & 1) << ((n - 1) - i);
  }
  return r;
}

main :: () {
  //input := fetch_demo_puzzle_input(true, 0);
  input := fetch_puzzle_input(true);
  lines := split(input, "\n");

  cpu: Cpu;
  cpu.verbose = true;
  {
    PREFIX :: "Register A: ".count;
    cpu.A = string_to_int(slice(lines[0], PREFIX, 100));
    cpu.B = string_to_int(slice(lines[1], PREFIX, 100));
    cpu.C = string_to_int(slice(lines[2], PREFIX, 100));
  }
  print("Cpu Init: %\n", cpu);
  PREFIX :: "Program: ".count;
  program_string := slice(lines[4], PREFIX, lines[4].count);
  program : [..]u8;
  for split(program_string, ",") {
    array_add(*program, string_to_int(it, 10, u8));
  }
  print("Program: %\n", program);

  simulate(*cpu, program);
  print("Output: %\n", array_view(cpu.output, 0, cpu.output_len));

  // Part 2
  BACKWARDS :: true;
  print("Program: %\n", program);
  init_A := ifx BACKWARDS then 0 else (ifx true 0b000_000_000_000_011_000_000_100_101_011_110_111_101_110_100_000_000_000_000_000 else 1 << (3 * 15));
  inc := 1;
  while true {
    reset(*cpu);
    #if BACKWARDS {
      reverted_A := revert_n_bits(init_A, 3 * 16);
      cpu.A = reverted_A;
    } else  {
      cpu.A = init_A;
    }

    if init_A % 10000000 == 0 {
      print("Testing... A = %\n", init_A);
    }


    simulate(*cpu, program);
    if program.count == cpu.output_len {
      num_correct := 0;

      #if !BACKWARDS {
        for i : 0..program.count-1 {
          if cpu.output[i] == program[i] {
            num_correct += 1;
          } else break;
        }
      } else {
        n := program.count;

        inc = 1;
        for i : 0..program.count-1 {
          if cpu.output[n - 1 - i] == program[n - 1 - i] {
            inc *= 0b1_000;
            num_correct += 1;
          } else break;
        }
      }

      if num_correct > 1 {
        print("init_A = oct % = bin % | % | %\n",
          formatInt(#ifx BACKWARDS reverted_A else init_A, minimum_digits=20, base=8),
          formatInt(#ifx BACKWARDS reverted_A else init_A, minimum_digits=60, base=2, digits_per_comma=3, comma_string="_"),
          array_view(cpu.output, 0, cpu.output_len), num_correct
        );
      }

      if num_correct == program.count {
        print("Found the initial A: %\n", init_A);
        //break;
      }
    } else {
      //print("% Wrong output length: % instead of %.\n", init_A, cpu.output_len, program.count);
    }

    #if BACKWARDS {
      init_A += inc;
    } else {
      init_A -= inc;
    }
    //break;
  }

  // Program loop:
  /*
ip: 000 | A=038d_45a0 B=0000_0000 C=0000_0000 | op 2 (bst), operand: 4 -> B = 59590048 (reg A) & 0x7
ip: 002 | A=038d_45a0 B=0000_0000 C=0000_0000 | op 1 (bxl), operand: 5 -> B = B ^ 5 (lit)
ip: 004 | A=038d_45a0 B=0000_0005 C=0000_0000 | op 7 (cdv), operand: 5 -> C = A >> 5 (reg B)
ip: 006 | A=038d_45a0 B=0000_0005 C=001c_6a2d | op 0 (adv), operand: 3 -> A = A >> 3 (lit)
ip: 008 | A=0071_a8b4 B=0000_0005 C=001c_6a2d | op 1 (bxl), operand: 6 -> B = B ^ 6 (lit)
ip: 00a | A=0071_a8b4 B=0000_0003 C=001c_6a2d | op 4 (bxc), operand: 3 -> B = B ^ C
ip: 00c | A=0071_a8b4 B=001c_6a2e C=001c_6a2d | op 5 (out), operand: 5 -> output: 1862190 (reg B) & 0x7 = 6
ip: 00e | A=0071_a8b4 B=001c_6a2e C=001c_6a2d | op 3 (jnz), operand: 0 -> jump: 0 (lit)
*/

/*
output = B & 7
       = B ^ C & 7
       = (B ^ 6) ^ C & 7
       = (B ^ 6) ^ (A >> (B)) & 7
       = (B ^ 5 ^ 6) ^ (A >> (B ^ 5)) & 7
       = ((A & 7) ^ 5 ^ 6) ^ (A >> ((A & 7) ^ 5)) & 7
Fully expanded, let's simplify:
       = ((A & 7) ^ (5 ^ 6)) & 7            ^  (A >> ((A & 7) ^ 5)) & 7
       = ((A & 7) ^ (0b101 ^ 0b110)) & 7    ^  (A >> ((A & 7) ^ 5)) & 7
       = ((A & 7) ^ (0b011)) & 7            ^  (A >> ((A & 7) ^ 5)) & 7
       = ((A & 7) ^ 3)                      ^  (A >> ((A & 7) ^ 5)) & 7

*/

}
