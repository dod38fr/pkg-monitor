/*global $, WebSocket */
"use strict";

$(document).ready(function() {
    // see https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications
    var buffer = [];
    var pkg_list_size = 15;

    $("#disconnected").hide();
    $("#connected").hide();
    $("#connecting").show();

    var connect = function () {
        var socket ;
        var ws_url = document.baseURI.replace(/^http/,"ws").replace(/#/,'') + 'pkg';
        console.debug("opening websocket to "+ ws_url);

        socket = new WebSocket(ws_url);

        socket.onmessage =  function(event) {
            var data = event.data;
            if (typeof data == 'undefined' || data === null) {
                return;
            }

            console.debug("received ", data);
            if (buffer.length > pkg_list_size) {
                buffer.shift();
            }
            buffer.push(data);
            $("#scrollDiv").html( "<p>" + buffer.join("</br>") + "</p>");
        };

        socket.onclose = function(event) {
            $("#disconnected").show();
            $("#connected").hide();
        };

        socket.onopen = function() {
            console.debug("connected");
            $("#disconnected").hide();
            $("#connected").show();
            $("#connecting").hide();
        };
    };

    $("#reconnect").click(function(){ connect(); return false; });
    connect();

});
