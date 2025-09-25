-module(island).

% functions you need to call for your implementation of island_par.
-export([rand_census/3, sim/1, sim/2, stats/2]).

% We'll export our other functions so you can run them from the Erlang
% shell prompt if you want to see what they do.
-export([flatten_census/1, unflatten_census/1, rand_permute/1, next_gen/1,
	 next_gen/2, offspring/1, names/0, names/1]).


rand_census(N_names, MeanPop0, StdPop0) ->
  [   {Name, max(round(StdPop0*rand:normal() + MeanPop0), 1)}
    || Name <- names(N_names) ].

sim(Census, Verbose) ->
  case Verbose of
    false -> ok;
    _ -> print_census(0, none, Census)
  end,
  sim(0, Census, length(Census), Verbose).
sim(Census) -> sim(Census, false).

sim(Generation, Census, N_Names, Verbose) ->
  NextCensus = next_gen(Census),
  N_Next = length(NextCensus),
  case Verbose of
    all ->
      print_census(Generation+1, Census, NextCensus);
    change when N_Next /= N_Names ->
      print_census(Generation+1, Census, NextCensus);
    _ -> ok
  end,
  case N_Next of
    1 -> Generation+1;
    _ -> sim(Generation+1, NextCensus, N_Next, Verbose)
  end.

% stats(C0, N_trials)
% Return the estimated mean and standard deviation of the number of generations
% it takes for the island population to reach a generation where everyone has
% the same surname starting from the distribution given by C0.  N_trials is
% the number of runs of sim/1 to make to calculate these statistics.
stats(C0, N_trials) ->
  A = stats(C0, N_trials, stat:create()),
  [{mean, stat:mean(A)}, {std, stat:std(A)}].

stats(_C0, 0, Acc) -> Acc;
stats(C0, N, Acc) ->
  stats(C0, N-1, stat:accum(sim(C0), Acc)).


flatten_census(Census) -> flatten_census(Census, []).

flatten_census([{_, 0} | Tl], Acc) -> flatten_census(Tl, Acc);
flatten_census([{Name, N} | Tl], Acc) when is_integer(N), 0 < N ->
  flatten_census([{Name, N-1} | Tl], [Name | Acc]);
flatten_census([], Acc) -> Acc.

unflatten_census(NameList) -> unflatten_census(lists:sort(NameList), 1, []).

unflatten_census([], 1, []) -> [];
unflatten_census([Name], NameCount, Acc) -> [{Name, NameCount} | Acc];
unflatten_census([Name | Tl = [Name | _]], NameCount, Acc) ->
  unflatten_census(Tl, NameCount+1, Acc);
unflatten_census([Name | Tl], NameCount, Acc) ->
  unflatten_census(Tl, 1, [{Name, NameCount} | Acc]).

rand_permute(List) ->
  [    X
    || {_,X} <- lists:sort([{rand:uniform(),Y} || Y <- List]) ].

offspring([Parent1, _Parent2 | Tl]) ->
  [Parent1, Parent1 | offspring(Tl)];
offspring(_) -> [].

next_gen(Census) -> unflatten_census(offspring(rand_permute(flatten_census(Census)))).

next_gen(0, Census) -> Census;
next_gen(Generations, Census) when is_integer(Generations), 0 < Generations ->
  next_gen(Generations-1, next_gen(Census)).


print_census(Generation, OldC, NewC) ->
  io:format("Generation = ~4b.  Census = ~p.", [Generation, NewC]),
  NewCensus = lists:sort(NewC),
  NewNames = [ Name || {Name, _} <- NewCensus],
  case OldC of
    none -> io:format("~n");
    _ ->
      OldCensus = lists:sort(OldC),
      OldNames = [ Name || {Name, _} <- OldCensus],
      case OldNames -- NewNames of
	[] -> io:format("~n");
	Departed -> io:format("  Say good-bye to ~w.~n", [Departed])
      end
  end.



