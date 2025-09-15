"""This module contains code to simulate a RSA cryptosystem."""

import math
import logging
import argparse
from datetime import datetime


def eulers_totient_function(a: int, b: int):
    """Calculate the eulers totient function from two integers"""
    return (a - 1) * (b - 1)


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


def chunk_bytearray(data, n):
    for i in range(0, len(data), n):
        yield data[i : i + n]


def rsa_calculation(X: int, e: int, n: int):
    """Encrypt/Decrypt using RSA methodology"""
    return (X**e) % n


def encrypt_from_bytearray(
    message: bytearray,
    e: int,
    n: int,
    *,
    endianness: str = "little",
    chunk_size=None,
    method=rsa_calculation,
):
    """Use RSA to encrypt a message"""

    if chunk_size is None:
        chunk_size = int(math.ceil(math.log2(n)))

    logging.debug(f"Encrypting message: {message}")

    secret_message = b""
    for b in message:
        raw_crypt = method(b, e, n)
        secret_message += raw_crypt.to_bytes(chunk_size, byteorder=endianness)

    return secret_message


def decrypt_from_bytearray(
    message: bytearray,
    d: int,
    n: int,
    *,
    endianness: str = "little",
    chunk_size=None,
    method=rsa_calculation,
):
    """Use RSA to decrypt a message"""

    if chunk_size is None:
        chunk_size = int(math.ceil(math.log2(n)))

    logging.debug(f"Decrypting message: {message}")

    recovered_message = b""
    for chunk in chunk_bytearray(message, chunk_size):
        b = int.from_bytes(chunk, byteorder=endianness)
        raw_crypt = method(b, d, n)
        recovered_message += raw_crypt.to_bytes(1, byteorder=endianness)

    return recovered_message


def calculate_rsa_keypair(p, q):
    """Find a valid e and q that can be used as keypairs"""
    n = p * q

    # Find a suitable exponent
    for e in range(eulers_totient_function(p, q), 3, -1):
        gcd = math.gcd(eulers_totient_function(p, q), e)

        if gcd == 1:
            break
    else:
        raise ValueError("No valid exponent found")

    # Calculate d the modular multiplicative inverse of e modulo Phi(n).
    # The extended euclidian algorithm is a fast way of finding this.
    gcd, d, _ = gcd_extended(e, eulers_totient_function(p, q))

    # if d is negative, add Phi(n) to get a positive value
    if d < 0:
        d += eulers_totient_function(p, q)

    return n, e, d


def main(p, q, num_bits, message, calculation_method):
    """Run main procedure"""

    n, e, d = calculate_rsa_keypair(p, q)

    # Print the relevant values calculated
    print(f"p: {p}", f"q: {q}", f"n: {n}", f"e: {e}", f"d: {d}")

    logging.info(f"Original message: {message}")

    start_time = datetime.now()
    secret_message = encrypt_from_bytearray(
        message, e, n, chunk_size=num_bits, method=calculation_method
    )
    recovered_message = decrypt_from_bytearray(
        secret_message, d, n, chunk_size=num_bits, method=calculation_method
    )
    stop_time = datetime.now()
    assert message == recovered_message

    logging.debug(f"Secret message {secret_message}")
    logging.info(f"Decrypted message: {recovered_message}")

    print(f"Time used: {stop_time - start_time}")


# Run
if __name__ == "__main__":
    """Handle arguments and run main method"""

    parser = argparse.ArgumentParser()
    parser.add_argument("-q", type=int, default=53)
    parser.add_argument("-p", type=int, default=61)
    parser.add_argument(
        "-m",
        "--message",
        type=str,
        action="store",
        help="The message to be encrypted and decrypted",
        default="Hey, how are you doing this lovely evening?",
    )
    parser.add_argument("-k", "--num-bits", type=int, default=256)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(
        args.p,
        args.q,
        args.num_bits,
        bytes(args.message, encoding="ASCII"),
        rsa_calculation,
    )
