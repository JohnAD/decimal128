import strutils
import decimal128

# Many original test cases adapted from:
#    * https://github.com/mongodb/mongo-java-driver/blob/master/bson/src/test/unit/org/bson/types/Decimal128Test.java
#    * ...

proc conversionTest(testNo: int, hexStr: string, canonicalStr: string, lossy: bool) =
  echo "testing $1: $2".format(testNo, canonicalStr)
  #
  echo "  decoding binary..."
  let decoded = hexStr.newDecimal128UsingBID
  let s = $decoded
  if s != canonicalStr:
    echo "    Error. Got:"
    echo "      " & s
    echo "    but expected:"
    echo "      " & canonicalStr
    raise newException(ValueError, "bad decoding")
  #
  echo "  parsing canonical string..."
  let parsed = newDecimal128(canonicalStr)
  if parsed !== decoded:
    echo "    Error. Parsed Decimal128 did not match decoded Decimal128."
    echo "    decoded: " & decoded.repr
    echo "    parsed : " & parsed.repr
    raise newException(ValueError, "bad parsing")
  #
  echo "  OK"

var canonicalHexBin = ""
var canonicalStr = ""
var resultLossy = false

canonicalHexBin = "7c000000000000000000000000000000"
canonicalStr = "NaN"
resultLossy = false
conversionTest(1, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "78000000000000000000000000000000"
canonicalStr = "Infinity"
resultLossy = false
conversionTest(2, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "f8000000000000000000000000000000"
canonicalStr = "-Infinity"
resultLossy = false
conversionTest(3, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "30400000000000000000000000000000"
canonicalStr = "0"
resultLossy = false
conversionTest(4, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "b0400000000000000000000000000000"
canonicalStr = "-0"
resultLossy = false
conversionTest(5, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "30400000000000000000000000000001"
canonicalStr = "1"
resultLossy = false
conversionTest(6, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "b0400000000000000000000000000001"
canonicalStr = "-1"
resultLossy = false
conversionTest(7, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "3040000000000000000000000000007B"
canonicalStr = "123"
resultLossy = false
conversionTest(8, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "304000000000000000000000000001C8"
canonicalStr = "456"
resultLossy = false
conversionTest(9, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "30400000000000000000000000000315"
canonicalStr = "789"
resultLossy = false
conversionTest(10, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "304000000000000000000000000003E7"
canonicalStr = "999"
resultLossy = false
conversionTest(11, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "304000000000000000000000000003E8"
canonicalStr = "1000"
resultLossy = false
conversionTest(12, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "304000000000000000000000000003FF"
canonicalStr = "1023"
resultLossy = false
conversionTest(13, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "30400000000000000000000000000400"
canonicalStr = "1024"
resultLossy = false
conversionTest(14, canonicalHexBin, canonicalStr, resultLossy)

canonicalHexBin = "3040000000000000000000000098967F"
canonicalStr = "9999999"
resultLossy = false
conversionTest(15, canonicalHexBin, canonicalStr, resultLossy)

# nine nines (one less than 1 billion)
canonicalHexBin = "3040000000000000000000003B9AC9FF"
canonicalStr = "999999999"
resultLossy = false
conversionTest(16, canonicalHexBin, canonicalStr, resultLossy)

# one billion exactly
canonicalHexBin = "3040000000000000000000003B9ACA00"
canonicalStr = "1000000000"
resultLossy = false
conversionTest(17, canonicalHexBin, canonicalStr, resultLossy)

# one billion plus 1
canonicalHexBin = "3040000000000000000000003B9ACA01"
canonicalStr = "1000000001"
resultLossy = false
conversionTest(18, canonicalHexBin, canonicalStr, resultLossy)

# 10 ^ 25 (more than 64 bits and lots of zeroes)
canonicalHexBin = "3040000000084595161401484A000000"
canonicalStr = "10000000000000000000000000"
resultLossy = false
conversionTest(19, canonicalHexBin, canonicalStr, resultLossy)

# all 34 digits filled
canonicalHexBin = "30403CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "1234567890123456789012345678901234"
resultLossy = false
conversionTest(20, canonicalHexBin, canonicalStr, resultLossy)

# 34 nines
canonicalHexBin = "3041ED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9999999999999999999999999999999999"
resultLossy = false
conversionTest(21, canonicalHexBin, canonicalStr, resultLossy)

# Regular - 0.1
canonicalHexBin = "303E0000000000000000000000000001"
canonicalStr = "0.1"
resultLossy = false
conversionTest(21, canonicalHexBin, canonicalStr, resultLossy)

# Regular - 0.1234567890123456789012345678901234
canonicalHexBin = "2FFC3CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "0.1234567890123456789012345678901234"
resultLossy = false
conversionTest(22, canonicalHexBin, canonicalStr, resultLossy)

# Regular - Smallest
canonicalHexBin = "303400000000000000000000000004D2"
canonicalStr = "0.001234"
resultLossy = false
conversionTest(23, canonicalHexBin, canonicalStr, resultLossy)

# Regular - Smallest with Trailing Zeros
canonicalHexBin = "302C0000000000000000000000BC4B20"
canonicalStr = "0.0012340000"
resultLossy = false
conversionTest(24, canonicalHexBin, canonicalStr, resultLossy)

# Regular - -0.0",
canonicalHexBin = "B03E0000000000000000000000000000"
canonicalStr = "-0.0"
resultLossy = false
conversionTest(25, canonicalHexBin, canonicalStr, resultLossy)

# Regular - 2.000
canonicalHexBin = "303A00000000000000000000000007D0"
canonicalStr = "2.000"
resultLossy = false
conversionTest(26, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Tiniest
canonicalHexBin = "0001ED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9.999999999999999999999999999999999E-6143"
resultLossy = false
conversionTest(27, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Tiny
canonicalHexBin = "00000000000000000000000000000001"
canonicalStr = "1E-6176"
resultLossy = false
conversionTest(28, canonicalHexBin, canonicalStr, resultLossy)

# # Scientific - Negative Tiny
# canonicalHexBin = "7C000000000000000000000000000000"
# canonicalStr =  "-1E-6176"
# resultLossy = false
# conversionTest(canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Adjusted Exponent Limit
canonicalHexBin = "2FF03CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "1.234567890123456789012345678901234E-7"
resultLossy = false
conversionTest(29, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Fractional
canonicalHexBin = "B02C0000000000000000000000000064"
canonicalStr = "-1.00E-8"
resultLossy = false
conversionTest(30, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - 0 with Exponent
canonicalHexBin = "5F200000000000000000000000000000"
canonicalStr = "0E+6000"
resultLossy = false
conversionTest(31, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - 0 with Negative Exponent
canonicalHexBin = "2B7A0000000000000000000000000000"
canonicalStr = "0E-611"
resultLossy = false
conversionTest(32, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - No Decimal with Signed Exponent
canonicalHexBin = "30460000000000000000000000000001"
canonicalStr = "1E+3"
resultLossy = false
conversionTest(33, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Trailing Zero
canonicalHexBin = "3042000000000000000000000000041A"
canonicalStr = "1.050E+4"
resultLossy = false
conversionTest(34, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - With Decimal
canonicalHexBin = "30420000000000000000000000000069"
canonicalStr = "1.05E+3"
resultLossy = false
conversionTest(35, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Full
canonicalHexBin = "3040FFFFFFFFFFFFFFFFFFFFFFFFFFFF"
canonicalStr = "5192296858534827628530496329220095"
resultLossy = false
conversionTest(36, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Large
canonicalHexBin = "5FFE314DC6448D9338C15B0A00000000"
canonicalStr = "1.000000000000000000000000000000000E+6144"
resultLossy = false
conversionTest(37, canonicalHexBin, canonicalStr, resultLossy)

# Scientific - Largest
canonicalHexBin = "5FFFED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9.999999999999999999999999999999999E+6144"
resultLossy = false
conversionTest(38, canonicalHexBin, canonicalStr, resultLossy)



#
# the rest of these are for parsing tests:
#

 #        {
 #            "description": "Non-Canonical Parsing - Exponent Normalization",
 #            "canonical_bson": "1800000013640064000000000000000000000000002CB000",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-100E-10\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-1.00E-8\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - Unsigned Positive Exponent",
 #            "canonical_bson": "180000001364000100000000000000000000000000463000",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E3\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E+3\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - Lowercase Exponent Identifier",
 #            "canonical_bson": "180000001364000100000000000000000000000000463000",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"1e+3\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E+3\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - Long Significand with Exponent",
 #            "canonical_bson": "1800000013640079D9E0F9763ADA429D0200000000583000",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"12345689012345789012345E+12\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1.2345689012345789012345E+34\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - Positive Sign",
 #            "canonical_bson": "18000000136400F2AF967ED05C82DE3297FF6FDE3C403000",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"+1234567890123456789012345678901234\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1234567890123456789012345678901234\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - Long Decimal String",
 #            "canonical_bson": "180000001364000100000000000000000000000000722800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E-999\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - nan",
 #            "canonical_bson": "180000001364000000000000000000000000000000007C00",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"nan\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"NaN\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - nAn",
 #            "canonical_bson": "180000001364000000000000000000000000000000007C00",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"nAn\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"NaN\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - +infinity",
 #            "canonical_bson": "180000001364000000000000000000000000000000007800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"+infinity\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - infinity",
 #            "canonical_bson": "180000001364000000000000000000000000000000007800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"infinity\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - infiniTY",
 #            "canonical_bson": "180000001364000000000000000000000000000000007800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"infiniTY\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - inf",
 #            "canonical_bson": "180000001364000000000000000000000000000000007800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"inf\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - inF",
 #            "canonical_bson": "180000001364000000000000000000000000000000007800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"inF\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - -infinity",
 #            "canonical_bson": "18000000136400000000000000000000000000000000F800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-infinity\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - -infiniTy",
 #            "canonical_bson": "18000000136400000000000000000000000000000000F800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-infiniTy\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - -Inf",
 #            "canonical_bson": "18000000136400000000000000000000000000000000F800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - -inf",
 #            "canonical_bson": "18000000136400000000000000000000000000000000F800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-inf\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}"
 #        },
 #        {
 #            "description": "Non-Canonical Parsing - -inF",
 #            "canonical_bson": "18000000136400000000000000000000000000000000F800",
 #            "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"-inF\"}}",
 #            "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"-Infinity\"}}"
 #        },
 #        {
 #           "description": "Rounded Subnormal number",
 #           "canonical_bson": "180000001364000100000000000000000000000000000000",
 #           "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"10E-6177\"}}",
 #           "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E-6176\"}}"
 #        },
 #        {
 #           "description": "Clamped",
 #           "canonical_bson": "180000001364000a00000000000000000000000000fe5f00",
 #           "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"1E6112\"}}",
 #           "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1.0E+6112\"}}"
 #        },
 #        {
 #           "description": "Exact rounding",
 #           "canonical_bson": "18000000136400000000000a5bc138938d44c64d31cc3700",
 #           "degenerate_extjson": "{\"d\" : {\"$numberDecimal\" : \"1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\"}}",
 #           "canonical_extjson": "{\"d\" : {\"$numberDecimal\" : \"1.000000000000000000000000000000000E+999\"}}"
 #        }
 #    ]
