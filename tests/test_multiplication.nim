import unittest

import decimal128


suite "multiplication and division":
  test "basic multiplication":
    check ( newDecimal128(    "2.0") * newDecimal128(    "3.0") ) === newDecimal128(    "6.0")
    check ( newDecimal128(    "1.0") * newDecimal128(    "3.0") ) === newDecimal128(    "3.3")
    check ( newDecimal128(    "0.0") * newDecimal128(    "3.0") ) === newDecimal128(    "0.0")
    check ( newDecimal128(    "1.8") * newDecimal128(    "3.3") ) === newDecimal128(    "5.9")  # NOT 5.94 due to significance rules
    check ( newDecimal128(    "9"  ) * newDecimal128(    "3"  ) ) === newDecimal128(     "27")
    check ( newDecimal128(   "99"  ) * newDecimal128(   "99"  ) ) === newDecimal128(   "98E2")  # NOT 9801 due to significance rules
    check ( newDecimal128( "9900"  ) * newDecimal128( "9900"  ) ) === newDecimal128(   "98E6")  # NOT 98,010,000 due to significance
    check ( newDecimal128( "9900.0") * newDecimal128( "9900.0") ) === newDecimal128("98010E3")
    #
    # check ( newDecimal128( "123456789012345678901234567890123") + newDecimal128("1") ) === newDecimal128( "123456789012345678901234567890124")
    # check ( newDecimal128(  "99999999999999999999999999999999") + newDecimal128("1") ) === newDecimal128( "100000000000000000000000000000000")
    # #
    # check ( newDecimal128("1234567890123456789012345678901234") + newDecimal128("1") ) === newDecimal128("1234567890123456789012345678901235")
    # check ( newDecimal128("9999999999999999999999999999999998") + newDecimal128("1") ) === newDecimal128("9999999999999999999999999999999999")

    check ( newDecimal128(    "inf") * newDecimal128(    "1.0") ) === newDecimal128(    "inf")
    check ( newDecimal128(   "-inf") * newDecimal128(    "1.0") ) === newDecimal128(   "-inf")
    check ( newDecimal128(    "inf") * newDecimal128(    "0.0") ) === newDecimal128(    "nan")
    check ( newDecimal128(    "inf") * newDecimal128(    "inf") ) === newDecimal128(    "inf")
    check ( newDecimal128(    "inf") * newDecimal128(   "-inf") ) === newDecimal128(   "-inf")
    check ( newDecimal128(   "-inf") * newDecimal128(   "-inf") ) === newDecimal128(    "inf")
    check ( newDecimal128(    "nan") * newDecimal128(    "inf") ) === newDecimal128(    "nan")
    check ( newDecimal128(    "inf") * newDecimal128(    "nan") ) === newDecimal128(    "nan")

  test "multiplication precision rounding handling":
    check 1 == 1
    # # should lose the digit due to limit of precision and "bankers rounding"
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("1") ) === newDecimal128("1.000000000000000000000000000000000E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("2") ) === newDecimal128("1.000000000000000000000000000000000E+34")
    # # 999...9 plus 6 is 100...5 and bankers-rounding rounds down to even
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("6") ) === newDecimal128("1.000000000000000000000000000000000E+34")
    # # 999...9 plus 7 is 100...6 and bankers-rounding rounds up
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("7") ) === newDecimal128("1.000000000000000000000000000000001E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("700") ) === newDecimal128("1.000000000000000000000000000000070E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("707") ) === newDecimal128("1.000000000000000000000000000000071E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("775") ) === newDecimal128("1.000000000000000000000000000000077E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("776") ) === newDecimal128("1.000000000000000000000000000000078E+34")
    # check (newDecimal128("9999999999999999999999999999999999") + newDecimal128("777") ) === newDecimal128("1.000000000000000000000000000000078E+34")
    # #
    # check (
    #   newDecimal128("9999999999999999999999999999999999") +
    #   newDecimal128("9999999999999999999999999999999999") 
    # ) === newDecimal128("2.000000000000000000000000000000000E+34")

  test "multiplication maintaining proper scale":
    check 1 == 1
  #   check ( newDecimal128(    "1.00"  ) + newDecimal128(    "1.003" ) ) === newDecimal128(    "2.00"  )
  #   check ( newDecimal128(    "2.00"  ) + newDecimal128(    "1.003" ) ) === newDecimal128(    "3.00"  )
  #   check ( newDecimal128(    "2.000" ) + newDecimal128(    "1.003" ) ) === newDecimal128(    "3.003" )
  #   check ( newDecimal128(    "2.00"  ) + newDecimal128(    "1.006" ) ) === newDecimal128(    "3.01"  )
  #   echo "ANSWER:" & $( newDecimal128(     2, scale=2      ) + newDecimal128(    "1.006" ))
  #   check ( newDecimal128(     2      ) + newDecimal128(    "1.006" ) ) === newDecimal128(    "3"     )
  #   check ( newDecimal128( 2, scale=3 ) + newDecimal128(    "1.006" ) ) === newDecimal128(    "3.006" )

  # test "multiplication from double-negative":
  #   check ( newDecimal128(    "1.0") - newDecimal128(   "-3.0") ) === newDecimal128(    "4.0")
  #   check ( newDecimal128(    "1.1") - newDecimal128(   "-3.0") ) === newDecimal128(    "4.1")
  #   check ( newDecimal128(    "1.8") - newDecimal128(   "-3.2") ) === newDecimal128(    "5.0")
  #   check ( newDecimal128(    "1.8") - newDecimal128(   "-3.3") ) === newDecimal128(    "5.1")
  #   check ( newDecimal128(    "9"  ) - newDecimal128(   "-3"  ) ) === newDecimal128(     "12")
  #   #
  #   check ( newDecimal128(   "-1.0") - newDecimal128(    "3.0") ) === newDecimal128(   "-4.0")
  #   check ( newDecimal128(   "-1.1") - newDecimal128(    "3.0") ) === newDecimal128(   "-4.1")
  #   check ( newDecimal128(   "-1.8") - newDecimal128(    "3.2") ) === newDecimal128(   "-5.0")
  #   check ( newDecimal128(   "-1.8") - newDecimal128(    "3.3") ) === newDecimal128(   "-5.1")
  #   check ( newDecimal128(   "-9"  ) - newDecimal128(    "3"  ) ) === newDecimal128(    "-12")
