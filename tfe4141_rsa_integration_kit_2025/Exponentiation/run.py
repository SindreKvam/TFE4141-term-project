"""Run all testbenches related to the found in the exponential modules"""

from pathlib import Path

from vunit import VUnit

root_folder = Path(__file__).resolve().parent
source_folder = root_folder / "source"
testbench_folder = root_folder / "testbench"

vu = VUnit.from_argv()

vu.add_vhdl_builtins()

# create design library
lib = vu.add_library("lib")

lib.add_source_files([source_folder / "*.vhd"])
lib.add_source_files([source_folder / "processing_elements/*.vhd"])
lib.add_source_files([testbench_folder / "*.vhd"])

vu.set_sim_option("modelsim.init_files.after_load", [str(testbench_folder / "wave.do")])


vu.main()
