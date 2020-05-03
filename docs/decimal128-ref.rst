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


    source line: `132 <../src/decimal128.nim#L132>`__



.. _Decimal128.type:
Decimal128
---------------------------------------------------------

    .. code:: nim

        Decimal128* = object
          negative: bool
          case kind: Decimal128Kind
          of dkValued:
          of dkInfinite:
          of dkNaN:


    source line: `116 <../src/decimal128.nim#L116>`__

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

    source line: `562 <../src/decimal128.nim#L562>`__

    Determint the inequality of two decimals, in terms of both numeric value
    and other characteristics such as significance. See ``proc `===` `` for
    more detail.


.. _`$`.p:
`$`
---------------------------------------------------------

    .. code:: nim

        proc `$`*(d: Decimal128): string =

    source line: `569 <../src/decimal128.nim#L569>`__

    Express the Decimal128 value as a canonical string


.. _`===`.p:
`===`
---------------------------------------------------------

    .. code:: nim

        proc `===`*(left: Decimal128, right: Decimal128): bool =

    source line: `528 <../src/decimal128.nim#L528>`__

    Determines the equality of the two decimals, in terms of both
    numeric value and other characteristics such as significance.
    
    So, while:
    
    ``Decimal128("120") == Decimal("1.2E2")`` is true
    
    because both are essentially the number 120, the following:
    
    ``Decimal("120") === Decimal("1.2E2")`` is NOT true
    
    because "120" has 3 sigificant digits, "1.2E2" has 2 significant digits.


.. _nan.p:
nan
---------------------------------------------------------

    .. code:: nim

        proc nan*(): Decimal128 =

    source line: `194 <../src/decimal128.nim#L194>`__

    Create a non-number aka NaN


.. _newDecimal128.p:
newDecimal128
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128*(str: string): Decimal128 =

    source line: `317 <../src/decimal128.nim#L317>`__

    convert a string containing a decimal number to Decimal128
    
    A few parsing rules:
    
    * leading whitespace or invalid characters are ignored.
    * invalid characters stop the conversion at that point.
    * underscores (_) are ignored
    * commas (,) are ignored
    * only one period is expected.
    *
    
    and, currently:
    
    * scientific notations or "E" notations are not supported.
    


.. _newDecimal128UsingBID.p:
newDecimal128UsingBID
---------------------------------------------------------

    .. code:: nim

        proc newDecimal128UsingBID*(data: string): Decimal128 =

    source line: `215 <../src/decimal128.nim#L215>`__

    Parse the string to a Decimal128 using the IEEE754 2008 encoding with
    the coefficient stored as a unsigned binary integer in the last 113 bits.
    
    This is the encoding method used by BSON and MongoDb.
    
    if the length of the ``data`` string is 32, then it is presumed to be expressed
    as hexidecimal digits.
    
    if the length of the ``data`` string is 16 (128 bits), then it is presumed
    to be a binary copy.
    
    The Decimal128 is NOT normalized in any way. If the returned value is then
    encoded back to binary using ``tbd`` then it should exactly match the
    original binary value.


.. _repr.p:
repr
---------------------------------------------------------

    .. code:: nim

        proc repr*(d: Decimal128): string =

    source line: `589 <../src/decimal128.nim#L589>`__



.. _zero.p:
zero
---------------------------------------------------------

    .. code:: nim

        proc zero*(): Decimal128 =

    source line: `185 <../src/decimal128.nim#L185>`__

    Create a Decimal128 value of positive zero







Table Of Contents
=================

1. `Introduction to decimal128 <https://github.com/JohnAD/decimal128>`__
2. Appendices

    A. `decimal128 Reference <decimal128-ref.rst>`__
