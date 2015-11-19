MANUAL_SCREEN_NAMES = %w(
) + # Bloc Québécois
%w(
  elizabethmay
) + # Green Party
%w(
) + # Forces et Démocratie
%w(
) + # Independent
%w(
  bradtrostcpc
  danalbas
  davidtilson
  davidyurdiga
  deanallisonmp
  honedfast
  honrobnicholson
  jacquesgourde
  kellyblockmp
  maximebernier
  michaelchongmp
  minksorenson
  petervanloan
  pierrepoilievre
  scottreidcpc
) + # Conservative
%w(
  honstephanedion
  judyfootemp
  toadamvaughan
) + # Liberal
%w(
  thomasmulcair
) # NDP

# Mismatches between Twitter names and parl.gc.ca names.
TWITTER_NAME_MAP = {
  'Alexandra Mendes' => 'Alexandra Mendès',
  'Anne Minh Thu Quach' => 'Anne Minh-Thu Quach',
  'Bill Blair' => 'William Blair',
  'Bob Nault' => 'Robert Nault',
  'Darshan Kang' => 'Darshan Singh Kang',
  'Deb Schulte' => 'Deborah Schulte',
  'EvaNassif Vimy' => 'Eva Nassif',
  'François-P Champagne' => 'François-Philippe Champagne',
  'Gudrid Hutchings' => 'Gudie Hutchings',
  'Harjit Sajjan' => 'Harjit S. Sajjan',
  'Marjolaine Boutin-S' => 'Marjolaine Boutin-Sweet',
  'Moore Christine' => 'Christine Moore',
  'Patty Hajdu' => 'Patricia Hajdu',
  'Rob Oliphant' => 'Robert Oliphant',
  'Robert-F Ouellette' => 'Robert-Falcon Ouellette',
  'Steve MacKinnon' => 'Steven MacKinnon',
  'T. J. Harvey' => 'TJ Harvey',
  'Tom Mulcair' => 'Thomas Mulcair',
  'Votechen' => 'Shaun Chen',
}

# The official party websites have errors. Causes "Not found" warnings. Items
# can be removed from this list once they are corrected on websites.
SCREEN_NAME_MAP = {
}

NON_MP_SCREEN_NAMES = [
  'cpc_hq',
  # Twitter
  'intent',
]

TWITTER_NAME_MAP_INVERSE = TWITTER_NAME_MAP.invert
SCREEN_NAME_MAP_INVERSE = SCREEN_NAME_MAP.invert
NON_MP_SCREEN_NAMES_COPY = NON_MP_SCREEN_NAMES.dup
