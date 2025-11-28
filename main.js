const { app, BrowserWindow, BrowserView } = require('electron')
const path = require('path')

function createWindow() {
    const win = new BrowserWindow({
        width: 1024,
        height: 768,
        webPreferences: {
            webviewTag: true, // Enable webview tag for our browser UI
            nodeIntegration: true, // For simplicity in this MVP, though usually discouraged
            contextIsolation: false // For simplicity in this MVP
        }
    })

    win.loadFile('index.html')
}

app.whenReady().then(() => {
    createWindow()

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow()
        }
    })
})

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
    }
})
