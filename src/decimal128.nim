##  IEEE 754-2008


import strutils
import bitops

proc nz(v: byte): bool =
  if v == 0.byte:
    result = false
  else:
    result = true

const
  MAXIMUM_COEFFICIENT: string = "10_000_000_000_000_000_000_000_000_000_000_000"
  COEFFICIENT_SIZE: int = 34
  BIAS: int = 6176

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
  COMBO_SHORTFLAG_EXPONENT_MASK_0: byte =    0b0111_1111 # first 7 bits of 14
  COMBO_SHORTFLAG_EXPONENT_MASK_1: byte =    0b1111_1110 # second 7 bits of 14
  COMBO_SHORTFLAG_SIG_MASK_1: byte =         0b0000_0001 # (math) 1 + (14*8) = 113 bits for significand
  #
  COMBO_SHORTFLAG_IMPLIED_PREFIX: byte =     0b0 # 1 bit implied; (math) 113 + 1 = 114 bits total
  #
  #   when a "MEDIUMFLAG"...
  COMBO_MEDIUMFLAG_MASK_0: byte =            0b0111_1000
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_A: byte = 0b0110_0000 
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_B: byte = 0b0110_1000
  COMBO_MEDIUMFLAG_MEANS_100PREFIX_C: byte = 0b0111_0000
  COMBO_MEDIUMFLAG_SIGNALS_LONGFLAG: byte =  0b0111_1000
  COMBO_MEDIUMFLAG_EXPONENT_MASK_0: byte =   0b0001_1111 # first 5 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_MASK_1: byte =   0b1111_1111 # second 8 bits of 14
  COMBO_MEDIUMFLAG_EXPONENT_MASK_2: byte =   0b1000_0000 # last 1 bit of 14
  COMBO_MEDIUMFLAG_SIG_MASK_2: byte =        0b0111_1111 # (math) 7 + (13*8) = 111 bits for significand
  #
  COMBO_MEDIUMFLAG_IMPLIED_PREFIX: byte =    0b100 # 3 bits implied; (math) 111 + 3 = 114 bits total
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
  # The significand has 114 bits (of the 128). It is stored as follows
  #
  # if the first digit starts with 8 or 9:
  #   The first digit is 0b100x, where the bit 17 of source is 'x'; essentially 8 = 0b1000 and 9 = 0b1001
  #   The remaining 110 bits are bits 18 to 127 and are decoded as eleven 10-bit triples for the remaining 33 digits.
  #   I've been calling this setup a "MEDIUMFLAG" in the COMBO field.
  # else:
  #   The first digit is 0b0xxx, where bits 15, 16, and 17 of source are 'xxx'
  #   The remaining 110 bits are bits 18 to 127 and are decoded as eleven 10-bit triples for the remaining 33 digits.
  #   I've been calling this setup a "SHORTFLAG" in the combo field.
  #
  # To head off a key question: 
  #   1. the "LONGFLAG" in the combo field is for non-numbers: not-a-number (NaN) and infinity (Infinity)
  #   2. yes everything is convoluted. But the spec is what it is.

# proc decode_dpb(dpd: uint16): seq[byte] =
#   # decode the 3 digits from a densley packed binary of the first 10 bits
#   # returns 3 bytes containing the digits
#   # original code from:
#   #   https://github.com/wd5gnr/DensePackDecimal/blob/master/dpd.c
#   var uint16: x=0, y=0, z=0
#   if (dpd&8):
#     if (dpd&0xE) == 0xE:
#       case (dpd&0x60):
#       of 0:
#         x = 8 + ((dpd&0x80)>>7)
#         y = 8 + ((dpd&0x10)>>4)
#         z = (dpd&0x300)>>7|(dpd&1)
#       of 0x20:
#         x = 8 + ((dpd&0x80)>>7)
#         y = (dpd&0x300)>>7|(dpd&0x10)>>4
#         z = 8 + (dpd&1)
#       of 0x40:
#         x = (dpd&0x380)>>7
#         y = 8 + ((dpd&0x10)>>4)
#         z = 8|(dpd&1)
#       of 0x60:
#         x = 8 + ((dpd&0x80)>>7)
#         y = 8 + ((dpd&0x10)>>4)
#         z = 8 + (dpd&1)
#     else:
#       case (dpd&0xE):
#       of 0x8:
#         x = (dpd&0x380)>>7
#         y = (dpd&0x70)>>4
#         z = 8 + (dpd&1)
#       of 0xA:
#         x = (dpd&0x380)>>7
#         y = 8 + ((dpd&0x10)>>4)
#         z = (dpd&0x60)>>4|(dpd&1)
#       of 0xC:
#         x = 8 + ((dpd&0x80)>>7)
#         y = (dpd&0x70)>>4
#         z = (dpd&0x300)>>7|(dpd&1)
#   else:
#     x = (dpd&0x380)>>7
#     y = (dpd&0x70)>>4
#     z = (dpd&7)
#   result = @[x.byte, y.byte, z.byte]


