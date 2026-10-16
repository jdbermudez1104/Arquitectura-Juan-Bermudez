# Definición de variables
CXX = g++
CXXFLAGS = -O2 -std=c++17 -Wall -Wextra
TARGET = comparacion
SRC = comparacion_Cache.cpp

# Regla principal (por defecto)
all: $(TARGET)

# Regla para compilar el ejecutable
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET)

# Regla para limpiar los archivos compilados
clean:
	rm -f $(TARGET)

# Declaración de pseudoreglas
.PHONY: all clean
