import unittest

import decimal128


# suite "addition and subtraction":
#   test "basic addition":
#     check ( newDecimal(    "1.0") + newDecimal(    "3.0") ) === newDecimal(    "4.0")
#     check ( newDecimal(    "1.1") + newDecimal(    "3.0") ) === newDecimal(    "4.1")
#     check ( newDecimal(    "1.8") + newDecimal(    "3.2") ) === newDecimal(    "5.0")
#     check ( newDecimal(    "1.8") + newDecimal(    "3.3") ) === newDecimal(    "5.1")
#     check ( newDecimal(    "9"  ) + newDecimal(    "3"  ) ) === newDecimal(     "11")

#     check ( newDecimal("123456789012345678901234567890123") + newDecimal("1") ) === newDecimal("123456789012345678901234567890124")
#     check ( newDecimal("99999999999999999999999999999999") + newDecimal("1") ) === newDecimal("100000000000000000000000000000000")

#   test "significance":
#     # "significance" is the "limit of measurement" or "accuracy" a measurement
#     #
#     # a odd-but-useful way to think of significance of number 123.450
#     #
#     #  (infinity)000000000123.450(stop)
#     #
#     # adding a number with more digits to the left will simply round back to three digits after the decimal point.
#     # The number 123.450 LIMITS the digits on the left.
#     # On the other hand, that number has INFINITE digits to the left of "123.450". So adding with a number with
#     # more digits of significance on the left is not a limit. Two quick examples demonstrating both of these ideas:
#     #
#     check ( newDecimal("123.450") + newDecimal("111.111111") ) === newDecimal("234.561")  # (a) limit on the right
#     check ( newDecimal("124.450") + newDecimal("90000.000") ) === newDecimal("90123.450") # (b) no limit on the left
#     #
#     # a mix
#     #
#     check ( newDecimal("124.450") + newDecimal("90000.0") ) === newDecimal("90123.4") # (c) no limit on left, limit on right, rounded to even
#     #
#     # the number with the greatest right-hand significance sets the "common base" of the digits; aka the highest "scale"
#     #
#     # "123.450" has scale = 3
#     # "111.111111" has scale = 6
#     # "90000.000" has scale = 3
#     # "90000.0" has scale = 1
#     #
#     # - this is done internally with newTempDecimal(x: Decimal128, forceScale: int): TempDecimal
#     #   if the number can't "fit", then it properly becomes a zero
#     #
#     # rounding, however, is done on the number with the lowest "scale"
#     #
#     # - this is done internally with newDecimal128(TempDecimal, forceScale: int): Decimal128
#     #
#     # (a) sig of 123 450 000 + 111 111 111; followed by rounding at scale 3
#     #
#     # (b) sig of 00 123 450 + 90 000 000; followed by rounding at scale 3 (nothing is rounded)
#     #
#     # (c) sig of 00 123 450 + 90 000 000; followed by rounding at scale 1
#     #
#     # general checks with rounding:
#     #
#     check ( newDecimal(    "1"       ) + newDecimal(    "3.3") ) === newDecimal(    "4"  )
#     check ( newDecimal(    "1"       ) + newDecimal(    "3.8") ) === newDecimal(    "5"  )
#     check ( newDecimal(    "1"       ) + newDecimal(    "3.5") ) === newDecimal(    "4"  ) # round to even
#     check ( newDecimal(    "1.8"     ) + newDecimal(    "3"  ) ) === newDecimal(    "5"  )
#     check ( newDecimal(    "1.2"     ) + newDecimal(    "3"  ) ) === newDecimal(    "4"  )
#     check ( newDecimal(    "1.5"     ) + newDecimal(    "3"  ) ) === newDecimal(    "4"  ) # round to even
#     check ( newDecimal(    "1.500000") + newDecimal(    "3"  ) ) === newDecimal(    "4"  ) # round to even
#     #
#     # check gain/loss of significance
#     #
#     check ( newDecimal("2000") + newDecimal("10000")) === newDecimal("12000")
#     check ( newDecimal("2000") + newDecimal("1E4")) === newDecimal("1E4")     # numbers cannot gain significance "on the right"
#     check ( newDecimal("2E3") + newDecimal("1E4")) === newDecimal("1E4")      #
#     check ( newDecimal("2E3") + newDecimal("10000")) === newDecimal("12000")  # numbers can gain significance "on the left"
#     #
#     # same checks in reverse
#     #
#     check ( newDecimal("10000") + newDecimal("2000")) === newDecimal("12000")
#     check ( newDecimal("1E4") + newDecimal("2000")) === newDecimal("1E4")     # numbers cannot gain significance "on the right"
#     check ( newDecimal("1E4") + newDecimal("2E3")) === newDecimal("1E4")      #
#     check ( newDecimal("10000") + newDecimal("2E3")) === newDecimal("12000")  # numbers can gain significance "on the left"

#   test "scales":

#     discard
