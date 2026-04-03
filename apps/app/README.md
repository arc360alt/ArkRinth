# ![Modrinth App](/.github/assets/app_cover.png)

## Modrinth App

The Modrinth App is a desktop application for managing your Minecraft mods. It is built with [Tauri](https://tauri.app/) and [Vue](https://vuejs.org/).

If you're not a developer and you've stumbled upon this repository, you can download the latest release of the app from the [Modrinth website](https://modrinth.com/app).

## Development

### Pre-requisites

Before you begin, ensure you have the following installed on your machine:

- [Node.js](https://nodejs.org/en/)
- [pnpm](https://pnpm.io/)
- [Rust](https://www.rust-lang.org/tools/install)
- [Tauri](https://v2.tauri.app/start/prerequisites/)

On Fedora-based systems, install the WebKit and GTK development packages required by Tauri:

```bash
sudo dnf install atk-devel gtk3-devel javascriptcoregtk4.1-devel libsoup3-devel webkit2gtk4.1-devel
```

### Setup

Follow these steps to set up your development environment:

```bash
pnpm install
pnpm app:dev
```

You should now have a development build of the app running with hot-reloading enabled. Any changes you make to the code will automatically refresh the app.

The local app build will use `packages/app-lib/.env.prod` automatically unless you provide a `packages/app-lib/.env` override.

For local backend development, create `packages/app-lib/.env` from `packages/app-lib/.env.local`.

If you hit a Wayland protocol error in toolbox/containerized Linux environments, run the app package directly with an X11 fallback:

```bash
cd apps/app
npm run dev:x11
```
