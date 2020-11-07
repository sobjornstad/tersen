require 'busted.runner'
local util = require '../tersen/util'


describe("is_nil_or_whitespace", function()
    it("returns true if its argument is nil", function()
        assert.is_true(util.is_nil_or_whitespace(nil))
    end)

    it("returns true if its argument is the empty string", function()
        assert.is_true(util.is_nil_or_whitespace(""))
    end)

    it("returns true if its argument consists only of whitespace", function()
        assert.is_true(util.is_nil_or_whitespace(" \t  \n "))
    end)

    it("returns false if its argument is not all whitespace", function()
        assert.is_false(util.is_nil_or_whitespace(" test"))
    end)
end)


describe("nil_to_empty", function()
    it("changes a nil value to the empty string", function()
        assert.is_equal(util.nil_to_empty(nil), "")
    end)

    it("does nothing to the empty string", function()
        assert.is_equal(util.nil_to_empty(""), "")
    end)

    it("does nothing to a non-empty string", function()
        assert.is_equal(util.nil_to_empty("Flopwobbles "), "Flopwobbles ")
    end)
end)


describe("trim", function()
    it("trims trailing spaces", function()
        assert.is_equal(util.trim("soren  "), "soren")
    end)

    it("trims leading spaces", function()
        assert.is_equal(util.trim("  soren"), "soren")
    end)

    it("trims leading and trailing tabs", function()
        assert.is_equal(util.trim("\tsoren\t\t"), "soren")
    end)
end)


describe("split_whitespace", function()
    local hello_expectation = {"Hello", "world"}
    it("should split a string on spaces", function()
        assert.are.same(util.split_whitespace("Hello world"), hello_expectation)
    end)

    it("should split a string on tabs", function()
        assert.are.same(util.split_whitespace("Hello\tworld"), hello_expectation)
    end)

    it("should split a string on newlines", function()
        assert.are.same(util.split_whitespace("Hello\nworld"), hello_expectation)
    end)

    it("should split a string on multiple adjacent whitespaces", function()
        assert.are.same(util.split_whitespace("Hello   \n \t world"), hello_expectation)
    end)

    it("should ignore leading and trailing whitespace", function()
        assert.are.same(util.split_whitespace("   Hello world\t"), hello_expectation)
    end)
end)


describe("split_paragraphs", function()
    it("should divide a string into paragraphs", function()
        local s = [[
Here is the first paragraph.

And here is a second paragraph,
which may go onto several lines.]]
        assert.are.same(util.split_paragraphs(s), {
            "Here is the first paragraph.",
            "And here is a second paragraph,\n"
            .. "which may go onto several lines."})
    end)
end)


describe("shallow_copy", function()
    it("should alter table values when not shallow-copied", function()
        local original = {one = "two"}
        local copy = original
        original.one = "three"
        assert.is_equal(copy.one, "three") -- changed
    end)

    it("should differentiate table values one level deep", function()
        local original = {one = "two"}
        local copy = util.shallow_copy(original)
        original.one = "three"
        assert.is_equal(copy.one, "two") -- not changed
    end)

    it("should not copy an extra level deep, as it is not a deep copy", function()
        local original = {one = {two = "three"}}
        local copy = util.shallow_copy(original)
        original.one.two = "four"
        assert.is_equal(copy.one.two, "four") -- changed
    end)
end)


describe("set", function()
    local s = util.set({"one", "two", "four"})

    it("should find items in the set are not nil", function()
        assert.is_not_nil(s["one"])
    end)

    it("should find items not in the set are nil", function()
        assert.is_nil(s["eight"])
    end)
end)
