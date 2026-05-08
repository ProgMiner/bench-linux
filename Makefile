IMAGE_NAME=bench-linux
OUTPUT_DIR=./output

.PHONY: all build extract clean

all: extract

build:
	docker build --progress=plain -t $(IMAGE_NAME) .

extract: build
	@mkdir -p $(OUTPUT_DIR)
	@container=$$(docker create $(IMAGE_NAME)); \
	docker cp $$container:/iso/. $(OUTPUT_DIR); \
	docker rm $$container > /dev/null
	@echo "ISO files extracted to $(OUTPUT_DIR)/"

clean:
	rm -rf $(OUTPUT_DIR)
	-docker rmi $(IMAGE_NAME)
