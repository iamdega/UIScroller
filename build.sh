#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Comment out THEOS_PACKAGE_SCHEME in Makefile before building
sed -i 's/^THEOS_PACKAGE_SCHEME/#THEOS_PACKAGE_SCHEME/' Makefile

echo -e "${GREEN}Building rootful (arm) package...${NC}"
make clean package

echo -e "\n${GREEN}Building rootless (arm64) package...${NC}"
THEOS_PACKAGE_SCHEME=rootless make clean package

echo -e "\n${GREEN}Building roothide (arm64e) package...${NC}"
THEOS_PACKAGE_SCHEME=roothide make clean package

# Restore THEOS_PACKAGE_SCHEME in Makefile
sed -i 's/^#THEOS_PACKAGE_SCHEME/THEOS_PACKAGE_SCHEME/' Makefile

echo -e "\n${GREEN}All packages built successfully!${NC}"

