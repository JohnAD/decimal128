## This library creates a data type called Decimal128 that allows one to do
## store and manipulated decimal numbers.
##
## By storing number as decimal digits you can avoid the ambiguity and rounding
## errors encountered when converting values back-and-forth from binary floating
## point numbers such as the 64-bit floats used by Nim.
##
## This is especially useful for applications that are not tolerant of such
## rounding errors such as accounting, banking, and finance.
##
## STANDARD
## --------
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

import strutils except strip
import unicode
import bitops
import uint113


proc nz(v: byte): bool =
  if v == 0.byte:
    result = false
  else:
    result = true

proc nz(v: uint16): bool =
  if v == 0.uint16:
    result = false
  else:
    result = true

const
  MAXIMUM_SIGNIFICAND: string = "10_000_000_000_000_000_000_000_000_000_000_000"
  SIGNIFICAND_SIZE: int = 34
  BIAS: int16 = 6176

const
  DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

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
  COMBO_SHORTFLAG_MEANS_0PREFIX_A: byte =    0b0000_0000
  COMBO_SHORTFLAG_MEANS_0PREFIX_B: byte =    0b0010_0000
  COMBO_SHORTFLAG_MEANS_0PREFIX_C: byte =    0b0100_0000
  COMBO_SHORTFLAG_SIGNALS_MEDIUMFLAG: byte = 0b0110_0000
  COMBO_SHORTFLAG_SIG_MASK_0: byte =         0b0000_0111
  #
  COMBO_SHORTFLAG_EXPONENT_MASK_0: byte =    0b0111_1111 # 7 of 14
  COMBO_SHORTFLAG_EXPONENT_SHL_0: int =      7
  COMBO_SHORTFLAG_EXPONENT_MASK_1: byte =    0b1111_1110 # 7 of 14
  COMBO_SHORTFLAG_EXPONENT_SHR_1: int =      1
  #
  COMBO_SHORTFLAG_IMPLIED_PREFIX: byte =     0b0 # 1 bit implied; (math) 113 + 1 = 114 bits total
  #
  #   when a "MEDIUMFLAG"...
  COMBO_MEDIUMFLAG_MASK_0: byte =            0b0111_1000
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_A: byte = 0b0110_0000 
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_B: byte = 0b0110_1000
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_C: byte = 0b0111_0000
  COMBO_MEDIUMFLAG_SIGNALS_LONGFLAG: byte =  0b0111_1000
  #
  COMBO_MEDIUMFLAG_EXPONENT_MASK_0: byte =   0b0001_1111 # first 5 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHL_0: int =     9
  COMBO_MEDIUMFLAG_EXPONENT_MASK_1: byte =   0b1111_1111 # second 8 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHL_1: int =     1
  COMBO_MEDIUMFLAG_EXPONENT_MASK_2: byte =   0b1000_0000 # last 1 bit of 14
  COMBO_MEDIUMFLAG_EXPONENT_SHR_2: int =     7
  #
  COMBO_MEDIUMFLAG_SIG_MASK_2: byte =        0b0111_1111 # (math) 7 + (13*8) = 111 bits for significand
  #
  COMBO_MEDIUMFLAG_IMPLIED_PREFIX: byte =    0b100 # 3 bits implied; (math) 111 + 3 = 114 bits total when DPD
  #
  #   when a "LONGFLAG"...
  COMBO_LONGFLAG_MASK_0: byte =             0b0111_1100
  COMBO_LONGFLAG_MEANS_INFINITY: byte =     0b0111_1000
  COMBO_LONGFLAG_MEANS_NAN: byte =          0b0111_1100
  #
  #   when NAN...
  COMBO_NAN_SIGNALING_MASK_0: byte =        0b0000_0010
  COMBO_NAN_QUIET_NAN: byte =               0b0000_0000
  COMBO_NAN_SIGNALING_NAN: byte =           0b0000_0010
  #
  # for BSON style import/export
  #
  BSON_STYLE_LEFT_MASK: uint64 =            0x003FFFFFFFFFFFFF'u64

type
  Decimal128Kind = enum
    # internal use: the state of the Decimal128 variable
    dkValued,
    dkInfinite,
    dkNaN
  Decimal128* = object
    ## A Decimal128 decimal number. Limited to 34 digits.
    ##
    ## This is the nim-internal storage of the number. To import or export
    ## use the corresponding ``newDecimal128`` and ``exportDecimal128`` procedures.
    negative: bool
    case kind: Decimal128Kind
    of dkValued:
      significand: array[SIGNIFICAND_SIZE, byte]
      exponent: int
    of dkInfinite:
      discard
    of dkNaN:
      signalling: bool

  #
  # ** Explaining Significand and It's Storage **
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


proc zero*(): Decimal128 =
  ## Create a Decimal128 value of positive zero
  result = Decimal128(kind: dkValued)
  result.negative = false
  for index in 0 ..< SIGNIFICAND_SIZE:
    result.significand[index] = 0.byte
  result.exponent = 0


proc nan*(): Decimal128 =
  ## Create a non-number aka NaN
  result = Decimal128(kind: dkNaN)


proc digitCount(significand: array[SIGNIFICAND_SIZE, byte]): int =
  # get the number of digits, ignoring the leading zeroes
  # if all zeroes, then eh answer is 1 the actual "0" in the number
  result = 0
  var nonZeroFound = false
  for d in significand:
    if d==0:
      if nonZeroFound:
        result += 1
    else:
      result += 1
      nonZeroFound = false
  if result == 0:
    result = 1


proc newDecimal128UsingBID*(data: string): Decimal128 =
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
  ## encoded back to binary using ``tbd`` then it should exactly match the 
  ## original binary value.
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


proc newDecimal128*(str: string): Decimal128 =
  ## convert a string containing a decimal number to Decimal128
  ##
  ## A few parsing rules:
  ##
  ## * leading whitespace or invalid characters are ignored.
  ## * invalid characters stop the conversion at that point.
  ## * underscores (_) are ignored
  ## * commas (,) are ignored
  ## * only one period is expected.
  ## * 
  ## 
  ## and, currently:
  ##
  ## * scientific notations or "E" notations are not supported.
  ##
  type
    ParseState = enum
      psPre,            # we haven't found the number yet
      psLeadingZeroes,  # we are ignoring any leading zero(s)
      psLeadingMinus,   # we found a minus sign
      psIntCoeff,       # we are reading the the integer part of a decimal number (NN.nnn)
      psDecimalPoint,   # we found a single decimal point
      psFracCoeff,      # we are reading the decimals of a decimal number  (nn.NNN)
      psSignForExp,      # we are reading the +/- of an exponent
      psExp,            # we are reading the decimals of an exponent
      psDone            # ignore everything else

  let s = str.toLower().strip()

  if s.startsWith("nan"):
    result = Decimal128(kind: dkNaN)
    return

  if s.startsWith("+inf"):
    result = Decimal128(kind: dkInfinite, negative: false)
    return
  if s.startsWith("inf"):
    result = Decimal128(kind: dkInfinite, negative: false)
    return
  if s.startsWith("-inf"):
    result = Decimal128(kind: dkInfinite, negative: true)
    return

  result = zero()
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
      digitList.add(DIGITS.find(ch).byte)
      legit = true
    of psDecimalPoint:
      discard
    of psFracCoeff:
      # given the state table, the 'find' function should never return -1
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
  # move the digits into the right-aligned significand
  #
  let offset = SIGNIFICAND_SIZE - digitList.len
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
    except:
      discard


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
    let digitLen = digitCount(d.significand)
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



