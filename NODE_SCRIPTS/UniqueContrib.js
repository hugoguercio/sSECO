//Modules
var request = require("request");
var tryjson = require('tryjson');
var sleep = require('system-sleep');
var pg = require('pg');


//Variables
var qtd_weeks = 0

var repos = [];
repos.push('eclipse/californium.actinium'
,'eclipse/californium.core'
,'eclipse/californium.element-connector'
,'eclipse/californium.scandium'
,'eclipse/californium.tools'
,'eclipse/cbi.maven.plugins'
);
//var repos = 'eclipse/aCute'
GetStatsContributorsData(repos);

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
        password: 'postgres'
    };
    var pool = new pg.Pool(dbConfig)
    //Para cada repositorio do array, tenta pegar os colaboradores
    for (let iRepo in repos) {
        //Request Options
        options = {
            method: 'GET',
            url: 'https://api.github.com/repos/' + repos[iRepo] + '/stats/contributors',
            headers: { 'user-agent': 'node.js' }
        };
        //Se temos requisicoes para fazer
        if (remainingCalls > 1) {
            console.log("vai fazer a call : " + repos[iRepo])
            //Connect to database
            pool.connect().then(client => {
                request(options, function(error, response, body) {
                    if (error) throw new Error(error);

                    //Atualiza variaveis do loop
                    remainingCalls = response.headers['x-ratelimit-remaining'];
                    console.log('Remaining Calls: ' + remainingCalls)
                    status = response.headers['status'];

                    if (status == '200 OK') {
                        console.log('Saving data from repo: ' + repos[iRepo])

                        var data = tryjson.parse(body);
                        console.log(data ? data.html_url : 'Error parsing JSON!');

                        for (var i = data.length - 1; i >= 0; i--) {

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
                            for (var x = data[i].weeks.length - 1; x >= 0; x--) {
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
                    } else if (status == '202 Accepted') {
                        console.log("Got a 202 message on repo: " + repos[iRepo] + ", let's give github a quarter of minute!")
                        sleep(15 * 1000); // 15 seconds
                        console.log('ahui' + repos[iRepo])
                        //Refaz o marcador do for para que rode a mesma consulta, agora esperamos o status 200 :D
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