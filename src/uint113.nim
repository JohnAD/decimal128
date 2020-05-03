## A 113-bit unsigned integer library
## Limited to 34 decimal digits, it is meant for use by ``decimal128``

import strutils
import strformat
import unicode

const
  MAXIMUM_SIGNIFICAND: string = "10_000_000_000_000_000_000_000_000_000_000_000"
  MAX_DIGITS: int = 34

const
  DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

type
  uint113* = object
    # used internally to store the digits when importing or exporting to 
    left: uint64
    right: uint64


proc leftHalf(value: uint64): uint32 =
  # TODO: untried
  result = (value shr 32).uint32

proc setLeftHalf(value: var uint64, newValue: uint64) =
  # TODO: untried
  value = value and 0x00000000FFFFFFFF'u64 # wipe out the left
  let temp = (newValue and 0x00000000FFFFFFFF'u64) shl 32        # shift new value to left
  value = value or temp                    # OR into place

proc rightHalf(value: uint64): uint32 =
  # TODO: untried
  result = (value and 0x00000000FFFFFFFF'u64).uint32

proc setRightHalf(value: var uint64, newValue: uint64) =
  # TODO: untried
  value = value and 0xFFFFFFFF00000000'u64 # wipe out right
  value = value or (newValue and 0x00000000FFFFFFFF'u64)


const
  MASK_FOR_LEFT_ON_113BITS: uint64 = 0x0001FFFFFFFFFFFF'u64
  MAX_DECIMAL = uint113(left: 0x0001_ED09_BEAD_87C0'u64, right: 0x378D_8E63_FFFF_FFFF'u64) # 34 decimals of '9' is hex 1 ED09 BEAD 87C0 378D 8E63 FFFF FFFF
  POWER_OF_TEN: seq[uint113] = @[
    uint113(left: 0x0000_314D_C644_8D93'u64, right: 0x38C1_5B0A_0000_0000'u64), # 10 ^ 33 = hex 314D C644 8D93 38C1 5B0A 0000 0000
    uint113(left: 0x0000_04EE_2D6D_415B'u64, right: 0x85AC_EF81_0000_0000'u64), # 10 ^ 32 = hex 4EE 2D6D 415B 85AC EF81 0000 0000
    uint113(left: 0x0000_007E_37BE_2022'u64, right: 0xC091_4B26_8000_0000'u64), # 10 ^ 31 = hex 7E 37BE 2022 C091 4B26 8000 0000
    uint113(left: 0x0000_000C_9F2C_9CD0'u64, right: 0x4674_EDEA_4000_0000'u64), # 10 ^ 30 = hex C 9F2C 9CD0 4674 EDEA 4000 0000
    uint113(left: 0x0000_0001_431E_0FAE'u64, right: 0x6D72_17CA_A000_0000'u64), # 10 ^ 29 = hex 1 431E 0FAE 6D72 17CA A000 0000
    uint113(left: 0x0000_0000_204F_CE5E'u64, right: 0x3E25_0261_1000_0000'u64), # 10 ^ 28 = hex 204F CE5E 3E25 0261 1000 0000
    uint113(left: 0x0000_0000_033B_2E3C'u64, right: 0x9FD0_803C_E800_0000'u64), # 10 ^ 27 = hex 33B 2E3C 9FD0 803C E800 0000
    uint113(left: 0x0000_0000_0052_B7D2'u64, right: 0xDCC8_0CD2_E400_0000'u64), # 10 ^ 26 = hex 52 B7D2 DCC8 0CD2 E400 0000
    uint113(left: 0x0000_0000_0008_4595'u64, right: 0x1614_0148_4A00_0000'u64), # 10 ^ 25 = hex 8 4595 1614 0148 4A00 0000
    uint113(left: 0x0000_0000_0000_D3C2'u64, right: 0x1BCE_CCED_A100_0000'u64), # 10 ^ 24 = hex D3C2 1BCE CCED A100 0000
    uint113(left: 0x0000_0000_0000_152D'u64, right: 0x02C7_E14A_F680_0000'u64), # 10 ^ 23 = hex 152D 02C7 E14A F680 0000
    uint113(left: 0x0000_0000_0000_021E'u64, right: 0x19E0_C9BA_B240_0000'u64), # 10 ^ 22 = hex 21E 19E0 C9BA B240 0000
    uint113(left: 0x0000_0000_0000_0036'u64, right: 0x35C9_ADC5_DEA0_0000'u64), # 10 ^ 21 = hex 36 35C9 ADC5 DEA0 0000
    uint113(left: 0x0000_0000_0000_0005'u64, right: 0x6BC7_5E2D_6310_0000'u64), # 10 ^ 20 = hex 5 6BC7 5E2D 6310 0000
    uint113(left: 0x0000_0000_0000_0000'u64, right: 0x8AC7_2304_89E8_0000'u64), # 10 ^ 19 = hex 8AC7 2304 89E8 0000
    uint113(left: 0'u64, right: 1000000000000000000'u64), # 10 ^ 18
    uint113(left: 0'u64, right: 100000000000000000'u64), # 10 ^ 17
    uint113(left: 0'u64, right: 10000000000000000'u64), # 10 ^ 16
    uint113(left: 0'u64, right: 1000000000000000'u64), # 10 ^ 15
    uint113(left: 0'u64, right: 100000000000000'u64), # 10 ^ 14
    uint113(left: 0'u64, right: 10000000000000'u64), # 10 ^ 13
    uint113(left: 0'u64, right: 1000000000000'u64), # 10 ^ 12
    uint113(left: 0'u64, right: 100000000000'u64), # 10 ^ 11
    uint113(left: 0'u64, right: 10000000000'u64), # 10 ^ 10
    uint113(left: 0'u64, right: 1000000000'u64), # 10 ^ 9
    uint113(left: 0'u64, right: 100000000'u64), # 10 ^ 8
    uint113(left: 0'u64, right: 10000000'u64), # 10 ^ 7
    uint113(left: 0'u64, right: 1000000'u64), # 10 ^ 6
    uint113(left: 0'u64, right: 100000'u64), # 10 ^ 5
    uint113(left: 0'u64, right: 10000'u64), # 10 ^ 4
    uint113(left: 0'u64, right: 1000'u64), # 10 ^ 3
    uint113(left: 0'u64, right: 100'u64), # 10 ^ 2
    uint113(left: 0'u64, right: 10'u64), # 10 ^ 1
    uint113(left: 0'u64, right: 1'u64)  # 10 ^ 0
  ]
  BILLION: uint32 = 1000 * 1000 * 1000 # a billion has 10 digits and fits into 32 bits


proc greaterOrEqualToOneBillion*(val: uint113): bool =
  ## very specifically, is the amount in uint113 more than 1_000_000_000
  if val.left != 0'u64:
    result = true
  elif val.right >= BILLION.uint64:
    result = true
  else:
    result = false


proc deepCopy*(original: uint113): uint113 =
  ## returns a copy of ``original`` that is not connected to the original
  result = uint113(left: original.left, right: original.right)


proc divide*(dividend: uint113, divisor: uint32): tuple[quotient: uint113, remainder: uint32] =
  ##
  ## division for uint113, but limited to a 32-bit divisor and 64-bit remainder
  ##
  # TODO: untried
  var remainder = 0.uint64
  var pending = uint113(left: dividend.left, right: dividend.right)
  if (pending.left == 0) and (pending.right == 0):
    result.quotient = pending
    result.remainder = 0.uint32
    return

  remainder += pending.left.leftHalf()
  pending.left.setLeftHalf(remainder div divisor)
  remainder = remainder mod divisor

  remainder = remainder shl 32
  remainder += pending.left.rightHalf()
  pending.left.setRightHalf(remainder div divisor)
  remainder = remainder mod divisor

  remainder = remainder shl 32
  remainder += pending.right.leftHalf()
  pending.right.setLeftHalf(remainder div divisor)
  remainder = remainder mod divisor

  remainder = remainder shl 32
  remainder += pending.right.rightHalf()
  pending.right.setRightHalf(remainder div divisor)
  remainder = remainder mod divisor

  result.quotient = pending
  result.remainder = remainder.uint32


proc decode113bit*(b: array[16, byte]): array[MAX_DIGITS, byte] =
  ## Decodes the decimal value of the 113bit ``b`` and returns the
  ## digits as an array of 34 digits. A digit is a byte with value between 00 to 09.
  for index in 0 ..< MAX_DIGITS:
    result[index] = 0.byte
  #
  # turn the byte array into a pair of uint64 and put it into uint113
  #
  var hold = uint113(left: 0, right: 0)
  for index in 0 .. 7:
    var temp_left: uint64 = b[index].uint64 shl ((7 - index) * 8) 
    hold.left = hold.left or temp_left
    var temp_right: uint64 = b[index + 8].uint64 shl ((7 - index) * 8)
    hold.right = hold.right or temp_right
  hold.left = hold.left and MASK_FOR_LEFT_ON_113BITS
  #
  #
  #
  if hold.left == 0:
    #
    # handle the simple case first: the most-significant (left-hand) 64 bits are zero
    #
    let digitStr = $hold.right # we take advantage of the standard library $
    var dIndex = MAX_DIGITS - 1  # max size is 18446744073709551615 (20 digits) so we are safe.
    for ch in digitStr.reversed:
      let digit = ch.byte - '0'.byte
      result[dIndex] = digit
      dIndex -= 1
  else:
    #
    # handle full conversion with 32-bit division against 113-bit
    #
    #
    # technique:
    #   We are going to play a "trick" with the number "one billion" aka 1,000,000,000. That number has the following traits:
    #
    #   * it fits into a 32-bit unsigned integer; we have a way of dividing a 113-bit (or 128-bit) number by a 32-bit number
    #   * when a big number is divided by a billion:
    #      - the remainder is the "bottom nine" digits of that number (which also fits in 32-bit number)
    #      - the quotient is a number representing the top part of that number
    #
    #   The maximum digits allowed by decimal128 is 34. We will keep dividing the number by a billion until we have a
    #   quotient below one billion. Then, that quotient followed by the remainders represents the digits.
    #
    #   here is an example showing the same idea but used with 100 (and two digits) to make it easier to visualize:
    #
    #     starting number: 90230427
    #
    #     90230427 / 100 = 902304 with remainder 27  # digits so far = "27"
    #     902304 / 100 = 9023 with remainder 4       # digits so far = "0427"
    #     9023 / 100 =  90 with remainder 23         # digits so far = "230427"
    #
    #     90 is less than 100, so the answer is "90" & "230427" which is "90230427"
    #
    var bigNumber = ""
    var quotient = uint113(left: hold.left, right:hold.right)
    var remainder: uint32 = 0
    while quotient.greaterOrEqualToOneBillion:
      (quotient, remainder) = divide(quotient, BILLION)
      bigNumber = fmt"{remainder:09}" & bigNumber  # put the new digits _before_ the existing ones
    let quotientSmaller = (quotient.right and 0xFFFF_FFFF'u64).uint32
    bigNumber = fmt"{quotientSmaller:09}" & bigNumber
    let digitCount = bigNumber.len
    if digitCount > MAX_DIGITS:
      let extraDigitCount = digitCount - MAX_DIGITS
      let extraDigits = bigNumber[0 ..< extraDigitCount ]
      for ch in extraDigits:
        if ch != '0':
          raise newException(ValueError, "Cannot store a number with more than 34 digits ($1).".format(bigNumber))
      bigNumber = bigNumber[extraDigitCount ..< ^0]
    var dIndex = MAX_DIGITS - 1
    for ch in fmt"{bigNumber:0>34}".reversed:
      let digit = ch.byte - '0'.byte
      result[dIndex] = digit
      dIndex -= 1

