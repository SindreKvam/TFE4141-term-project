import sys
import argparse
import math
from dataclasses import dataclass

import logging

logger = logging.getLogger(__name__)


@dataclass
class RsaKeyValues:
    n: int
    n_0_prime: int
    word_size: int
    r: int
    r_inv: int
    r2_mod_n: int

    def __repr__(self):
        a = "-" * 50 + "\n"
        b = f"n: {hex(self.n)}\n"
        b += f"n': {hex(self.n_0_prime)}\n"
        b += f"word size: {self.word_size}\n"
        b += f"r: {hex(self.r)}\n"
        b += f"r⁻¹: {hex(self.r_inv)}\n"
        b += f"r² mod n: {hex(self.r2_mod_n)}\n"
        return a + b + a


def gcd_extended(a, b):
    """Method for calculating the extended euclidean algorithm"""
    # Base Case
    if a == 0:
        return b, 0, 1

    gcd, x1, y1 = gcd_extended(b % a, a)

    # Update x and y using results of recursive
    # call
    x = y1 - (b // a) * x1
    y = x1

    return gcd, x, y


def gcd_extended_ensure_positive_x(a, b):
    gcd, x, y = gcd_extended(a, b)

    if x < 0:
        x + b

    return gcd, x, y


def hex_to_int(x):
    """Converts a hexadecimal string to an integer."""
    return int(x, 0)


def main():
    """Run main CLI application"""

    parser = argparse.ArgumentParser()
    parser.add_argument("key-n", type=hex_to_int, help="N - key", metavar="key_n")
    # parser.add_argument(
    #     "key-e", type=hex_to_int, help="Encryption key", metavar="key_e"
    # )
    # parser.add_argument(
    #     "key-d", type=hex_to_int, help="Decryption key", metavar="key_d"
    # )
    # parser.add_argument(
    #     "-f", "--key-file", type=str, help=".yaml file containing key values"
    # )
    parser.add_argument("-w", "--word-size", default=256, type=int)
    parser.add_argument("-s", "--limb-size", default=1, type=int)
    args = parser.parse_args()

    key_values = get_rsa_key_values(
        getattr(args, "key-n"), args.word_size, args.limb_size
    )
    print(key_values)

    return 0


def get_rsa_key_values(n, word_size: int, limb_size: int = 1) -> RsaKeyValues:
    """Get RSA key values that can be pre-calculated"""

    k = word_size * limb_size

    # R = 2^k
    r = 1 << k

    # Ensure gcd(r,n) = 1
    assert n % 2 != 0
    assert math.gcd(r, n) == 1

    gcd, x, r_inv = gcd_extended_ensure_positive_x(n, r)
    n_0_prime = r - x

    assert (n * n_0_prime + 1) % r == 0

    r2_mod_n = (r * r) % n

    key_values = RsaKeyValues(
        n=n,
        n_0_prime=n_0_prime,
        word_size=word_size,
        r=r,
        r_inv=r_inv,
        r2_mod_n=r2_mod_n,
    )

    return key_values


if __name__ == "__main__":
    sys.exit(main())
