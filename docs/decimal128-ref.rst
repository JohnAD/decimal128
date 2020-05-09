decimal128 Reference
==============================================================================

The following are the references for decimal128.



Types
=====



.. _# ** Explaining Significand and It's Storage *.type:
# ** Explaining Significand and It's Storage *
---------------------------------------------------------

    .. code:: nim

        # ** Explaining Significand and It's Storage **


    source line: `171 <../src/decimal128.nim#L171>`__



.. _CoefficientEncoding.type:
CoefficientEncoding
---------------------------------------------------------

    .. code:: nim

        CoefficientEncoding* = enum
          ceDPD,
          ceBID


    source line: `148 <../src/decimal128.nim#L148>`__

    The two coefficient (significand) storage formats supported by IEEE 754 2008.
    
    ``ceDPD`` stands for Densely Packed Decimal
    ``ceBID`` stands for Binary Integer Decimal


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
    use the corresponding ``newDecimal128`` and ``exportDecimal128`` procedures.






Procs, Methods, Iterators
=========================


.. _`!==`.p:
`!==`
---------------------------------------------------------

    .. code:: nim

        proc `!==`*(left: Decimal128, right: Decimal128): bool =

    source line: `966 <../src/decimal128.nim#L966>`__

    Determint the inequality of two decimals, in terms of both numeric value
    and other characteristics such as significance. See ``proc `===` `` for
    more detail.


.. _`$`.p:
`$`
---------------------------------------------------------

    .. code:: nim

        proc `$`*(d: Decimal128): string

    source line: `224 <../src/decimal128.nim#L224>`__



.. _`$`.p:
`$`
---------------------------------------------------------

    .. code:: nim

        proc `$`*(d: Decimal128): string =

    source line: `973 <../src/decimal128.nim#L973>`__

    Express the Decimal128 value as a canonical string


.. _`===`.p:
`===`
---------------------------------------------------------

    .. code:: nim

        proc `===`*(left: Decimal128, right: Decimal128): bool =

    source line: `932 <../src/decimal128.nim#L932>`__

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

    source line: `457 <../src/decimal128.nim#L457>`__

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

    source line: `572 <../src/decimal128.nim#L572>`__

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

    source line: `396 <../src/decimal128.nim#L396>`__

    Get number of digits of precision (significance) of the decimal number.
    
    If a real number, then it will be a number between 1 and 34. Even a value of "0" has
    one digit of Precision.
    A zero is only returned if the number is not-a-number (NaN) or if Infinity.


.. _isInfinite.p:
isInfinite
---------------------------------------------------------

    .. code:: nim

        proc isInfinite*(number: Decimal128): bool =

    source line: `288 <../src/decimal128.nim#L288>`__

    Returns true the number is infinite (positive or negative); otherwise false.


.. _isNaN.p:
isNaN
---------------------------------------------------------

    .. code:: nim

        proc isNaN*(number: Decimal128): bool =

    source line: `327 <../src/decimal128.nim#L327>`__

    Returns true the number is actually not a number (NaN); otherwise false.


.. _isNegative.p:
isNegative
---------------------------------------------------------

    .. code:: nim

        proc isNegative*(number: Decimal128): bool =

    source line: `255 <../src/decimal128.nim#L255>`__

    Returns true if the number is negative or is negative infinity; otherwise false.


.. _isNegativeInfinity.p:
isNegativeInfinity
---------------------------------------------------------

    .. code:: nim

        proc isNegativeInfinity*(number: Decimal128): bool =

    source line: `313 <../src/decimal128.nim#L313>`__

    Returns true the number is infinite and negative; otherwise false.


.. _isPositive.p:
isPositive
---------------------------------------------------------

    .. code:: nim

        proc isPositive*(number: Decimal128): bool =

    source line: `266 <../src/decimal128.nim#L266>`__

    Returns true the number is positive or is positive infinity; otherwise false.


.. _isPositiveInfinity.p:
isPositiveInfinity
---------------------------------------------------------

    .. code:: nim

        proc isPositiveInfinity*(number: Decimal128): bool =

    source line: `299 <../src/decimal128.nim#L299>`__

    Returns true the number is infinite and positive; otherwise false.


.. _isReal.p:
isReal
---------------------------------------------------------

    .. code:: nim

        proc isReal*(number: Decimal128): bool =

    source line: `277 <../src/decimal128.nim#L277>`__

    Returns true the number has a real value; otherwise false.


.. _nan.p:
nan
---------------------------------------------------------

    .. code:: nim

        proc nan*(): Decimal128 =

    source line: `377 <../src/decimal128.nim#L377>`__

    Create a non-number aka NaN


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(str: string): Decimal128 =

    source line: `622 <../src/decimal128.nim#L622>`__

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
    


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(value: float): Decimal128 =

    source line: `850 <../src/decimal128.nim#L850>`__

    Convert a 64-bit floating point number to Decimal128


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(value: int, precision: int): Decimal128 =

    source line: `827 <../src/decimal128.nim#L827>`__

    Convert an integer to Decimal128
    
    Because there is nothing "intrisic" to a binary integer to determine
    precision, a precision parameter *must* be passed.


.. _repr.p:
repr
---------------------------------------------------------

    .. code:: nim

        proc repr*(d: Decimal128): string =

    source line: `226 <../src/decimal128.nim#L226>`__



.. _toFloat.p:
toFloat
---------------------------------------------------------

    .. code:: nim

        proc toFloat*(value: Decimal128): float =

    source line: `909 <../src/decimal128.nim#L909>`__

    Return the floating point equivalent of a decimal.
    
    Please keep in mind that a decimal number can store numbers not possible in binary
    so it is possible this conversion will introduce rounding and conversion
    errors.


.. _toInt.p:
toInt
---------------------------------------------------------

    .. code:: nim

        proc toInt*(value: Decimal128): int =

    source line: `886 <../src/decimal128.nim#L886>`__

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

    source line: `369 <../src/decimal128.nim#L369>`__

    Create a Decimal128 value of positive zero







Table Of Contents
=================

1. `Introduction to decimal128 <https://github.com/JohnAD/decimal128>`__
2. Appendices

    A. `decimal128 Reference <decimal128-ref.rst>`__
