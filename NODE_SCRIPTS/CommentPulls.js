//Modules
//var request = require("request");
var request = require('requestretry');
var tryjson = require('tryjson');
var sleep = require('system-sleep');
var pg = require('pg');
var ProxyAgent = require('proxy-agent');

var proxyUri = process.env.http_proxy || 'http://177.128.156.207:65103';
//Connection Config
var dbConfig = {
    database: 'github',
    port: 5432,
    host: 'localhost',
    user: 'postgres',
    password: 'postgres',
    max: 60
};


const pool = new pg.Pool(dbConfig)
global.remainingCalls = 60;

//var page = 2
//var repos = 'eclipse/vert.x'
//var repos = 'eclipse/actf'

var reposit = [];
reposit.push(

    'eclipse/che'


)


for (let repos in reposit) {
saveCommentsFromRepo(reposit[repos])
}


function saveCommentsFromRepo(repos) {
    getLastPageSaveFirst(repos, function(err, results) {

        if (results > 1) { console.log(results + ' Pages on repo: ' + repos) };
        for (let i = 1; i < results; i++) {

            getCommentsFromPage(repos, i + 1)
        }
    });
}



async function getLastPageSaveFirst(repos, callback) {
    options = {
        method: 'GET',
        url: 'https://api.github.com/repos/' + repos + '/pulls/comments?per_page=100',
        headers: { 'user-agent': 'node.js' },
        retryStrategy: myRetryStrategy,
        delayStrategy: myDelayStrategy,
        protocol: 'https:',
        agent: new ProxyAgent(proxyUri)
    };
    request(options, function(error, response, body) {
        if (error) throw new Error(error);
        try {
            var data = tryjson.parse(body);
            console.log(data ? data.html_url : 'Error parsing JSON!');
            global.remainingCalls = response.headers['x-ratelimit-remaining'];
            console.log('Remaining Calls: ' + global.remainingCalls)

            saveResults(repos, data, function(err, results) {
                //console.log('Saved the first page from repos:' +repos)
            })
            //pega esquerda 10 do last, depois pega a parte dps do =        
            var str = response.headers['link']
            var aux = str.substring(str.lastIndexOf('>; rel="last"') - 10, str.lastIndexOf('>; rel="last"'))
            var totalPages = aux.substring(aux.lastIndexOf('=') + 1, str.length)
            return callback(null, totalPages)
        } catch (err) {
            return callback(err, 1)
        }
    });
}

function saveResults(repos, data, callback) {
    pool.connect().then(client => {
        if (data.length == 0) {
            //Insere o repo pra nao passar em branco
            client.query('INSERT INTO public.t_comment (path) VALUES($1)', [repos])
        } else {
            for (var i = data.length - 1; i >= 0; i--) {
                try {
                    //Insere colaborador
                    client.query('INSERT INTO public.t_comment(' +
                        'id, path, user_login, user_id, user_url, user_html_url, user_type, user_site_admin, body, created_at, updated_at)' +
                        " VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9 ,$10 ,$11)", [data[i].id,
                            repos,
                            data[i].user.login,
                            data[i].user.id,
                            data[i].user.url,
                            data[i].user.html_url,
                            data[i].user.type,
                            data[i].user.site_admin,
                            data[i].body,
                            data[i].created_at,
                            data[i].updated_at
                        ]);

                } catch (err) {
                    console.log('Inserção do registro ' + i + ' falhou.');
                    console.log('erro')
                    client.release();
                }
            }
        }
        client.release();
        return callback(null, 'ok')

    });
}



async function getCommentsFromPage(repos, page) {

    var status
    var options
    var link
    //Se temos requisicoes para fazer
    if (global.remainingCalls > 1) {
        console.log("vai fazer a call : " + repos + ' page ' + page)
        //Connect to database
        pool.connect().then(client => {

            //Request Options
            options = {
                method: 'GET',
                url: 'https://api.github.com/repos/' + repos + '/pulls/comments?per_page=100&page=' + page + '',
                headers: { 'user-agent': 'node.js' },
                retryStrategy: myRetryStrategy,
                delayStrategy: myDelayStrategy,
                protocol: 'https:',
                agent: new ProxyAgent(proxyUri)
            };


            request(options, function(error, response, body) {
                if (error) throw new Error(error);
                global.remainingCalls = response.headers['x-ratelimit-remaining'];
                console.log('Remaining Calls: ' + global.remainingCalls)

                //remainingCalls = response.headers['x-ratelimit-remaining'];
                //console.log('Remaining Calls: ' + remainingCalls)
                status = response.headers['status'];

                if (status == '200 OK') {
                    console.log('Saving data from repo: ' + repos + ', page ' + page)

                    var data = tryjson.parse(body);
                    console.log(data ? data.html_url : 'Error parsing JSON!');

                    if (data.length == 0) {
                        //Insere o repo pra nao passar em branco
                        client.query('INSERT INTO public.t_comment (path) VALUES($1)', [repos])
                    }
                    for (var i = data.length - 1; i >= 0; i--) {
                        try {
                            //Insere colaborador
                            client.query('INSERT INTO public.t_comment(' +
                                'id, path, user_login, user_id, user_url, user_html_url, user_type, user_site_admin, body, created_at, updated_at)' +
                                " VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9 ,$10 ,$11)", [data[i].id,
                                    repos,
                                    data[i].user.login,
                                    data[i].user.id,
                                    data[i].user.url,
                                    data[i].user.html_url,
                                    data[i].user.type,
                                    data[i].user.site_admin,
                                    data[i].body,
                                    data[i].created_at,
                                    data[i].updated_at
                                ]);
                        } catch (err) {
                            console.log('Inserção do registro ' + i + ' falhou.');
                        }
                    }
                } else if (status == '403 Forbidden') {
                    Console.log("Terminando, estamos sem chamadas")
                    process.exit()

                } else {
                    console.log('Erro na chamada do repo: ' + repos + ' com status: ' + status);
                }
            });
        });
        //Falta tratar um erro de quando a conexao falha com o bd.
    } else {
        Console.log("Terminando, estamos sem chamadas")
        process.exit()
    }
}


function myRetryStrategy(err, response, body) {
    // retry the request if we had an error or if the response was a 'Bad Gateway'   
    console.log("retry")
    return err || response.headers['status'] == '202 Accepted';
}

function myDelayStrategy(err, response, body) {
    // set delay of retry to a random number between 500 and 3500 ms 
    return 2000;
}