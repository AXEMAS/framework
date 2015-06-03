; (function(win, undefined) {
    "use strict";

    var axemas = win['axemas'] = (win['axemas'] || {} );

    axemas.goto = function(data) {
        if (typeof data === 'string' || data instanceof String)
            data = {'url': data};
        
        if (axemas.getPlatform() == 'unsupported')
            window.location = '../' + data["url"];
        else
            axemas.call('goto', data);
    };

    axemas.gotoFromSidebar = function(data) {
        if (typeof data === 'string' || data instanceof String)
            data = {'url': data};
        
        if (axemas.getPlatform() == 'unsupported')
            window.location = '../' + data["url"];
        else
            axemas.call('gotoFromSidebar', data);
    };

    axemas.showProgressHUD = function() {
        axemas.call('showProgressHUD', "");
    };

    axemas.hideProgressHUD = function() {
        axemas.call('hideProgressHUD', "");
    };

    axemas.dialog = function(title, message, buttons, onButtonClickCallback) {
        axemas.call('dialog', {title: title,
                               message: message,
                               buttons: buttons},
                    onButtonClickCallback);
    };

    axemas.alert = function(title, message) {
        axemas.dialog(title, message, ['Ok']);
    };
    
    axemas.getPlatform = function() {
        if (navigator.userAgent.match(/Android/i))
            return 'android';
        if (navigator.userAgent.match(/iPhone|iPad|iPod/i))
            return 'ios';

        return 'unsupported';
    };

    axemas.storeData = function(key, value){
        if(typeof(localStorage) !== "undefined") {
            localStorage.setItem(key, value);
        } else {
            alert("local storage is unavailable");
        }
    };

    axemas.fetchData = function(key){
        if(typeof(localStorage) !== "undefined") {
            return localStorage.getItem(key);
        } else {
            alert("local storage is unavailable");
        }
    };

    axemas.removeData = function(key){
        if(typeof(localStorage) !== "undefined") {
            localStorage.removeItem(key);
        } else {
            alert("local storage is unavailable");
        }
    };

    axemas.call = function(handlerName, data, responseCallback) {
        WebViewJavascriptBridge.callHandler(handlerName, data, responseCallback);
    };

    axemas.register = function(handlerName, handler) {
        WebViewJavascriptBridge.registerHandler(handlerName, handler);
    };


    // Support for native calls on Android
    if (axemas.getPlatform() == 'android') {
        if (!win.WebViewJavascriptBridge) {
            var messageHandlers = {};
            var responseCallbacks = {};
            var uniqueId = 1;

            var callHandler = function(handlerName, data, responseCallback) {
                var message = {data: data};
                if (responseCallback) {
                    var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
                    responseCallbacks[callbackId] = responseCallback;
                    message['callbackId'] = callbackId;
                }

                var encodedMessage = JSON.stringify(message);
                AndroidNativeJS.callAndroid(handlerName, encodedMessage);
            };

            var registerHandler = function(handlerName, handler) {
                messageHandlers[handlerName] = handler;
            };

            var _callJSCallback = function(callbackId, data) {
                var responseCallback = responseCallbacks[callbackId];
                if (!responseCallback) { return; }
                delete responseCallbacks[callbackId];
                responseCallback(data);
            };

            var _callJSHandler = function(handlerName, data, callbackId) {
                var responseCallback = function(responseData) {
                    AndroidNativeJS.callAndroidCallback(callbackId,
                                                        JSON.stringify(responseData));
                }

                var handler = messageHandlers[handlerName];
                if (!handler) {
                    console.log('No handler in place for message', data);
                    responseCallback({});
                    return;
                }

                handler(data, responseCallback);
            }

            win.WebViewJavascriptBridge = {
                registerHandler: registerHandler,
                callHandler: callHandler,
                _callJSCallback: _callJSCallback,
                _callJSHandler: _callJSHandler
            };
        }
    }

    // Support for native calls on iOS
    if (axemas.getPlatform() == 'ios') {
        if (!win.WebViewJavascriptBridge) {
            var messagingIframe
            var sendMessageQueue = []
            var receiveMessageQueue = []
            var messageHandlers = {}

            var CUSTOM_PROTOCOL_SCHEME = 'wvjbscheme'
            var QUEUE_HAS_MESSAGE = '__WVJB_QUEUE_MESSAGE__'

            var responseCallbacks = {}
            var uniqueId = 1

            var _createQueueReadyIframe = function(doc) {
                messagingIframe = doc.createElement('iframe')
                messagingIframe.style.display = 'none'
                doc.documentElement.appendChild(messagingIframe)
            }

            var send = function(data, responseCallback) {
                _doSend({ data:data }, responseCallback)
            }

            var registerHandler = function(handlerName, handler) {
                messageHandlers[handlerName] = handler
            }

            var callHandler = function(handlerName, data, responseCallback) {
                _doSend({ handlerName:handlerName, data:data }, responseCallback)
            }

            var _doSend= function(message, responseCallback) {
                if (responseCallback) {
                    var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime()
                    responseCallbacks[callbackId] = responseCallback
                    message['callbackId'] = callbackId
                }
                sendMessageQueue.push(message)
                messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE
            }

            var _fetchQueue = function() {
                var messageQueueString = JSON.stringify(sendMessageQueue)
                sendMessageQueue = []
                return messageQueueString
            }

            var _defaultHandler = function(data, responseCallback) {
                console.log('No handler in place for message', data);
                if (responseCallback)
                    responseCallback(null);
            }

            var  _dispatchMessageFromObjC = function(messageJSON) {
                setTimeout(function _timeoutDispatchMessageFromObjC() {
                    var message = JSON.parse(messageJSON)
                    var messageHandler

                    if (message.responseId) {
                        var responseCallback = responseCallbacks[message.responseId]
                        if (!responseCallback) { return; }
                        delete responseCallbacks[message.responseId]
                        responseCallback(message.responseData)
                    } else {
                        var responseCallback
                        if (message.callbackId) {
                            var callbackResponseId = message.callbackId
                            responseCallback = function(responseData) {
                                _doSend({ responseId:callbackResponseId, responseData:responseData })
                            }
                        }

                        var handler = _defaultHandler
                        if (message.handlerName) {
                            handler = messageHandlers[message.handlerName]
                        }

                        try {
                            handler(message.data, responseCallback)
                        } catch(exception) {
                            if (typeof console != 'undefined') {
                                console.log("WebViewJavascriptBridge: WARNING: javascript handler threw.", message, exception)
                            }
                        }
                    }
                })
            }

            var _handleMessageFromObjC = function(messageJSON) {
                _dispatchMessageFromObjC(messageJSON)
            }

            win.WebViewJavascriptBridge = {
                send: send,
                registerHandler: registerHandler,
                callHandler: callHandler,
                _fetchQueue: _fetchQueue,
                _handleMessageFromObjC: _handleMessageFromObjC
            }

            var doc = win.document
            _createQueueReadyIframe(doc)
        }
    }

})(window);


