local app = require("app.server")
--local app = require("lor.index")

app:get("/baidu", function(req, res, next)
    res:send("hello world!")
end)

app:get("/user/find", function(req, res, next)
    res:send("this is sumory.")
end)



app:run()
