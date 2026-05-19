const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("desktopBridge", {
  pickDirectory: () => ipcRenderer.invoke("dialog:pick-directory"),
  getDefaults: () => ipcRenderer.invoke("app:get-defaults"),
  listUsbDevices: () => ipcRenderer.invoke("helper:usb-devices"),
  planImport: (payload) => ipcRenderer.invoke("helper:plan", payload),
  runImport: (payload) => ipcRenderer.invoke("helper:import", payload),
});
