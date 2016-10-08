/*global $, WebSocket */

$(document).ready(function() {
    // see https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications
    var buffer = [];
    var pkg_list_size = 15;

    var connect = function () {
        var socket ;
        var ws_url = document.baseURI.replace(/^http/,"ws") + 'pkg';
        console.debug("opening websocket to "+ ws_url);

        socket = new WebSocket(ws_url);
        $("#reconnect").hide();

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
            $('#status').html('Socket closed');
            $("#reconnect").show();
        };

        socket.onopen = function() {
            console.debug("connected");
            $('#status').html('Connected');
        };
    };

    $("#reconnect").click(connect);
    connect();

});
