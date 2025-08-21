#define RAYGUI_IMPLEMENTATION
#include "raygui.h"
void RayguiLoadStyle(const unsigned char *fileData, int dataSize) {
  GuiLoadStyleFromMemory(fileData, dataSize);
};
int RayguiGetTextWidth(const char *text) { return GetTextWidth(text); }
