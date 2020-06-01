decimal128 Reference
==============================================================================

The following are the references for decimal128.



Types
=====



.. _CoefficientEncoding.type:
CoefficientEncoding
---------------------------------------------------------

    .. code:: nim

        CoefficientEncoding* = enum
          ceDPD,
          ceBID


    source line: `147 <../src/decimal128.nim#L147>`__

    The two coefficient (significand) storage formats supported by IEEE 754 2008.
    
    - ``ceDPD`` stands for Densely Packed Decimal
    - ``ceBID`` stands for Binary Integer Decimal
    


.. _Decimal128.type:
Decimal128
---------------------------------------------------------

    .. code:: nim

        Decimal128* = object
          negative: bool
          case kind: Decimal128Kind
          of dkNaN:
          of dkValued:
          of dkInfinite:


    source line: `155 <../src/decimal128.nim#L155>`__

    A Decimal128 decimal number. Limited to 34 digits.
    
    This is the nim-internal storage of the number. To import or export
    use the corresponding ``decodeDecimal128`` and ``encodeDecimal128`` procedures.






Procs, Methods, Iterators
=========================


.. _`!==`.p:
`!==`
---------------------------------------------------------

    .. code:: nim

        proc `!==`*(left: Decimal128, right: Decimal128): bool =

    source line: `1227 <../src/decimal128.nim#L1227>`__

    Determint the inequality of two decimals, in terms of both numeric value
    and other characteristics such as significance. See ``proc `===` `` for
    more detail.


.. _`$`.p:
`$`
---------------------------------------------------------

    .. code:: nim

        proc `$`*(d: Decimal128): string

    source line: `242 <../src/decimal128.nim#L242>`__



.. _`$`.p:
`$`
---------------------------------------------------------

    .. code:: nim

        proc `$`*(d: Decimal128): string =

    source line: `1234 <../src/decimal128.nim#L1234>`__

    Express the Decimal128 value as a canonical string


.. _`===`.p:
`===`
---------------------------------------------------------

    .. code:: nim

        proc `===`*(left: Decimal128, right: Decimal128): bool =

    source line: `1193 <../src/decimal128.nim#L1193>`__

    Determines the equality of the two decimals, in terms of both
    numeric value and other characteristics such as significance.
    
    So, while:
    
    ``Decimal128("120") == Decimal("1.2E2")`` is true
    
    because both are essentially the number 120, the following:
    
    ``Decimal("120") === Decimal("1.2E2")`` is NOT true
    
    because "120" has 3 sigificant digits, "1.2E2" has 2 significant digits.


.. _decodeDecimal128.p:
decodeDecimal128
---------------------------------------------------------

    .. code:: nim

        proc decodeDecimal128*(data: string, encoding: CoefficientEncoding): Decimal128 =

    source line: `574 <../src/decimal128.nim#L574>`__

    Parse the string to a Decimal128 using the IEEE754 2008 encoding with
    the coefficient stored as a unsigned binary integer in the last 113 bits.
    
    This is the encoding method used by BSON and MongoDb.
    
    if the length of the ``data`` string is 32, then it is presumed to be expressed
    as hexidecimal digits.
    
    if the length of the ``data`` string is 16 (128 bits), then it is presumed
    to be a binary copy.
    
    The Decimal128 is NOT normalized in any way. If the returned value is then
    encoded back to binary using ``encodeDecimal128`` then it should exactly match the
    original binary value.
    
    The ``encoding`` method must be of the one of the following:
    
    1. ``ceDPD`` -- Densely Packed Decimal. This matches method 1 of storing the coefficient (significand).
        Essentially, each three digits is stored as a 10-bit declet as described in
        https://en.wikipedia.org/wiki/Densely_packed_decimal
    2. ``ceBID`` -- Binary Integer Decimal. This matches method 2 of storing the coeffecient.
        Essentially, the number is stored as a simple unsigned integer into the last
        133 bits of the 128-bit pattern. See the IEEE 754 2008 spec for details.


.. _encodeDecimal128.p:
encodeDecimal128
---------------------------------------------------------

    .. code:: nim

        proc encodeDecimal128*(value: Decimal128, encoding: CoefficientEncoding): string =

    source line: `689 <../src/decimal128.nim#L689>`__

    Generate a sequence of bytes that matches the IEEE 754 2008 specification.
    
    The returned string will be exactly 16 bytes long and very likely contains
    binary zero (null) values. The result is not meant to be printable.
    
    The ``encoding`` method must be of the one of the following:
    
    1. ``ceDPD`` -- Densely Packed Decimal. This matches method 1 of storing the coefficient (significand).
        Essentially, each three digits is stored as a 10-bit declet as described in
        https://en.wikipedia.org/wiki/Densely_packed_decimal
    2. ``ceBID`` -- Binary Integer Decimal. This matches method 2 of storing the coeffecient.
        Essentially, the number is stored as a simple unsigned integer into the last
        133 bits of the 128-bit pattern. See the IEEE 754 2008 spec for details.


