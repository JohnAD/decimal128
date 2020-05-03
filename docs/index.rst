Introduction to decimal128
==============================================================================
ver 0.1.0

This library creates a data type called Decimal128 that allows one to do
store and manipulated decimal numbers.

By storing number as decimal digits you can avoid the ambiguity and rounding
errors encountered when converting values back-and-forth from binary floating
point numbers such as the 64-bit floats used by Nim.

This is especially useful for applications that are not tolerant of such
rounding errors such as accounting, banking, and finance.

STANDARD
--------

The specification specifically conforms to the IEEE 754-2008 standard that
is formally available at https://standards.ieee.org/standard/754-2008.html

A more informal copy of that spec can be seen at
http://speleotrove.com/decimal/decbits.html , though that spec only shows
the Densely Packed Binary (DPD) version of storing the coefficient. This library
supports both DPD and the unsigned binary integer storage (BID) method when
for serializing and unserializing from binary images.

The BID method is used by BSON and MongoDB.




Table Of Contents
=================

1. `Introduction to decimal128 <https://github.com/JohnAD/decimal128>`__
2. Appendices

    A. `decimal128 Reference <decimal128-ref.rst>`__
