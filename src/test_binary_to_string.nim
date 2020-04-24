import strutils
import decimal128


# Original test cases adapted from:
#    https://github.com/mongodb/mongo-java-driver/blob/master/bson/src/test/unit/org/bson/types/Decimal128Test.java

proc conversionTest(hexStr: string, expected: string, lossy: bool) =
  let d = hexStr.newDecimal128FromHex
  let s = $d
  if s != expected:
    echo "Error. From:"
    echo "  " & hexStr
    echo "got:"
    echo "  " & s
    echo "but expected:"
    echo "  " & expected
    raise newException(ValueError, "bad conversion")
  else:
    echo "ok : " & s


var canonicalHexStr = ""
var canonicalExpectedResult = ""
var resultLossy = false

#
# decimal128 type checks

canonicalHexStr = "7c000000000000000000000000000000"
canonicalExpectedResult = "NaN"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "78000000000000000000000000000000"
canonicalExpectedResult = "Infinity"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "f8000000000000000000000000000000"
canonicalExpectedResult = "-Infinity"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "30400000000000000000000000000000"
canonicalExpectedResult = "0"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "b0400000000000000000000000000000"
canonicalExpectedResult = "-0"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

#
# decimal simple numbers
#

canonicalHexStr = "30400000000000000000000000000000"
canonicalExpectedResult = "0"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "b0400000000000000000000000000000"
canonicalExpectedResult = "-0"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "30400000000000000000000000000001"
canonicalExpectedResult = "1"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "b0400000000000000000000000000001"
canonicalExpectedResult = "-1"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "3040000000000000002bdc545d6b4b87"
canonicalExpectedResult = "12345678901234567"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "3040000000000000000000e67a93c822"
canonicalExpectedResult = "989898983458"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "b040000000000000002bdc545d6b4b87"
canonicalExpectedResult = "-12345678901234567"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "30360000000000000000000000003039"
canonicalExpectedResult = "0.12345"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "30320000000000000000000000003039"
canonicalExpectedResult = "0.0012345"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)

canonicalHexStr = "3040000000000000002bdc545d6b4b87"
canonicalExpectedResult = "00012345678901234567"
resultLossy = false
conversionTest(canonicalHexStr, canonicalExpectedResult, resultLossy)
