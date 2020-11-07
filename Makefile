.PHONY: all test

TESTS = $(wildcard test/test_*.lua)

all: test

test: $(TESTS)
	busted -v $^
