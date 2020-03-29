import asyncdispatch
import jester
import os
import posix
import strutils
import  htmlgen, asyncfile, asyncstreams, streams
import strutils
import ws, ws/jester_extra

onSignal(SIGABRT):
    ## Handle SIGABRT from systemd
    # Lines printed to stdout will be received by systemd and logged
    # Start with "<severity>" from 0 to 7
    echo "<2>Received SIGABRT"
    quit(1)

onSignal(SIGINT):
    echo "<2>Recieved SIGINT"
    quit(1)

include "templates/main.html"

router myrouter:
    get "/":
        var html = """
            <script>
            function submit_file() {
            let ws = new WebSocket("ws://localhost:3000/ws-upload");
            let filedom = document.querySelector("#input-field");
            ws.onmessage = function(evnt) {
                console.log(evnt.data);
            }
            ws.onopen = function(evnt) {
                ws.send(filedom.files[0].name);
                ws.send(filedom.files[0].slice());
                ws.close();
            }
            return true;
            }
            </script>
        """
        for file in walkFiles("*.*"):
            html.add "<li>" & file & "</li>"
        html.add "<form action=\"upload\" method=\"post\"enctype=\"multipart/form-data\">"
        html.add "<input id=\"input-field\" type=\"file\" name=\"file\" value=\"file\">"
        html.add "<input type=\"button\" value=\"Submit\" name=\"submit-button\" onclick=\"submit_file()\">"
        html.add "</form>"
        resp(html)
  
    get "/ws-upload":
        try:
            var wsconn = await newWebSocket(request)
            await wsconn.send("send the filename")
            var fname = await wsconn.receiveStrPacket()
            var f = openAsync(fname, fmWrite)
            while wsconn.readyState == Open:
                let (op, seqbyte) = await wsconn.receivePacket()
                if op != Binary:
                    resp Http400, "invalid sent format"
                    wsconn.close()
                    return
                var cnt = 0
                if seqbyte.len < 4096:
                    await f.write seqbyte.join
                    continue
                
                while cnt < (seqbyte.len-4096):
                    let datastr = seqbyte[cnt .. cnt+4095].join
                    cnt.inc 4096
                    await f.write(datastr)
                
                wsconn.close()
            f.close()
        except:
            echo "websocket close: ", getCurrentExceptionMsg()
        resp Http200, "file uploaded"

    get "/hello/@name":
        var name: string = @"name"
        # This matches "/hello/fred" and "/hello/bob".
        # In the route ``@"name"`` will be either "fred" or "bob".
        # This can of course match any value which does not contain '/'.
        echo name
        resp "hello " & name

proc main() =
    let port = parseInt("3000").Port
    let staticDir = joinPath(getCurrentDir(), "../public")
    let settings = newSettings(port=port, staticDir=staticDir)
    var jester = initJester(myrouter, settings=settings)
    jester.serve()
    
when isMainModule:
    main()