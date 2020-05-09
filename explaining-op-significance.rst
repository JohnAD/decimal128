Impact of Arithmetic Operations on Significance
===============================================

> An arithmetic operation on two decimal values can create a new decimal value with a significance varied from the original values. It can lose significance from bounds of least significance and can gain significance from the amplification of the most significant digits. Details depend on the operation.

I realize that is quite mouthful, so let's instead show all this using examples:


.. code:: math

        12.34  (sig 4)
    +   12.34  (sig 4)
        ----- 
        24.68  (sig 4)


No surprises here. For most of the examples I will be noting how many significant digits are in the number.

.. code:: math

        12.34  (sig 4)
    + 1200.30  (sig 6)
    ---------
      1212.64  (sig 6)


Also not surprising, but it demonstrates one of the characteristics of significance: significance can "grow" when it is from point of view of the most-significant digits. In other words, it can "grow" on the left but not on the right. Here is a more concrete example of that.

.. code:: math

        12.34  (sig 4)
    +   82.34  (sig 4)
        ----- 
       104.68  (sig 5)


Think of "significance" as a way of stating what is "not known" about smaller measures. So,

.. code:: math

    12.34


can also be thought of as:

.. code:: math

    ...00000012.34??????...


We are confident that there are no "missing" digits before 12; but we are *not* confident we didn't fail to measure better after the 34. That is also why leading zeroes are ignored:

.. code:: math

    00012.34 (sig 4)


is the same as

.. code:: math

    12.34    (sig 4)


because digits to the left are always assumed to be perfectly measured. But,

.. code:: math

    12.3     (sig 3)


is different than:

.. code:: math

    12.30    (sig 4)


From a scalar point of view, they have the same value. But for 12.3 we are unsure of the digit after the 3. But for 12.30 we KNOW the digit after the three. It is zero.

That is why:


.. code:: math

        12.34  (sig 4)
    + 1200.3   (sig 5)
    ---------
      1212.6   (sig 5)


And:

.. code:: math

        99.9  (sig 3)
    +   88.6  (sig 3)
    --------
       188.5  (sig 4)


This answer had more significance than both the original values because it gained a digit on the left, where we have absolute confidence.

Another example:

.. code:: math

        99.9999  (sig 6)
        88.6     (sig 3)
    -----------
       188.5999  [interim]
       188.6     (sig 4)


Notice in this last example, I demonstrated rounding. 188.5999 is *not* the answer, but the interim value was used to handle the final rounding to the correct level of significance.

[SIDEBAR: the Decimal128 library uses an algorithm known as "banker's rounding". If the digit(s) to remove start with 0 to 4, it is rounded down. It it starts with 6 to 9, it is rounded up. If it is 5, but the next more significant digit is even, it is rounded down; otherwise it is rounded up. This method generally removes many forms of bias over large number of calculations.]

If two numbers are far apart enough in scale but with limited significance, the addition can, in fact, have no real impact. For example:

.. code:: math

         1.0     (sig 2)
    +    0.005   (sig 1)
    ----------
         1.0     (sig 2)


This is not always intuitive, but it makes philisophical sense. If we only have measured 1.0 to a single decimal place, then the digits after 1.0 are not known. Adding a known value to an unknown value does not somehow make the value known. 

[SIDEBAR: Database programmers are familiar with this because of the NULL concept. NULL means "unknown" not "empty" or zero in the world of SQL database records (rows). So, 3 + NULL = NULL. Again, adding a known value to a unknown value does not create a known value.]

If one did know the value to 3 decimal places, then the math problem would have been:

.. code:: math

         1.000   (sig 4)
    +    0.005   (sig 1)
    ----------
         1.005   (sig 4)


And now, a note for those doing financial programming using a decimal library: You will want to consistently fill out the known values to the
correct decimal place. If someone gives me one U.S. dollar, then storing:

.. code:: math

    1       (sig 1)


means I received a dollar and an UNKNOWN amount of change. If really received exactly one dollar, I should store:

.. code:: math

    1.00    (sig 3)


Otherwise very non-intuitive errors will show up. For example, if I then received 25 cents, then:

.. code:: math

         1       (sig 1)
    +    0.25    (sig 2)
         ----
         1       (sig 1)


is probably not the answer you really wanted. You _probably_ wanted:

.. code:: math

         1.00    (sig 3)
    +    0.25    (sig 2)
         ----
         1.25    (sig 3)


On the other hand, if I'm calculating a royalty with a rate of 0.0223843 against the 16,000 USD of revenue of given quarterly report; where the numbers are estimated to the nearest 100 USD, then you *don't* want to do this:

.. code:: math

       16000.00    (sig 7)
    *  0.0223843   (sig 6)
       ---------
       358.1488    [interim]
       358.149     (sig 6)


or even this:

.. code:: math

       16000       (sig 5)
    *  0.0223843   (sig 6)
       ---------
       358.15      (sig 5)


Instead you want to mark the lower two digits of 16,000 as "unknown" using scientific notation, such as 160E2 or 1.60E4. So that you get:

.. code:: math

       1.60E4      (sig 3)
    *  0.0223843   (sig 6)
       ------
       358         (sig 3)

Here the resulting answer is more correct in the sense that it matches the revenue's general estimation limit.

Addition
--------

TBD


Subtraction
-----------

TBD


Multiplication
--------------

TBD


Division
--------

TBD

