"""
This module contains code to generate the instruction set to be used for controlling Muxes in the
systolic array implementation of montgomery monpro CIOS.
"""

import sys
from enum import IntEnum
from dataclasses import dataclass

PACKAGE_NAME = "instruction_pkg"

# Expected number of clock cycles to perform the entire algorithm
NUM_CLOCK_CYCLES = 33


@dataclass
class Instruction:
    instruction: int = 0
    word_size: int = 2

    def __repr__(self):
        return bin(self.instruction)[2:].zfill(self.word_size)


@dataclass
class InstructionWord:
    instruction_word: list[Instruction]

    def __repr__(self):
        return "".join(str(x) for x in self.instruction_word)


class InstructionSet:
    instruction_set: list[InstructionWord] = []

    def __iter__(self):
        return iter(self.instruction_set)

    def __getitem__(self, key):
        return self.instruction_set[key]


@dataclass
class AlphaMux:
    carry_instruction: int
    sum_instruction: int
    carry_input: Instruction = None
    sum_input: Instruction = None

    def __post_init__(self):
        self.carry_input: Instruction = Instruction(
            instruction=self.carry_instruction, word_size=1
        )
        self.sum_input: Instruction = Instruction(
            instruction=self.sum_instruction, word_size=2
        )

    def __repr__(self):
        return f"{self.sum_input}{self.carry_input}"


@dataclass
class AlphaFinalMux:
    sum_instruction: int
    sum_input: Instruction = None

    def __post_init__(self):
        self.sum_input: Instruction = Instruction(
            instruction=self.sum_instruction, word_size=1
        )

    def __repr__(self):
        return f"{self.sum_input}"


@dataclass
class AlphaAMux:
    a: int
    a_input: int = None

    def __post_init__(self):
        self.a_input: Instruction = Instruction(instruction=self.a, word_size=2)

    def __repr__(self):
        return f"{self.a_input}"


class Alpha1Carry(IntEnum):
    zero = 0
    alpha_1 = 1


class Alpha1Sum(IntEnum):
    zero = 0
    gamma_1 = 1
    gamma_2 = 2


class Alpha2Carry(IntEnum):
    alpha_1 = 0
    alpha_2 = 1


class Alpha2Sum(IntEnum):
    zero = 0
    gamma_2 = 1
    gamma_3 = 2


class Alpha3Carry(IntEnum):
    alpha_2 = 0
    alpha_3 = 1


class Alpha3Sum(IntEnum):
    zero = 0
    gamma_3 = 1
    gamma_final = 2


class AlphaFinalSum(IntEnum):
    zero = 0
    gamma_final = 1


# Gamma
@dataclass
class GammaMux:
    carry_instruction: int
    sum_instruction: int
    carry_input: Instruction = None
    sum_input: Instruction = None

    def __post_init__(self):
        self.carry_input: Instruction = Instruction(
            instruction=self.carry_instruction, word_size=1
        )
        self.sum_input: Instruction = Instruction(
            instruction=self.sum_instruction, word_size=1
        )

    def __repr__(self):
        return f"{self.sum_input}{self.carry_input}"


@dataclass
class Gamma2Sum(IntEnum):
    alpha_1 = 0
    alpha_2 = 1


@dataclass
class Gamma2Carry(IntEnum):
    gamma_1 = 0
    gamma_2 = 1


@dataclass
class Gamma3Sum(IntEnum):
    alpha_2 = 0
    alpha_3 = 1


@dataclass
class Gamma3Carry(IntEnum):
    gamma_2 = 0
    gamma_3 = 1


