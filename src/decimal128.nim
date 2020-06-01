## This library creates a data type called ``Decimal128`` that allows one to
## store and manipulate decimal numbers.
##
## By storing a number as decimal digits you can avoid the ambiguity and rounding
## errors encountered when converting values back-and-forth from binary floating
## point numbers (base 2) and the decimal notation typically used by humans (base 10).
##
## This is especially useful for applications that are not tolerant of such
## rounding errors such as accounting, banking, and finance.
##
## STANDARD USED
## -------------
##
## The specification specifically conforms to the IEEE 754-2008 standard that
## is formally available at https://standards.ieee.org/standard/754-2008.html
##
## A more informal copy of that spec can be seen at 
## http://speleotrove.com/decimal/decbits.html , though that spec only shows
## the Densely Packed Binary (DPD) version of storing the coefficient. This library
## supports both DPD and the unsigned binary integer storage (BID) method when
## for serializing and unserializing from binary images.
##
## The BID method is used by BSON and MongoDB.
##
## EXAMPLES OF USE
## --------------
##
## .. code:: nim
##
##     import decimal128
##
##     let a = newDecimal128("4003.250")
## 
##     assert a.getPrecision == 7
##     assert a.getScale = 3
##     assert a.toFloat == 4003.25
##     assert a.toInt == 4003
##     assert $a == "4003.250"
##
##     assert a === newDecimal128("4003250E-3")
##     assert a === newDecimal128("4.003250E+3")
## 
##     # interpret a segment of data from a BSON file:
##     let b = decodeDecimal128("2FF83CD7450BE3F39FA2D32880000000", encoding=ceBID)
## 
##     assert $b == "0.001234000000000000000000000000000000"
##     assert b.getPrecision == 34
##     assert b.getScale = 36
##     assert b.toFloat == 0.001234
##

import strutils except strip
import unicode
import decimal128/uint113


proc nz(v: byte): bool =
  if v == 0.byte:
    result = false
  else:
    result = true

# proc nz(v: uint16): bool =
#   if v == 0.uint16:
#     result = false
#   else:
#     result = true

