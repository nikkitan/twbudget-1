csv = require \csv
argv = require \optimist .argv
fs = require \fs
file = argv.file or throw 'file required'
year = argv.year or throw 'year required'

readit = (done) ->
    entry = []
    depcat = {}
    depname = {}
    topname = {}
    var current_cat
    populate_fuzzy_entries = -> for depcatname, {name,code,amount} of depcat
        [A, B, C] = depcatname.split \.
        # no subcategory available
        unless [e for {ref}:e in entry when ref[0 to 2] === [A,B,C]].length
            _depcat = depcat["#A.#B.#C"]
            entry.push {code, amount} <<< do
                name: '無細項'
                topname: topname[A]
                depname: depname["#A.#B"]
                depcat: _depcat.name
                cat: _depcat.cat
                ref: [A, B, C]

    [...ref, code, name, amount, _, _, _,remark] <- csv!from.stream fs.createReadStream(file)
    .on \end ->
        populate_fuzzy_entries!
        done entry
    .on \record
    amount -= /,/g
    amount = +amount * 1000
    [A, B, C, D] = for x in ref => x - /^\s*|\s*$/g
    match A, B, C, D
    | /\D/                => # ignore csv header
    | _, _, _ , \999      => current_cat := name
    | _, /\S/, /\S/, /\S/ => entry.push {code, name, amount} <<< do
        topname: topname[A]
        depname: depname["#A.#B"]
        depcat: depcat["#A.#B.#C"]name
        cat: current_cat
        ref: [A, B, C, D]
    | _, /\S/, /\S/       => depcat["#A.#B.#C"] = {name,code,amount,cat:current_cat}
    | _, /\S/             => depname["#A.#B"] = name
    | otherwise           => topname[A] = name

data <- readit!
fields = <[year code amount name topname depname depcat cat ref]>
console.log fields.join \,
for {ref}:d in data
    [year] ++ d<[code amount name topname depname depcat cat]> ++ ref.join \.
    |> -> console.log it.join \,

