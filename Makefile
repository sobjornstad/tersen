.PHONY: all docs test luarocks clean

TESTS = $(wildcard test/test_*.lua)

all: test luarocks

docs:
	make -C docs html

test: $(TESTS)
	busted -v $^

luarocks:
	-luarocks --local remove tersen
	luarocks --local make

clean:
	make -C docs clean
