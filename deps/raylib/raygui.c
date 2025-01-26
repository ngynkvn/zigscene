#define RAYGUI_IMPLEMENTATION
#include "raygui.h"
#include "style_dark.h"
void RayguiDark(void){ GuiLoadStyleDark(); };
int Get_TextWidth(const char *text){ return GetTextWidth(text); }