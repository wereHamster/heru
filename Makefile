
TESTS=$(shell find test/unit -type f -name '*.coffee')

all: test

.PHONY: test
test: $(TESTS)
	@./node_modules/.bin/expresso -I src -I vendor -I test/library $(TESTS)

