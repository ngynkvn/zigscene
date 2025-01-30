#define RAYGUI_IMPLEMENTATION
#include "raygui.h"
#include "style_dark.h"
void RayguiDark(void) { GuiLoadStyleDark(); };
void RayguiLoadStyle(const unsigned char *fileData, int dataSize) {
  GuiLoadStyleFromMemory(fileData, dataSize);
};
int Get_TextWidth(const char *text) { return GetTextWidth(text); }