type
  Decimal128Kind = enum
    dkValued,
    dkInfinite,
    dkNaN
  Decimal128 = object
    negative: bool
    case kind: Decimal128Kind
    of dkValued:
      significand: array[COEFFICIENT_SIZE, byte]
      exponent: int
    of dkInfinite:
      discard
    of dkNaN:
      signalling: bool


proc zero*(): Decimal128 =
  ## Create a Decimal128 value of positive zero
  result = Decimal128(kind: dkValued)
  result.negative = false
  for index in 0 ..< COEFFICIENT_SIZE:
    result.significand[index] = 0.byte
  result.exponent = 0


proc nan*(): Decimal128 =
  ## Create a non-number aka NaN
  result = Decimal128(kind: dkNaN)


  # SIGN_MASK_0: byte =  0b1000_0000 # the first bit of byte 0 is the positive/negative sign
  # COMBO_MASK_0: byte = 0b0111_1111 # first 7 bits in the combo field of 17 bits (byte 0)
  # COMBO_MASK_1: byte = 0b1111_1111 # second 8 bits in the combo field of 17 bits (byte 1)
  # COMBO_MASK_2: byte = 0b1100_1111 # remaining 2 bits in the combo field (byte 2)
  # #
  # # breaking down the possible parts of the combo field (17 bits in 3 bytes)
  # #
  # #   starting with the combo fields first two bits (what I will call a "SHORTFLAG")...
  # COMBO_SHORTFLAG_MASK_0: byte =             0b0110_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_A: byte =    0b0000_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_B: byte =    0b0010_0000
  # COMBO_SHORTFLAG_MEANS_0PREFIX_C: byte =    0b0100_0000
  # COMBO_SHORTFLAG_SIGNALS_MEDIUMFLAG: byte = 0b0110_0000
  # COMBO_SHORTFLAG_EXPONENT_MASK_0: byte =    0b0111_1111 # first 7 bits of 14
  # COMBO_SHORTFLAG_EXPONENT_MASK_1: byte =    0b1111_1110 # second 7 bits of 14
  # COMBO_SHORTFLAG_SIG_MASK_1: byte =         0b0000_0001 # (math) 1 + (14*8) = 113 bits for significand
  # #
  # COMBO_SHORTFLAG_IMPLIED_PREFIX: byte =     0b0 # 1 bit implied; (math) 113 + 1 = 114 bits total
  # #
  # #   when a "MEDIUMFLAG"...
  # COMBO_MEDIUMFLAG_MASK_0: byte =            0b0111_1000
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_A: byte = 0b0110_0000 
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_B: byte = 0b0110_1000
  # COMBO_MEDIUMFLAG_MEANS_100PREFIX_C: byte = 0b0111_0000
  # COMBO_MEDIUMFLAG_SIGNALS_LONGFLAG: byte =  0b0111_1000
  # COMBO_MEDIUMFLAG_EXPONENT_MASK_0: byte =   0b0001_1111 # first 5 bits of 14
  # COMBO_MEDIUMFLAG_EXPONENT_MASK_1: byte =   0b1111_1111 # second 8 bits of 14
  # COMBO_MEDIUMFLAG_EXPONENT_MASK_2: byte =   0b1000_0000 # last 1 bit of 14
  # COMBO_MEDIUMFLAG_SIG_MASK_2: byte =        0b0111_1111 # (math) 7 + (13*8) = 111 bits for significand
  # #
  # COMBO_MEDIUMFLAG_IMPLIED_PREFIX: byte =    0b100 # 3 bits implied; (math) 111 + 3 = 114 bits total
  # #
  # #   when a "LONGFLAG"...
  # COMBO_LONGFLAG_MASK_0: byte =             0b0111_1100
  # COMBO_LONGFLAG_MEANS_INFINITY: byte =     0b0111_1000
  # COMBO_LONGFLAG_MEANS_NAN: byte =          0b0111_1100
  # #
  # #   when NAN...
  # COMBO_NAN_SIGNALING_MASK_0: byte =        0b0000_0010
  # COMBO_NAN_QUIET_NAN: byte =               0b0000_0000
  # COMBO_NAN_SIGNALING_NAN: byte =           0b0000_0010

