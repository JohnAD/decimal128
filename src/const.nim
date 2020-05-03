const
  BITS: int = 128
  EXPONENT_BITS: int = 12
  COEFFICIENT_BITS: int = 110
  COEFFICIENT_SIZE: int  = 34
  MAXIMUM_COEFFICIENT: string = "10_000_000_000_000_000_000_000_000_000_000_000"
  BIAS: int = 6176;


# pub trait DecimalProps: Copy {
#     // Total size (bits)
#     const BITS: usize;
#     // Exponent continuation field (bits)
#     const EXPONENT_BITS: usize;
#     // Coefficient continuation field (bits)
#     const COEFFICIENT_BITS: usize;
#     // Coefficient size (decimal digits)
#     const COEFFICIENT_SIZE: usize;
#     const MAXIMUM_COEFFICIENT: Self;
#     const BIAS: isize;
# }

# impl DecimalProps for u32 {
#     const BITS: usize = 32;
#     const EXPONENT_BITS: usize = 6;
#     const COEFFICIENT_BITS: usize = 20;
#     const COEFFICIENT_SIZE: usize = 7;
#     const MAXIMUM_COEFFICIENT: u32 = 10_000_000;
#     const BIAS: isize = 101;
# }

# impl DecimalProps for u64 {
#     const BITS: usize = 64;
#     const EXPONENT_BITS: usize = 8;
#     const COEFFICIENT_BITS: usize = 50;
#     const COEFFICIENT_SIZE: usize = 16;
#     const MAXIMUM_COEFFICIENT: u64 = 10_000_000_000_000_000;
#     const BIAS: isize = 398;
# }

# impl DecimalProps for u128 {
#     const BITS: usize = 128;
#     const EXPONENT_BITS: usize = 12;
#     const COEFFICIENT_BITS: usize = 110;
#     const COEFFICIENT_SIZE: usize = 34;
#     const MAXIMUM_COEFFICIENT: u128 = 10_000_000_000_000_000_000_000_000_000_000_000;
#     const BIAS: isize = 6176;
# }

# pub mod factors {
#     pub const u32: [u32; 7] = [1, 10, 100, 1000, 10000, 100000, 1000000];
#     pub const u64: [u64; 16] = [
#         1,
#         10,
#         100,
#         1000,
#         10000,
#         100000,
#         1000000,
#         10000000,
#         100000000,
#         1000000000,
#         10000000000,
#         100000000000,
#         1000000000000,
#         10000000000000,
#         100000000000000,
#         1000000000000000,
#     ];
#     pub const u128: [u128; 34] = [
#         1,
#         10,
#         100,
#         1000,
#         10000,
#         100000,
#         1000000,
#         10000000,
#         100000000,
#         1000000000,
#         10000000000,
#         100000000000,
#         1000000000000,
#         10000000000000,
#         100000000000000,
#         1000000000000000,
#         10000000000000000,
#         100000000000000000,
#         1000000000000000000,
#         10000000000000000000,
#         100000000000000000000,
#         1000000000000000000000,
#         10000000000000000000000,
#         100000000000000000000000,
#         1000000000000000000000000,
#         10000000000000000000000000,
#         100000000000000000000000000,
#         1000000000000000000000000000,
#         10000000000000000000000000000,
#         100000000000000000000000000000,
#         1000000000000000000000000000000,
#         10000000000000000000000000000000,
#         100000000000000000000000000000000,
#         1000000000000000000000000000000000,
#     ];
# }