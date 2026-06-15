APP_NAME = triangle
SRC = main.m
FRAMEWORKS = -framework Cocoa -framework Metal -framework MetalKit

all: $(APP_NAME)

$(APP_NAME): $(SRC)
	clang $(SRC) -o $(APP_NAME) $(FRAMEWORKS) -fobjc-arc

clean:
	rm -f $(APP_NAME)
