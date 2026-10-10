// The browser owns file selection; Zig adopts the finished virtual file next frame.
#include <emscripten.h>
#include <string.h>
static char picked_path[512];
EM_JS(void, zigscene_pick_audio, (void), {
    if (Module.zigscenePicker) return;
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.mp3,.wav,.ogg';
    input.style.display = 'none';
    Module.zigscenePicker = input;
    const cleanup = () => { input.remove(); Module.zigscenePicker = null; };
    input.addEventListener('cancel', cleanup, { once: true });
    input.addEventListener('change', async () => {
        try {
            const file = input.files[0];
            if (file) {
                const extension = file.name.split('.').pop().toLowerCase();
                if (!['mp3', 'wav', 'ogg'].includes(extension)) return;
                // Fixed slots bound memory while preserving the playing file until adoption.
                Module.zigscenePickerSlot = 1 - (Module.zigscenePickerSlot || 0);
                const directory = '/audio-picker-' + Module.zigscenePickerSlot;
                FS.mkdirTree(directory);
                const data = new Uint8Array(await file.arrayBuffer());
                const previous = Module.zigscenePickerPaths || (Module.zigscenePickerPaths = []);
                if (previous[Module.zigscenePickerSlot]) FS.unlink(previous[Module.zigscenePickerSlot]);
                // Keep the track's own name in the player, with a bounded UTF-8 path.
                const path = directory + '/' + file.name.replace(/[\\/]/g, '_').slice(-100);
                FS.writeFile(path, data);
                previous[Module.zigscenePickerSlot] = path;
                Module.zigscenePickedPath = path;
            }
        } catch (error) {
            console.warn('Could not read the chosen audio file', error);
        } finally { cleanup(); }
    }, { once: true });
    document.body.appendChild(input);
    input.click();
});
EM_JS(int, copy_picked_audio, (char *buffer, int capacity), {
    if (!Module.zigscenePickedPath) return 0;
    stringToUTF8(Module.zigscenePickedPath, buffer, capacity);
    Module.zigscenePickedPath = null;
    return 1;
});
const char *zigscene_picked_audio(void) {
    return copy_picked_audio(picked_path, sizeof(picked_path)) ? picked_path : 0;
}