const
  SIGNIFICAND_SIZE: int = 34
  TRANSIENT_SIGNIFICAND_SIZE: int = (34 * 2) + 2  # 70 digits
  TRANSIENT_OFFSET: int = TRANSIENT_SIGNIFICAND_SIZE - SIGNIFICAND_SIZE
  BIAS: int16 = 6176
  # EXP_UPPER_BOUND: int16 = 0x3fff.int16 - BIAS  # 14 bits less bias
  EXP_LOWER_BOUND: int16 = 0 - BIAS
  ALLZERO: array[SIGNIFICAND_SIZE, byte] = [0.byte, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  TALLZERO: array[TRANSIENT_SIGNIFICAND_SIZE, byte] = [0.byte, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.byte, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

const
  DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  NOP: int = -999999999

const
  #
  # breaking down the entire 16 bytes (128 bits) of a binary image of Decimal128
  #
  SIGN_MASK_0: byte =  0b1000_0000 # the first bit of byte 0 is the positive/negative sign
  COMBO_MASK_0: byte = 0b0111_1111 # first 7 bits in the combo field of 17 bits (byte 0)
  COMBO_MASK_1: byte = 0b1111_1111 # second 8 bits in the combo field of 17 bits (byte 1)
  COMBO_MASK_2: byte = 0b1100_1111 # remaining 2 bits in the combo field (byte 2)
  #
  # breaking down the possible parts of the combo field (17 bits in 3 bytes)
  #
  #   starting with the combo fields first two bits (what I will call a "SHORTFLAG")...
  COMBO_SHORTFLAG_MASK_0: byte =             0b0110_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_A: byte =    0b0000_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_B: byte =    0b0010_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_C: byte =    0b0100_0000
  COMBO_SHORTFLAG_SIGNALS_MEDIUMFLAG: byte = 0b0110_0000
  # COMBO_SHORTFLAG_SIG_MASK_0: byte =         0b0000_0111
  #
  COMBO_SHORTFLAG_EXPONENT_MASK_0: byte =    0b0111_1111 # 7 of 14
  COMBO_SHORTFLAG_EXPONENT_SHL_0: int =      7
  # COMBO_SHORTFLAG_EXPONENT_MASK_1: byte =    0b1111_1110 # 7 of 14
  COMBO_SHORTFLAG_EXPONENT_SHR_1: int =      1
  #
  # COMBO_SHORTFLAG_IMPLIED_PREFIX: byte =     0b0 # 1 bit implied; (math) 113 + 1 = 114 bits total
  #
  #   when a "MEDIUMFLAG"...
  COMBO_MEDIUMFLAG_MASK_0: byte =            0b0111_1000
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_A: byte = 0b0110_0000 
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_B: byte = 0b0110_1000
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_C: byte = 0b0111_0000
  COMBO_MEDIUMFLAG_SIGNALS_LONGFLAG: byte =  0b0111_1000
  #
  COMBO_MEDIUMFLAG_EXPONENT_MASK_0: byte =   0b0001_1111 # first 5 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHL_0: int =     9
  # COMBO_MEDIUMFLAG_EXPONENT_MASK_1: byte =   0b1111_1111 # second 8 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHL_1: int =     1
  COMBO_MEDIUMFLAG_EXPONENT_MASK_2: byte =   0b1000_0000 # last 1 bit of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHR_2: int =     7
  #
  # COMBO_MEDIUMFLAG_SIG_MASK_2: byte =        0b0111_1111 # (math) 7 + (13*8) = 111 bits for significand
  #
  # COMBO_MEDIUMFLAG_IMPLIED_PREFIX: byte =    0b100 # 3 bits implied; (math) 111 + 3 = 114 bits total when DPD
  #
  #   when a "LONGFLAG"...
  COMBO_LONGFLAG_MASK_0: byte =             0b0111_1100
  COMBO_LONGFLAG_MEANS_INFINITY: byte =     0b0111_1000
  # COMBO_LONGFLAG_MEANS_NAN: byte =          0b0111_1100
  #
  #   when NAN...
  # COMBO_NAN_SIGNALING_MASK_0: byte =        0b0000_0010
  # COMBO_NAN_QUIET_NAN: byte =               0b0000_0000
  COMBO_NAN_SIGNALING_NAN: byte =           0b0000_0010
  #
  # for BSON style import/export
  #
  # BSON_STYLE_LEFT_MASK: uint64 =            0x003FFFFFFFFFFFFF'u64

type
  Decimal128Kind = enum
    # internal use: the state of the Decimal128 variable
    dkValued,
    dkInfinite,
    dkNaN
  CoefficientEncoding* = enum
    ## The two coefficient (significand) storage formats supported by IEEE 754 2008.
    ##
    ## - ``ceDPD`` stands for Densely Packed Decimal
    ## - ``ceBID`` stands for Binary Integer Decimal
    ##
    ceDPD,
    ceBID
  Decimal128* = object
    ## A Decimal128 decimal number. Limited to 34 digits.
    ##
    ## This is the nim-internal storage of the number. To import or export
    ## use the corresponding ``decodeDecimal128`` and ``encodeDecimal128`` procedures.
    negative: bool
    case kind: Decimal128Kind
    of dkNaN:
      signalling: bool
    of dkValued:
      significand: array[SIGNIFICAND_SIZE, byte]
      exponent: int
    of dkInfinite:
      discard
  Transient128 = object
    # A temporary decimal number with 70 digits ((34 * 2) + 2)
    #
    # this number is NOT used outside the library. It is used as a "temporary"
    # holder of value with higher resolution.
    negative: bool
    case kind: Decimal128Kind
    of dkNaN:
      signalling: bool
    of dkValued:
      significand: array[TRANSIENT_SIGNIFICAND_SIZE, byte]
      exponent: int
    of dkInfinite:
      discard

  # use of the term "scale":
  #
  # https://www.gnu.org/software/bc/manual/html_mono/bc.html#SEC5

  #
  # Explaining Significand and It's Storage
  #
  # The word significand is also sometimes called a mantissa or significand.
  # It is the "details" part of a scientific notation number. For example, with
  #
  #    3.239 x 10^7
  #
  # the significand is the "3.239" part. The exponent is the "7" part. The base "10"
  # is presumed because this is a decimal library.
  #
  # For decimal128, 34 digits are stored for the significand. Leading zeroes are ignored. The position of
  # first non zero establishes the significant digits. So,
  #
  #    4     = digits 0000000000000000000000000000000004  with exponent 0
  #    4.0   = digits 0000000000000000000000000000000040  with exponent -1
  #    4.000 = digits 0000000000000000000000000000004000  with exponent -3
  #
  # while all three values of 4 are equal, "4.000" is known precisely to 3 decimal places. So, one could say "4.000" has a
  # significance of 3.
  #
  # The following numbers also have a significance of 3, but are larger numbers:
  #
  #    40.00 = digits 0000000000000000000000000000004000  with exponent -2
  #    400.0 = digits 0000000000000000000000000000004000  with exponent -1
  #
  # A single digit (a value from 0 to 9) can be simply stored in 4 bits: 0b0000 to 0b1001.
  # But doing so wastes space since 4 bits could technically store 16 numbers (0 to F). So, the makers of the
  # protocol used something called Binary Packed Decimal instead; where 3 numbers can be stored in only 10 bits rather than
  # 12 bits. See decode_dpb for the complicated details.
  #
  # However, *despite* what the specification says, for MongoDb and it's BSON library, the number is
  # simply a 128-bit unsigned integer. By staying within the 34-digit limit, the number will never have
  # enough high bits set to overwrite the SIGN or COMBO fields.
  #
  # https://github.com/mongodb/libbson/blob/master/src/bson/bson-decimal128.c#L693
  #
  # The significand has 114 bits (of the 128). It is stored as follows
  #
  # if the first digit starts with 8 or 9:
  #   The first digit is 0b100x, where the bit 17 of source is 'x'; essentially 8 = 0b1000 and 9 = 0b1001
  #   The remaining 110 bits are bits 18 to 127 and are decoded as eleven 10-bit triples for the remaining 33 digits.
  #   I've been calling this setup a "MEDIUMFLAG" in the COMBO field.
  #   With the MongoDB non-compliance, this whole "first digit" thing really never happens that I can detect for BSON.
  # else:
  #   The first digit is 0b0xxx, where bits 15, 16, and 17 of source are 'xxx'
  #   The remaining 110 bits are bits 18 to 127 and are decoded as eleven 10-bit triples for the remaining 33 digits.
  #   I've been calling this setup a "SHORTFLAG" in the combo field.
  #
  # To head off a key question: 
  #   1. the "LONGFLAG" in the combo field is for non-numbers: not-a-number (NaN) and infinity (Infinity)
  #   2. yes everything is convoluted. But the spec is what it is.

# forward-ref:
proc `$`*(d: Decimal128): string

proc repr*(d: Decimal128): string =
  result = "( "
  case d.kind:
  of dkValued:  
    if d.negative:
      result &= "-"
    else:
      result &= "+"
    result &= " , "
    for digit in d.significand:
      result &= DIGITS[digit]
    result &= " , E "
    result &= $d.exponent
  of dkInfinite:
    if d.negative:
      result &= "-"
    else:
      result &= "+"
    result &= " , "
    result &= "Infinity"
  of dkNaN:
    result &= "NaN , "
    if d.signalling:
      result &= "signalling"
    else:
      result &= "NOT signalling"
  result &= " )"


proc isNegative*(number: Decimal128): bool =
  ## Returns true if the number is negative or is negative infinity; otherwise false.
  case number.kind:
  of dkValued:  
    result = number.negative
  of dkInfinite:
    result = number.negative
  of dkNaN:
    result = false


proc isPositive*(number: Decimal128): bool =
  ## Returns true the number is positive or is positive infinity; otherwise false.
  case number.kind:
  of dkValued:  
    result = not number.negative
  of dkInfinite:
    result = not number.negative
  of dkNaN:
    result = false


proc isReal*(number: Decimal128): bool =
  ## Returns true the number has a real value; otherwise false.
  case number.kind:
  of dkValued:  
    result = true
  of dkInfinite:
    result = false
  of dkNaN:
    result = false


proc isInfinite*(number: Decimal128): bool =
  ## Returns true the number is infinite (positive or negative); otherwise false.
  case number.kind:
  of dkValued:  
    result = false
  of dkInfinite:
    result = true
  of dkNaN:
    result = false


proc isPositiveInfinity*(number: Decimal128): bool =
  ## Returns true the number is infinite and positive; otherwise false.
  case number.kind:
  of dkValued:  
    result = false
  of dkInfinite:
    if number.negative:
      result = false
    else:
      result = true
  of dkNaN:
    result = false


proc isNegativeInfinity*(number: Decimal128): bool =
  ## Returns true the number is infinite and negative; otherwise false.
  case number.kind:
  of dkValued:  
    result = false
  of dkInfinite:
    if number.negative:
      result = true
    else:
      result = false
  of dkNaN:
    result = false


proc isNaN*(number: Decimal128): bool =
  ## Returns true the number is actually not a number (NaN); otherwise false.
  case number.kind:
  of dkValued:  
    result = false
  of dkInfinite:
    result = false
  of dkNaN:
    result = true


proc intStr(dList: array[SIGNIFICAND_SIZE, byte]): string =
  # a quick way to generate an integer from the significand
  var firstDigitSeen = false
  for digit in dList:
    if nz(digit):
      firstDigitSeen = true
    if firstDigitSeen:
      result &= $(digit.int)
  if not firstDigitSeen:
    result = "0"


proc shiftDecimalsLeft(values: array[SIGNIFICAND_SIZE, byte], shiftNeeded: int16): array[SIGNIFICAND_SIZE, byte] =
  for index in 0 ..< SIGNIFICAND_SIZE:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 0 ..< (SIGNIFICAND_SIZE - 1):
      result[index] = result[index + 1]
    result[33] = 0.byte


proc shiftDecimalsRight(values: array[SIGNIFICAND_SIZE, byte], shiftNeeded: int16): array[SIGNIFICAND_SIZE, byte] =
  for index in 0 ..< SIGNIFICAND_SIZE:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 1 ..< SIGNIFICAND_SIZE:
      let place = SIGNIFICAND_SIZE - index
      result[place] = result[place - 1]
    result[0] = 0.byte


proc shiftDecimalsRightTransient(values: array[TRANSIENT_SIGNIFICAND_SIZE, byte], shiftNeeded: int16): array[TRANSIENT_SIGNIFICAND_SIZE, byte] =
  for index in 0 ..< TRANSIENT_SIGNIFICAND_SIZE:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 1 ..< TRANSIENT_SIGNIFICAND_SIZE:
      let place = TRANSIENT_SIGNIFICAND_SIZE - index
      result[place] = result[place - 1]
    result[0] = 0.byte


proc zero*(): Decimal128 =
  ## Create a Decimal128 value of positive zero
  result = Decimal128(kind: dkValued)
  result.negative = false
  result.significand = ALLZERO
  result.exponent = 0


proc transientZero(): Transient128 =
  # Create a Transient128 value of positive zero
  result = Transient128(kind: dkValued)
  result.negative = false
  result.significand = TALLZERO
  result.exponent = 0


proc nan*(): Decimal128 =
  ## Create a non-number aka NaN
  result = Decimal128(kind: dkNaN)


proc digitCount(significand: array[SIGNIFICAND_SIZE, byte]): int =
  # get the number of digits, ignoring the leading zeroes;
  # special case: all zeroes results returns a result of zero
  result = 0
  var nonZeroFound = false
  for d in significand:
    if d != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      result += 1


proc digitCount(significand: array[TRANSIENT_SIGNIFICAND_SIZE, byte]): int =
  # get the number of digits, ignoring the leading zeroes;
  # special case: all zeroes results returns a result of zero
  result = 0
  var nonZeroFound = false
  for d in significand:
    if d != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      result += 1


proc bankersRoundingToEven(values: array[TRANSIENT_SIGNIFICAND_SIZE, byte]): (array[SIGNIFICAND_SIZE, byte], int) =
  # used to round from the transient (interim) result to a final result with rounding
  var sig: array[SIGNIFICAND_SIZE, byte]
  let size = digitCount(values)
  if size == 0:
    result = (ALLZERO, 0)
  elif size <= SIGNIFICAND_SIZE:
    for index in 0 ..< SIGNIFICAND_SIZE:
      sig[index] = values[index + TRANSIENT_OFFSET]
    result = (sig, 0)
  else:
    #
    # gather info needed for the rounding decision
    #
    var trimCount = size - SIGNIFICAND_SIZE
    let keyDigitIndex = TRANSIENT_SIGNIFICAND_SIZE - trimCount
    var AllZeroesFollowingKeyDigit: bool = true
    if trimCount > 1:
      for index in (keyDigitIndex + 1) ..< TRANSIENT_SIGNIFICAND_SIZE:
        if values[index] > 0.byte:
          AllZeroesFollowingKeyDigit = false
    let keyDigit = values[keyDigitIndex]
    #
    # make a rounding decision
    #
    var roundUp: bool
    if keyDigit < 5:         # ...123[4]12 becomes ...123
      roundUp = false
    elif keyDigit > 5:       # ...123[6]12 becomes ...124
      roundUp = true
    elif (keyDigit == 5) and (AllZeroesFollowingKeyDigit == false):  # ...123[5]12 becomes ...124
      roundUp = true
    else:    # keydigit == 5 and all zeroes followed the 5
      let evenFlag = ((values[keyDigitIndex - 1] mod 2.byte) == 0.byte)  # is the last digit (before the key digit) even?
      if evenFlag:
        roundUp = false      # ...123[5]00 becomes ...124
      else:
        roundUp = true       # ...122[5]00 becomes ...122
    #
    # get result truncated (and detect problematic all-nines scenario)
    #
    var allNines = true
    for index in 0 ..< SIGNIFICAND_SIZE:
      sig[index] = values[index + TRANSIENT_OFFSET - trimCount]
      if sig[index] != 9.byte:
        allNines = false
    #
    # adjust if all-nines
    #
    if allNines:
      sig[0] = 0.byte
      trimCount += 1
    #
    # and do rounding
    #
    if roundUp:
      var index = SIGNIFICAND_SIZE - 1 # start with last digit
      for counter in 0 ..< SIGNIFICAND_SIZE:
        sig[index] += 1.byte
        if sig[index] < 10:
          break  # done
        else:
          sig[index] = 0 # if it rounds up to "11", then set to zero and
          index -= 1        # increment the previous digit
    #
    # done
    #
    result = (sig, trimCount)


proc getPrecision*(number: Decimal128): int =
  ## Get number of digits of precision (significance) of the decimal number.
  ##
  ## If a real number, then it will be a number between 1 and 34. Even a value of "0" has
  ## one digit of Precision.
  ##
  ## A zero is returned if the number is not-a-number (NaN) or Infinity.
  case number.kind:
  of dkValued:
    result = digitCount(number.significand)
    if result == 0:  # only a true zero value can generate this
      if number.exponent < 0:
        result = -number.exponent
      else:
        result = 1
  of dkInfinite:
    result = 0
  of dkNaN:
    result = 0


proc getScale*(number: Decimal128): int =
  ## Get number of digits of the fractional part of the number. Or to put it differently:
  ## get the number of decimals after the decimal point.
  ##
  ## If a real number, then it will be a number between -6143 and 6144.
  ##
  ## ``assert getScale(Decimal128("123.450")) == 3``
  ##
  ## ``assert getScale(Decimal128("1.2E3")) == -2``  # aka 1.2 x 10^3  or 1200
  ##
  ## A zero is returned if the number is not-a-number (NaN) or Infinity.
  case number.kind:
  of dkValued:
    result = -number.exponent
  of dkInfinite:
    result = 0
  of dkNaN:
    result = 0

proc adjustExponent(number: Decimal128, newExponent: int, forgiveSmall = false): Decimal128 =
  result = number
  if number.significand == ALLZERO:
    result = zero()
    return
  let currentExponent = number.exponent
  let diff = (currentExponent - newExponent).int16
  if diff == 0:
    return
  elif diff > 0:
    result.significand = shiftDecimalsLeft(number.significand, diff)
    result.exponent -= diff
    if result.significand == ALLZERO:
      raise newException(ValueError, "number too large to adjust")
  elif diff < 0:
    result.significand = shiftDecimalsRight(number.significand, -diff)
    result.exponent -= diff
    if not forgiveSmall:
      if result.significand == ALLZERO:
        raise newException(ValueError, "number too small to adjust")


proc decodeDecimal128*(data: string, encoding: CoefficientEncoding): Decimal128 =
  ## Parse the string to a Decimal128 using the IEEE754 2008 encoding with
  ## the coefficient stored as a unsigned binary integer in the last 113 bits.
  ##
  ## This is the encoding method used by BSON and MongoDb.
  ##
  ## if the length of the ``data`` string is 32, then it is presumed to be expressed
  ## as hexidecimal digits.
  ##
  ## if the length of the ``data`` string is 16 (128 bits), then it is presumed
  ## to be a binary copy.
  ##
  ## The Decimal128 is NOT normalized in any way. If the returned value is then
  ## encoded back to binary using ``encodeDecimal128`` then it should exactly match the 
  ## original binary value.
  ##
  ## The ``encoding`` method must be of the one of the following:
  ##
  ## 1. ``ceDPD`` -- Densely Packed Decimal. This matches method 1 of storing the coefficient (significand).
  ##     Essentially, each three digits is stored as a 10-bit declet as described in
  ##     https://en.wikipedia.org/wiki/Densely_packed_decimal
  ## 2. ``ceBID`` -- Binary Integer Decimal. This matches method 2 of storing the coeffecient.
  ##     Essentially, the number is stored as a simple unsigned integer into the last
  ##     133 bits of the 128-bit pattern. See the IEEE 754 2008 spec for details.
  var bs: array[16, byte]
  if data.len == 32:
    let bsStr = parseHexStr(data)
    if bsStr.len != 16:  # 128 bits == 16 bytes
      raise newException(ValueError, "parsed string as hex ($1) but it created the wrong binary (len=$1)".format(data, bsStr.len))
    var i = 0;
    for ch in bsStr:
      bs[i] = ch.byte
      i += 1
  elif data.len == 16:
    var i = 0;
    for ch in data:
      bs[i] = ch.byte
      i += 1
  else:
    raise newException(ValueError, "original data string the wrong size (len=$1)".format(data.len))
  #
  # interpret the SIGN
  #
  var negative: bool
  if (bs[0] and SIGN_MASK_0) == SIGN_MASK_0:
    negative = true 
  else:
    negative = false
  #
  # interpret the COMBOFIELD
  #
  var decType: Decimal128Kind
  var exponentBits: uint16
  var significand: array[SIGNIFICAND_SIZE, byte]
  var signalling: bool
  let c0 = bs[0] and COMBO_MASK_0
  let c1 = bs[1] and COMBO_MASK_1
  let c2 = bs[2] and COMBO_MASK_2
  let comboShortFlag = c0 and COMBO_SHORTFLAG_MASK_0
  if comboShortFlag == COMBO_SHORTFLAG_SIGNALS_MEDIUMFLAG:
    let comboMediumFlag = c0 and COMBO_MEDIUMFLAG_MASK_0
    if comboMediumFlag == COMBO_MEDIUMFLAG_SIGNALS_LONGFLAG:
      #
      # interpret longFlag
      #
      let comboLongFlag = c0 and COMBO_LONGFLAG_MASK_0
      if comboLongFlag == COMBO_LONGFLAG_MEANS_INFINITY:
        decType = dkInfinite
      else:
        decType = dkNaN
        if (c0 and COMBO_NAN_SIGNALING_NAN) == COMBO_NAN_SIGNALING_NAN:
          signalling = true
        else:
          signalling = false
    else:
      #
      # interpret mediumFlag
      #
      decType = dkValued
      exponentBits = (c0 and COMBO_MEDIUMFLAG_EXPONENT_MASK_0).uint16 shl COMBO_MEDIUMFLAG_EXPONENT_SHL_0
      exponentBits = exponentBits or (c1.uint16 shl COMBO_MEDIUMFLAG_EXPONENT_SHL_1)
      exponentBits = exponentBits or ( (c2 and COMBO_MEDIUMFLAG_EXPONENT_MASK_2).uint16 shr COMBO_MEDIUMFLAG_EXPONENT_SHR_2)
  else:
    #
    # interpret shortFlag
    #
    decType = dkValued
    exponentBits = (c0 and COMBO_SHORTFLAG_EXPONENT_MASK_0).uint16 shl COMBO_SHORTFLAG_EXPONENT_SHL_0
    exponentBits = exponentBits or (c1.uint16 shr COMBO_SHORTFLAG_EXPONENT_SHR_1)
  #
  # interpret the significand
  #
  if decType == dkValued:
    case encoding:
    of ceDPD:
      raise newException(ValueError, "DPD support on decoding not actually implemented yet.")
    of ceBID:
      significand = decode113bit(bs)
  #
  # return the value
  #
  case decType:
  of dkValued:
    result = Decimal128(kind: dkValued)
    result.negative = negative
    result.significand = significand
    result.exponent = exponentBits.int16 - BIAS
  of dkInfinite:
    result = Decimal128(kind: dkInfinite)
    result.negative = negative
  of dkNaN:
    result = Decimal128(kind: dkNaN)
    result.signalling = signalling


proc encodeDecimal128*(value: Decimal128, encoding: CoefficientEncoding): string =
  ## Generate a sequence of bytes that matches the IEEE 754 2008 specification.
  ##
  ## The returned string will be exactly 16 bytes long and very likely contains
  ## binary zero (null) values. The result is not meant to be printable.
  ##
  ## The ``encoding`` method must be of the one of the following:
  ##
  ## 1. ``ceDPD`` -- Densely Packed Decimal. This matches method 1 of storing the coefficient (significand).
  ##     Essentially, each three digits is stored as a 10-bit declet as described in
  ##     https://en.wikipedia.org/wiki/Densely_packed_decimal
  ## 2. ``ceBID`` -- Binary Integer Decimal. This matches method 2 of storing the coeffecient.
  ##     Essentially, the number is stored as a simple unsigned integer into the last
  ##     133 bits of the 128-bit pattern. See the IEEE 754 2008 spec for details.
  case value.kind:
  of dkValued:
    result = "00000000000000000000000000000000".parseHexStr
    if value.negative:
      result[0] = (result[0].byte or SIGN_MASK_0).char
    if true:
      # TODO: test mediumflag handling
      let unbiasedExponent = (value.exponent + BIAS).uint16
      let exponentBits = unbiasedExponent shl 1
      result[0] = (result[0].byte or (exponentBits shr 8).byte).char
      result[1] = (result[1].byte or exponentBits.byte).char
    case encoding:
    of ceDPD:
      raise newException(ValueError, "DPD support on encoding not actually implemented yet.")
    of ceBID:
      #
      # BID encoding
      #
      var bigInt = new_uint113(value.significand)
      var left = bigInt.left   # both uint64 types
      var right = bigInt.right
      for place in 0 .. 7:
        let index = 7 - place
        result[index] = (result[index].byte or left.byte).char
        left = left shr 8
        result[index + 8] = (result[index + 8].byte or right.byte).char
        right = right shr 8
  of dkInfinite:
    if value.negative:
      result = "f8000000000000000000000000000000".parseHexStr
    else:
      result = "78000000000000000000000000000000".parseHexStr
  of dkNaN:
    result = "7c000000000000000000000000000000".parseHexStr



proc parseFromString(str: string): Transient128 =
  # used internally to parse a decimal string into a temporarary holding
  # value.
  type
    ParseState = enum
      psPre,            # we haven't found the number yet
      psLeadingZeroes,  # we are ignoring any leading zero(s)
      psLeadingMinus,   # we found a minus sign
      psIntCoeff,       # we are reading the the integer part of a decimal number (NN.nnn)
      psDecimalPoint,   # we found a single decimal point
      psFracCoeff,      # we are reading the decimals of a decimal number  (nn.NNN)
      psSignForExp,     # we are reading the +/- of an exponent
      psExp,            # we are reading the decimals of an exponent
      psDone            # ignore everything else

  const
    IGNORED_CHARS: seq[char] = @[
      '_', 
      ','
    ]

  let s = str.toLower().strip()

  if s.startsWith("nan"):
    result = Transient128(kind: dkNaN)
    return

  if s.startsWith("+inf"):
    result = Transient128(kind: dkInfinite, negative: false)
    return
  if s.startsWith("inf"):
    result = Transient128(kind: dkInfinite, negative: false)
    return
  if s.startsWith("-inf"):
    result = Transient128(kind: dkInfinite, negative: true)
    return

  result = transientZero()
  var state: ParseState = psPre
  var legit = false
  var digitList: seq[byte] = @[]
  var expDigitList = ""
  var expNegative = false

  for ch in s:
    #
    # detect change first
    #
    case state:
    of psPre:
      if ch == '-':
        state = psLeadingMinus
      elif ch == '0':
        state = psLeadingZeroes
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':  # yes, we are allowing numbers like ".123" even though that is bad form
        state = psDecimalPoint
    of psLeadingMinus:
      if ch == '0':
        state = psLeadingZeroes
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':  # yes, we are allowing numbers like "-.123" even though that is bad form
        state = psDecimalPoint
      else:
        state = psDone  # anything else is not legit
    of psLeadingZeroes:
      if ch == '0':
        discard
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':
        state = psDecimalPoint
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psIntCoeff:
      if DIGITS.contains(ch):
        discard
      elif IGNORED_CHARS.contains(ch):
        discard
      elif ch == '.':
        state = psDecimalPoint
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psDecimalPoint:
      if DIGITS.contains(ch):
        state = psFracCoeff
      else:
        state = psDone
    of psFracCoeff:
      if DIGITS.contains(ch):
        discard
      elif IGNORED_CHARS.contains(ch):
        discard
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psSignForExp:
      if DIGITS.contains(ch):
        state = psExp
      elif (ch == '-') or (ch == '+'):
        discard
      else:
        state = psDone
    of psExp:
      if DIGITS.contains(ch):
        discard
      else:
        state = psDone
    of psDone:
      discard
    #
    # act on state
    #
    case state:
    of psPre:
      discard
    of psLeadingMinus:
      result.negative = true
    of psLeadingZeroes:
      legit = true
    of psIntCoeff:
      # given the state table, the 'find' function should never return -1
      if not IGNORED_CHARS.contains(ch):
        digitList.add(DIGITS.find(ch).byte)
        legit = true
    of psDecimalPoint:
      discard
    of psFracCoeff:
      # given the state table, the 'find' function should never return -1
      if not IGNORED_CHARS.contains(ch):
        digitList.add(DIGITS.find(ch).byte)
        result.exponent -= 1
        legit = true
    of psSignForExp:
      if ch == '-':
        expNegative = true
    of psExp:
      expDigitList &= ch
    of psDone:
      discard
  #
  # remove leading zeroes
  #
  var nonZeroFound = false
  var temp: seq[byte] = @[]
  for val in digitList:
    if val != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      temp.add val
  digitList = temp
  #
  # if too many digits, removing trailing digits.
  # Note: because this is on 70-digit Transient, simple "truncation" is good enough
  #
  if digitList.len > TRANSIENT_SIGNIFICAND_SIZE:
    let digitsToRemove = digitList.len - TRANSIENT_SIGNIFICAND_SIZE
    digitList = digitList[0 ..< TRANSIENT_SIGNIFICAND_SIZE]
    result.exponent += digitsToRemove
  #
  # move to result to final significand
  #
  let offset = TRANSIENT_SIGNIFICAND_SIZE - digitList.len
  for index, val in digitList:
    result.significand[index + offset] = val
  #
  # parse the exponent value
  #
  if expDigitList.len > 0:
    try:
      let exp = parseInt(expDigitList)
      if expNegative:
        result.exponent -= exp
      else:
        result.exponent += exp
      if result.exponent < EXP_LOWER_BOUND:
        let shiftNeeded = (EXP_LOWER_BOUND - result.exponent).int16
        result.significand = shiftDecimalsRightTransient(result.significand, shiftNeeded)
        result.exponent += shiftNeeded
    except:
      discard


proc convertTransientToDecimal128(t: Transient128): Decimal128 =
  # convert from internal Transient128 to public Decimal128
  # it will "clamp" the value with Bankers Rounding if needed.
  case t.kind:
  of dkValued:
    result = Decimal128(kind: dkValued)
    result.negative = t.negative
    var trimmed = 0
    (result.significand, trimmed) = bankersRoundingToEven(t.significand)
    result.exponent = t.exponent + trimmed
  of dkInfinite:
    result = Decimal128(kind: dkInfinite)
    result.negative = t.negative
  of dkNaN:
    result = Decimal128(kind: dkNaN)
    result.signalling = t.signalling


proc setPrecision*(value: Decimal128, precision: int): Decimal128 =
  ## Create a Decimal128 with the supplied precision.
  ##
  ## The supplied precision must be a value from 1 to 34.
  ##
  ## When NaN or Infinity is passed, the value is return as-is.
  result = value
  case value.kind:
  of dkValued:
    if precision != NOP:
      if precision < 1:
        raise newException(ValueError, "precision cannot be less than 1. $1 was tried.".format(precision))
      if precision > 34:
        raise newException(ValueError, "precision cannot be more than 34. $1 was tried.".format(precision))
    let nativePrecision = result.getPrecision
    if nativePrecision != precision:
      let shiftNeeded = (nativePrecision - precision).int16
      if shiftNeeded > 0:
        result.significand = shiftDecimalsRight(result.significand, shiftNeeded)
        result.exponent += shiftNeeded
      else:
        result.significand = shiftDecimalsLeft(result.significand, -shiftNeeded)
        result.exponent += shiftNeeded
  of dkInfinite:
    discard
  of dkNaN:
    discard
  

proc setScale*(value: Decimal128, scale: int): Decimal128 =
  ## Create a Decimal128 with the supplied scale.
  ##
  ## The scale must be a value from −6143 to +6144
  ##  
  ## When NaN or Infinity is passed, the value is return as-is.
  result = value
  case value.kind:
  of dkValued:
    let negLimit = 0 - 6143  # honestly, I don't know why this is needed.
    if scale < negLimit:
      raise newException(ValueError, "scale cannot be less than -6143. $1 was tried.".format(scale))
    if scale > 6144:
      raise newException(ValueError, "scale cannot be greater than 6144. $1 was tried.".format(scale))
    let nativeScale = result.getScale
    if scale != nativeScale:
      let digitsNeeded = (scale - nativeScale).int16
      if digitsNeeded > 0:
        result.significand = shiftDecimalsLeft(result.significand, digitsNeeded)
      else:
        result.significand = shiftDecimalsRight(result.significand, -(digitsNeeded))
      result.exponent -= digitsNeeded
  of dkInfinite:
    discard
  of dkNaN:
    discard
  

proc newDecimal128*(str: string, precision: int = NOP, scale: int = NOP): Decimal128 =
  ## convert a string containing a decimal number to Decimal128
  ##
  ## A few parsing rules:
  ##
  ## * leading whitespace or invalid characters are ignored.
  ## * invalid characters stop the conversion at that point.
  ## * underscores (_) are ignored
  ## * commas (,) are ignored
  ## * only one period is expected.
  ## * case is ignored
  ##
  ## The string can contain one of the following:
  ##
  ## 1. ``"Infinity"`` or ``"-Infinity"`` for positive/negative infinity.
  ##    This can also be ``"+Infinity"`` or anything that starts with "inf"
  ## 2. ``"NaN"`` for a Not-A-Number designation.
  ## 3. Any simple decimal number, such as ``"12.34223"``.
  ## 4. Any simple integer, such as ``"38923"`` or ``"-0236"``.
  ## 5. Any number in scientific notation using ``E`` as a prefix for the exponent.
  ##    Examples: ``"-1423E+3"`` or ``"3.2232E-20"``.
  ## 
  ## If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
  ## needed, additional decimal places are added to the right. For example, ``Decimal128("423.0", precision=6)`` is
  ## the equivalant of "423.000" and ``Decimal128("423.0", precision=1)`` is "400", or more accurately, "4E2".
  ##
  ## If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
  ## of digits before/after the decimal place. For example, ``Decimal128("423.0", scale=2)`` is the equivalent of
  ## "423.00" and ``Decimal128("423.0", scale=-2)`` is "400", or more accurately, "4E2".
  ##
  ## If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
  ## resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
  ##
  ## For example:
  ##
  ## ``let x = Decimal128("423.0", precision=6, scale=2)``
  ##
  ## works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
  ##
  ## ``let x = Deicmal128("73737", precision=6, scale=2)``
  ##
  ## will generate a ValueError at run-time since "73737.00" has a precision of 7.
  let t = parseFromString(str)
  result = convertTransientToDecimal128(t)
  #
  # make scale/precision adjustments
  #
  if scale != NOP:
    result = result.setScale(scale)
    if precision != NOP:  # if both are set, then precision is simply a checker
      if result.getPrecision() > precision:
        raise newException(
          ValueError, 
          "a precision of $1 was requested, but $2 has a precision of $3 at scale $4".format($precision, $result, $getPrecision(result), $scale)
        )
  elif precision != NOP:
    result = result.setPrecision(precision)


proc newDecimal128*(value: int, precision: int = NOP, scale: int = NOP): Decimal128 =
  ## Convert an integer to Decimal128
  ##
  ## If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
  ## needed, additional decimal places are added to the right. For example, ``Decimal128(423, precision=6)`` is
  ## the equivalant of "423.000" and ``Decimal128(423, precision=1)`` is "400", or more accurately, "4E2".
  ##
  ## If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
  ## of digits before/after the decimal place. For example, ``Decimal128(423, scale=2)`` is the equivalent of
  ## "423.00" and ``Decimal128(423, scale=-2)`` is "400", or more accurately, "4E2".
  ##
  ## If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
  ## resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
  ##
  ## For example:
  ##
  ## ``let x = Decimal128(423, precision=6, scale=2)``
  ##
  ## works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
  ##
  ## ``let x = Deicmal128(73737, precision=6, scale=2)``
  ##
  ## will generate a ValueError at run-time since "73737.00" has a precision of 7.
  result = newDecimal128($value, precision=precision, scale=scale)


proc newDecimal128*(value: float, precision: int = NOP, scale: int = NOP): Decimal128 =
  ## Convert a 64-bit floating point number to Decimal128
  ##
  ## If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
  ## needed, additional decimal places are added to the right. For example, ``Decimal128(423.0, precision=6)`` is
  ## the equivalant of "423.000" and ``Decimal128(423.0, precision=1)`` is "400", or more accurately, "4E2".
  ##
  ## If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
  ## of digits before/after the decimal place. For example, ``Decimal128(423.0, scale=2)`` is the equivalent of
  ## "423.00" and ``Decimal128(423.0, scale=-2)`` is "400", or more accurately, "4E2".
  ##
  ## If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
  ## resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
  ##
  ## For example:
  ##
  ## ``let x = Decimal128(423.0, precision=6, scale=2)``
  ##
  ## works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
  ##
  ## ``let x = Deicmal128(73737.0, precision=6, scale=2)``
  ##
  ## will generate a ValueError at run-time since "73737.00" has a precision of 7.
  result = newDecimal128($value, precision=precision, scale=scale)


proc simpleDecStr(dList: array[SIGNIFICAND_SIZE, byte], decimalPlace: int): string =
  let justDigits = dList.intStr
  let scientificExponent = justDigits.len - 1 + decimalPlace
  if (scientificExponent < -6) or (decimalPlace > 0):
    # express with scientific notation
    for index, ch in justDigits:
      if index == 1:
        result &= "."
      result &= ch
    result &= "E"
    if scientificExponent >= 0:
      result &= "+"
    result &= $scientificExponent
  elif decimalPlace == 0:
    # if zero decimal places, then it is a simple integer
    result = justDigits
  else:
    let significance = -decimalPlace
    let leadingZeroes = significance - justDigits.len
    if leadingZeroes >= 0:
      result &= "0."
      result &= "0".repeat(leadingZeroes)
      result &= justDigits
    else:
      let depth = -leadingZeroes
      for index, ch in justDigits:
        if index == depth:
          result &= "."
        result &= ch


proc toInt*(value: Decimal128): int =
  ## Return the integer part of a decimal as an int.
  ##
  ## This function truncates rather than rounds. So "1.6" will return an integer of
  ## 1 not 2.
  ##
  ## If the integer part will not fit into a Nim integer, then
  ## an OverflowError error is raised.
  case value.kind:
  of dkInfinite:
    raise newException(OverflowError, "Decimal infinity will not fit into an integer.")
  of dkNaN:
    raise newException(ValueError, "Decimal NaN cannot be stored into an integer.")
  of dkValued:
    let temp = value.adjustExponent(0, forgiveSmall=true)
    let bigInt = new_uint113(temp.significand)
    if bigInt.left != 0:
      raise newException(OverflowError, "Decimal is too large to fit into an integer.")
    result = bigInt.right.int
    if value.negative:
      result = -result


proc toFloat*(value: Decimal128): float =
  ## Return the floating point equivalent of a decimal.
  ##
  ## Please keep in mind that a decimal number can store numbers not possible in binary
  ## so it is possible this conversion will introduce rounding and conversion
  ## errors.
  #
  # TODO: This is a hack. Make this fancier later; I'm not convinced this will
  # cover all possible conversion border cases
  #
  # a IEEE 754-1985 double float, as used by Nim, has a 11-bit binary exponent and
  # a 52-bit binary fraction. By adjusting and reducing, I can envision scenarious where
  # a direct and purposeful conversion could handle more border cases.
  case value.kind:
  of dkInfinite:
    raise newException(OverflowError, "Decimal infinity will not fit into a float.")
  of dkNaN:
    raise newException(ValueError, "Decimal NaN cannot be stored into a float.")
  of dkValued:
    let s = $value
    result = parseFloat(s)


proc `===`*(left: Decimal128, right: Decimal128): bool =
  ## Determines the equality of the two decimals, in terms of both
  ## numeric value and other characteristics such as significance.
  ##
  ## So, while:
  ##
  ## ``Decimal128("120") == Decimal("1.2E2")`` is true
  ##
  ## because both are essentially the number 120, the following:
  ##
  ## ``Decimal("120") === Decimal("1.2E2")`` is NOT true
  ##
  ## because "120" has 3 sigificant digits, "1.2E2" has 2 significant digits.
  result = false
  if left.kind != right.kind:
    return
  case left.kind:
  of dkValued:
    if left.negative != right.negative:
      return
    for index, val in left.significand:
      if val != right.significand[index]:
        return
    if left.exponent != right.exponent:
      return
  of dkInfinite:
    if left.negative != right.negative:
      return
  of dkNaN:
    if left.signalling != right.signalling:
      return
  result = true


proc `!==`*(left: Decimal128, right: Decimal128): bool =
  ## Determint the inequality of two decimals, in terms of both numeric value
  ## and other characteristics such as significance. See ``proc `===` `` for
  ## more detail.
  result = not (left === right)


proc `$`*(d: Decimal128): string =
  ## Express the Decimal128 value as a canonical string
  case d.kind:
  of dkValued:
    # TODO: finish
    # let digitLen = digitCount(d.significand)
    if d.negative:
      result = "-"
    else:
      result = ""
    result &= simpleDecStr(d.significand, d.exponent)
  of dkInfinite:
    if d.negative:
      result = "-Infinity"
    else:
      result = "Infinity"
  of dkNaN:
    result = "NaN"