proc newDecimal128FromHex*(hexStr: string): Decimal128 =
  #
  # parse the string to binary
  #
  if hexStr.len != 32:  # 128 bits == 16 bytes * 2 = 32
    raise newException(ValueError, "original hexStr the wrong size (len=$1)".format(hexStr.len))
  let bsStr = parseHexStr(hexStr)
  if bsStr.len != 16:  # 128 bits == 16 bytes
    raise newException(ValueError, "parsed hexStr the wrong size (len=$1)".format(bsStr.len))
  var bs: seq[byte] = @[]
  for ch in bsStr:
    bs.add ch.byte
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
  var exponent: int16
  var sigPrefix: byte
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
      # TODO: the rest
  else:
    #
    # interpret shortFlag
    #
    decType = dkValued
    # exponentPrefix = comboShortFlag >> 5
    # sigPrefix = (COMBO_SHORTFLAG_SIG_MASK_1 and c1)
    # TODO: the rest
  #
  # return the value
  #
  case decType:
  of dkValued:
    result = Decimal128(kind: dkValued)
    result.negative = negative
    # TODO: the rest
  of dkInfinite:
    result = Decimal128(kind: dkInfinite)
    result.negative = negative
  of dkNaN:
    result = Decimal128(kind: dkNaN)
    result.signalling = signalling


proc toDecimal128*(s: string): Decimal128 =
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
      psExp,            # not used at moment
      psDone            # ignore everything else


  result = zero()
  var state: ParseState = psPre
  var index: int = 0
  var legit = false

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
      else:
        state = psDone
    of psIntCoeff:
      if DIGITS.contains(ch):
        discard
      elif ch == '.':
        state = psDecimalPoint
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
      else:
        state = psDone
    of psExp:
      discard
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
      result.significand[index] = DIGITS.find(ch).byte
      index += 1
      legit = true
    of psDecimalPoint:
      discard
    of psFracCoeff:
      # given the state table, the 'find' function should never return -1
      result.significand[index] = DIGITS.find(ch).byte
      index += 1
      result.exponent -= 1
      legit = true
    of psExp:
      discard
    of psDone:
      discard


proc `$`*(d: Decimal128): string =
  case d.kind:
  of dkValued:
    # TODO: fix
    if d.negative:
      result = "-"
    else:
      result = ""
    result &= "0"
  of dkInfinite:
    if d.negative:
      result = "-Infinity"
    else:
      result = "Infinity"
  of dkNaN:
    result = "NaN"
  # if d.negative:
  #   result &= "-"
  # for digit in d.significand:
  #   result &= DIGITS[digit]
  # result &= "*10^"
  # result &= $d.exponent


proc repr*(d: Decimal128): string =
  result = "( "
  if d.negative:
    result &= "-"
  else:
    result &= "+"
  result &= " , "
  for digit in d.significand:
    result &= DIGITS[digit]
  result &= " , *10^ "
  result &= $d.exponent
  result &= " )"



