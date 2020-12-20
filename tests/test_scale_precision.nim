import unittest

import decimal128


suite "scale and precision":
  test "scale measurement (from string)":

    check newDecimal128("0").getScale == 0
    check newDecimal128("1").getScale == 0
    check newDecimal128("1.0").getScale == 1
    check newDecimal128("1.00").getScale == 2
    check newDecimal128("1.000").getScale == 3
    check newDecimal128("1.0000").getScale == 4
    check newDecimal128("-0.0000").getScale == 4

    check newDecimal128("1.0000").getScale == 4
    check newDecimal128("10.000").getScale == 3
    check newDecimal128("100.00").getScale == 2
    check newDecimal128("1000.0").getScale == 1
    check newDecimal128("10000.").getScale == 0
    check newDecimal128("10000").getScale == 0

    check newDecimal128("001.0000").getScale == 4
    check newDecimal128("00010000").getScale == 0

    check newDecimal128("1").getScale == 0
    check newDecimal128("1") === newDecimal128("1E+0")
    check newDecimal128("1E+0").getScale == 0
    check newDecimal128("1E+1").getScale == -1
    check newDecimal128("1E+2").getScale == -2
    check newDecimal128("1E+3").getScale == -3

    check newDecimal128("1E-0").getScale == 0
    check newDecimal128("1E-1").getScale == 1
    check newDecimal128("1E-2").getScale == 2
    check newDecimal128("1E-3").getScale == 3
    #
    check newDecimal128("1E-3") === newDecimal128("0.001")

    check newDecimal128("1E+3").getScale == -3
    check newDecimal128("1.0E+3").getScale == -2
    check newDecimal128("1.00E+3").getScale == -1
    check newDecimal128("1.000E+3").getScale == 0
    check newDecimal128("1.0000E+3").getScale == 1
    #
    check newDecimal128("1.00000E+3").getScale == 2
    check newDecimal128("1.00000E+3") === newDecimal128("1000.00")

    check newDecimal128("1234567890123456789012345678901234").getScale == 0     # 34 is max precision
    check newDecimal128("1234567890123456789012345678901234567").getScale == -3 # so, with rounding, we get negative scale
    #
    check newDecimal128("1234567890123456789012345678901234567") === newDecimal128("1234567890123456789012345678901235000")
    check newDecimal128("1234567890123456789012345678901234500") === newDecimal128("1234567890123456789012345678901234000")

    check newDecimal128("0.1234567890123456789012345678901234").getScale == 34 
    check newDecimal128("0.0000012345678901234567890123456789").getScale == 34
    check newDecimal128("0.000001234567890123456789012345678901234").getScale == 39
    check newDecimal128("0.000001234567890123456789012345678901234567").getScale == 39

  test "precision measurement (from string)":

    check newDecimal128("0").getPrecision == 1
    check newDecimal128("1").getPrecision == 1
    check newDecimal128("1.0").getPrecision == 2
    check newDecimal128("1.00").getPrecision == 3
    check newDecimal128("1.000").getPrecision == 4
    check newDecimal128("1.0000").getPrecision == 5

    check newDecimal128("-0.0000").getPrecision == 4
    check newDecimal128("0.0000").getPrecision == 4
    check newDecimal128("0.083").getPrecision == 3
    check newDecimal128("0.0").getPrecision == 1

    check newDecimal128("1.0000").getPrecision == 5
    check newDecimal128("10.000").getPrecision == 5
    check newDecimal128("100.00").getPrecision == 5
    check newDecimal128("1000.0").getPrecision == 5
    check newDecimal128("10000.").getPrecision == 5

    check newDecimal128("001.0000").getPrecision == 5
    check newDecimal128("00010000").getPrecision == 5

    check newDecimal128("1").getPrecision == 1
    check newDecimal128("1") === newDecimal128("1E+0")
    check newDecimal128("1E+0").getPrecision == 1
    check newDecimal128("1E+1").getPrecision == 1
    check newDecimal128("1E+2").getPrecision == 1
    check newDecimal128("1E+3").getPrecision == 1

    check newDecimal128("1E-0").getPrecision == 1
    check newDecimal128("1E-1").getPrecision == 1
    check newDecimal128("1E-2").getPrecision == 1
    check newDecimal128("1E-3").getPrecision == 1
    #
    check newDecimal128("1E-3") === newDecimal128("0.001")

    check newDecimal128("1E+3").getPrecision == 1
    check newDecimal128("1.0E+3").getPrecision == 2
    check newDecimal128("1.00E+3").getPrecision == 3
    check newDecimal128("1.000E+3").getPrecision == 4
    check newDecimal128("1.0000E+3").getPrecision == 5
    check newDecimal128("1.00000E+3").getPrecision == 6
    #
    check newDecimal128("1.00000E+3") === newDecimal128("1000.00")

    check newDecimal128("1234567890123456789012345678901234").getPrecision == 34     # 34 is max precision
    check newDecimal128("1234567890123456789012345678901234567").getPrecision == 34
    #
    check newDecimal128("1234567890123456789012345678901234567") === newDecimal128("1234567890123456789012345678901235000")

    check newDecimal128("0.1234567890123456789012345678901234").getPrecision == 34   # 34 is max precision
    check newDecimal128("0.0000012345678901234567890123456789").getPrecision == 29
    check newDecimal128("0.000001234567890123456789012345678901234").getPrecision == 34
    check newDecimal128("0.000001234567890123456789012345678901234567").getPrecision == 34
    #
    check newDecimal128("0.000001234567890123456789012345678901234567") === newDecimal128("0.000001234567890123456789012345678901235")
    #
    # check for extreme rounding examples
    # almost all nines:
    check newDecimal128("0.000000899999999999999999999999999999999999") === newDecimal128("0.0000009000000000000000000000000000000000")
    # all nines:
    check newDecimal128("0.000000999999999999999999999999999999999999") === newDecimal128("0.000001000000000000000000000000000000000")

  test "set scale":
    check $newDecimal128(123, scale=2) == "123.00"
    check $newDecimal128("123.0000", scale=2) == "123.00"
    check $newDecimal128(123.0, scale=2) == "123.00"

    check $newDecimal128(123, scale= -1) == "1.2E+2"
    check $newDecimal128("123.0000", scale= -1) == "1.2E+2"
    check $newDecimal128(123.0, scale= -1) == "1.2E+2"

  test "set precision":
    check $newDecimal128(123, precision=5) == "123.00"
    check $newDecimal128("123.0000", precision=5) == "123.00"
    check $newDecimal128(123.0, precision=5) == "123.00"

    check $newDecimal128(123, precision=2) == "1.2E+2"
    check $newDecimal128("123.0000", precision=2) == "1.2E+2"
    check $newDecimal128(123.0, precision=2) == "1.2E+2"

  test "set both scale and precision":
    check $newDecimal128(123, precision=5, scale=2) == "123.00"
    check $newDecimal128("123.0000", precision=5, scale=2) == "123.00"
    check $newDecimal128(123.0, precision=5, scale=2) == "123.00"

    check $newDecimal128(123, precision=6, scale=2) == "123.00"
    check $newDecimal128("123.0000", precision=6, scale=2) == "123.00"
    check $newDecimal128(123.0, precision=6, scale=2) == "123.00"

    expect ValueError:
      let _ = $newDecimal128(123, precision=4, scale=2)
    expect ValueError:
      let _ = $newDecimal128("123.0000", precision=4, scale=2)
    expect ValueError:
      let _ = $newDecimal128(123.0, precision=4, scale=2)
