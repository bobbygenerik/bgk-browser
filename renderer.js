const webview = document.getElementById('view')
const urlInput = document.getElementById('url-input')
const backBtn = document.getElementById('back')
const forwardBtn = document.getElementById('forward')
const reloadBtn = document.getElementById('reload')
const goBtn = document.getElementById('go')

// Load URL on Enter key
urlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        navigateTo(urlInput.value)
    }
})

// Load URL on Go button click
goBtn.addEventListener('click', () => {
    navigateTo(urlInput.value)
})

// Navigation controls
backBtn.addEventListener('click', () => {
    if (webview.canGoBack()) {
        webview.goBack()
    }
})

forwardBtn.addEventListener('click', () => {
    if (webview.canGoForward()) {
        webview.goForward()
    }
})

reloadBtn.addEventListener('click', () => {
    webview.reload()
})

// Update address bar when page loads
webview.addEventListener('did-navigate', (e) => {
    urlInput.value = e.url
})

webview.addEventListener('did-navigate-in-page', (e) => {
    urlInput.value = e.url
})

// Helper to handle URL formatting
function navigateTo(url) {
    let targetUrl = url
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
        targetUrl = 'https://' + targetUrl
    }
    webview.loadURL(targetUrl)
}
