##  IEEE 754-2008 densley packed decimal


proc get10bitGroups*(b: array[16, byte]): array[11, uint16] =
  # this function is for parsing the 110 bits of the significand stored in DPD format
  # returns the 11 groups of 10 bits stored as unsigned 16 bit integers
  const
    START_BIT = 18  # 128 - 18 = 110
    START_BIT_MASK: seq[byte] = @[
      0b11111111.byte, # 0
      0b01111111.byte, # 1
      0b00111111.byte, # 2
      0b00011111.byte, # 3
      0b00001111.byte, # 4
      0b00000111.byte, # 5
      0b00000011.byte, # 6
      0b00000001.byte, # 7
    ]
    END_BIT_MASK: seq[byte] = @[
      0b00000000.byte, # 0 (this value should never be needed)
      0b10000000.byte, # 1
      0b11000000.byte, # 2
      0b11100000.byte, # 3
      0b11110000.byte, # 4
      0b11111000.byte, # 5
      0b11111100.byte, # 6
      0b11111110.byte, # 7
    ]
  var dpb: uint16
  var byteIndex: int
  var bitOffset: int
  var bitsNeeded: int
  if true:
    var bitDisplay = ""
    for i in 0 ..< 16:
      bitDisplay &= b[i].int.toBin(8)
    # echo "full bin: " & bitDisplay
  for i in 0 ..< 11:
    # echo "i: $1".format(i)
    dpb = 0.uint16
    let offset = START_BIT + (i * 10)
    byteIndex = int(offset / 8)
    bitOffset = offset mod 8
    bitsNeeded = 10
    while bitsNeeded > 0:
      # echo "byte: " & $byteIndex
      if bitOffset == 0:
        if bitsNeeded >= 8:
          let remainingBits = bitsNeeded - 8
          # echo "mask: 11111111" 
          dpb = dpb or ( b[byteIndex].uint16 shl remainingBits )
          bitsNeeded -= 8
        else:
          # echo "mask: " & END_BIT_MASK[bitsNeeded].int.toBin(8)
          dpb = dpb or ( (b[byteIndex] and END_BIT_MASK[bitsNeeded]).uint16 shr (8 - bitsNeeded) )
          bitsNeeded = 0
        byteIndex += 1
      else:
        let bitsAvailable = 8 - bitOffset
        # echo "mask: " & START_BIT_MASK[bitOffset].int.toBin(8)
        # echo "shl: " & $(10 - bitsAvailable)
        # echo "masked first:" & (b[byteIndex] and START_BIT_MASK[bitOffset]).int.toBin(8)
        dpb = (b[byteIndex] and START_BIT_MASK[bitOffset]).uint16 shl (10 - bitsAvailable)
        bitsNeeded -= bitsAvailable
        byteIndex += 1
        bitOffset = 0
    result[i] = dpb
    # echo "dpb: " & dpb.int.toBin(10)
    # echo ": " & dpb.int.toBin(13)


proc decode10bitDPD*(dpd: uint16): seq[byte] =
  # decode the 3 digits from a densley packed binary of the first 10 bits
  # returns 3 bytes containing the digits
  # original code from:
  #   https://github.com/wd5gnr/DensePackDecimal/blob/master/dpd.c
  const
    FIRST_CHUNK = 0x380.uint16
    SECOND_CHUNK = 0x70.uint16
    THIRD_CHUNK = 0x7.uint16
  var x: uint16 = 0
  var y: uint16 = 0
  var z: uint16 = 0
  if nz(dpd and 8):
    if (dpd and 0xE) == 0xE:
      case (dpd and 0x60):
      of 0:
        x = 8 + ((dpd and 0x80) shr 7)
        y = 8 + ((dpd and 0x10) shr 4)
        z = ((dpd and 0x300) shr 7) or (dpd and 1)
      of 0x20:
        x = 8 + ((dpd and 0x80) shr 7)
        y = ((dpd and 0x300) shr 7) or ((dpd and 0x10) shr 4)
        z = 8 + (dpd and 1)
      of 0x40:
        x = (dpd and 0x380) shr 7
        y = 8 + ((dpd and 0x10) shr 4)
        z = 8 or (dpd and 1)
      of 0x60:
        x = 8 + ((dpd and 0x80) shr 7)
        y = 8 + ((dpd and 0x10) shr 4)
        z = 8 + (dpd and 1)
      else:
        echo "should never happen (A)"
    else:
      case (dpd and 0xE):
      of 0x8:
        x = (dpd and 0x380) shr 7
        y = (dpd and 0x70) shr 4
        z = 8 + (dpd and 1)
      of 0xA:
        x = (dpd and 0x380) shr 7
        y = 8 + ((dpd and 0x10) shr 4)
        z = ((dpd and 0x60) shr 4) or (dpd and 1)
      of 0xC:
        x = 8 + ((dpd and 0x80) shr 7)
        y = (dpd and 0x70) shr 4
        z = ((dpd and 0x300) shr 7) or (dpd and 1)
      else:
        echo "should never happen (B)"
  else:
    echo "clean"
    x = (dpd and FIRST_CHUNK) shr 7
    y = (dpd and SECOND_CHUNK) shr 4
    z = (dpd and THIRD_CHUNK)
    echo "xyz " & $x & " " & $y & " " & $z
  result = @[x.byte, y.byte, z.byte]
