#import "Basic";
#import "File";
#import "String";
#import "Sort";
#import "Math";
#load "AOC.jai";

main :: () {
  input := fetch_puzzle_input();
  while input[input.count - 1] == #char "\n" input.count -= 1;

  tasks := split(input, "\n\n");

  BUTTON_PREFIX :: "Button A: X+";
  PRIZE_PREFIX :: "Prize: X=";
  total_cost := 0;

  for task : tasks {
    auto_release_temp();

    lines := split(task, "\n");
    a_line := split(slice(lines[0], BUTTON_PREFIX.count, 1000), ", Y+");
    b_line := split(slice(lines[1], BUTTON_PREFIX.count, 1000), ", Y+");
    p_line := split(slice(lines[2], PRIZE_PREFIX.count, 1000), ", Y=");

    dx_A, dy_A : s64 = string_to_int(a_line[0]), string_to_int(a_line[1]);
    dx_B, dy_B : s64 = string_to_int(b_line[0]), string_to_int(b_line[1]);
    x_P, y_P   : s64 = string_to_int(p_line[0]), string_to_int(p_line[1]);



    PRIZE_OFFSET : s64 : 10000000000000;
    x_P, y_P += PRIZE_OFFSET, PRIZE_OFFSET;

    COST_A :: 3;
    COST_B :: 1;

    if min(dx_A, dy_A) == 0 print("A had delta zero\n");
    if min(dx_B, dy_B) == 0 print("B had delta zero\n");

    // System of equations, LOL.
    eqs : [2][3]float64 = .[
      .[xx dx_A, xx dx_B, xx x_P], // x-equation
      .[xx dy_A, xx dy_B, xx y_P], // y-equation
    ];

    /* Row-reduced echelon form */
    {
      x_in_y_1 := eqs[1][0] / eqs[0][0];
      for i : 0..2 eqs[1][i] -= x_in_y_1 * eqs[0][i];
      norm := eqs[0][0];
      for i : 0..2 eqs[0][i] /= norm;

      y_in_x_2 := eqs[0][1] / eqs[1][1];
      for i : 0..2 eqs[0][i] -= y_in_x_2 * eqs[1][i];
      norm = eqs[1][1];
      for i : 0..2 eqs[1][i] /= norm;
    }

    fA := eqs[0][2];
    fB := eqs[1][2];

    iA : s64 = xx floor(fA + 0.5);
    iB : s64 = xx floor(fB + 0.5);

    print("% => %\n% => %\n", fA, iA, fB, iB);

    rX := iA * dx_A + iB * dx_B;
    rY := iA * dy_A + iB * dy_B;
    if iA >= 0 && iB >= 0 {
      if rX == x_P && rY == y_P {
        print("Match!");
        print("   % * (%,%) + % * (%,%) = (%,%)\n", iA, dx_A, dy_A, iB, dx_B, dy_B, rX, rY);
        total_cost += iA * COST_A + iB * COST_B;
      } else {
        print("Non-Match...\n");
      }
    } else {
      print("Non-positive\n");
    }

    print("\n");
  }
  print("Total cost: %\n", total_cost);
}
