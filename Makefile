docker/build:
	docker build -t code-server-oss:latest .

docker/build/test:
	docker build -t code-server-oss:test . --progress=plain

vscode:
	git clone --progress --filter=tree:0 https://github.com/microsoft/vscode.git --branch=main ./vscode

code-server/build: code-server/deps-install code-server/src-patch build/steps/build

code-server/deps-install: export PATH := $(shell pwd)/bin:$(PATH)
code-server/deps-install: vscode
	cd vscode && code-server-deps-install

code-server/src-patch: export PATH := $(shell pwd)/bin:$(PATH)
code-server/src-patch: vscode
	cd vscode && code-server-src-patch

code-server/compile: export PATH := $(shell pwd)/bin:$(PATH)
code-server/compile: vscode
	cd vscode && code-server-compile

clean:
	rm -rf vscode
