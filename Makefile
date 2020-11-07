.PHONY: all test

all: test

test:
	busted -v test/test_util.lua
