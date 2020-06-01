import unittest

import decimal128


suite "scale and precision":
  test "scale measurement":

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

# For later:

# assert $newDecimal128128("43.2") == "43.2"
# assert newDecimal128128("43.2").getPrecision == 3
# assert newDecimal128128("43.2").getScale == 1

# assert $newDecimal128128("43.2", precision=5) == "43.200"
# assert newDecimal128128("43.2", precision=5).getPrecision == 5
# assert newDecimal128128("43.2", precision=5).getScale == 3

# assert $newDecimal128128("43.2", scale=2) == "43.20"
# assert newDecimal128128("43.2", scale=2).getPrecision == 4
# assert newDecimal128128("43.2", scale=2).getScale == 2

# assert $newDecimal128128("43.2", scale=-1) == "4E+1"
# assert newDecimal128128("43.2", scale=-1).getPrecision == 1
# assert newDecimal128128("43.2", scale=-1).getScale == -1