.. _getPrecision.p:
getPrecision
---------------------------------------------------------

    .. code:: nim

        proc getPrecision*(number: Decimal128): int =

    source line: `512 <../src/decimal128.nim#L512>`__

    Get number of digits of precision (significance) of the decimal number.
    
    If a real number, then it will be a number between 1 and 34. Even a value of "0" has
    one digit of Precision.
    
    A zero is returned if the number is not-a-number (NaN) or Infinity.


.. _getScale.p:
getScale
---------------------------------------------------------

    .. code:: nim

        proc getScale*(number: Decimal128): int =

    source line: `533 <../src/decimal128.nim#L533>`__

    Get number of digits of the fractional part of the number. Or to put it differently:
    get the number of decimals after the decimal point.
    
    If a real number, then it will be a number between -6143 and 6144.
    
    ``assert getScale(Decimal128("123.450")) == 3``
    
    ``assert getScale(Decimal128("1.2E3")) == -2``  # aka 1.2 x 10^3  or 1200
    
    A zero is returned if the number is not-a-number (NaN) or Infinity.


.. _isInfinite.p:
isInfinite
---------------------------------------------------------

    .. code:: nim

        proc isInfinite*(number: Decimal128): bool =

    source line: `306 <../src/decimal128.nim#L306>`__

    Returns true the number is infinite (positive or negative); otherwise false.


.. _isNaN.p:
isNaN
---------------------------------------------------------

    .. code:: nim

        proc isNaN*(number: Decimal128): bool =

    source line: `345 <../src/decimal128.nim#L345>`__

    Returns true the number is actually not a number (NaN); otherwise false.


.. _isNegative.p:
isNegative
---------------------------------------------------------

    .. code:: nim

        proc isNegative*(number: Decimal128): bool =

    source line: `273 <../src/decimal128.nim#L273>`__

    Returns true if the number is negative or is negative infinity; otherwise false.


.. _isNegativeInfinity.p:
isNegativeInfinity
---------------------------------------------------------

    .. code:: nim

        proc isNegativeInfinity*(number: Decimal128): bool =

    source line: `331 <../src/decimal128.nim#L331>`__

    Returns true the number is infinite and negative; otherwise false.


.. _isPositive.p:
isPositive
---------------------------------------------------------

    .. code:: nim

        proc isPositive*(number: Decimal128): bool =

    source line: `284 <../src/decimal128.nim#L284>`__

    Returns true the number is positive or is positive infinity; otherwise false.


.. _isPositiveInfinity.p:
isPositiveInfinity
---------------------------------------------------------

    .. code:: nim

        proc isPositiveInfinity*(number: Decimal128): bool =

    source line: `317 <../src/decimal128.nim#L317>`__

    Returns true the number is infinite and positive; otherwise false.


.. _isReal.p:
isReal
---------------------------------------------------------

    .. code:: nim

        proc isReal*(number: Decimal128): bool =

    source line: `295 <../src/decimal128.nim#L295>`__

    Returns true the number has a real value; otherwise false.


