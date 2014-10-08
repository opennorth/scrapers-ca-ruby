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
) + # Inactive (davidmcguinty from scrape_liberal is also inactive)
%w(
  barrydevolin_mp
  bryanhayesmp
  christianparad
  danalbas
  davidtilson
  honrobnicholson
  jacquesgourde
  jayaspinmp
  joe_preston
  joycebatemanmp
  kellyblockmp
  leonaaglukkaq
  mpeveadams
  mpmikea
  pierrepoilievre
  pmharper
  scottreidcpc
  shellyglovermin
  susantruppe
  terenceyoungmp
) + # Conservative
%w(
  honstephanedion
  judyfootemp
  scottandrewsmp
) + # Liberal
%w(
  fboivinnpd
  jtremblaynpd
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

# The official party websites have errors.
SCREEN_NAME_MAP = {
  'dianeablonczymp' => 'dianeablonczy',
  'edholdermp' => 'edholder_mp',
  'jayaspin' => 'jayaspinmp',
  'joyce_bateman' => 'joycebatemanmp',
  'judyfoote' => 'judyfootemp',
  'justinpjtrudeau' => 'justintrudeau',
  'npdlavallesiles' => 'francoispilon',
  'sdionliberal' => 'honstephanedion',
}

BACKUP_URLS = {
  'http://www.lukiwski.ca' => 'http://www.tomlukiwski.com',
}
