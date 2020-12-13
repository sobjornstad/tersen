.PHONY: all docs test luarocks clean

TESTS = $(wildcard test/test_*.lua)
API_KEY != cat "$$HOME/.luarocks/apikey"

all: test luarocks

docs:
	make -C docs html

test: $(TESTS)
	busted -v $^

luarocks:
	-luarocks --local remove tersen
	luarocks --local make

publish: test luarocks
	@luarocks upload tersen-*.rockspec --api-key "$(API_KEY)"

clean:
	make -C docs clean
