SIM            ?= nvc
TOPLEVEL_LANG  ?= vhdl
ARCH           := rtl

SIM_ARGS += --wave=waves.ghw

PROJ_DIR := $(PWD)
SRC_DIR  := $(PROJ_DIR)/source
TB_DIR   := $(PROJ_DIR)/python_testbench

VHDL_SOURCES += \
  $(SRC_DIR)/montgomery_pkg.vhd \
  $(SRC_DIR)/instruction_pkg.vhd \
  $(SRC_DIR)/alpha.vhd \
  $(SRC_DIR)/alpha_final.vhd \
  $(SRC_DIR)/gamma.vhd \
  $(SRC_DIR)/gamma_final.vhd \
  $(SRC_DIR)/beta.vhd \
  $(SRC_DIR)/montgomery_monpro_cios_systolic_array.vhd

COCOTB_TOPLEVEL      := montgomery_monpro_cios_systolic_array
COCOTB_TEST_MODULES  := montgomery_monpro_systolic_array_tb

export PYTHONPATH := $(TB_DIR):$(PYTHONPATH)

# (Optional) print what we’re passing to cocotb for sanity
$(info COCOTB_TEST_MODULES=$(COCOTB_TEST_MODULES))
$(info PYTHONPATH=$(PYTHONPATH))

include $(shell cocotb-config --makefiles)/Makefile.sim
