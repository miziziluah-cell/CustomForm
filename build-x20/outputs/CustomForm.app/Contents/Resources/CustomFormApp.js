ObjC.import('Cocoa');
ObjC.import('WebKit');

// Keep these at file scope: Objective-C delegates are weakly retained by AppKit/WebKit.
var application = $.NSApplication.sharedApplication;
var appWindow;
var webView;
var scriptMessageHandler;
var applicationDelegate;

function unwrap(value) {
  return ObjC.unwrap(value);
}

function appRoot() {
  var environment = $.NSProcessInfo.processInfo.environment;
  return String(unwrap(environment.objectForKey($('CUSTOMFORM_APP_ROOT'))));
}

function savedTemplatesFolder() {
  var home = String(unwrap($.NSHomeDirectory()));
  var folder = home + '/Library/Application Support/Custom Form/Saved Templates';
  $.NSFileManager.defaultManager.createDirectoryAtPath_withIntermediateDirectories_attributes_error($(folder), true, null, null);
  return folder;
}

function safeFilename(value) {
  var name = String(value || 'Untitled Form').replace(/[\\/:*?"<>|]/g, '-').replace(/\s+/g, ' ').trim();
  return (name || 'Untitled Form').slice(0, 80);
}

function timestamp() {
  var now = new Date();
  var pad = function(value) { return String(value).padStart(2, '0'); };
  return now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate()) + '-' + pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds()) + '-' + String(now.getMilliseconds()).padStart(3, '0');
}

function callPage(functionName, value) {
  var script = 'window.' + functionName + ' && window.' + functionName + '(' + JSON.stringify(value) + ');';
  webView.evaluateJavaScript_completionHandler($(script), null);
}

function saveTemplate(request) {
  try {
    var folder = savedTemplatesFolder();
    var path = folder + '/' + safeFilename(request.name) + '-' + timestamp() + '.json';
    var data = $(String(request.payload)).dataUsingEncoding($.NSUTF8StringEncoding);
    var didWrite = data.writeToFile_atomically($(path), true);
    if (!didWrite) throw new Error('macOS could not write the file.');
    callPage('nativeSaveCompleted', { success: true, path: path });
  } catch (error) {
    callPage('nativeSaveCompleted', { success: false, message: String(error) });
  }
}

function loadTemplate() {
  try {
    var panel = $.NSOpenPanel.openPanel;
    panel.setTitle($('Load Custom Form Template'));
    panel.setMessage($('Choose a JSON template file to load.'));
    panel.setCanChooseFiles(true);
    panel.setCanChooseDirectories(false);
    panel.setAllowsMultipleSelection(false);
    panel.setAllowedFileTypes($(['json']));
    panel.setDirectoryURL($.NSURL.fileURLWithPath($(savedTemplatesFolder())));
    if (Number(panel.runModal()) !== Number($.NSModalResponseOK)) {
      callPage('nativeLoadCancelled', null);
      return;
    }
    var data = $.NSData.dataWithContentsOfURL(panel.URL);
    var text = $.NSString.alloc.initWithData_encoding(data, $.NSUTF8StringEncoding);
    if (!text) throw new Error('The selected file could not be read as text.');
    callPage('nativeLoadCompleted', String(unwrap(text)));
  } catch (error) {
    callPage('nativeLoadFailed', String(error));
  }
}

function handleScriptMessage(message) {
  try {
    var request = JSON.parse(String(unwrap(message.body)));
    if (request.action === 'saveTemplate' || request.action === 'saveWorkspace') saveTemplate(request);
    if (request.action === 'loadTemplate') loadTemplate();
  } catch (error) {
    callPage('nativeLoadFailed', String(error));
  }
}

var MessageHandler = ObjC.registerSubclass({
  name: 'CustomFormScriptMessageHandler',
  methods: {
    'userContentController:didReceiveScriptMessage:': {
      types: ['void', ['id', 'id']],
      implementation: function(controller, message) { handleScriptMessage(message); }
    }
  }
});

var ApplicationDelegate = ObjC.registerSubclass({
  name: 'CustomFormApplicationDelegate',
  methods: {
    'applicationShouldTerminateAfterLastWindowClosed:': {
      types: ['bool', ['id']],
      implementation: function(notification) { return true; }
    }
  }
});

application.setActivationPolicy($.NSApplicationActivationPolicyRegular);
applicationDelegate = ApplicationDelegate.alloc.init;
application.setDelegate(applicationDelegate);

var configuration = $.WKWebViewConfiguration.alloc.init;
var contentController = $.WKUserContentController.alloc.init;
scriptMessageHandler = MessageHandler.alloc.init;
contentController.addScriptMessageHandler_name(scriptMessageHandler, $('customForm'));
configuration.setUserContentController(contentController);

var styleMask = $.NSWindowStyleMaskTitled | $.NSWindowStyleMaskClosable | $.NSWindowStyleMaskMiniaturizable | $.NSWindowStyleMaskResizable;
appWindow = $.NSWindow.alloc.initWithContentRect_styleMask_backing_defer($.NSMakeRect(0, 0, 1120, 760), styleMask, $.NSBackingStoreBuffered, false);
appWindow.setTitle($('Custom Form'));
appWindow.center;

webView = $.WKWebView.alloc.initWithFrame_configuration(appWindow.contentView.bounds, configuration);
webView.setAutoresizingMask($.NSViewWidthSizable | $.NSViewHeightSizable);
appWindow.contentView.addSubview(webView);

var resources = appRoot() + '/Resources';
var pageURL = $.NSURL.fileURLWithPath($(resources + '/CustomForm.html'));
var readAccessURL = $.NSURL.fileURLWithPath($(resources));
webView.loadFileURL_allowingReadAccessToURL(pageURL, readAccessURL);

appWindow.makeKeyAndOrderFront(null);
application.activateIgnoringOtherApps(true);
application.run;
