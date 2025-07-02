.PHONY: add-bin-to-zshrc

install:
	@BIN_PATH="$$(cd "$$(dirname "$$0")/bin" && pwd)"; \
	if ! grep -q "$$BIN_PATH" $$HOME/.zshrc; then \
		#echo '\n# Add cli-config bin to PATH' >> $$HOME/.zshrc; \
		#echo 'export PATH="$$BIN_PATH:$$PATH"' >> $$HOME/.zshrc; \
		echo "Added $$BIN_PATH to .zshrc"; \
	else \
		echo "$$BIN_PATH already in .zshrc"; \
	fi