names() ->  % from https://forebears.io/canada/surnames
  Names = 
    [ "Smith", "Brown", "Tremblay", "Martin", "Roy", "Gagnon", "Lee", "Wilson", "Johnson", "MacDonald",
      "Taylor", "Campbell", "Anderson", "Jones", "Leblanc", "Cote", "Williams", "Miller", "Thompson", "Gauthier",
      "White", "Morin", "Wong", "Young", "Bouchard", "Scott", "Stewart", "Pelletier", "Lavoie", "Robinson",
      "Moore", "Belanger", "Singh", "Fortin", "Levesque", "Chan", "Reid", "Ross", "Clark", "Johnston",
      "Walker", "Thomas", "King", "Gagne", "Bergeron", "Li", "Boucher", "Landry", "Poirier", "Murray",
      "Murphy", "McDonald", "Wright", "Richard", "Mitchell", "Girard", "Clarke", "Davis", "Simard", "Kelly",
      "Lewis", "Graham", "Caron", "Wang", "Fraser", "Fournier", "Jackson", "Beaulieu", "Wood", "Hall",
      "Baker", "Chen", "Hill", "Harris", "Green", "Roberts", "Lapointe", "Bell", "Ouellet", "Patel", "Watson",
      "Kennedy", "Cloutier", "Robertson", "Allen", "Lefebvre", "Nguyen", "Hamilton", "Desjardins", "Adams", "Gill",
      "Khan", "Cameron", "Morrison", "Dube", "Evans", "Grant", "Nadeau", "Zhang", "Peters", "Armstrong",
      "Phillips", "Hebert", "Cook", "Poulin", "Liu", "Michaud", "Kim", "Martel", "Edwards", "Turner",
      "Nelson", "Bennett", "Cooper", "Ferguson", "Gray", "Paquette", "Marshall", "Cormier", "Simpson", "Harvey",
      "McLean", "Collins", "Leclerc", "Bedard", "Grenier", "Russell", "Couture", "Lessard", "Cyr", "Ward",
      "Shaw", "Boudreau", "Bernier", "Lambert", "Lalonde", "Friesen", "Blais", "Proulx", "Morris", "Arsenault", "Parker",
      "Henderson", "Demers", "Gilbert", "Hunter", "Gallant", "Davidson", "Dupuis", "Elliott", "Walsh", "Turcotte", "Lemieux",
      "Harrison", "Lachance", "Carter", "Richardson", "Beaudoin", "James", "Foster", "Gosselin", "MacKenzie", "Gordon",
      "Fisher", "Hughes", "Parent", "Theriault", "Lam", "Rogers", "Perron", "Gibson", "Ryan", "Morgan", "Langlois",
      "Savard", "Perreault", "Patterson", "Thibault", "McLeod", "Bailey", "Mercier", "McKay", "Villeneuve", "St-Pierre",
      "Raymond", "Thomson", "Dion", "Fortier", "Charbonneau", "Bernard", "Robert", "Dubois", "Giroux", "Leung",
      "Dufour", "Schmidt", "Paradis", "Black", "Davies", "Ouellette", "Houle", "MacLeod", "Menard", "Rose",
      "Champagne", "Plante", "Mills", "Benoit", "Tran", "MacLean", "Leduc", "Boisvert", "Wu", "Allard", "Legault",
      "Hamel", "Wiebe", "Stevens", "Berube", "Lemay", "Lacroix", "Rousseau", "Labelle", "Renaud", "Bolduc",
      "Klassen", "Paul", "Parsons", "Bertrand", "Perry", "Bilodeau", "Henry", "Ellis", "Ng", "Wallace",
      "Burns", "Mason", "Hunt", "Park", "Ho", "Fontaine", "Seguin", "Therrien", "Andrews", "Crawford",
      "Butler", "Brooks", "Gervais", "Kerr", "Yu", "Dyck", "Yang", "Alexander", "Price", "Burke", "Saunders",
      "Boivin", "McKenzie", "O'Brien", "Tessier", "Richards", "Lawrence", "Holmes", "Dionne", "Goulet", "Sullivan",
      "Power", "Cole", "Guay", "Lepage", "Lauzon", "MacKay", "Ali", "Vincent", "Huang", "Vachon", "Robichaud",
      "Doucet", "Jacques", "Dunn", "Gravel", "Picard", "Noel", "Doyle", "Matthews", "Carrier", "Paquet",
      "Moreau", "Larocque", "Peterson", "Chapman", "Sinclair", "Palmer", "Sutherland", "Duncan", "Cox", "Stevenson",
      "Pilon", "Vaillancourt", "Craig", "Porter", "Savoie", "Jean", "Godin", "Chartrand", "Mann", "Page", "Comeau",
      "Cheung", "Boyd", "Daigle", "Desrosiers", "George", "Sharma", "Trudel", "Hart", "Penner", "Wells", "Robitaille",
      "Pearson", "Rioux", "Lapierre", "Hansen", "Francis", "Dumont", "Charron", "Ford", "Douglas", "Fox", "Gingras",
      "Woods", "Dixon", "Warren", "Lau", "Barnes", "Chow", "Spencer", "Gendron", "Lin", "Reynolds", "Marchand",
      "Audet", "Jensen", "Lavigne", "Cunningham", "McIntyre", "Bourque", "Lavallee", "Bradley", "Deschenes", "Tang", "MacKinnon",
      "Larouche", "Powell", "Dawson", "Long", "Cheng", "Currie", "Fleming", "Potvin", "Drouin", "Laplante", "Gaudet",
      "Knight", "Olson", "Hayes", "Webb", "Carriere", "Ahmed", "Paquin", "Payne", "Thibodeau", "Bishop", "Wall", "Beauchamp",
      "Chabot", "Laflamme", "Pare", "Brunet", "Blanchard", "Little", "West", "Howard", "Lussier", "Tardif", "Nicholson",
      "Burton", "Day", "Boutin", "Blanchette", "McCarthy", "Duguay", "Chung", "Wagner", "Atkinson", "Williamson", "Bourgeois",
      "Breton", "Barrett", "Pepin", "Auger", "Turgeon", "Hardy", "Chang", "Desrochers", "McLaughlin", "Rivard",
      "Ma", "Chouinard", "Veilleux", "Racine", "Beaudry", "Neufeld", "Laroche", "Joseph", "Roberge", "Clement", "Giguere",
      "Chiasson", "Lamontagne", "Sandhu", "Denis", "Oliver", "Lang", "Sauve", "Gelinas", "Samson", "Stone", "Harper",
      "Coulombe", "Leroux", "Charette", "Fletcher", "Webster", "Sidhu", "David", "Carr", "Lane", "Ducharme",
      "Forget", "Munro", "McMillan", "Barker", "Lamoureux", "Lebel", "McIntosh", "Leger", "Dupont", "Hanson",
      "Tanguay", "Marcoux", "Vallee", "Marcotte", "Lacasse", "Reimer", "Spence", "Vezina", "Gregoire", "Hicks", "Myers",
      "Larose", "Lowe", "Boyer", "Pereira", "Plourde", "Labrecque", "MacNeil", "Xu", "Thiessen", "MacPherson", "Steele",
      "Laliberte", "Letourneau", "Bruce", "Beauregard", "Blouin", "Duchesne", "Jenkins", "Martineau", "Leonard", "Gillis", "Newman",
      "Sheppard", "Ball", "Allan", "Masse", "Asselin", "Dallaire", "Richer", "Weber", "Quinn", "Lafontaine", "Lu",
      "Lloyd", "Wilkinson", "Bisson", "Tucker", "Mathieu", "Cardinal", "Garcia", "Brisson", "Shah",
      "Arnold", "May", "Duval", "Doucette", "O'Connor", "Talbot", "Pouliot", "Schneider", "Chambers", "O'Neill",
      "Lafrance", "Blair", "Trottier", "Fowler", "Hudson", "Gardner", "Lynch", "Ritchie", "Emond", "Lindsay", "Piche",
      "Berry", "Buchanan", "Leclair", "Zhou", "McNeil", "Forbes", "Carroll", "Bird", "Belisle", "McKinnon",
      "Laurin", "Lafleur", "Rodrigue", "Mercer", "Dufresne", "Lawson", "Dumas", "Burgess", "Montgomery", "Chu", "Grewal",
      "Farrell", "Lariviere", "Sun", "Choi", "MacMillan", "Dhaliwal", "Albert", "Bond", "Labonte", "Law", "Thibeault",
      "Pellerin", "Germain", "Rowe", "Trepanier", "Paterson", "Le", "Giesbrecht", "Trudeau", "Sabourin", "Jordan", "Braun", "Dean",
      "Fernandes", "Archambault", "Delisle", "Jamieson", "Drolet", "Curtis", "Lemire", "Schultz", "Sirois", "Boulanger", "Griffin", "Cooke",
      "Lai", "Gaudreault", "Lo", "Fehr", "Brassard", "Carlson", "Desmarais", "Cross", "Zhao", "Poitras", "Wheeler",
      "Prevost", "Charest", "McGregor", "Noble", "Provost", "Freeman", "Durand", "Dagenais", "Morissette", "Rice", "Laberge",
      "Desbiens", "McDougall", "Lajoie", "Baxter", "Snow", "Tan", "Hopkins", "Simon", "Watt", "Aubin", "Croteau",
      "Matheson", "French", "Lachapelle", "Ethier", "Hawkins", "Dhillon", "Logan", "Gauvin", "Ferland", "Irwin", "Nielsen",
      "Cowan", "Maltais", "Morton", "Harding", "Dickson", "Tam", "Skinner", "Silva", "Martens", "Rochon", "Lafreniere", "Daoust",
      "McCallum", "Carson", "Lucas", "Labbe", "Castonguay", "McGrath", "Osborne", "Christie", "Hutchinson", "St-Onge", "Loewen",
      "Laporte", "Meyer", "Guillemette", "Brennan", "Boudreault", "Abbott", "Pearce", "Adam", "Mayer", "Langevin", "Wolfe",
      "Corriveau", "FitzGerald", "Kumar", "Deschamps", "Lim", "MacDougall", "Higgins", "Larochelle", "Stephens", "Maxwell", "Potter",
      "Brousseau", "Austin", "Bourassa", "Lagace", "Bissonnette", "Begin", "Gould", "Simmons", "Erickson", "Hickey", "Walters",
      "Blake", "Cantin", "Reed", "Doyon", "Weir", "Robillard", "Rempel", "Best", "Stephenson", "Melanson", "Beland",
      "Major", "Bastien", "Ramsay", "Frechette", "Barber", "Hogan", "Provencher", "Doiron", "Barry", "Gaudreau",
      "Sharpe", "Holland", "Sutton", "Durocher", "Prince", "Marsh", "Flynn", "Brochu", "Beck", "Lamarche", "Sanderson",
      "Coleman", "Hodgson", "Lepine", "Norman", "Watts", "Penney", "Corbeil", "Meunier", "Fillion", "Jacobs", "Julien",
      "Booth", "Brar", "Labrie", "Klein", "Lopez", "Bartlett", "Soucy", "Lamothe", "Janzen", "Chisholm", "Hanna", "Cadieux",
      "Faucher", "Rouleau", "Filion", "Levasseur", "Ladouceur", "Hoffman", "Benson", "St-Laurent", "Francoeur", "Kaur", "FitzPatrick", "Lord",
      "St Pierre", "McConnell", "Cochrane", "Cohen", "Marquis", "Howe", "Bates", "Riley", "Boily", "Olsen", "Butt", "Charles",
      "Newton", "Charlebois", "Zhu", "Roussel", "Grondin", "Lyons", "Baril", "Larson", "Milne", "Millar", "Savage",
      "Yeung", "Bowman", "Gallagher", "Garneau", "McPherson", "Rondeau", "Dennis", "Stuart", "Todd", "McCormick", "Ouimet",
      "Hammond", "Harder", "Fischer", "Blackburn", "Hamelin", "Frenette", "Fung", "Plouffe", "Huynh", "Steeves", "Hiebert",
      "Monette", "Duquette", "Joly", "Ferreira", "Leslie", "Fleury", "Campeau", "Rodriguez", "Daniels", "Jarvis",
      "McRae", "Stanley", "Goodwin", "Barton", "Lafond", "Funk", "Houde", "Gardiner", "Hewitt", "Desroches",
      "Brodeur", "Cousineau", "Delorme", "Barr", "Pratt", "McBride", "Foley", "Lamb", "St-Jean", "Boyle", "Hay", "Johnstone",
      "Barrette", "Mah", "Baird", "Muir", "Cummings", "Donaldson", "Lacombe", "Warner", "Kang", "Kwan", "Gillespie",
      "Christensen", "Jacob", "Norris", "Chiu", "McFarlane", "Orr", "Hu", "Santos", "Liang", "Martinez",
      "Bellemare", "Brisebois", "Sampson", "Nichols", "Dick", "Kent", "Godbout", "Roth", "Medeiros", "Beaupre", "Baldwin",
      "Enns", "Pike", "Owen", "Bouffard", "Deslauriers", "Mailloux", "Persaud", "Morrow", "Jobin", "Rodgers", "McArthur",
      "McGuire", "Pham", "Dumais", "Hudon", "Willis", "Ricard", "Hayward", "Irvine", "Banks", "Forest", "Chamberland", "Mueller",
      "Frank", "McLellan", "Plamondon", "John", "Poole", "Preston", "McMahon", "Becker", "Shepherd", "Griffiths", "Pitre",
      "Dubuc", "Gonzalez", "Donnelly", "Winter", "Small", "Legare", "Byrne", "Sharp", "Gregory", "Gamache",
      "Howell", "Chartier", "Robson", "McKee", "Wiens", "Guerin", "Walton", "Dugas", "Kenny", "Whalen", "Miles", "Caldwell",
      "Goyette", "Lamarre", "Beattie", "Arseneault", "Greene", "Beaudin", "Fong", "Corbett", "Dueck", "Guy", "Doherty", "Dunlop",
      "Hussain", "Blanchet", "Nash", "Huot", "Carpenter", "Berthiaume", "Lebrun", "Ahmad", "Thorne", "Larsen",
      "Huard", "Berg", "Pollock", "Viau", "Tait", "Manning", "Beauchemin", "Mohammed", "Malik", "English", "Shannon",
      "Hernandez", "Tetreault", "Read", "Hynes", "Matte", "Downey", "MacFarlane", "Patry", "Nixon", "Ayotte",
      "Sanders", "Reeves", "Fuller", "Love", "Han", "Guimond", "Beaton", "Coates", "Chin", "Costa", "Boulet",
      "Cossette", "Dussault", "Turnbull", "Donovan", "Mohamed", "Glover", "Auclair", "Messier", "He", "Song",
      "Chevalier", "Nickerson", "Welsh", "Carey", "McCann", "Allaire", "Rivest", "Berger", "Hillier", "Kemp", "Dore",
      "Lake", "Jiang", "Middleton", "Briere", "Gratton", "Dobson", "Kay", "Giles", "Toews", "Keller", "Patenaude", "Hache",
      "Vallieres", "McKenna" ],
    AtomChar = fun(C) when $a =< C, C =< $z -> C;
		  (C) when $A =< C, C =< $Z -> C + ($a - $A);
		  (_) -> $_
	       end,
    [ list_to_atom([AtomChar(C) || C <- Name ]) || Name <- Names ].

names(N) when is_integer(N), 0 =< N ->
  Names = names(),
  N_Names = length(Names),
  case N =< N_Names of
    true -> names(N, Names, N_Names, []);
    false ->
      io:format("~w:names(N=~b): N must be less than the number of names that we know, i.e. ~b~n",
		[?MODULE, N, N_Names]),
      error(bad_arg)
  end.

names(0, _, _, Acc) -> Acc;
names(N, Names, N_Names, Acc) ->
  {Name, Names2} = get_name(rand:uniform(N_Names), Names),
  names(N-1, Names2, N_Names-1, [Name | Acc]).

get_name(1, [Name | Tl]) -> {Name, Tl};
get_name(I, [Hd | Tl]) ->
  {Name, Tl2} = get_name(I-1, Tl),
  {Name, [Hd | Tl2]}.
