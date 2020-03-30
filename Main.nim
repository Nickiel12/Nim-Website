import asyncdispatch
import jester
import os
import posix
import strutils
import asyncfile, asyncstreams
import strutils
import ws, ws/jester_extra
import times

onSignal(SIGABRT):
    ## Handle SIGABRT from systemd
    # Lines printed to stdout will be received by systemd and logged
    # Start with "<severity>" from 0 to 7
    echo "<2>Received SIGABRT"
    quit(1)

onSignal(SIGINT):
    echo "<2>Recieved SIGINT"
    quit(1)

include "templates/Home.html"

router myrouter:
    get "/audition/@name":
        resp(home_page(@"name"))
  
    get "/ws-upload/@name":
        echo "connected"
        discard existsOrCreateDir("loaded_files/")
        discard existsOrCreateDir("loaded_files/" & @"name")
        try:
            var wsconn = await newWebSocket(request)
            await wsconn.send("send the filename")
            var fname = await wsconn.receiveStrPacket()
            let fileExt = splitFile(fname).ext
            var part = await wsconn.receiveStrPacket()
            
            let fileName = "loaded_files/" & @"name" & "/" & part & " : " & format(getTime(), "d MMMM yyyy HH-mm") & fileExt
            echo "Recieved, saving file to ", filename
            var f = openAsync(fileName, fmWrite)
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
        redirect "Success/" & @"name"

    get "/Sucess/@name":
        var name: string = @"name"
        # This matches "/hello/fred" and "/hello/bob".
        # In the route ``@"name"`` will be either "fred" or "bob".
        # This can of course match any value which does not contain '/'.
        echo name
        resp "You're File Has Successfully Uploaded"

proc main() =
    let port = parseInt("3000").Port
    let staticDir = joinPath(getCurrentDir(), "/public")
    let settings = newSettings(port=port, staticDir=staticDir)
    var jester = initJester(myrouter, settings=settings)
    jester.serve()
    
when isMainModule:
    main()