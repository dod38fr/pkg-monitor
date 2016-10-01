/*global $, WebSocket */

$(document).ready(function() {
// see https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications
    var socket = new WebSocket("ws://127.0.0.1:3000/pkg");

    socket.onmessage =  function(event) {
        var data = event.data;
        if (typeof data == 'undefined' || data === null)
            return;
        console.debug("received ", data);
        $('#pkgline').html(data);
    };

    socket.onclose = function() {
       console.debug("closed ");
       $('#status').html("closed socket, please reload page to reconnect");
    };

    socket.onopen = function() {
        console.debug("connected");
        $('#pkgline').html('[waiting for data]');
    };
});
