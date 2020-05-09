import unittest

import decimal128

let dAThree = newDecimal128("199")
let dANine = newDecimal128("199.000000")

let dBThree = newDecimal128("0.123")
let dBNine = newDecimal128("0.123000000")

let dCThree = newDecimal128("567E+6")
let dCNine = newDecimal128("567_000_000")

suite "using nim-native number types":
  test "integer conversion":

    let testAThree = newDecimal128(199, precision=3)
    let testANine = newDecimal128(199, precision=9)

    check testAThree === dAThree
    check testAThree.getPrecision == 3
    check $testAThree == "199"
    check testAThree.toInt == 199

    check testANine === dANine
    check testANine.getPrecision == 9
    check $testANine == "199.000000"
    check testANine.toInt == 199

    let testCThree = newDecimal128(567000000, precision=3)
    let testCNine = newDecimal128(567000000, precision=9)

    check testCThree === dCThree
    check testCThree.getPrecision == 3
    check $testCThree == "5.67E+8"
    check testCThree.toInt == 567000000

    check testCNine === dCNine
    check testCNine.getPrecision == 9
    check $testCNine == "567000000"
    check testCNine.toInt == 567000000

  test "float conversion":

    let testA = newDecimal128(199.0)
    check $testA == "199.0"
    check testA.getPrecision == 4
    check testA.toInt == 199
    check testA.toFloat == 199.0

    let testB = newDecimal128(0.123)
    check $testB == "0.123"
    check testB.getPrecision == 3
    check testB.toInt == 0
    check testB.toFloat == 0.123

    let testC = newDecimal128(567000000.0)
    check $testC == "567000000.0"
    check testC.getPrecision == 10
    check testC.toInt == 567000000
    check testC.toFloat == 567000000.0

    let testD = newDecimal128(1.0 / 7.0)
    check $testD == "0.1428571428571428"
    check testD.getPrecision == 16
    check testD.toInt == 0
    check testD.toFloat == 0.1428571428571428
    check testD.toFloat != (1.0 / 7.0)  # due to decimal/binary rounding error

    let testE = newDecimal128( -5000.0 * (1.0 / 5.0) )
    check $testE == "-1000.0"
    check testE.getPrecision == 5
    check testE.toInt == -1000
    check testE.toFloat == -1000.0
    check testE.toFloat == ( -5000.0 * (1.0 / 5.0) )

