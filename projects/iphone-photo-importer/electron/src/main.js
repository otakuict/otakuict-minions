const path = require("node:path");
const { spawn } = require("node:child_process");
const { app, BrowserWindow, dialog, ipcMain } = require("electron");

function createWindow() {
  const window = new BrowserWindow({
    width: 1240,
    height: 860,
    minWidth: 980,
    minHeight: 700,
    backgroundColor: "#efe7db",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  window.loadFile(path.join(__dirname, "renderer", "index.html"));
}

function getProjectRoot() {
  return path.resolve(__dirname, "..", "..");
}

function getPythonDir() {
  return path.join(getProjectRoot(), "python");
}

function getDefaultStateDb(libraryPath) {
  return path.join(libraryPath, ".state", "imports.sqlite3");
}

function buildHelperArgs(command, payload = {}) {
  if (command === "usb-devices") {
    return ["-m", "iphone_photo_importer.cli", "usb-devices", "--json"];
  }

  return [
    "-m",
    "iphone_photo_importer.cli",
    command,
    "--source",
    payload.source,
    "--library",
    payload.library,
    "--source-kind",
    payload.sourceKind,
    "--state-db",
    payload.stateDb || getDefaultStateDb(payload.library),
    "--json",
  ];
}

function runHelper(command, payload) {
  return new Promise((resolve, reject) => {
    const pythonDir = getPythonDir();
    const args = buildHelperArgs(command, payload);

    const child = spawn("python", args, {
      cwd: pythonDir,
      windowsHide: true,
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (error) => {
      reject(error);
    });

    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(stderr || stdout || `Python helper exited with code ${code}.`));
        return;
      }

      try {
        resolve(JSON.parse(stdout));
      } catch (error) {
        reject(new Error(`Could not parse helper output: ${error.message}\n\n${stdout}`));
      }
    });
  });
}

ipcMain.handle("dialog:pick-directory", async () => {
  const result = await dialog.showOpenDialog({
    properties: ["openDirectory", "createDirectory"],
  });

  if (result.canceled || result.filePaths.length === 0) {
    return null;
  }

  return result.filePaths[0];
});

ipcMain.handle("app:get-defaults", () => {
  const picturesDir = app.getPath("pictures");
  const library = path.join(picturesDir, "iPhone Archive");
  return {
    sourceKind: "usb",
    source: path.join(picturesDir, "iCloud Photos"),
    library,
    stateDb: getDefaultStateDb(library),
  };
});

ipcMain.handle("helper:plan", async (_event, payload) => {
  return runHelper("plan", payload);
});

ipcMain.handle("helper:import", async (_event, payload) => {
  return runHelper("import", payload);
});

ipcMain.handle("helper:usb-devices", async () => {
  return runHelper("usb-devices");
});

app.whenReady().then(() => {
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
