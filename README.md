# zigscene

Audio visualization experiment using zig and raylib.

Built against `0.14.0-dev.2605+136c5a916`

## Getting Started

> [!NOTE]
> This project uses the nightly master build for zig, which frequently introduces breaking changes to the language. While this allows us to use the latest features and
> improvements, it may:
>
> - Break unexpectedly when updating Zig versions
> - Contain code patterns that don't work in stable Zig releases
> - Require periodic updates to maintain compatibility
>
>   To build this project, you'll need to use Zig's master branch. You can download the latest nightly build from <https://ziglang.org/download/>.
>
>   I also recommend using [zigup][1] or [zvm][2] to install and manage zig versions.

You should have:

- This repository:

  ```bash
  git clone https://github.com/ngynkvn/zigscene
  cd zigscene
  ```

- `zig` available in PATH.
  - Ensure `zig version` outputs `0.14.0-dev.2605+136c5a916`

```bash
# Build the project
zig build

# Build and run
zig build run

# Build with release optimization
zig build -Doptimize=ReleaseFast

# Run tests
zig build test
```

## Developer Tools

This project uses [just](https://github.com/casey/just) as well.

## Usage

`zig build run`, then drag and drop an audio file onto the window. Simple hotkeys are available: **TODO**

## Screenshots

<div style="display: flex; flex-wrap: wrap; gap: 10px;">
    <img src="https://github.com/user-attachments/assets/c87094ec-866d-4cd1-ad56-1fe32f4a6de0" alt="example" style="width: 40%;"/>
    <img src="https://github.com/user-attachments/assets/c61581d6-0686-4786-9f4f-2cdd4cfb98dc" alt="example" style="width: 47%;"/>
    <img src="https://github.com/user-attachments/assets/125bb810-4936-4b71-9610-727efa382211" alt="example" style="width: 40%;"/>
    <img src="https://github.com/user-attachments/assets/4e427ed1-1396-4c51-a5fe-27ca09f74000" alt="example" style="width: 46%;"/>
</div>

[1]: https://github.com/marler8997/zigup?tab=readme-ov-file#how-to-install
[2]: https://github.com/tristanisham/zvm?tab=readme-ov-file#installing-zvm
