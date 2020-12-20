import unittest

import decimal128


suite "using non-number decimals":
  test "NaN":

    let testNaN = newDecimal128("NaN")

    check $testNaN == "NaN"
    check testNaN.isNaN == true

    check testNaN !== newDecimal128("123")
    check testNaN !== newDecimal128("Infinity")

    check testNaN === newDecimal128("Infinity") * newDecimal128("0")

  test "Infinity":

    let testPosInf = newDecimal128("Infinity")
    let testNegInf = newDecimal128("-Infinity")

    check testPosInf.isInfinite == true
    check testPosInf.isPositive == true
    check testPosInf.isPositiveInfinity == true
    check testPosInf.isNegativeInfinity == false
    check $testPosInf == "Infinity"
    check testPosInf === newDecimal128("inf")
    check testPosInf === newDecimal128("+inf")
    check testPosInf === newDecimal128("+Infinity")

    check testNegInf.isInfinite == true
    check testNegInf.isNegative == true
    check testNegInf.isPositiveInfinity == false
    check testNegInf.isNegativeInfinity == true
    check $testNegInf == "-Infinity"
    check testNegInf === newDecimal128("-inf")

    check testNegInf !== testPosInf
