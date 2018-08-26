//Modules
//var request = require("request");
var request = require('requestretry');
var tryjson = require('tryjson');
var sleep = require('system-sleep');
var pg = require('pg');
var ProxyAgent = require('proxy-agent');

var proxyUri = process.env.http_proxy || 'http://64.34.21.84:80';

//Variables
var qtd_weeks = 0

var repos = [];
repos.push(
'eclipse/xtext-web'
)


GetStatsContributorsData(repos);

function myRetryStrategy(err, response, body) {
    // retry the request if we had an error or if the response was a 'Bad Gateway'   
    console.log("retry")
    return err || response.headers['status'] == '202 Accepted';
}

function myDelayStrategy(err, response, body) {
    // set delay of retry to a random number between 500 and 3500 ms 
    return 15000;
}

async function GetStatsContributorsData(repos) {
    var remainingCalls = 60;
    var status
    var options
    //Connection Config
    var dbConfig = {
        database: 'github',
        port: 5432,
        host: 'localhost',
        user: 'postgres',
        password: 'postgres',
        max: 60
    };
    var pool = new pg.Pool(dbConfig)
    //Para cada repositorio do array, tenta pegar os colaboradores
    for (let iRepo in repos) {
        //Request Options
        /*   options = {
               method: 'GET',
               url: 'https://api.github.com/repos/' + repos[iRepo] + '/stats/contributors',
               headers: { 'user-agent': 'node.js' },
               retryStrategy: myRetryStrategy,
               delayStrategy: myDelayStrategy,
               protocol: 'https:',
               agent: new ProxyAgent(proxyUri)
           };*/
        //Se temos requisicoes para fazer
        if (remainingCalls > 1) {
            console.log("vai fazer a call : " + repos[iRepo])
            //Connect to database
            pool.connect().then(client => {
                request({
                    method: 'GET',
                    url: 'https://api.github.com/repos/' + repos[iRepo] + '/stats/contributors',
                    headers: { 'user-agent': 'node.js' },
                    retryStrategy: myRetryStrategy,
                    delayStrategy: myDelayStrategy,
                    protocol: 'https:',
                    agent: new ProxyAgent(proxyUri)
                }, function(error, response, body) {
                    if (error) throw new Error(error);

                    //Atualiza variaveis do loop
                    remainingCalls = response.headers['x-ratelimit-remaining'];
                    console.log('Remaining Calls: ' + remainingCalls)
                    status = response.headers['status'];

                    if (status == '200 OK') {
                        console.log('Saving data from repo: ' + repos[iRepo])

                        var data = tryjson.parse(body);
                        console.log(data ? data.html_url : 'Error parsing JSON!');
                        if (data.length == 0) {
                            client.query('INSERT INTO public.t_contributor (path) VALUES($1)', [repos[iRepo]]);
                        } else {
                            for (let i = data.length - 1; i >= 0; i--) {

                                //Insere colaborador
                                client.query('INSERT INTO public.t_contributor(' +
                                    'login, id, url, html_url, type, site_admin, total, path)' +
                                    " VALUES ($1,    $2,     $3,     $4,     $5,     $6,     $7, $8)", [data[i].author.login,
                                        data[i].author.id,
                                        data[i].author.url,
                                        data[i].author.html_url,
                                        data[i].author.type,
                                        data[i].author.site_admin,
                                        data[i].total,
                                        repos[iRepo]
                                    ]);

                                //Identifica Semanas  do projeto
                                qtd_weeks = data[i].weeks.length

                                //Insere Associacoes
                                for (let x = data[i].weeks.length - 1; x >= 0; x--) {
                                    if (data[i].weeks[x].c != 0) {
                                        client.query('INSERT INTO public.t_contribution(' +
                                            'login, id, path, week, additions, deletions, commits)' +
                                            " VALUES ($1,    $2,     $3,     to_timestamp($4)::date,     $5,     $6,     $7)", [
                                                data[i].author.login,
                                                data[i].author.id,
                                                repos[iRepo],
                                                data[i].weeks[x].w,
                                                data[i].weeks[x].a,
                                                data[i].weeks[x].d,
                                                data[i].weeks[x].c
                                            ])
                                    }
                                }
                            }
                        }
                    } else if (status == '202 Accepted') {
                        console.log("Got a 202 message on repo: " + repos[iRepo] + ", let's give github a quarter of minute!")
                        sleep(15 * 1000); // 15 seconds
                        console.log('ahui' + repos[iRepo])
                        //Refaz o marcador do for para que rode a mesma consulta, agora esperamos o status 200 :D
                    } else if (status == '403 Forbidden') {
                        Console.log("Terminando, estamos sem chamadas")
                        process.exit()

                    } else {
                        console.log('Erro na chamada do repo: ' + repos[iRepo] + ' com status: ' + status);
                    }
                });
            });
            //Falta tratar um erro de quando a conexao falha com o bd.
        } else {
            //Aqui temos que esperar até response.header['X-RateLimit-Reset'] chegar ou chamar um proxy bolads
            //Depois fazer remainingCalls = 60 pra tentar de novo
        }
    }
}