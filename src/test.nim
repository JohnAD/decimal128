import strutils
import decimal128

proc stringTest(s: string) =
  let x = s.toDecimal128
  echo "orig: \"$1\", result: $2".format(s, x.repr)

stringTest "12345"

stringTest "123.45"

stringTest "0.12345"

stringTest "000.12345"

stringTest "0.00012345"

stringTest ".12345"

stringTest "-12345"

stringTest "-123.45"

stringTest "-0.12345"

stringTest "-.12345"

stringTest "-000.12345"

stringTest "-0.00012345"
