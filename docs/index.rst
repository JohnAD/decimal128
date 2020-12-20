Introduction to decimal128
==============================================================================
ver 0.1.2

This library creates a data type called ``Decimal128`` that allows one to
store and manipulate decimal numbers.

By storing a number as decimal digits you can avoid the ambiguity and rounding
errors encountered when converting values back-and-forth from binary floating
point numbers (base 2) and the decimal notation typically used by humans (base 10).

This is especially useful for applications that are not tolerant of such
rounding errors such as accounting, banking, and finance.

STANDARD USED
-------------

The specification specifically conforms to the IEEE 754-2008 standard that
is formally available at https://standards.ieee.org/standard/754-2008.html

A more informal copy of that spec can be seen at
http://speleotrove.com/decimal/decbits.html , though that spec only shows
the Densely Packed Binary (DPD) version of storing the coefficient. This library
supports both DPD and the unsigned binary integer storage (BID) method when
for serializing and unserializing from binary images.

The BID method is used by BSON and MongoDB.

EXAMPLES OF USE
--------------

.. code:: nim

    import decimal128

    let a = newDecimal128("4003.250")

    assert a.getPrecision == 7
    assert a.getScale == 3
    assert a.toFloat == 4003.25
    assert a.toInt == 4003
    assert $a == "4003.250"

    assert a === newDecimal128("4003250E-3")
    assert a === newDecimal128("4.003250E+3")

    # interpret a segment of data from a BSON file:
    let b = decodeDecimal128("2FF83CD7450BE3F39FA2D32880000000", encoding=ceBID)

    assert $b == "0.001234000000000000000000000000000000"
    assert b.getPrecision == 34
    assert b.getScale == 36
    assert b.toFloat == 0.001234

    assert $(newDecimal128("423.77") + newDecimal128("20.9362")) == "444.71"



Table Of Contents
=================

1. `Introduction to decimal128 <https://github.com/JohnAD/decimal128>`__
2. Appendices

    A. `decimal128 Reference <decimal128-ref.rst>`__
