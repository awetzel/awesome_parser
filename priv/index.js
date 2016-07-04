require('node_erlastic').server(function(term,from,state,done){
  if (term[0] == "parse") return done("reply",require('css').parse(term[1].toString()))
  throw new Error("unexpected request")
})
