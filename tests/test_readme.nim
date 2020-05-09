import unittest

import decimal128

suite "documentation references":
  test "from readme":

    let a = newDecimal128("4003.250")

    assert a.getPrecision == 7

    assert a.toFloat == 4003.25

    assert a.toInt == 4003

    assert $a == "4003.250"

    assert a === newDecimal128("4003250E-3")

    assert a === newDecimal128("4.003250E+3")

    # interpret a segment of data from a BSON file:
    let b = decodeDecimal128("2FF83CD7450BE3F39FA2D32880000000", encoding=ceBID)

    assert $b == "0.001234000000000000000000000000000000"

    assert b.getPrecision == 34

    assert b.toFloat == 0.001234
