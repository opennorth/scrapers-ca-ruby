MANUAL_SCREEN_NAMES = %w(
  boudrias2015
  gabriel_smarie
  lucterjo1
  mario_beaulieu
  reloif
) + # Bloc Québécois
%w(
  elizabethmay
) + # Green Party
%w(
) + # Forces et Démocratie
%w(
) + # Independent
%w(
  alupa_clarke
  arnoldviersen
  benlobbmp
  bobzimmermp
  bradtrostcpc
  cathy_mcleod
  chriswarkentin
  danalbas
  davemackenziemp
  davidsweetmp
  davidtilson
  davidyurdiga
  deanallisonmp
  deepakobhrai
  denislebelpcc
  genereuxbernard
  gerarddeltell
  gerryritzmp
  gordbrown
  honedfast
  honrobnicholson
  jacquesgourde
  jamesbezan
  jamie_schmale
  jeneroux
  jimeglinski
  jkenney
  jlnater
  kellyblockmp
  kellymccauleymp
  kevinasorenson
  kevinasorenson
  kevinwaugh_cpc
  lucberthold
  markstrahl
  martinbowriver
  maximebernier
  melarnold2015
  michaelchongmp
  mprandyhoback
  petervanloan
  pierrepoilievre
  ronliepert
  scottreidcpc
  shannonlstubbs
  stephenharper
  stevenblaneypcc
  sylviepcc2015
  tedfalkcpc
  todddohertymp
  tomaszkmiec
  votepatkelly
  ziad4manning
) + # Conservative
%w(
) + # Liberal
%w(
) # NDP

# Mismatches between Twitter names and parl.gc.ca names.
TWITTER_NAME_MAP = {
  'Alexandra Mendes' => 'Alexandra Mendès',
  'Anne Minh Thu Quach' => 'Anne Minh-Thu Quach',
  'Bernard Genereux' => 'Bernard Généreux',
  'Bill Blair' => 'William Blair',
  'Bob Nault' => 'Robert Nault',
  'Celina R C-Chavannes' => 'Celina Caesar-Chavannes',
  'Darshan Kang' => 'Darshan Singh Kang',
  'Deb Schulte' => 'Deborah Schulte',
  'EvaNassif Vimy' => 'Eva Nassif',
  'François-P Champagne' => 'François-Philippe Champagne',
  'Ginette Peti. Taylor' => 'Ginette Petitpas Taylor',
  'Gord Brown' => 'Gordon Brown',
  'Gudrid Hutchings' => 'Gudie Hutchings',
  'Harjit Sajjan' => 'Harjit S. Sajjan',
  'Marjolaine Boutin-S' => 'Marjolaine Boutin-Sweet',
  'Mary Ann Mihychuk' => 'MaryAnn Mihychuk',
  'Moore Christine' => 'Christine Moore',
  'Nate Erskine-Smith' => 'Nathaniel Erskine-Smith',
  'Patty Hajdu' => 'Patricia Hajdu',
  'Rob Oliphant' => 'Robert Oliphant',
  'Robert-F Ouellette' => 'Robert-Falcon Ouellette',
  'Steve MacKinnon' => 'Steven MacKinnon',
  'T. J. Harvey' => 'TJ Harvey',
  'Tom Mulcair' => 'Thomas Mulcair',
}

# The official party websites have errors. Causes "Not found" warnings. Items
# can be removed from this list once they are corrected on websites.
SCREEN_NAME_MAP = {
  # Liberal
  'bryanmay17' => '_bryanmay',
  'gptaylor2015' => 'gptaylormrd',
  'l_macaulaymp' => 'l_macaulay',
  'mcdonald4avalon' => 'avalonmpken',
  'remi_masseplc' => 'remi_masse1',
  'rubys22' => 'mprubysahota',
  'rusnak2015' => 'donrusnakmp',
  'scarpaleggiamp' => 'scarpaleggialsl',
  'stephenfuhr' => 'fuhr2015',
  'votecelina' => 'celinachavannes',
  'votechen' => 'shaun_chen',
  'votegengtan' => 'gengtanmp',
  'votejatisidhu' => 'jatisidhulpc',
  'votemihychuk' => 'mpmihychuk',
  'votenatebey' => 'beynate',
  'votesorbara' => 'fsorbara',
  'votewhalen' => 'nickwhalenmp',
  'yswahmed' => 'ahmedhussenmp',

}

NON_MP_SCREEN_NAMES = [
  'cpc_hq',
  # Twitter
  'intent',
]

TWITTER_NAME_MAP_COPY = TWITTER_NAME_MAP.keys
SCREEN_NAME_MAP_COPY = SCREEN_NAME_MAP.keys
NON_MP_SCREEN_NAMES_COPY = NON_MP_SCREEN_NAMES.dup
