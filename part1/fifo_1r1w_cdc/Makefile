REPO_ROOT ?= $(shell git rev-parse --show-toplevel)

PCF_PATH = $(REPO_ROOT)/part1/fifo_1r1w_cdc/icebreaker.pcf
-include $(REPO_ROOT)/frag/simulate.mk
-include $(REPO_ROOT)/frag/synth.mk
-include $(REPO_ROOT)/frag/fpga.mk