.. _nan.p:
nan
---------------------------------------------------------

    .. code:: nim

        proc nan*(): Decimal128 =

    source line: `413 <../src/decimal128.nim#L413>`__

    Create a non-number aka NaN


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(str: string, precision: int = NOP, scale: int = NOP): Decimal128 =

    source line: `1005 <../src/decimal128.nim#L1005>`__

    convert a string containing a decimal number to Decimal128
    
    A few parsing rules:
    
    * leading whitespace or invalid characters are ignored.
    * invalid characters stop the conversion at that point.
    * underscores (_) are ignored
    * commas (,) are ignored
    * only one period is expected.
    * case is ignored
    
    The string can contain one of the following:
    
    1. ``"Infinity"`` or ``"-Infinity"`` for positive/negative infinity.
       This can also be ``"+Infinity"`` or anything that starts with "inf"
    2. ``"NaN"`` for a Not-A-Number designation.
    3. Any simple decimal number, such as ``"12.34223"``.
    4. Any simple integer, such as ``"38923"`` or ``"-0236"``.
    5. Any number in scientific notation using ``E`` as a prefix for the exponent.
       Examples: ``"-1423E+3"`` or ``"3.2232E-20"``.
    
    If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
    needed, additional decimal places are added to the right. For example, ``Decimal128("423.0", precision=6)`` is
    the equivalant of "423.000" and ``Decimal128("423.0", precision=1)`` is "400", or more accurately, "4E2".
    
    If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
    of digits before/after the decimal place. For example, ``Decimal128("423.0", scale=2)`` is the equivalent of
    "423.00" and ``Decimal128("423.0", scale=-2)`` is "400", or more accurately, "4E2".
    
    If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
    resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
    
    For example:
    
    ``let x = Decimal128("423.0", precision=6, scale=2)``
    
    works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
    
    ``let x = Deicmal128("73737", precision=6, scale=2)``
    
    will generate a ValueError at run-time since "73737.00" has a precision of 7.


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(value: float, precision: int = NOP, scale: int = NOP): Decimal128 =

    source line: `1090 <../src/decimal128.nim#L1090>`__

    Convert a 64-bit floating point number to Decimal128
    
    If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
    needed, additional decimal places are added to the right. For example, ``Decimal128(423.0, precision=6)`` is
    the equivalant of "423.000" and ``Decimal128(423.0, precision=1)`` is "400", or more accurately, "4E2".
    
    If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
    of digits before/after the decimal place. For example, ``Decimal128(423.0, scale=2)`` is the equivalent of
    "423.00" and ``Decimal128(423.0, scale=-2)`` is "400", or more accurately, "4E2".
    
    If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
    resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
    
    For example:
    
    ``let x = Decimal128(423.0, precision=6, scale=2)``
    
    works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
    
    ``let x = Deicmal128(73737.0, precision=6, scale=2)``
    
    will generate a ValueError at run-time since "73737.00" has a precision of 7.


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(value: int, precision: int = NOP, scale: int = NOP): Decimal128 =

    source line: `1064 <../src/decimal128.nim#L1064>`__

    Convert an integer to Decimal128
    
    If ``precision`` is passed a value (from 1 to 34), then the number is forced to use that precision. When
    needed, additional decimal places are added to the right. For example, ``Decimal128(423, precision=6)`` is
    the equivalant of "423.000" and ``Decimal128(423, precision=1)`` is "400", or more accurately, "4E2".
    
    If ``scale`` is passed a value (−6143 to +6144), then the number is forced to use the equivalent number
    of digits before/after the decimal place. For example, ``Decimal128(423, scale=2)`` is the equivalent of
    "423.00" and ``Decimal128(423, scale=-2)`` is "400", or more accurately, "4E2".
    
    If both ``precision`` and ``scale`` are passed, then the ``scale`` is first used, then a check is made: does the
    resulting decimal value "fit" within the requested ``precision``? If not, a ValueError is raised.
    
    For example:
    
    ``let x = Decimal128(423, precision=6, scale=2)``
    
    works perfectly. "423.00" has a precision of 5, which is less than or equal to 6. But:
    
    ``let x = Deicmal128(73737, precision=6, scale=2)``
    
    will generate a ValueError at run-time since "73737.00" has a precision of 7.


.. _repr.p:
repr
---------------------------------------------------------

    .. code:: nim

        proc repr*(d: Decimal128): string =

    source line: `244 <../src/decimal128.nim#L244>`__



.. _setPrecision.p:
setPrecision
---------------------------------------------------------

    .. code:: nim

        proc setPrecision*(value: Decimal128, precision: int): Decimal128 =

    source line: `948 <../src/decimal128.nim#L948>`__

    Create a Decimal128 with the supplied precision.
    
    The supplied precision must be a value from 1 to 34.
    
    When NaN or Infinity is passed, the value is return as-is.


.. _setScale.p:
setScale
---------------------------------------------------------

    .. code:: nim

        proc setScale*(value: Decimal128, scale: int): Decimal128 =

    source line: `977 <../src/decimal128.nim#L977>`__

    Create a Decimal128 with the supplied scale.
    
    The scale must be a value from −6143 to +6144
    
    When NaN or Infinity is passed, the value is return as-is.


.. _toFloat.p:
toFloat
---------------------------------------------------------

    .. code:: nim

        proc toFloat*(value: Decimal128): float =

    source line: `1170 <../src/decimal128.nim#L1170>`__

    Return the floating point equivalent of a decimal.
    
    Please keep in mind that a decimal number can store numbers not possible in binary
    so it is possible this conversion will introduce rounding and conversion
    errors.


.. _toInt.p:
toInt
---------------------------------------------------------

    .. code:: nim

        proc toInt*(value: Decimal128): int =

    source line: `1147 <../src/decimal128.nim#L1147>`__

    Return the integer part of a decimal as an int.
    
    This function truncates rather than rounds. So "1.6" will return an integer of
    1 not 2.
    
    If the integer part will not fit into a Nim integer, then
    an OverflowError error is raised.


.. _zero.p:
zero
---------------------------------------------------------

    .. code:: nim

        proc zero*(): Decimal128 =

    source line: `397 <../src/decimal128.nim#L397>`__

    Create a Decimal128 value of positive zero







Table Of Contents
=================

1. `Introduction to decimal128 <https://github.com/JohnAD/decimal128>`__
2. Appendices

    A. `decimal128 Reference <decimal128-ref.rst>`__
