const sourceKind = document.querySelector("#sourceKind");
const deviceField = document.querySelector("#deviceField");
const sourceField = document.querySelector("#sourceField");
const usbDevice = document.querySelector("#usbDevice");
const refreshUsb = document.querySelector("#refreshUsb");
const sourcePath = document.querySelector("#sourcePath");
const libraryPath = document.querySelector("#libraryPath");
const planButton = document.querySelector("#planButton");
const runButton = document.querySelector("#runButton");
const pickSource = document.querySelector("#pickSource");
const pickLibrary = document.querySelector("#pickLibrary");
const status = document.querySelector("#status");
const output = document.querySelector("#output");

function setStatus(message) {
  status.textContent = message;
}

function isUsbMode() {
  return sourceKind.value === "usb";
}

function getPayload() {
  return {
    sourceKind: sourceKind.value,
    source: isUsbMode() ? usbDevice.value : sourcePath.value.trim(),
    library: libraryPath.value.trim(),
  };
}

function renderResult(result) {
  output.textContent = JSON.stringify(result, null, 2);
}

async function pickInto(input) {
  const folder = await window.desktopBridge.pickDirectory();
  if (folder) {
    input.value = folder;
  }
}

function syncSourceModeUi() {
  const usbMode = isUsbMode();
  deviceField.hidden = !usbMode;
  sourceField.hidden = usbMode;
  pickSource.disabled = usbMode;
  sourcePath.disabled = usbMode;

  if (usbMode) {
    setStatus("USB mode selected. Connect, unlock, and trust the iPhone, then refresh devices.");
  }
}

function renderUsbDevices(result) {
  usbDevice.innerHTML = "";
  const devices = Array.isArray(result.devices) ? result.devices : [];
  const diagnostics = Array.isArray(result.diagnostics) ? result.diagnostics : [];

  if (devices.length === 0) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "No USB portable devices found";
    usbDevice.append(option);
    setStatus(diagnostics.join(" ") || "No USB devices found.");
    return;
  }

  devices.forEach((device) => {
    const option = document.createElement("option");
    option.value = device.id;
    option.textContent = `${device.name} (${device.type})`;
    usbDevice.append(option);
  });

  setStatus(`Found ${devices.length} USB device${devices.length === 1 ? "" : "s"}.`);
}

async function loadUsbDevices() {
  refreshUsb.disabled = true;
  try {
    const result = await window.desktopBridge.listUsbDevices();
    renderUsbDevices(result);
  } catch (error) {
    usbDevice.innerHTML = "";
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "USB refresh failed";
    usbDevice.append(option);
    setStatus("USB refresh failed.");
    output.textContent = error.message;
  } finally {
    refreshUsb.disabled = false;
  }
}

async function runAction(actionName, runner) {
  const payload = getPayload();
  if (!payload.source || !payload.library) {
    setStatus(isUsbMode() ? "USB device and archive folder are required." : "Source and archive folders are required.");
    return;
  }

  planButton.disabled = true;
  runButton.disabled = true;
  setStatus(`${actionName} in progress...`);

  try {
    const result = await runner(payload);
    renderResult(result);
    const summary = result.summary || {};
    if (result.command === "plan") {
      setStatus(
        `Plan finished. ${summary.ready_to_import ?? 0} ready, ${summary.duplicates ?? 0} duplicates, ${summary.unsupported ?? 0} unsupported, ${summary.failed ?? 0} failed, ${summary.total ?? 0} total.`,
      );
    } else {
      setStatus(
        `${actionName} finished. ${summary.imported ?? 0} imported, ${summary.duplicates ?? 0} duplicates, ${summary.unsupported ?? 0} unsupported, ${summary.failed ?? 0} failed, ${summary.total ?? 0} total.`,
      );
    }
  } catch (error) {
    output.textContent = error.message;
    setStatus(`${actionName} failed.`);
  } finally {
    planButton.disabled = false;
    runButton.disabled = false;
  }
}

pickSource.addEventListener("click", () => pickInto(sourcePath));
pickLibrary.addEventListener("click", () => pickInto(libraryPath));
refreshUsb.addEventListener("click", loadUsbDevices);
sourceKind.addEventListener("change", syncSourceModeUi);
planButton.addEventListener("click", () => runAction("Plan", window.desktopBridge.planImport));
runButton.addEventListener("click", () => runAction("Import", window.desktopBridge.runImport));

window.addEventListener("DOMContentLoaded", async () => {
  const defaults = await window.desktopBridge.getDefaults();
  sourceKind.value = defaults.sourceKind;
  sourcePath.value = defaults.source;
  libraryPath.value = defaults.library;
  syncSourceModeUi();
  await loadUsbDevices();
});
