var str =  '<https://api.github.com/repositories/1911523/pulls/comments?per_page=100&page=3>; rel="next", <https://api.github.com/repositories/1911523/pulls/comments?per_page=100&page=14>; rel="last", <https://api.github.com/repositories/1911523/pulls/comments?per_page=100&page=1>; rel="first", <https://api.github.com/repositories/1911523/pulls/comments?per_page=100&page=1>; rel="prev"'



var aux = str.substring(str.lastIndexOf('>; rel="last"')-10,str.lastIndexOf('>; rel="last"'))
var return = aux.substring(aux.lastIndexOf('=')+1,str.length)