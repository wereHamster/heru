
TESTS=$(shell find test/unit -type f -name '*.coffee')

all: $(TESTS)
	@expresso -I src -I vendor -I test/library $(TESTS)

