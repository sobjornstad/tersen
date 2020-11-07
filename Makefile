.PHONY: all test

TESTS = $(wildcard test/test_*.lua)

all: test luarocks

test: $(TESTS)
	busted -v $^

luarocks:
	-luarocks --local remove tersen
	luarocks --local make