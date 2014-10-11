MANUAL_SCREEN_NAMES = %w(
  andrebellavance
  claude_patry
) + # Bloc Québécois
%w(
  brucehyer
  elizabethmay
) + # Green Party
%w(
  brentrathgeber
  mpdeandelmastro
  fortjf
  mperreaultqc
) + # Independent
%w(
  bradtrostcpc
  brianstorseth
  f_lapointe
  galipeauorleans
  gschellenberger
  keithashfield11
  mackaycpc
  petergoldring
) + # Inactive
# davidmcguinty from scrape_liberal is also inactive.
# Cause "Old tweets" warnings.
%w(
  barrydevolin_mp
  bryanhayesmp
  christianparad
  danalbas
  davidtilson
  davidyurdiga
  honedfast
  honrobnicholson
  jacquesgourde
  jayaspinmp
  joe_preston
  johnw_mp
  kellyblockmp
  leonaaglukkaq
  maximebernier
  michaelchongmp
  min_lebel
  minksorenson
  mpeveadams
  mpmikea
  mptedfalk
  petervanloan
  pierrepoilievre
  pmharper
  ryanleefmp
  scottreidcpc
  shellyglovermin
  stellaamblermp
  susantruppe
  terenceyoungmp
) + # Conservative
%w(
  honstephanedion
  irwincotler
  judyfootemp
  l_macaulaymp
  scottandrewsmp
  toadamvaughan
) + # Liberal
%w(
  elaine_michaud
  fboivinnpd
  jtremblaynpd
  sadia_groguhe
  sanahassainia
  thomasmulcair
) # NDP

# Mismatches between Twitter names and parl.gc.ca names.
TWITTER_NAME_MAP = {
  'Alexandrine' => 'Alexandrine Latendresse',
  'Anne Minh Thu Quach' => 'Anne Minh-Thu Quach',
  'Elaine Michaud' => 'Élaine Michaud',
  'Genest-Jourdain' => 'Jonathan Genest-Jourdain',
  'Gord Brown' => 'Gordon Brown',
  'Jinny Sims' => 'Jinny Jogindera Sims',
  'Marjolaine Boutin-S.' => 'Marjolaine Boutin-Sweet',
  'Moore Christine' => 'Christine Moore',
  'T. Benskin' => 'Tyrone Benskin',
}

NON_MP_SCREEN_NAMES = [
  'hnisc', # http://www.rickdykstra.ca
  'industrycanada',
  'liberal_party',
  'm_ignatieff', # http://dominicleblanc.liberal.ca
  'parti_liberal',
  'pmwebupdates',
  'socdevsoc',
  'uwaysc', # http://www.rickdykstra.ca
  'canada_swc', # http://www.rickdykstra.ca

  # Twitter
  'intent',
  'search',
  'share',
]

BAD_SCREEN_NAMES = NON_MP_SCREEN_NAMES + [
  'pmharper', # http://www.robertgoguen.ca
]

# The official party websites have errors. Cause "Not found" warnings. Items can
# be removed from this list once they are corrected on websites.
SCREEN_NAME_MAP = {
  'rob_clarke_mp' => 'robclarkemp', # first link at robclarkemp.ca is bad
  'edholdermp' => 'edholder_mp',
  'joyce_bateman' => 'joycebatemanmp',
  'judyfoote' => 'judyfootemp',
  'justinpjtrudeau' => 'justintrudeau', # justinpjtrudeau is an old parked account
  'npdlavallesiles' => 'francoispilon', # npdlavallesiles is a riding account
  'sdionliberal' => 'honstephanedion',
  'stevenjfletcher' => 'honsfletchermp',
}

BACKUP_URLS = {
  'http://www.lukiwski.ca' => 'http://www.tomlukiwski.com',
}