def main():
    instruction_set = InstructionSet()

    for clock_cycle in range(NUM_CLOCK_CYCLES):
        a_input = clock_cycle % 3

        # Alpha modules
        if clock_cycle % 3 == 0:
            # The start of each "block"
            alpha_1_sum_instruction = Alpha1Sum.gamma_1
            alpha_1_carry_instruction = Alpha1Carry.zero

            alpha_2_sum_instruction = Alpha2Sum.gamma_2
            alpha_2_carry_instruction = Alpha2Carry.alpha_1

            alpha_3_sum_instruction = Alpha3Sum.gamma_3
            alpha_3_carry_instruction = Alpha3Carry.alpha_2

        else:
            alpha_1_sum_instruction = Alpha1Sum.gamma_2
            alpha_1_carry_instruction = Alpha1Carry.alpha_1

            alpha_2_sum_instruction = Alpha2Sum.gamma_3
            alpha_2_carry_instruction = Alpha2Carry.alpha_2

            alpha_3_sum_instruction = Alpha3Sum.gamma_final
            alpha_3_carry_instruction = Alpha3Carry.alpha_3

        # For the first 3 clock cycles for each module, the sum is zero
        if clock_cycle <= 2:
            alpha_1_sum_instruction = Alpha1Sum.zero
        if clock_cycle <= 5:
            alpha_2_sum_instruction = Alpha2Sum.zero
        if clock_cycle <= 7:
            alpha_3_sum_instruction = Alpha3Sum.zero
        if clock_cycle <= 8:
            alpha_final_sum = AlphaFinalSum.zero
        else:
            alpha_final_sum = AlphaFinalSum.gamma_final

        alpha_1 = AlphaMux(
            carry_instruction=alpha_1_carry_instruction,
            sum_instruction=alpha_1_sum_instruction,
        )

        alpha_2 = AlphaMux(
            carry_instruction=alpha_2_carry_instruction,
            sum_instruction=alpha_2_sum_instruction,
        )

        alpha_3 = AlphaMux(
            carry_instruction=alpha_3_carry_instruction,
            sum_instruction=alpha_3_sum_instruction,
        )

        alpha_final = AlphaFinalMux(sum_instruction=alpha_final_sum)

        # Gamma modules

        if clock_cycle % 3 == 0:
            gamma_2_sum_instruction = Gamma2Sum.alpha_1
            gamma_2_carry_instruction = Gamma2Carry.gamma_1

            gamma_3_sum_instruction = Gamma3Sum.alpha_2
            gamma_3_carry_instruction = Gamma3Carry.gamma_2
        else:
            gamma_2_sum_instruction = Gamma2Sum.alpha_2
            gamma_2_carry_instruction = Gamma2Carry.gamma_2

            gamma_3_sum_instruction = Gamma3Sum.alpha_3
            gamma_3_carry_instruction = Gamma3Carry.gamma_3

        gamma_2 = GammaMux(
            carry_instruction=gamma_2_carry_instruction,
            sum_instruction=gamma_2_sum_instruction,
        )

        gamma_3 = GammaMux(
            carry_instruction=gamma_3_carry_instruction,
            sum_instruction=gamma_3_sum_instruction,
        )

        alpha_a = AlphaAMux(a=a_input)

        instruction_word = InstructionWord(
            instruction_word=[
                alpha_a,
                gamma_3,
                gamma_2,
                alpha_final,
                alpha_3,
                alpha_2,
                alpha_1,
            ]
        )

        instruction_set.instruction_set.append(instruction_word)

    package_file_content_prefix = f"""-- This file has been generated using a python script,
-- please do not make any modifications to this file directly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package {PACKAGE_NAME} is

    constant C_NUMBER_OF_INSTRUCTIONS : integer := {NUM_CLOCK_CYCLES};
    constant C_INSTRUCTION_LENGTH : integer := {len(str(instruction_word))};

    type T_INSTRUCTION_SET is array(0 to C_NUMBER_OF_INSTRUCTIONS - 1) of std_logic_vector(C_INSTRUCTION_LENGTH - 1 downto 0);

    constant C_INSTRUCTION_SET : T_INSTRUCTION_SET := (\n"""

    package_file_content_suffix = f"""
    );

end package {PACKAGE_NAME};

package body {PACKAGE_NAME} is
end package body {PACKAGE_NAME};
"""

    with open(PACKAGE_NAME + ".vhd", "w") as file:
        file.write(package_file_content_prefix)

        for instruction in instruction_set[:-1]:
            file.write(f'        b"{instruction}",\n')
        file.write(f'        b"{instruction_set[-1]}"')

        file.write(package_file_content_suffix)


if __name__ == "__main__":
    sys.exit(main())
